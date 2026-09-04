import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/parcel_model.dart';

/// [ApiService] acts as the central HTTP communication bridge between the Flutter mobile
/// client and the Cheetah Logistics backend (PHP/MySQLi REST endpoints).
///
/// Architectural Principles:
/// 1. Security & Token Authentication:
///    Every authenticated endpoint expects a standard Bearer token in the `Authorization`
///    header. On the server side, the plain token is SHA-256 hashed and matched against
///    `users.api_token_hash` with active expiry checks (`api_token_expires_at > NOW()`).
/// 2. Fault-Tolerant Response Parsing:
///    Field couriers frequently encounter intermittent cellular coverage and captive Wi-Fi
///    portals that return HTML error pages instead of JSON. `_decodeResponse` rigorously
///    guards against HTML body bleed and malformed JSON payloads.
/// 3. Bounded Request Timeouts:
///    Field operations require rapid failure feedback (15-second cutoff) so that pending
///    Proof of Delivery (POD) actions can gracefully fall back to the encrypted offline queue
///    rather than hanging the courier's UI in dead zones.
class ApiService {
  /// 15-second strict timeout for field operations to prevent indefinite UI blocking
  /// in remote delivery zones with spotty LTE/3G reception.
  static const _requestTimeout = Duration(seconds: 15);

