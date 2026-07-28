import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'api_service.dart';

class LocationService {
  static Timer? _locationTimer;
  static bool _isTracking = false;
  static bool _isGpsDialogShowing = false;
  static bool _isPermissionDialogShowing = false;

  /// Starts background/foreground periodic live GPS location updates to server.
  static void startLiveLocationTracking(String apiToken) {
    if (apiToken.isEmpty) return;
    if (_isTracking) return;

    _isTracking = true;

    // Force permission & GPS check immediately on start
    _sendCurrentLocation(apiToken);

    // Periodically update GPS every 8 seconds and enforce location state
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _sendCurrentLocation(apiToken);
    });
  }

  /// Stops periodic location updates (e.g., on logout)
  static void stopLiveLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
    _dismissDialogs();
  }

  static void _dismissDialogs() {
    if ((_isGpsDialogShowing || _isPermissionDialogShowing) && Get.isDialogOpen == true) {
      Get.back();
    }
    _isGpsDialogShowing = false;
    _isPermissionDialogShowing = false;
  }

  static Future<void> _sendCurrentLocation(String apiToken) async {
    try {
      // 1. Check if device Location/GPS hardware toggle is turned ON
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) print("GPS Location services disabled on device!");
        await _forceEnableGpsHardware();
        return;
      } else {
        if (_isGpsDialogShowing && Get.isDialogOpen == true) {
          Get.back();
          _isGpsDialogShowing = false;
        }
      }

      // 2. Check & Request Location Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _forceGrantLocationPermission(isPermanent: false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _forceGrantLocationPermission(isPermanent: true);
        return;
      }

      // If permission granted & GPS enabled, close any remaining blocking dialogs
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        if (_isPermissionDialogShowing && Get.isDialogOpen == true) {
          Get.back();
          _isPermissionDialogShowing = false;
        }
      }

      // 3. Fetch exact high-accuracy GPS position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      // 4. Send live location ping to server API
      final res = await ApiService.updateLocation(
        token: apiToken,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (res['success'] == false) {
        final err = (res['error'] ?? '').toString().toLowerCase();
        if (err.contains('invalid api token') || err.contains('session expired') || err.contains('token is required')) {
          if (Get.isRegistered<AuthController>()) {
            Get.find<AuthController>().handleSessionExpired();
          }
        }
      }

      if (kDebugMode) {
        print("GPS Update sent successfully: ${position.latitude}, ${position.longitude}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error in location tracking ping: $e");
      }
    }
  }

  /// Displays an un-dismissible, persistent modal forcing the user to turn ON GPS Location Services
  static Future<void> _forceEnableGpsHardware() async {
    if (_isGpsDialogShowing) return;
    _isGpsDialogShowing = true;

    // Automatically trigger system location settings screen
    await Geolocator.openLocationSettings();

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevent dialog back button dismissal
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFF18181B),
          title: const Column(
            children: [
              Icon(Icons.location_off_rounded, color: Color(0xFFEF4444), size: 48),
              SizedBox(height: 12),
              Text(
                'GPS Location is Turned OFF',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Cheetah Express requires active GPS Location to assign delivery orders and broadcast live tracking to dispatchers.\n\nPositioning cannot be bypassed. Please turn ON Location in settings to proceed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                  if (serviceEnabled) {
                    _isGpsDialogShowing = false;
                    if (Get.isDialogOpen == true) Get.back();
                  }
                },
                icon: const Icon(Icons.gps_fixed, color: Colors.white),
                label: const Text('TURN ON GPS LOCATION NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Displays an un-dismissible, persistent modal forcing location permission grant
  static Future<void> _forceGrantLocationPermission({required bool isPermanent}) async {
    if (_isPermissionDialogShowing) return;
    _isPermissionDialogShowing = true;

    if (isPermanent) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.requestPermission();
    }

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevent dialog back button dismissal
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFF18181B),
          title: const Column(
            children: [
              Icon(Icons.gavel_rounded, color: Color(0xFFF59E0B), size: 48),
              SizedBox(height: 12),
              Text(
                'Location Access Mandatory',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            isPermanent
                ? 'Location permission is permanently blocked in device settings.\n\nPlease tap below to open App Settings and grant "Allow while using the app" permission.'
                : 'Location permission is required for rider duty and route navigation.\n\nPlease allow Location access to continue.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (isPermanent) {
                    await Geolocator.openAppSettings();
                  } else {
                    LocationPermission p = await Geolocator.requestPermission();
                    if (p == LocationPermission.whileInUse || p == LocationPermission.always) {
                      _isPermissionDialogShowing = false;
                      if (Get.isDialogOpen == true) Get.back();
                    }
                  }
                },
                icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white),
                label: Text(
                  isPermanent ? 'OPEN APP SETTINGS' : 'GRANT LOCATION ACCESS',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
