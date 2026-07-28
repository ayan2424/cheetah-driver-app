import 'package:get/get.dart';
import '../utils/constants.dart';
import '../views/splash_view.dart';
import '../views/login_view.dart';
import '../views/home_view.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashView(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginView(),
    ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => HomeView(),
    ),
  ];
}
