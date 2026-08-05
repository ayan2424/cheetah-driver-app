import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/parcel_model.dart';

class ApiService {
  static const _requestTimeout = Duration(seconds: 15);

  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.trim().startsWith('<')) {
      return {
        'success': false,
        'error': 'The server returned an invalid response.',
      };
    }

    try {
      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return {
          'success': false,
          'error': 'The server returned an invalid response.',
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
        'error': 'The server returned an invalid response.',
      };
    }
  }

  // Login Driver
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
        'error': 'Connection failed. Please try again.',
      };
    }
  }

  // Request Password Reset Link via Email
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
        'message': 'Connection error. Please try again.',
      };
    }
  }

  // Fetch Driver Full Profile Details
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
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  // Fetch Parcels & Stats
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
      return {'success': false, 'error': data['error'] ?? 'Failed to fetch'};
    } catch (_) {
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  // Update Status & Submit POD
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
        'error': 'Failed to submit POD. Please try again.',
      };
    }
  }

  // Update Profile & Avatar (File or Preset)
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

  // Change Password
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
        'error': 'Failed to change password. Please try again.',
      };
    }
  }

  // Update Live GPS Location & Online Status
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
        'error': 'Failed to send GPS location. Please try again.',
      };
    }
  }
}
