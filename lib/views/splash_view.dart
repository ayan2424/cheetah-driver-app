import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/session_store.dart';
import '../utils/constants.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final token = await SessionStore.readToken();

    if (token.isNotEmpty) {
      Get.offAllNamed(AppRoutes.HOME);
    } else {
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Clean Centered Official Logo
            Center(
              child: Image.asset(
                'assets/images/whiteLogo.png',
                height: 75,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.local_shipping,
                  size: 75,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            // Minimal Professional Circular Progress Indicator
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.2,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
