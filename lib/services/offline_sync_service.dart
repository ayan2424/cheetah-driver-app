import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class OfflineSyncService {
  static const String boxName = 'offline_pod_queue';
  static late Box box;
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isSyncing = false;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);
    box = await Hive.openBox(boxName);
    
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        syncPendingPods();
      }
    });
  }

  static Future<void> savePodToQueue(Map<String, dynamic> payload) async {
    await box.add(payload);
  }

  static Future<void> syncPendingPods() async {
    if (_isSyncing) return;
    if (box.isEmpty) return;

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
            token: payload['token'],
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
