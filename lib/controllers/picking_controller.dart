import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../controllers/auth_controller.dart';

class PickingController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  
  var isLoading = false.obs;
  var tasks = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final token = authController.userToken.value;
    if (token.isEmpty) return;
    
    isLoading.value = true;
    final res = await ApiService.fetchPickTasks(token);
    isLoading.value = false;
    
    if (res['success'] == true) {
      tasks.value = List<Map<String, dynamic>>.from(res['tasks'] ?? []);
    }
  }

  Future<void> updateTaskStatus(int taskId, String status) async {
    final token = authController.userToken.value;
    if (token.isEmpty) return;
    
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    final res = await ApiService.updatePickTaskStatus(
      token: token,
      taskId: taskId,
      status: status,
    );
    
    Get.back(); // close loading dialog
    
    if (res['success'] == true) {
      Get.snackbar('Success', 'Task updated to $status');
      fetchTasks();
    } else {
      Get.snackbar('Error', res['error'] ?? 'Failed to update task');
    }
  }
}
