import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/session_store.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';

/// [AuthController] manages authentication state, user identity observables, theme preferences,
/// localized language settings, and active session lifecycles across the mobile application.
///
/// Core Responsibilities:
/// 1. Session Hydration: Reads hardware-isolated bearer tokens on boot and fetches refreshed profile metadata.
/// 2. Role-Based Navigation: Evaluates `userRole` ('driver' vs 'picker') to dynamically configure UI tabs.
/// 3. Device Lifecycle Monitoring: Implements [WidgetsBindingObserver] to verify GPS guard enforcement
///    and platform brightness shifts whenever the application resumes from background state.
/// 4. Zero-Leak Logout & Invalidation: Safely tears down live GPS telemetry timers, clears Keystore/Keychain
///    tokens, and flushes cached preferences upon sign-out or 401 unauthorized triggers.
/// 5. Network Awareness: Monitors real-time internet connectivity status to display offline HUD banners.
class AuthController extends GetxController with WidgetsBindingObserver {
  var isLoading = false.obs;
  var userToken = ''.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userPhone = ''.obs;
  var userRole = 'driver'.obs; // 'driver' or 'picker'
  var userAvatarUrl = ''.obs;
  var branchName = ''.obs;
  var branchCity = ''.obs;
  var isDarkMode = true.obs;
  var themePreference = 'system'.obs; // 'system', 'dark', 'light'
  var selectedLanguage =
      'en'.obs; // 'en', 'sw', 'ur', 'ar', 'fr', 'es', 'de', 'tr', 'zh'
  RxString get appLanguage => selectedLanguage;

