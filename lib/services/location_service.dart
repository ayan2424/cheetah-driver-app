import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class LocationService {
  static Timer? _locationTimer;
  static bool _isTracking = false;

  /// Starts background/foreground periodic live GPS location updates to server.
  static void startLiveLocationTracking(String apiToken) {
    if (apiToken.isEmpty) return;
    if (_isTracking) return;

    _isTracking = true;

    // Send immediately on start
    _sendCurrentLocation(apiToken);

    // Periodically update GPS every 15 seconds
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _sendCurrentLocation(apiToken);
    });
  }

  /// Stops periodic location updates (e.g., on logout)
  static void stopLiveLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
  }

  static Future<void> _sendCurrentLocation(String apiToken) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) print("GPS Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final res = await ApiService.updateLocation(
        token: apiToken,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (kDebugMode) {
        print("GPS Update sent: ${position.latitude}, ${position.longitude} -> $res");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sending location update: $e");
      }
    }
  }
}
