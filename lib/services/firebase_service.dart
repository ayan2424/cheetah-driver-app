import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/constants.dart';
import 'session_store.dart';

// Top-level background message handler for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint("Handling background FCM push notification: ${message.messageId}");
}

/// Commercial-Grade Plug-and-Play Firebase Service
/// Operates seamlessly in Standalone Mode if Firebase is unconfigured,
/// and automatically activates Push Notifications when google-services.json is present.
class FirebaseService {
  static bool isAvailable = false;
  static String? fcmToken;

  /// Initialize Firebase Core & FCM with full crash-safety
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      isAvailable = true;
      debugPrint("Firebase Core: Initialized successfully.");

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Setup FCM permissions and message listeners
      await _setupFcm();
    } catch (e) {
      isAvailable = false;
      debugPrint("Firebase Optional Mode: App running in standalone mode ($e)");
    }
  }

  /// Configure FCM permissions, tokens, and foreground alert listeners
  static Future<void> _setupFcm() async {
    if (!isAvailable) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request Notification Permissions (Android 13+ & iOS)
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint("FCM Authorization Status: ${settings.authorizationStatus}");

      // 2. Fetch Device Token
      fcmToken = await messaging.getToken();
      debugPrint("FCM Device Token: $fcmToken");

      // 3. Foreground Message Listener (In-App Floating Alert)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Foreground FCM Message Received: ${message.notification?.title}");
        _showForegroundNotification(message);
      });

      // 4. Token Refresh Listener
      messaging.onTokenRefresh.listen((newToken) {
        fcmToken = newToken;
        debugPrint("FCM Token Refreshed: $newToken");
        syncTokenWithBackend();
      });

      // 5. Message Opened from Notification Bar
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("FCM Notification Clicked by Driver: ${message.data}");
      });
    } catch (e) {
      debugPrint("FCM Setup Warning: $e");
    }
  }

  /// Show a clean, modern floating banner when a push arrives while app is open
  static void _showForegroundNotification(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'Cheetah Dispatch Alert';
    final body = message.notification?.body ?? message.data['body'] ?? 'New update received for your route.';

    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      icon: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
      margin: const EdgeInsets.all(12),
      borderRadius: 16,
      duration: const Duration(seconds: 5),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      boxShadows: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.4),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Sync the driver's device FCM token with the Cheetah PHP backend
  static Future<void> syncTokenWithBackend([String? explicitApiToken]) async {
    if (!isAvailable || fcmToken == null || fcmToken!.isEmpty) {
      return;
    }

    try {
      final token = explicitApiToken ?? await SessionStore.readToken();
      if (token.isEmpty) return;

      final url = Uri.parse('${AppConstants.apiUrl}update_fcm_token.php');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'api_token': token,
          'fcm_token': fcmToken!,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint("FCM Token successfully synced with Cheetah Backend.");
      } else {
        debugPrint("FCM Token sync responded with HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("FCM Token sync error: $e");
    }
  }
}
