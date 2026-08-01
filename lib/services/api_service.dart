import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/parcel_model.dart';

class ApiService {
  // Login Driver
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}login.php'),
        body: {
          'email': email,
          'password': password,
        },
      );
      if (response.body.trim().startsWith('<')) {
        return {
          'success': false,
          'error': 'Server 404 or HTML response. Please run git pull on live server or check URL SSL.'
        };
      }
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // Request Password Reset Link via Email
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}forgot_password.php'),
        body: {'email': email},
      );
      if (response.body.trim().startsWith('<')) {
        return {'success': false, 'message': 'Server error. Please check server URL.'};
      }
      final data = json.decode(response.body);
      return {
        'success': data['status'] == 'success',
        'message': data['message'] ?? 'Check your email for password reset instructions.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Fetch Driver Full Profile Details
  static Future<Map<String, dynamic>> fetchProfile(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}get_profile.php'),
        body: {'api_token': token},
      );
      if (response.body.trim().startsWith('<')) {
        return {'success': false, 'error': 'HTML Error response from server'};
      }
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Fetch Parcels & Stats
  static Future<Map<String, dynamic>> fetchParcels(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}get_parcels.php'),
        body: {'api_token': token},
      );
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final List<ParcelModel> parcels = (data['parcels'] as List)
            .map((p) => ParcelModel.fromJson(p))
            .toList();
        final ParcelStats stats = ParcelStats.fromJson(data['stats']);
        return {
          'success': true,
          'parcels': parcels,
          'stats': stats,
        };
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to fetch'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
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
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiUrl}update_status.php'),
      );

      request.fields['api_token'] = token;
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

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Failed to submit POD: $e'};
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

      request.fields['api_token'] = token;
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

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Failed to update profile: $e'};
    }
  }

  // Change Password
  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}change_password.php'),
        body: {
          'api_token': token,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Failed to change password: $e'};
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
      final Map<String, String> body = {
        'api_token': token,
        'gps_enabled': gpsEnabled.toString(),
      };
      if (latitude != null) body['latitude'] = latitude.toString();
      if (longitude != null) body['longitude'] = longitude.toString();

      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}update_location.php'),
        body: body,
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Failed to send GPS location: $e'};
    }
  }
}
