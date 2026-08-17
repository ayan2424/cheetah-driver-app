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

class OfflineSyncService {
  static const String boxName = 'offline_pod_queue';
  static const String _encryptionKeyName = 'offline_pod_queue_key_v1';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static late Box box;
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isSyncing = false;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);

    // Previous builds stored queued POD data unencrypted. Preserve any pending
    // payloads once, then re-open the box with a key kept in device secure
    // storage. New queues never contain the bearer token.
    final storedKey = await _secureStorage.read(key: _encryptionKeyName);
    if (storedKey != null && storedKey.isNotEmpty) {
      // Secure queues from a previous launch must always be opened with their
      // existing device key. Never attempt plaintext migration in this path.
      box = await Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(base64Url.decode(storedKey)),
      );
    } else if (await Hive.boxExists(boxName)) {
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
    
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        syncPendingPods();
      }
    });
  }

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

  static Future<void> savePodToQueue(Map<String, dynamic> payload) async {
    await box.add(payload);
  }

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
            photoFile = File(payload['photo_path']);
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

          if (res['success'] == true) {
            await box.delete(key);
          }
        } catch (e) {
          // Leave it in the queue if fails
        }
      }
    }
    _isSyncing = false;
  }
}