  // Real-time network state observables
  var isOffline = false.obs;
  var showReconnectedBanner = false.obs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initConnectivityWatcher();
    loadUserSession();
  }

  void _initConnectivityWatcher() async {
    final initial = await Connectivity().checkConnectivity();
    isOffline.value = initial.contains(ConnectivityResult.none);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final none = results.contains(ConnectivityResult.none);
      if (none) {
        isOffline.value = true;
        showReconnectedBanner.value = false;
      } else {
        if (isOffline.value) {
          isOffline.value = false;
          showReconnectedBanner.value = true;
          Future.delayed(const Duration(seconds: 4), () {
            showReconnectedBanner.value = false;
          });
        }
      }
    });
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (themePreference.value == 'system') {
      _applyThemePreference('system');
    }
  }

  /// Triggered whenever courier returns to the app from OS home screen or third-party navigation app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Re-verify that hardware GPS was not disabled while minimized
      LocationService.checkAndEnforceLocationState();
      if (themePreference.value == 'system') {
        _applyThemePreference('system');
      }
    }
  }

  /// Hydrates the reactive session from secure storage and cached preferences on cold start.
  Future<void> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    userToken.value = await SessionStore.readToken();
    userName.value = prefs.getString('user_name') ?? 'Rider';
    userEmail.value = prefs.getString('user_email') ?? '';
    userPhone.value = prefs.getString('user_phone') ?? '';
    userRole.value = prefs.getString('user_role') ?? 'driver';
    userAvatarUrl.value = prefs.getString('user_avatar') ?? '';
    branchName.value = prefs.getString('branch_name') ?? 'Main Hub';
    branchCity.value = prefs.getString('branch_city') ?? 'Headquarters';

    final savedLang = prefs.getString('selected_language');
    if (savedLang != null && savedLang.isNotEmpty) {
      selectedLanguage.value = savedLang;
    } else {
      // Auto-detect mobile device operating system locale on first cold boot
      final deviceLocale =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
      const supported = ['en', 'sw', 'ur', 'ar', 'fr', 'es', 'de', 'tr', 'zh'];
      if (supported.contains(deviceLocale)) {
        selectedLanguage.value = deviceLocale;
      } else {
        selectedLanguage.value = 'en';
      }
    }
    themePreference.value = prefs.getString('theme_preference') ?? 'system';
    _applyThemePreference(themePreference.value);

    // If an authenticated session exists, bootstrap fleet telemetry and push sync
    if (userToken.value.isNotEmpty) {
      fetchUserProfile();
      LocationService.startLiveLocationTracking(userToken.value);
      FirebaseService.syncTokenWithBackend(userToken.value);
    }
  }

  /// Updates theme mode setting ('system', 'dark', 'light') and persists selection.
  Future<void> setThemePreference(String mode) async {
    themePreference.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_preference', mode);
    _applyThemePreference(mode);
  }

  /// Evaluates whether dark styling should be applied based on user preference or OS system theme.
  bool isDark(BuildContext context) {
    final pref = themePreference.value;
    if (pref == 'dark') return true;
    if (pref == 'light') return false;
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  void _applyThemePreference(String mode) {
    if (mode == 'dark') {
      isDarkMode.value = true;
    } else if (mode == 'light') {
      isDarkMode.value = false;
    } else {
      // System mode: Query actual mobile device platform brightness
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      isDarkMode.value = (brightness == Brightness.dark);
    }
  }

  /// Synchronizes latest courier profile, branch assignment, and avatar from server.
  Future<void> fetchUserProfile() async {
    if (userToken.value.isEmpty) return;
    final res = await ApiService.fetchProfile(userToken.value);
    if (res['success'] == true && res['user'] != null) {
      final u = res['user'];
      userName.value = u['name'] ?? userName.value;
      userEmail.value = u['email'] ?? userEmail.value;
      userPhone.value = u['phone'] ?? '';
      userAvatarUrl.value = u['profile_image'] ?? '';

      if (u['branch'] != null) {
        branchName.value = u['branch']['name'] ?? 'Main Hub';
        branchCity.value = u['branch']['city'] ?? 'Headquarters';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', userName.value);
      await prefs.setString('user_email', userEmail.value);
      await prefs.setString('user_phone', userPhone.value);
      await prefs.setString('user_avatar', userAvatarUrl.value);
      await prefs.setString('branch_name', branchName.value);
      await prefs.setString('branch_city', branchCity.value);
    }
  }

  /// Updates active localization language and saves to persistent preferences.
  Future<void> setAppLanguage(String langCode) async {
    selectedLanguage.value = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', langCode);
  }

  /// Toggles between light and dark theme modes.
  Future<void> toggleTheme() async {
    final nextMode = isDarkMode.value ? 'light' : 'dark';
    await setThemePreference(nextMode);
  }

  /// Performs secure courier or picker login against the Cheetah REST API.
  ///
  /// Flow:
  /// 1. Transmits credentials via POST to `api/v1/driver/login.php`.
  /// 2. Stores token in hardware Keystore/Keychain via [SessionStore].
  /// 3. Sets reactive role ('driver' vs 'picker') for layout rendering.
  /// 4. Boots background GPS tracking and syncs FCM notification token.
  /// 5. Transitions to [AppRoutes.HOME].
  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    final res = await ApiService.login(email, password);
    isLoading.value = false;

    if (res['success'] == true) {
      final token = res['token'] ?? res['api_token'] ?? '';
      final name = res['user']['name'] ?? 'Rider';
      final userEmailVal = res['user']['email'] ?? email;
      final role = res['user']['role'] ?? 'driver';

      final prefs = await SharedPreferences.getInstance();
      await SessionStore.writeToken(token);
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', userEmailVal);
      await prefs.setString('user_role', role);

      userToken.value = token;
      userName.value = name;
      userEmail.value = userEmailVal;
      userRole.value = role;

      fetchUserProfile();
      LocationService.startLiveLocationTracking(token);
      FirebaseService.syncTokenWithBackend(token);

      Get.offAllNamed(AppRoutes.HOME);
      Get.snackbar(
        'Success',
        'Welcome back, $name!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Login Failed',
        res['error'] ?? 'Invalid credentials',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Initiates password reset dispatch flow for forgotten courier credentials.
  Future<void> requestPasswordReset(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    final res = await ApiService.forgotPassword(email);
    isLoading.value = false;

    if (res['success'] == true) {
      Get.snackbar(
        'Email Sent',
        res['message'],
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } else {
      Get.snackbar(
        'Error',
        res['message'],
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  /// Terminates active session, shuts down background telemetry, revokes server token, and flushes local credentials.
  Future<void> logout() async {
    LocationService.stopLiveLocationTracking();
    final token = userToken.value;
    if (token.isNotEmpty) {
      try {
        await ApiService.logout(token);
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await SessionStore.clearToken();
    userToken.value = '';
    userName.value = '';
    userAvatarUrl.value = '';
    Get.offAllNamed(AppRoutes.LOGIN);
  }

  /// Automatically triggered upon receiving HTTP 401 Unauthorized from backend.
  /// Protects against stale session data or account revocation on the web portal.
  Future<void> handleSessionExpired() async {
    LocationService.stopLiveLocationTracking();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await SessionStore.clearToken();
    userToken.value = '';
    userName.value = '';
    userAvatarUrl.value = '';
    Get.offAllNamed(AppRoutes.LOGIN);
    Get.snackbar(
      'Session Expired ⚠️',
      'Your session has expired or was logged in on another device. Please log in again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  /// Uploads custom camera photo or assigns a pre-rendered 3D courier avatar.
  Future<bool> updateAvatar({File? avatarFile, String? presetAvatar}) async {
    if (userToken.value.isEmpty) return false;
    isLoading.value = true;
    final res = await ApiService.updateProfile(
      token: userToken.value,
      avatarFile: avatarFile,
      presetAvatar: presetAvatar,
    );
    isLoading.value = false;

    if (res['success'] == true && res['user'] != null) {
      if (res['user']['profile_image'] != null) {
        userAvatarUrl.value = res['user']['profile_image'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar', userAvatarUrl.value);
      }
      Get.snackbar(
        'Profile Updated',
        'Your profile picture has been synced with the website!',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } else {
      Get.snackbar(
        'Update Failed',
        res['error'] ?? 'Could not update profile',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Validates existing password and applies newly entered credential.
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (userToken.value.isEmpty) return false;
    isLoading.value = true;
    final res = await ApiService.changePassword(
      token: userToken.value,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    isLoading.value = false;

    if (res['success'] == true) {
      Get.snackbar(
        'Success',
        'Password updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } else {
      Get.snackbar(
        'Error',
        res['error'] ?? 'Could not update password',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
