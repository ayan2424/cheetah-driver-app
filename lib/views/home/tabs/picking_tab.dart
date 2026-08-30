import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/picking_controller.dart';
import '../../../utils/app_translations.dart';
import '../../../utils/constants.dart';

/// [PickingTab] renders active Warehouse Management System (WMS) batch pick tasks for warehouse personnel.
///
/// Warehouse Fulfillment Flow:
/// - Ingests sales orders requiring physical stock gathering from warehouse bin locations.
/// - Enables status progression: 'Pending' -> 'In Progress' (traversing aisles) -> 'Completed' (packed & ready).
/// - Once marked 'Completed', the Cheetah backend flags the order as 'Prepared' for courier dispatch manifest creation.
class PickingTab extends StatelessWidget {
  final PickingController controller = Get.put(PickingController());
  final AuthController authController = Get.find<AuthController>();

  PickingTab({super.key});

  String t(String text) => text.localize(authController.selectedLanguage.value);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lang = authController.selectedLanguage.value;
      if (controller.isLoading.value && controller.tasks.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchTasks(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Warehouse Pick Tasks'.localize(lang),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Get.isDarkMode ? Colors.white : AppColorsLight.textMain,
              ),
            ),
            const SizedBox(height: 16),
            if (controller.tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 52, color: Get.isDarkMode ? Colors.white54 : Colors.black54),
                    const SizedBox(height: 12),
                    Text(
                      'No assigned pick tasks.'.localize(lang),
                      style: TextStyle(color: Get.isDarkMode ? Colors.white54 : Colors.black54),
                    ),
                  ],
                ),
              )
            else
              ...controller.tasks.map((task) => _buildTaskCard(task, lang)),
          ],
        ),
      );
    });
  }

  Widget _buildTaskCard(Map<String, dynamic> task, String lang) {
    final bool isDark = Get.isDarkMode;
    final cardColor = isDark ? AppColors.cardBg : AppColorsLight.cardBg;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final String rawStatus = task['status'] ?? 'Pending';
    final String localizedStatus = rawStatus.localize(lang);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'Task'.localize(lang)} #${task['id']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rawStatus == 'Completed' 
                      ? Colors.green.withValues(alpha: 0.2) 
                      : (rawStatus == 'In Progress' 
                          ? Colors.orange.withValues(alpha: 0.2) 
                          : Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  localizedStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: rawStatus == 'Completed' 
                        ? Colors.green 
                        : (rawStatus == 'In Progress' ? Colors.orange : (isDark ? Colors.white70 : Colors.black87)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${'Order'.localize(lang)}: ${task['order_number']}',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          Text(
            '${'Store'.localize(lang)}: ${task['store_name']}',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (rawStatus == 'Pending' || rawStatus == 'Assigned')
            ElevatedButton(
              onPressed: () => controller.updateTaskStatus(task['id'], 'In Progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Start Picking'.localize(lang)),
            )
          else if (rawStatus == 'In Progress')
            ElevatedButton(
              onPressed: () => controller.updateTaskStatus(task['id'], 'Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Complete Task'.localize(lang)),
            ),
        ],
      ),
    );
  }
}
