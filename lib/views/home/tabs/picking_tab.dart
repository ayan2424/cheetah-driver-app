import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/picking_controller.dart';
import '../../../utils/constants.dart';

class PickingTab extends StatelessWidget {
  final PickingController controller = Get.put(PickingController());

  PickingTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
              'Warehouse Pick Tasks',
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
                      'No assigned pick tasks.',
                      style: TextStyle(color: Get.isDarkMode ? Colors.white54 : Colors.black54),
                    ),
                  ],
                ),
              )
            else
              ...controller.tasks.map((task) => _buildTaskCard(task)).toList(),
          ],
        ),
      );
    });
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final bool isDark = Get.isDarkMode;
    final cardColor = isDark ? AppColors.cardBg : AppColorsLight.cardBg;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    
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
                'Task #${task['id']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task['status'] == 'Completed' ? Colors.green.withOpacity(0.2) : (task['status'] == 'In Progress' ? Colors.orange.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: task['status'] == 'Completed' ? Colors.green : (task['status'] == 'In Progress' ? Colors.orange : (isDark ? Colors.white70 : Colors.black87)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Order: ${task['order_number']}',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          Text(
            'Store: ${task['store_name']}',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (task['status'] == 'Pending' || task['status'] == 'Assigned')
            ElevatedButton(
              onPressed: () => controller.updateTaskStatus(task['id'], 'In Progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Picking'),
            )
          else if (task['status'] == 'In Progress')
            ElevatedButton(
              onPressed: () => controller.updateTaskStatus(task['id'], 'Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Complete Task'),
            ),
        ],
      ),
    );
  }
}
