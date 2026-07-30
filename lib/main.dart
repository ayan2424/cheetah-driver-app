import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/auth_controller.dart';
import 'routes/app_pages.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AuthController(), permanent: true);
  runApp(const CheetahDriverApp());
}

class CheetahDriverApp extends StatelessWidget {
  const CheetahDriverApp({Key? key}) : super(key: key);

  ThemeMode _getThemeMode(String pref) {
    if (pref == 'light') return ThemeMode.light;
    if (pref == 'dark') return ThemeMode.dark;
    return ThemeMode.system; // Real-time OS System theme!
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final currentPref = authController.themePreference.value;

      return GetMaterialApp(
        title: 'Cheetah Driver App',
        debugShowCheckedModeBanner: false,
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
