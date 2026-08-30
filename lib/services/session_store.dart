import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [SessionStore] manages hardware-isolated persistence of bearer authentication tokens.
///
/// Security Architecture:
/// - Android: Tokens are encrypted using Android Keystore provider (AES-256 GCM) with RSA key wrapping.
/// - iOS: Tokens are stored inside the hardware-backed iOS Keychain (`kSecClassGenericPassword`).
///
/// Plain Storage Isolation:
/// Plain [SharedPreferences] is strictly restricted to non-sensitive UI configuration (e.g. theme preference,
/// UI language selection, display names). Bearer tokens are NEVER stored in plaintext XML/plist files,
/// protecting drivers against credential harvesting via rooted device file exploration or ADB backup extraction.
///
/// Server-Side Token Lifecycle:
/// On login, the backend issues an unhashed token string to the client while storing its SHA-256 digest
/// (`users.api_token_hash`) with a 30-day validity window (`users.api_token_expires_at`).
/// When making API calls, the client supplies the bearer token; the server hashes it in constant time
/// to perform zero-knowledge matching.
class SessionStore {
  SessionStore._();

  static const _tokenKey = 'api_token';
  static const _legacyTokenKey = 'api_token';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Retrieves the active bearer token from hardware secure storage.
  ///
  /// Includes automatic one-time migration for legacy installs that previously
  /// stored tokens in plain SharedPreferences before the security upgrade.
  static Future<String> readToken() async {
    final secureToken = await _secureStorage.read(key: _tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    // One-time automatic migration for legacy client installations.
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_legacyTokenKey) ?? '';
    if (legacyToken.isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: legacyToken);
      await prefs.remove(_legacyTokenKey);
    }
    return legacyToken;
  }

  /// Securely writes the newly acquired bearer token into Keystore/Keychain
  /// and purges any residual legacy keys from plaintext preferences.
  static Future<void> writeToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenKey);
  }

  /// Completely wipes the stored authentication token from the secure enclave.
  /// Invoked during intentional driver logout or server-triggered 401 session expiry.
  static Future<void> clearToken() => _secureStorage.delete(key: _tokenKey);
}
