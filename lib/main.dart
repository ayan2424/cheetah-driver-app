import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/auth_controller.dart';
import 'routes/app_pages.dart';
import 'utils/constants.dart';
import 'services/offline_sync_service.dart';
import 'services/firebase_service.dart';

/// Entry point of the Cheetah Driver & Warehouse Picker Mobile Application.
///
/// Boot Sequence:
/// 1. Widgets Flutter Binding: Ensures platform channels are ready for Keystore/Keychain access.
/// 2. Offline Sync Service: Opens hardware-encrypted Hive box (`offline_pod_queue`) and starts network watcher.
/// 3. Firebase Push Service: Initializes FCM with safe fallback if optional marketplace config is absent.
/// 4. Permanent Auth Controller: Injects reactive identity and theme state into GetX dependency graph.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OfflineSyncService.init();
  await FirebaseService.init();
  Get.put(AuthController(), permanent: true);
  runApp(const CheetahDriverApp());
}

/// Root widget configuring reactive dual-theme support (Dark/Light/System) and GetX routing.
class CheetahDriverApp extends StatelessWidget {
  const CheetahDriverApp({super.key});

  ThemeMode _getThemeMode(String pref) {
    if (pref == 'light') return ThemeMode.light;
    if (pref == 'dark') return ThemeMode.dark;
    return ThemeMode.system; // Follows real-time mobile OS platform brightness
  }

  Locale _getLocale(String lang) {
    if (lang.isEmpty) return const Locale('en');
    if (lang.contains('-')) {
      final parts = lang.split('-');
      return Locale(parts[0], parts[1].toUpperCase());
    }
    return Locale(lang);
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final currentPref = authController.themePreference.value;
      final currentLang = authController.appLanguage.value;

      return GetMaterialApp(
        title: 'Cheetah Driver App',
        debugShowCheckedModeBanner: false,
        locale: _getLocale(currentLang),
        fallbackLocale: const Locale('en'),
        themeMode: _getThemeMode(currentPref),
        theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: AppColorsLight.background,
          primaryColor: AppColorsLight.primary,
          colorScheme: const ColorScheme.light(
            primary: AppColorsLight.primary,
            secondary: AppColorsLight.accentGreen,
          ),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColorsLight.cardBg,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.accentGreen,
          ),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.cardBg,
            elevation: 0,
          ),
        ),
        initialRoute: AppRoutes.SPLASH,
        getPages: AppPages.routes,
      );
    });
  }
}
