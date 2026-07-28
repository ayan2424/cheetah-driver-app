import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/parcel_controller.dart';
import '../../../models/parcel_model.dart';
import '../../../utils/constants.dart';

class DeliveriesTab extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final ParcelController parcelController = Get.find<ParcelController>();
  final Function(ParcelModel) onParcelTap;

  DeliveriesTab({Key? key, required this.onParcelTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = authController.isDarkMode.value;
      final cardColor = isDark ? AppColors.cardBg : AppColorsLight.cardBg;
      final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
      final textColor = isDark ? Colors.white : AppColorsLight.textMain;
      final subtextColor = isDark ? const Color(0xFFd4d4d8) : AppColorsLight.textMuted;

      if (parcelController.isLoading.value && parcelController.parcelsList.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        );
      }

      final filteredParcels = parcelController.filteredParcels;

      return RefreshIndicator(
        onRefresh: () => parcelController.fetchParcels(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // Search Input
            TextField(
              onChanged: (val) => parcelController.searchQuery.value = val,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by tracking # or receiver...',
                hintStyle: TextStyle(color: subtextColor, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
            const SizedBox(height: 14),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'all',
                  'Pending',
                  'In Transit',
                  'Out for Delivery',
                  'Delivered',
                  'Returned'
                ].map((st) {
                  final isSelected = parcelController.activeFilter.value.toLowerCase() == st.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(st == 'all' ? 'All' : st),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : textColor,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: cardColor,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : borderColor,
                      ),
                      onSelected: (val) {
                        parcelController.activeFilter.value = st;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            if (filteredParcels.isEmpty) ...[
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 54, color: subtextColor),
                    const SizedBox(height: 12),
                    Text(
                      'No Deliveries Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pull down to refresh or change filters',
                      style: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredParcels.length,
                itemBuilder: (context, index) {
                  final parcel = filteredParcels[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: borderColor),
                    ),
                    child: InkWell(
                      onTap: () => onParcelTap(parcel),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  parcel.trackingNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(parcel.status).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _getStatusColor(parcel.status).withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    parcel.status,
                                    style: TextStyle(
                                      color: _getStatusColor(parcel.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'To: ${parcel.receiverName}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              parcel.receiverAddress,
                              style: TextStyle(fontSize: 12, color: subtextColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      );
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.accentGreen;
      case 'Out for Delivery':
        return AppColors.primary;
      case 'In Transit':
        return Colors.blueAccent;
      case 'Returned':
        return Colors.redAccent;
      default:
        return Colors.amber;
    }
  }
}
