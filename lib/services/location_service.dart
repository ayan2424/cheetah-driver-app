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

  /// Starts background/foreground periodic live GPS location updates to server.
  static void startLiveLocationTracking(String apiToken) {
    if (apiToken.isEmpty) return;
    if (_isTracking) return;

    _isTracking = true;

    // Send immediately on start
    _sendCurrentLocation(apiToken);

    // Periodically update GPS every 10 seconds
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _sendCurrentLocation(apiToken);
    });
  }

  /// Stops periodic location updates (e.g., on logout)
  static void stopLiveLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
    if (_isGpsDialogShowing && Get.isDialogOpen == true) {
      Get.back();
      _isGpsDialogShowing = false;
    }
  }

  static Future<void> _sendCurrentLocation(String apiToken) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) print("GPS Location services disabled on device!");
        _showGpsHardwareDialog();
        return;
      } else {
        if (_isGpsDialogShowing && Get.isDialogOpen == true) {
          Get.back();
          _isGpsDialogShowing = false;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionRequiredDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionRequiredDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

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
        print("GPS Update sent: ${position.latitude}, ${position.longitude} -> $res");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sending location update: $e");
      }
    }
  }

  static void _showGpsHardwareDialog() {
    if (_isGpsDialogShowing) return;
    _isGpsDialogShowing = true;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF18181B),
          title: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text(
                'Turn ON Device GPS',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Your device Location (GPS) toggle is turned OFF.\n\nCheetah Express requires active GPS to track your delivery route and update dispatcher maps. Please turn ON GPS Location to proceed.',
            style: TextStyle(color: Color(0xFFd4d4d8), fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                _isGpsDialogShowing = false;
                if (Get.isDialogOpen == true) Get.back();
              },
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: const Text('Open GPS Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void _showPermissionRequiredDialog() {
    if (_isGpsDialogShowing) return;
    _isGpsDialogShowing = true;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF18181B),
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.amberAccent, size: 28),
              SizedBox(width: 10),
              Text(
                'Location Permission Needed',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Location permission is permanently denied or restricted. Please allow Location access in app settings to use Cheetah Driver.',
            style: TextStyle(color: Color(0xFFd4d4d8), fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                await Geolocator.openAppSettings();
                _isGpsDialogShowing = false;
                if (Get.isDialogOpen == true) Get.back();
              },
              icon: const Icon(Icons.settings, color: Colors.white),
              label: const Text('Open App Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
