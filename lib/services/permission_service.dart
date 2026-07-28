import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Requests all essential logistics permissions (GPS Location, Camera, Notifications)
  /// immediately upon App launch so the rider never encounters permission blockage.
  static Future<void> requestAllPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.camera,
        Permission.notification,
      ].request();
      
      bool allGranted = true;
      statuses.forEach((key, value) {
        if (!value.isGranted) allGranted = false;
      });
      
      if (!allGranted) {
        // Enforce permissions by requesting again if denied
        await [Permission.location, Permission.camera, Permission.notification].request();
      }
    } catch (e) {
      // Graceful fallback
    }
  }
}
