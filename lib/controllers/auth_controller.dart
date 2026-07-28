import 'dart:io';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var userToken = ''.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userPhone = ''.obs;
  var userAvatarUrl = ''.obs;
  var branchName = ''.obs;
  var branchCity = ''.obs;
  var isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserSession();
  }

  Future<void> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    userToken.value = prefs.getString('api_token') ?? '';
    userName.value = prefs.getString('user_name') ?? 'Rider';
    userEmail.value = prefs.getString('user_email') ?? '';
    userPhone.value = prefs.getString('user_phone') ?? '';
    userAvatarUrl.value = prefs.getString('user_avatar') ?? '';
    branchName.value = prefs.getString('branch_name') ?? 'Main Hub';
    branchCity.value = prefs.getString('branch_city') ?? 'Headquarters';
    isDarkMode.value = prefs.getBool('is_dark_mode') ?? true;

    if (userToken.value.isNotEmpty) {
      fetchUserProfile();
    }
  }

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

  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDarkMode.value);
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    final res = await ApiService.login(email, password);
    isLoading.value = false;

    if (res['success'] == true) {
      final token = res['token'] ?? res['api_token'] ?? '';
      final name = res['user']['name'] ?? 'Rider';
      final userEmailVal = res['user']['email'] ?? email;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_token', token);
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', userEmailVal);

      userToken.value = token;
      userName.value = name;
      userEmail.value = userEmailVal;

      fetchUserProfile();

      Get.offAllNamed(AppRoutes.HOME);
      Get.snackbar('Success', 'Welcome back, $name!',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Login Failed', res['error'] ?? 'Invalid credentials',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    userToken.value = '';
    userName.value = '';
    userAvatarUrl.value = '';
    Get.offAllNamed(AppRoutes.LOGIN);
  }

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
      Get.snackbar('Profile Updated', 'Your profile picture has been synced with the website!',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } else {
      Get.snackbar('Update Failed', res['error'] ?? 'Could not update profile',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (userToken.value.isEmpty) return false;
    isLoading.value = true;
    final res = await ApiService.changePassword(
      token: userToken.value,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    isLoading.value = false;

    if (res['success'] == true) {
      Get.snackbar('Success', 'Password updated successfully!',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } else {
      Get.snackbar('Error', res['error'] ?? 'Could not update password',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }
}
