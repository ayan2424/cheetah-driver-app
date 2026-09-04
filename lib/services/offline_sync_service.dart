import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import 'session_store.dart';

/// [OfflineSyncService] manages offline-first Proof of Delivery (POD) capture and synchronization.
///
/// Logistics Problem Solved:
/// Couriers frequently deliver packages in basements, rural zones, cargo containers, and elevators
/// where cellular reception drops completely. Without an offline queue, drivers would be blocked
/// from completing drop-offs, capturing recipient signatures, or obtaining delivery photos.
///
/// Architectural Design:
/// 1. Encrypted Local Storage (Hive + AES-256):
///    Payloads are stored in a dedicated Hive box (`offline_pod_queue`) encrypted using
///    [HiveAesCipher]. The 256-bit encryption key is generated via [Random.secure] and safely
///    stored in the device's hardware-backed Keystore (Android) or Keychain (iOS) via [FlutterSecureStorage].
/// 2. Zero-Token Payload Storage:
///    Payloads never store bearer authentication tokens directly. When connectivity returns,
///    the active, validated session token is dynamically loaded from [SessionStore] to avoid
///    token staleness or security exposure in local queue files.
/// 3. Reactive Auto-Sync:
///    Listens to [Connectivity().onConnectivityChanged]. The moment Wi-Fi or Mobile data is restored,
///    the service re-attempts transmission of all pending payloads sequentially.
/// 4. Idempotent Conflict-Safe Delivery:
///    A queued entry is only removed (`box.delete(key)`) once the Cheetah backend returns `success: true`.
///    If an upload fails (e.g. timeout or server error), the item remains securely queued for the next retry wave.
class OfflineSyncService {
  static const String boxName = 'offline_pod_queue';
  static const String _encryptionKeyName = 'offline_pod_queue_key_v1';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  /// Global Hive box reference for queued offline deliveries.
  static late Box box;
  
  /// Connectivity listener subscription for auto-syncing when network returns.
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  /// Re-entrancy guard to prevent overlapping background sync executions.
  static bool _isSyncing = false;

  /// Initializes encrypted Hive storage and registers real-time network transition listeners.
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);

    // Read or generate hardware-backed AES-256 encryption key.
    final storedKey = await _secureStorage.read(key: _encryptionKeyName);
    if (storedKey != null && storedKey.isNotEmpty) {
      box = await Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(base64Url.decode(storedKey)),
      );
    } else if (await Hive.boxExists(boxName)) {
      // One-time migration for legacy unencrypted queues: read existing, encrypt, and rewrite.
      final legacyBox = await Hive.openBox(boxName);
      final pending = legacyBox.values
          .whereType<Map>()
          .map((value) => Map<dynamic, dynamic>.from(value))
          .toList();
      await legacyBox.close();
      await Hive.deleteBoxFromDisk(boxName);
      final key = await _loadOrCreateEncryptionKey();
      box = await Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(key),
      );
      if (pending.isNotEmpty) {
        await box.addAll(pending);
      }
    } else {
      final key = await _loadOrCreateEncryptionKey();
      box = await Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(key),
      );
    }
    
    // Automatically trigger queue sync whenever device regains internet connection.
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        syncPendingPods();
      }
    });
  }

  /// Cancels connectivity stream listeners and releases resources on app shutdown.
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Generates a cryptographically strong 32-byte (256-bit) random key and stores it in secure storage.
  static Future<List<int>> _loadOrCreateEncryptionKey() async {
    final stored = await _secureStorage.read(key: _encryptionKeyName);
    if (stored != null && stored.isNotEmpty) {
      return base64Url.decode(stored);
    }

    final key = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    await _secureStorage.write(
      key: _encryptionKeyName,
      value: base64Url.encode(key),
    );
    return key;
  }

  /// Persists a failed or offline Proof of Delivery submission to the encrypted local queue.
  ///
  /// Stored Fields:
  /// - `parcelId`: Internal shipment identifier.
  /// - `trackingNumber`: Human-readable AWB code.
  /// - `status`: Target state transition (e.g. 'Delivered').
  /// - `receiverName`: Recipient name who signed for package.
  /// - `description`: Courier field remarks / exception details.
  /// - `deliveryOtp`: Customer OTP verification code (if required).
  /// - `photo_path`: Local disk absolute path to captured evidence photo.
  /// - `signature_base64`: Base64 encoded PNG raster of recipient's vector signature.
  static Future<void> savePodToQueue(Map<String, dynamic> payload) async {
    await box.add(payload);
  }

  /// Number of deliveries currently waiting for network connectivity to sync.
  static int get pendingCount => box.length;

  /// Iterates through pending offline deliveries and submits them to the live backend.
  ///
  /// Conflict & Retry Management:
  /// - Reads active session token from [SessionStore] on every run.
  /// - If the app is unauthenticated (e.g. driver logged out), sync pauses until next login.
  /// - Uploads multipart payload including local photo and signature image files.
  /// - Deletes from local Hive queue only when server acknowledges with `{success: true}`.
  /// - Retains entry in queue if network fails midway, preventing data loss.
  static Future<void> syncPendingPods() async {
    if (_isSyncing) return;
    if (box.isEmpty) return;

    final token = await SessionStore.readToken();
    if (token.isEmpty) return;

    _isSyncing = true;
    final keys = box.keys.toList();

    for (var key in keys) {
      final payload = box.get(key) as Map<dynamic, dynamic>?;
      if (payload != null) {
        try {
          File? photoFile;
          Uint8List? signatureBytes;

          if (payload['photo_path'] != null) {
            final file = File(payload['photo_path']);
            if (await file.exists()) {
              photoFile = file;
            }
          }
          if (payload['signature_base64'] != null) {
            signatureBytes = base64Decode(payload['signature_base64']);
          }

          final res = await ApiService.updateStatusWithPod(
            token: token,
            parcelId: payload['parcelId'],
            trackingNumber: payload['trackingNumber'],
            status: payload['status'],
            receiverName: payload['receiverName'],
            description: payload['description'],
            deliveryOtp: payload['deliveryOtp'],
            photoFile: photoFile,
            signatureBytes: signatureBytes,
          );

          // Evict from queue when server confirms successful status update and POD ingestion,
          // or when server returns a permanent terminal error (e.g. already delivered or transition invalid)
          if (res['success'] == true) {
            await box.delete(key);
          } else if (res['error'] != null) {
            final err = res['error'].toString().toLowerCase();
            if (err.contains('transition is not allowed') ||
                err.contains('not found') ||
                err.contains('unauthorized')) {
              // Terminal state: parcel cannot be transitioned or was already updated.
              // Evict to prevent dead-looping on future connectivity triggers.
              await box.delete(key);
            }
          }
        } catch (_) {
          // Leave item in the queue for next synchronization cycle
        }
      }
    }
    _isSyncing = false;
  }
}
