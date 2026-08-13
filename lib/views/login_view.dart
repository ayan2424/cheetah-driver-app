import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/constants.dart';
import '../utils/app_translations.dart';

class LoginView extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isPasswordVisible = false.obs;

  LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = authController.isDark(context);
      final bgColor = isDark ? AppColors.background : AppColorsLight.background;
      final cardColor = isDark ? AppColors.cardBg : AppColorsLight.cardBg;
      final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
      final textColor = isDark ? Colors.white : AppColorsLight.textMain;
      final subtextColor = isDark ? const Color(0xFFd4d4d8) : AppColorsLight.textMuted;
      final logoAsset = isDark ? 'assets/images/whiteLogo.png' : 'assets/images/logo.png';
      final lang = authController.appLanguage.value;

      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // Theme Toggle Button
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: isDark ? Colors.amberAccent : AppColors.primary,
              ),
              onPressed: () => authController.toggleTheme(),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dynamic Official Logo (whiteLogo in Dark Mode, logo in Light Mode)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        logoAsset,
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.delivery_dining,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // High-Contrast Dynamic Title & Subtitle
                  Text(
                    'Cheetah Driver Portal'.localize(lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Official Rider & Delivery Agent App'.localize(lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Email Input Box
                  Text(
                    'Email Address'.localize(lang),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'e.g. rider@cheetah.com'.localize(lang),
                      hintStyle: TextStyle(color: subtextColor),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                      filled: true,
                      fillColor: cardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Input Box
                  Text(
                    'Password'.localize(lang),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible.value,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: subtextColor),
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: subtextColor,
                        ),
                        onPressed: () => isPasswordVisible.value = !isPasswordVisible.value,
                      ),
                      filled: true,
                      fillColor: cardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Forgot Password Action Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        final resetEmailController = TextEditingController(text: emailController.text);
                        Get.dialog(
                          Dialog(
                            backgroundColor: cardColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.mark_email_read_outlined, size: 36, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Reset Your Password'.localize(lang),
                                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enter your email address to receive an official password reset link.'.localize(lang),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: subtextColor, fontSize: 13),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: resetEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(color: textColor, fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. rider@cheetah.com'.localize(lang),
                                      hintStyle: TextStyle(color: subtextColor),
                                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                                      filled: true,
                                      fillColor: bgColor,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () => Get.back(),
                                          child: Text('Cancel'.localize(lang), style: TextStyle(color: subtextColor)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            final emailToReset = resetEmailController.text.trim();
                                            Get.back();
                                            authController.requestPasswordReset(emailToReset);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: Text('Send Reset Link'.localize(lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?'.localize(lang),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Premium Gradient Submit Button
                  Obx(() => Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: authController.isLoading.value
                              ? null
                              : () {
                                  authController.login(
                                    emailController.text.trim(),
                                    passwordController.text.trim(),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: authController.isLoading.value
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  'Sign In'.localize(lang),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
