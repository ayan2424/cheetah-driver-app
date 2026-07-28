import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'routes/app_pages.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CheetahDriverApp());
}

class CheetahDriverApp extends StatelessWidget {
  const CheetahDriverApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Cheetah Driver App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
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
  }
}