  /// Generates standardized Bearer authorization headers required by Cheetah API routes.
  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// Sanitizes and validates raw HTTP responses.
  ///
  /// Prevents runtime JSON decoding exceptions when firewalls, reverse proxies,
  /// or PHP fatal errors output raw HTML error documents instead of JSON.
  static Map<String, dynamic> _decodeResponse(http.Response response) {
    // Detect HTML responses (e.g. gateway timeout, 404 HTML, or PHP error output)
    if (response.body.trim().startsWith('<')) {
      return {
        'success': false,
        'error': 'The server returned an invalid response. Please try again.',
      };
    }

    try {
      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return {
          'success': false,
          'error': 'Unexpected response format received from server.',
        };
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {
          ...decoded,
          'success': false,
          'error': decoded['error'] ?? 'The request could not be completed.',
        };
      }
      return decoded;
    } catch (_) {
      return {
        'success': false,
        'error': 'Failed to process server response. Please verify connection.',
      };
    }
  }

  /// Authenticates courier drivers and warehouse pickers against `api/v1/driver/login.php`.
  ///
  /// On successful authentication:
  /// - Server issues a 30-day cryptographically secure Bearer token.
  /// - Returns user role (`driver` vs `picker`) which dictates bottom navigation hierarchy.
  /// - Returns assigned branch scoping data (branch ID, city, hub name).
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiUrl}login.php'),
            body: {'email': email, 'password': password},
          )
          .timeout(_requestTimeout);
      return _decodeResponse(response);
    } catch (_) {
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet and try again.',
      };
    }
  }

  /// Fetches real-time Cash on Delivery (COD) balance and payout history from `get_wallet.php`.
  ///
  /// Cheetah Business Rule:
  /// Drivers collect cash upon delivering COD shipments. This endpoint retrieves the driver's
  /// unremitted cash ledger, allowing both the driver and branch supervisor to reconcile
  /// collected funds before end-of-shift cash drop-off.
  static Future<Map<String, dynamic>> fetchDriverWallet({
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiUrl}get_wallet.php'),
            headers: _authHeaders(token),
          )
          .timeout(_requestTimeout);
      return _decodeResponse(response);
    } catch (_) {
      return {
        'success': false,
        'error': 'Unable to synchronize wallet data. Please try again.',
      };
    }
  }

  /// Triggers automated password recovery email dispatch from `forgot_password.php`.
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiUrl}forgot_password.php'),
            body: {'email': email},
          )
          .timeout(_requestTimeout);
      final data = _decodeResponse(response);
      return {
        'success': data['status'] == 'success',
        'message':
            data['message'] ??
            'Check your email for password reset instructions.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Connection error. Please try again later.',
      };
    }
  }

  /// Retrieves authenticated user profile, avatar, assigned vehicle, and branch details.
  static Future<Map<String, dynamic>> fetchProfile(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiUrl}get_profile.php'),
            headers: _authHeaders(token),
          )
          .timeout(_requestTimeout);
      return _decodeResponse(response);
    } catch (_) {
      return {
        'success': false,
        'error': 'Failed to load profile. Please check your network.',
      };
    }
  }

  /// Fetches assigned delivery manifests and daily performance metrics from `get_parcels.php`.
  ///
  /// Cheetah Driver Isolation Rule:
  /// The server enforces strict SQL scoping (`WHERE driver_id = :authenticated_user_id`),
  /// ensuring couriers only receive shipments specifically dispatched to their manifest.
  /// Summary statistics (outForDelivery, inTransit, deliveredToday, codTotal) are aggregated
  /// in the same payload to minimize network roundtrips for battery preservation.
  static Future<Map<String, dynamic>> fetchParcels(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiUrl}get_parcels.php'),
            headers: _authHeaders(token),
          )
          .timeout(_requestTimeout);
      final data = _decodeResponse(response);
      if (data['success'] == true) {
        final List<ParcelModel> parcels = (data['parcels'] as List)
            .map((p) => ParcelModel.fromJson(p))
            .toList();
        final ParcelStats stats = ParcelStats.fromJson(data['stats']);
        return {'success': true, 'parcels': parcels, 'stats': stats};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to fetch parcels'};
    } catch (_) {
      return {
        'success': false,
        'error': 'Network error while fetching parcels. Will retry shortly.',
      };
    }
  }

  /// Submits Proof of Delivery (POD) evidence and advances parcel status via `update_status.php`.
  ///
  /// Multipart Transmission Details:
  /// - `photo`: JPEG/PNG raster of package delivered at recipient address. Server applies a
  ///   cryptographic non-repudiation watermark overlay (Tracking #, UTC Timestamp, Driver Name).
  /// - `signature`: Vector signature pad export (PNG bytes) confirming recipient acknowledgment.
  /// - `delivery_otp`: Mandatory 4-digit code if `requires_otp == true` (high-value / cash orders).
  /// - `receiver_name` & `description`: Recorded for customer audit trail and dispatch tracking.
  ///
  /// Security Enforcement:
  /// The endpoint strictly validates driver ownership, legal state transitions (e.g. Out for Delivery -> Delivered),
  /// and branch assignment before updating the database.
  static Future<Map<String, dynamic>> updateStatusWithPod({
    required String token,
    required String parcelId,
    required String trackingNumber,
    required String status,
    required String receiverName,
    required String description,
    String? deliveryOtp,
    File? photoFile,
    Uint8List? signatureBytes,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiUrl}update_status.php'),
      );
      request.headers.addAll(_authHeaders(token));

      request.fields['parcel_id'] = parcelId;
      request.fields['tracking_number'] = trackingNumber;
      request.fields['status'] = status;
      request.fields['receiver_name'] = receiverName;
      request.fields['description'] = description;

      if (deliveryOtp != null && deliveryOtp.isNotEmpty) {
        request.fields['delivery_otp'] = deliveryOtp;
      }

      if (photoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', photoFile.path),
        );
      }

      if (signatureBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'signature',
            signatureBytes,
            filename: 'signature.png',
          ),
        );
      }

      var streamedResponse = await request.send().timeout(_requestTimeout);
      var response = await http.Response.fromStream(streamedResponse);
      return _decodeResponse(response);
    } catch (_) {
      return {
        'success': false,
        'error': 'Failed to submit POD. Saved to offline queue if offline.',
      };
    }
  }

  /// Updates driver profile information and profile photo/avatar preset via `update_profile.php`.
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    File? avatarFile,
    String? presetAvatar,
    String? name,
    String? phone,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiUrl}update_profile.php'),
      );
      request.headers.addAll(_authHeaders(token));

      if (name != null && name.isNotEmpty) request.fields['name'] = name;
      if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
      if (presetAvatar != null && presetAvatar.isNotEmpty) {
        request.fields['preset_avatar'] = presetAvatar;
      }

      if (avatarFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', avatarFile.path),
        );
      }

      var streamedResponse = await request.send().timeout(_requestTimeout);
      var response = await http.Response.fromStream(streamedResponse);
      return _decodeResponse(response);
    } catch (_) {
      return {
        'success': false,
        'error': 'Failed to update profile. Please try again.',
      };
    }
  }

  /// Updates account authentication password with current credential validation.
  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiUrl}change_password.php'),
            headers: _authHeaders(token),
            body: {
              'current_password': currentPassword,
              'new_password': newPassword,
            },
          )
          .timeout(_requestTimeout);
      return _decodeResponse(response);
    } catch (_) {
      return {
        'success': false,
        'error': 'Failed to change password. Please verify connection.',
      };
    }
  }

  /// Transmits live telemetry (GPS coordinates & device GPS sensor status) to `update_location.php`.
  ///
  /// Telemetry Strategy:
  /// - `gps_enabled`: Sent as `0` if driver turns off hardware GPS, immediately alerting dispatcher
  ///   on the live operations map that tracking was suppressed.
  /// - `latitude` & `longitude`: High-accuracy coordinates sampled at a 30-second interval
  ///   to power customer live-tracking links while preserving device battery life.
  static Future<Map<String, dynamic>> updateLocation({
    required String token,
    double? latitude,
    double? longitude,
    int gpsEnabled = 1,
  }) async {
    try {
      final Map<String, String> body = {'gps_enabled': gpsEnabled.toString()};
      if (latitude != null) body['latitude'] = latitude.toString();
      if (longitude != null) body['longitude'] = longitude.toString();

      final response = await http
          .post(
            Uri.parse('${AppConstants.apiUrl}update_location.php'),
            headers: _authHeaders(token),
            body: body,
          )
          .timeout(_requestTimeout);
      return _decodeResponse(response);
    } catch (_) {
      return {
        'success': false,
        'error': 'Failed to send GPS telemetry.',
      };
    }
  }

  /// Fetches assigned warehouse pick tasks from Cheetah WMS endpoint `wms_get_pick_tasks.php`.
  ///
  /// Warehouse Picker Role Integration:
  /// Used by warehouse pickers to view batch order picking lists, target bin/shelf locations
  /// (Zone -> Aisle -> Shelf -> Bin), item SKUs, and required unit quantities.
  static Future<Map<String, dynamic>> fetchPickTasks(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.pickerApiUrl}wms_get_pick_tasks.php'),
            headers: _authHeaders(token),
          )
          .timeout(_requestTimeout);
      return _decodeResponse(response);
    } catch (_) {
      return {
        'success': false,
        'error': 'Failed to load warehouse pick tasks. Please check your network.',
      };
    }
  }

  /// Updates warehouse picking task execution status via `wms_update_task.php`.
  ///
  /// State Flow in Cheetah WMS:
  /// 1. `Pending`: Task assigned to picker; awaiting physical bin traversal.
  /// 2. `In Progress`: Picker actively scanning SKU barcodes at shelf.
  /// 3. `Completed`: All items picked and verified; triggers sales order transition to `Prepared`
  ///    state for packaging and driver manifest assignment.
  static Future<Map<String, dynamic>> updatePickTaskStatus({
    required String token,
    required int taskId,
    required String status,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.pickerApiUrl}wms_update_task.php'),
            headers: {
              ..._authHeaders(token),
              'Content-Type': 'application/json',
            },
            body: json.encode({'task_id': taskId, 'status': status}),
          )
          .timeout(_requestTimeout);
      return _decodeResponse(response);
    } catch (_) {
      return {
        'success': false,
        'error': 'Failed to update WMS task status. Please retry.',
      };
    }
  }

  /// Invalidates active Bearer token on the server upon driver or picker logout.
  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiUrl}logout.php'),
            headers: _authHeaders(token),
          )
          .timeout(_requestTimeout);
      return _decodeResponse(response);
    } catch (_) {
      return {
        'success': false,
        'error': 'Failed to reach server for logout.',
      };
    }
  }
}
