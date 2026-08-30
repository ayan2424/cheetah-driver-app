import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../controllers/auth_controller.dart';

/// [PickingController] coordinates Warehouse Management System (WMS) pick task assignments
/// and item fulfillment workflows for warehouse personnel.
///
/// Cheetah WMS Workflow:
/// 1. Task Ingestion: Pulls batch picking waves from `wms_get_pick_tasks.php` scoped to the authenticated picker.
/// 2. Bin / Shelf Guidance: Tasks contain structured location coordinates (Zone -> Aisle -> Shelf -> Bin).
/// 3. State Progression:
///    - `Pending`: Initial queue state after warehouse manager dispatch.
///    - `In Progress`: Picker is on the warehouse floor scanning SKU barcodes.
///    - `Completed`: All line items picked; server automatically transitions linked sales order to `Prepared`.
class PickingController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  
  var isLoading = false.obs;
  var tasks = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  /// Synchronizes assigned warehouse picking waves from the Cheetah WMS backend.
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

  /// Advances pick task lifecycle state (e.g. 'In Progress' or 'Completed').
  Future<void> updateTaskStatus(int taskId, String status) async {
    final token = authController.userToken.value;
    if (token.isEmpty) return;
    
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    final res = await ApiService.updatePickTaskStatus(
      token: token,
      taskId: taskId,
      status: status,
    );
    
    Get.back(); // Dismiss loading indicator
    
    if (res['success'] == true) {
      Get.snackbar('Success', 'WMS Task updated to $status');
      fetchTasks();
    } else {
      Get.snackbar('Error', res['error'] ?? 'Failed to update WMS task');
    }
  }
}
