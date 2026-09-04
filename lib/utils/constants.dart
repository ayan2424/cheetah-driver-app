import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Palette
  static const Color background = Color(0xFF09090b);
  static const Color cardBg = Color(0xFF121216);
  static const Color cardBorder = Color(0x14FFFFFF);
  static const Color primary = Color(0xFFFF4D00);
  static const Color primaryLight = Color(0xFFFF7700);
  static const Color accentGreen = Color(0xFF10b981);
  static const Color accentBlue = Color(0xFF3b82f6);
  static const Color accentGold = Color(0xFFf59e0b);
  static const Color textMain = Color(0xFFf4f4f5);
  static const Color textMuted = Color(0xFFa1a1aa);
}

class AppColorsLight {
  // Light Theme Palette
  static const Color background = Color(0xFFf4f4f6);
  static const Color cardBg = Color(0xFFffffff);
  static const Color cardBorder = Color(0xFFe4e4e7);
  static const Color primary = Color(0xFFFF4D00);
  static const Color primaryLight = Color(0xFFFF7700);
  static const Color accentGreen = Color(0xFF059669);
  static const Color accentBlue = Color(0xFF2563eb);
  static const Color accentGold = Color(0xFFd97706);
  static const Color textMain = Color(0xFF09090b);
  static const Color textMuted = Color(0xFF71717a);
}

class AppConstants {
  // Configurable base URL via --dart-define=BASE_URL=https://yourdomain.com
  // Defaults to production live server https://cheetah.ayan24.me/
  static const String _envBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://cheetah.ayan24.me',
  );

  /// Normalized base domain URL with guaranteed trailing slash
  static String get baseUrl =>
      _envBaseUrl.endsWith('/') ? _envBaseUrl : '$_envBaseUrl/';
  static String get apiUrl => '${baseUrl}api/v1/driver/';
  static String get pickerApiUrl => '${baseUrl}api/v1/picker/';
}

class AppRoutes {
  static const String SPLASH = '/splash';
  static const String LOGIN = '/login';
  static const String HOME = '/home';
}
