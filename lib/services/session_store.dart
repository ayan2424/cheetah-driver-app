import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps authentication material out of the app's plain preferences store.
class SessionStore {
  SessionStore._();

  static const _tokenKey = 'api_token';
  static const _legacyTokenKey = 'api_token';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<String> readToken() async {
    final secureToken = await _secureStorage.read(key: _tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    // One-time migration for users upgrading from the previous release.
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_legacyTokenKey) ?? '';
    if (legacyToken.isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: legacyToken);
      await prefs.remove(_legacyTokenKey);
    }
    return legacyToken;
  }

  static Future<void> writeToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenKey);
  }

  static Future<void> clearToken() => _secureStorage.delete(key: _tokenKey);
}
