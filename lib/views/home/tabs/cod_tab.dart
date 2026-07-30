import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/parcel_controller.dart';
import '../../../utils/constants.dart';

class CodTab extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final ParcelController parcelController = Get.find<ParcelController>();

  CodTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = authController.isDark(context);
      final cardColor = isDark ? AppColors.cardBg : AppColorsLight.cardBg;
      final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
      final textColor = isDark ? Colors.white : AppColorsLight.textMain;
      final subtextColor = isDark ? const Color(0xFFd4d4d8) : AppColorsLight.textMuted;

      final stats = parcelController.stats.value;

      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Total COD Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Pending COD Collection',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'PKR ${stats.codTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'To be collected upon parcel delivery',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Daily Statistics Grid
          Text(
            'Daily Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  icon: Icons.check_circle_outline,
                  label: 'Delivered Today',
                  value: '${stats.deliveredToday}',
                  color: AppColors.accentGreen,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  icon: Icons.assignment_outlined,
                  label: 'Out For Delivery',
                  value: '${stats.outForDelivery}',
                  color: AppColors.primary,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: subtextColor),
          ),
        ],
      ),
    );
  }
}
