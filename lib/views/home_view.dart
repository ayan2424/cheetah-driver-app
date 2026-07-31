import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/auth_controller.dart';
import '../controllers/parcel_controller.dart';
import '../models/parcel_model.dart';
import '../utils/constants.dart';
import '../utils/app_translations.dart';

class HomeView extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());
  final ParcelController parcelController = Get.put(ParcelController());
  final RxInt selectedNavIndex = 0.obs;

  HomeView({Key? key}) : super(key: key);

  String t(String text) => text.tr(authController.selectedLanguage.value);

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

      return Scaffold(
        extendBody: false,
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          title: Row(
            children: [
              // Dynamic Logo (whiteLogo in Dark Mode, logo in Light Mode)
              Image.asset(
                logoAsset,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delivery_dining, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
          actions: [
            // Theme Toggle Button
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: isDark ? Colors.amberAccent : AppColors.primary,
              ),
              onPressed: () => authController.toggleTheme(),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: subtextColor),
              onPressed: () {
                parcelController.fetchParcels();
                Get.snackbar('Refreshing', 'Fetching latest parcels...',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 1));
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () => _confirmLogout(context, isDark),
            ),
          ],
        ),
        body: parcelController.isLoading.value
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : IndexedStack(
                index: selectedNavIndex.value,
                children: [
                  _buildDeliveriesTab(context, isDark, cardColor, borderColor, textColor, subtextColor),
                  _buildCodSettlementTab(isDark, cardColor, borderColor, textColor, subtextColor),
                  _buildQuickScanTab(context, isDark, cardColor, borderColor, textColor, subtextColor),
                  _buildProfileTab(context, isDark, cardColor, borderColor, textColor, subtextColor),
                ],
              ),
        // Dynamic Floating Bottom Navigation Bar
        bottomNavigationBar: Container(
          color: Colors.transparent,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(left: 14, right: 14, bottom: 10, top: 5),
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF14141A).withOpacity(0.96)
                    : Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.15)
                        : Colors.black.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.6 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.local_shipping, t('Deliveries'), isDark),
                  _buildNavItem(1, Icons.account_balance_wallet, t('COD Cash Log'), isDark),
                  _buildNavItem(2, Icons.qr_code_scanner, t('Scanner'), isDark),
                  _buildNavItem(3, Icons.person, t('Profile'), isDark),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = selectedNavIndex.value == index;
    final unselectedColor = isDark ? const Color(0xFFd4d4d8) : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: () => selectedNavIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.primary.withOpacity(0.5))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : unselectedColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColorsLight.textMain,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // TAB 0: Deliveries View
  Widget _buildDeliveriesTab(BuildContext context, bool isDark, Color cardColor,
      Color borderColor, Color textColor, Color subtextColor) {
    return RefreshIndicator(
      onRefresh: () => parcelController.fetchParcels(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 24.0),
        children: [
          // Search Input Box with Persistent Controller
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: parcelController.searchController,
              onChanged: (val) => parcelController.searchParcels(val),
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by Tracking #, Name, Address...',
                hintStyle: TextStyle(color: subtextColor, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() => parcelController.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: subtextColor, size: 20),
                            onPressed: () => parcelController.clearSearch(),
                          )
                        : const SizedBox.shrink()),
                    // Built-in QR Scan Icon Button
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 22),
                      tooltip: 'Scan Parcel QR Code',
                      onPressed: () => _openCameraQrScanner(context, isDark),
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // KPI Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Out for Delivery',
                  parcelController.stats.value.outForDelivery.toString(),
                  Icons.local_shipping_outlined,
                  AppColors.accentGold,
                  cardColor,
                  borderColor,
                  subtextColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  'COD Pending Cash',
                  'Rs. ${parcelController.stats.value.codTotal.toStringAsFixed(0)}',
                  Icons.payments_outlined,
                  AppColors.accentGreen,
                  cardColor,
                  borderColor,
                  subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter Scroll Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill('All Parcels', 'all', cardColor, borderColor, subtextColor),
                _buildFilterPill('Out for Delivery', 'Out for Delivery', cardColor, borderColor, subtextColor),
                _buildFilterPill('In Transit', 'In Transit', cardColor, borderColor, subtextColor),
                _buildFilterPill('Delivered Today', 'Delivered', cardColor, borderColor, subtextColor),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Parcel List
          if (parcelController.filteredParcels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 52, color: subtextColor),
                  const SizedBox(height: 12),
                  Text(
                    'No matching parcels found.',
                    style: TextStyle(color: subtextColor, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ...parcelController.filteredParcels
                .map((p) => _buildParcelCard(context, p, isDark, cardColor, borderColor, textColor, subtextColor))
                .toList(),
        ],
      ),
    );
  }

  // TAB 1: COD Cash Settlement View
  Widget _buildCodSettlementTab(bool isDark, Color cardColor, Color borderColor,
      Color textColor, Color subtextColor) {
    final codParcels = parcelController.parcelsList
        .where((p) => p.paymentStatus == 'COD')
        .toList();
    final deliveredCodParcels =
        codParcels.where((p) => p.status == 'Delivered').toList();
    final totalCollected = deliveredCodParcels.fold<double>(
        0.0, (sum, item) => sum + item.amount);

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
      children: [
        Text('Cash Collection Summary',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064e3b), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Collected COD Cash Today',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Rs. ${totalCollected.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                        'Pending: Rs. ${parcelController.stats.value.codTotal.toStringAsFixed(0)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                  Text('${deliveredCodParcels.length} Delivered',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('COD Parcels Log',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor)),
        const SizedBox(height: 10),
        ...codParcels.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${p.trackingNumber}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Text(p.receiverName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: subtextColor, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('Rs. ${p.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: p.status == 'Delivered'
                              ? AppColors.accentGreen
                              : AppColors.accentGold)),
                ],
              ),
            )),
      ],
    );
  }

  // TAB 2: Quick Search & Instant Camera QR Scan View
  Widget _buildQuickScanTab(BuildContext context, bool isDark, Color cardColor,
      Color borderColor, Color textColor, Color subtextColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parcel Search & QR Scanner',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    const SizedBox(height: 2),
                    Text('Type tracking code or tap QR icon to scan',
                        style: TextStyle(fontSize: 12, color: subtextColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Field with Corner QR Scan Icon Button
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: parcelController.searchController,
              onChanged: (val) => parcelController.searchParcels(val),
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter Tracking # (e.g. PK-1001)',
                hintStyle: TextStyle(color: subtextColor),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 24),
                  tooltip: 'Tap to Scan QR Code',
                  onPressed: () => _openCameraQrScanner(context, isDark),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Big Quick Camera Launch Button
          ElevatedButton.icon(
            onPressed: () => _openCameraQrScanner(context, isDark),
            icon: const Icon(Icons.camera_alt, size: 20),
            label: const Text('Open Camera Scanner',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 24),

          // Helpful Instructions Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scanning or typing parcel code automatically filters your delivery list and opens parcel status.',
                    style: TextStyle(color: subtextColor, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: Rider Profile & System Info (Clean 3-Card Architecture)
  Widget _buildProfileTab(BuildContext context, bool isDark, Color cardColor,
      Color borderColor, Color textColor, Color subtextColor) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 24),
      children: [
        // CARD 1: ACCOUNT & SECURITY CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(t('Account & Security'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Obx(() {
                      final avatar = authController.userAvatarUrl.value;
                      return GestureDetector(
                        onTap: () => _openAvatarPicker(context, isDark),
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryLight],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.primary.withOpacity(0.35),
                                      blurRadius: 15),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: avatar.isNotEmpty
                                    ? Image.network(
                                        avatar,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => Center(
                                          child: Text(
                                            authController.userName.value.isNotEmpty
                                                ? authController.userName.value[0].toUpperCase()
                                                : 'R',
                                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          authController.userName.value.isNotEmpty
                                              ? authController.userName.value[0].toUpperCase()
                                              : 'R',
                                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() => Text(
                          authController.userName.value,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        )),
                    const SizedBox(height: 3),
                    Obx(() => Text(
                          authController.userEmail.value,
                          style: TextStyle(fontSize: 13, color: subtextColor),
                        )),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record, size: 8, color: AppColors.accentGreen),
                          SizedBox(width: 6),
                          Text(
                            'Rider Account Active',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Obx(() => _buildProfileTile(
                icon: Icons.storefront_outlined,
                title: 'Assigned Branch',
                subtitle: '${authController.branchName.value} (${authController.branchCity.value})',
                cardColor: Colors.transparent,
                borderColor: Colors.transparent,
                textColor: textColor,
                subtextColor: subtextColor,
              )),
              _buildProfileTile(
                icon: Icons.lock_reset_outlined,
                title: 'Change Password',
                subtitle: 'Update your login password',
                cardColor: Colors.transparent,
                borderColor: Colors.transparent,
                textColor: textColor,
                subtextColor: subtextColor,
                onTap: () => _openChangePasswordDialog(context, isDark),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // CARD 2: APP SETTINGS CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings_suggest_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(t('App Settings & Preferences'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              const SizedBox(height: 14),
              Obx(() {
                final lang = authController.selectedLanguage.value;
                final Map<String, String> langNames = {
                  'en': 'English (Global Default 🌐)',
                  'sw': 'Kiswahili (Tanzania 🇹🇿)',
                  'ur': 'اردو (Pakistan 🇵🇰)',
                  'ar': 'العربية (Saudi Arabia 🇸🇦)',
                  'tr': 'Türkçe (Turkey 🇹🇷)',
                  'hi': 'हिन्दी (India 🇮🇳)',
                  'fr': 'Français (France 🇫🇷)',
                  'zh': '中文 (China 🇨🇳)',
                  'es': 'Español (Spain 🇪🇸)',
                  'es-co': 'Español (Colombia 🇨🇴)',
                  'es-ar': 'Español (Argentina 🇦🇷)',
                  'es-do': 'Español (Dominicana 🇩🇴)',
                  'pt-pt': 'Português (Portugal 🇵🇹)',
                  'pt-br': 'Português (Brasil 🇧🇷)',
                  'ru': 'Русский (Russia 🇷🇺)',
                  'zh-tw': '繁體中文 (Taiwan 🇹🇼)',
                  'de': 'Deutsch (Germany 🇩🇪)',
                  'id': 'Indonesian (Bahasa 🇮🇩)',
                  'nl-nl': 'Nederlands (Dutch 🇳🇱)',
                  'ko-kr': '한국어 (Korea 🇰🇷)',
                  'vi-vn': 'Tiếng Việt (Vietnam 🇻🇳)',
                  'ja-jp': '日本語 (Japan 🇯🇵)',
                  'ro-ro': 'Română (Romania 🇷🇴)',
                };
                final langLabel = langNames[lang] ?? 'English (Global Default 🌐)';

                return _buildProfileTile(
                  icon: Icons.language_outlined,
                  title: 'App Language',
                  subtitle: langLabel,
                  cardColor: Colors.transparent,
                  borderColor: Colors.transparent,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () => _openLanguageSelectorModal(context, isDark),
                );
              }),
              Obx(() {
                final pref = authController.themePreference.value;
                String prefLabel = 'Dark Mode Active';
                IconData prefIcon = Icons.dark_mode_outlined;
                if (pref == 'system') {
                  prefLabel = 'System Theme (Auto)';
                  prefIcon = Icons.brightness_auto_outlined;
                } else if (pref == 'light') {
                  prefLabel = 'Light Mode Active';
                  prefIcon = Icons.light_mode_outlined;
                }
                return _buildProfileTile(
                  icon: prefIcon,
                  title: 'Theme Preference',
                  subtitle: prefLabel,
                  cardColor: Colors.transparent,
                  borderColor: Colors.transparent,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () => _openThemeSelectorModal(context, isDark),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // CARD 3: ABOUT & POLICIES CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('About & System Policies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              const SizedBox(height: 14),
              _buildProfileTile(
                icon: Icons.speed_outlined,
                title: 'App Version',
                subtitle: 'v1.0.0 (Cheetah Express Systems)',
                cardColor: Colors.transparent,
                borderColor: Colors.transparent,
                textColor: textColor,
                subtextColor: subtextColor,
              ),
              _buildProfileTile(
                icon: Icons.gavel_outlined,
                title: 'Terms of Service',
                subtitle: 'Read driver terms & service policies',
                cardColor: Colors.transparent,
                borderColor: Colors.transparent,
                textColor: textColor,
                subtextColor: subtextColor,
                onTap: () => _launchExternalUrl('https://cheetah.ayan24.me/terms-and-conditions'),
              ),
              _buildProfileTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Data usage & privacy standards',
                cardColor: Colors.transparent,
                borderColor: Colors.transparent,
                textColor: textColor,
                subtextColor: subtextColor,
                onTap: () => _launchExternalUrl('https://cheetah.ayan24.me/privacy-policy'),
              ),
              _buildProfileTile(
                icon: Icons.delete_sweep_outlined,
                title: 'Data Deletion Request',
                subtitle: 'Account & data deletion options',
                cardColor: Colors.transparent,
                borderColor: Colors.transparent,
                textColor: textColor,
                subtextColor: subtextColor,
                onTap: () => _launchExternalUrl('https://cheetah.ayan24.me/data-deletion'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _confirmLogout(context, isDark),
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Sign Out of Device', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  // Camera QR Scanner Modal Sheet Function
  void _openCameraQrScanner(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardBg : AppColorsLight.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          height: 420,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scan Parcel QR / Barcode',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColorsLight.textMain),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white70 : AppColorsLight.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      MobileScanner(
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            final code = barcode.rawValue;
                            if (code != null && code.isNotEmpty) {
                              parcelController.searchParcels(code);
                              selectedNavIndex.value = 0; // Switch to Deliveries
                              Navigator.pop(ctx);
                              Get.snackbar(
                                'QR Scanned! 📦',
                                'Tracking Code: $code',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.primary,
                                colorText: Colors.white,
                              );
                              break;
                            }
                          }
                        },
                      ),
                      Center(
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary, width: 2.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Point camera at QR code. Scanned code will auto-fill input & search.',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFd4d4d8) : AppColorsLight.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color cardColor,
      required Color borderColor,
      required Color textColor,
      required Color subtextColor,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: subtextColor, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(
      String label,
      String value,
      IconData icon,
      Color color,
      Color cardColor,
      Color borderColor,
      Color subtextColor) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: subtextColor)),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title, String value, Color cardColor,
      Color borderColor, Color subtextColor) {
    return Obx(() {
      final isSelected = parcelController.activeFilter.value == value;
      return GestureDetector(
        onTap: () => parcelController.applyFilter(value),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected ? AppColors.primary : borderColor),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : subtextColor,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildParcelCard(
      BuildContext context,
      ParcelModel p,
      bool isDark,
      Color cardColor,
      Color borderColor,
      Color textColor,
      Color subtextColor) {
    final bool isDelivered = p.status == 'Delivered';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDelivered
              ? AppColors.accentGreen.withOpacity(0.35)
              : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${p.trackingNumber}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 15),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDelivered
                      ? AppColors.accentGreen.withOpacity(0.2)
                      : AppColors.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  p.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDelivered
                        ? AppColors.accentGreen
                        : AppColors.accentGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            p.receiverName,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  p.receiverAddress,
                  style: TextStyle(fontSize: 13, color: subtextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Mode',
                      style: TextStyle(fontSize: 11, color: subtextColor)),
                  const SizedBox(height: 2),
                  Text(
                    '${p.paymentStatus} (Rs. ${p.amount.toStringAsFixed(0)})',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGreen),
                  ),
                ],
              ),
              Row(
                children: [
                  // Direct Call
                  _buildActionButton(
                    icon: Icons.phone,
                    color: AppColors.accentGreen,
                    onTap: () => _makePhoneCall(p.receiverPhone),
                  ),
                  const SizedBox(width: 8),
                  // WhatsApp Chat
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    color: Colors.lightGreenAccent,
                    onTap: () => _openWhatsApp(p.receiverPhone),
                  ),
                  const SizedBox(width: 8),
                  // Navigation
                  _buildActionButton(
                    icon: Icons.navigation_outlined,
                    color: AppColors.accentBlue,
                    onTap: () => _openMap(p.receiverAddress),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // POD Action Button
          if (isDelivered)
            ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Delivered (POD Verified)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen.withOpacity(0.18),
                foregroundColor: AppColors.accentGreen,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => _showPodBottomSheet(context, p, cardColor, borderColor, textColor, subtextColor),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Mark Delivered & POD',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }

  void _showPodBottomSheet(BuildContext context, ParcelModel p, Color cardColor,
      Color borderColor, Color textColor, Color subtextColor) {
    File? selectedPhoto;
    final TextEditingController nameController =
        TextEditingController(text: p.receiverName);
    final TextEditingController descController = TextEditingController();
    final ImagePicker picker = ImagePicker();

    final SignatureController signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Proof of Delivery (POD)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: subtextColor),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text('Receiver Name *',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text('Photo Proof (Camera or Gallery)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final XFile? photo = await picker.pickImage(
                                source: ImageSource.camera, imageQuality: 80);
                            if (photo != null) {
                              setState(() {
                                selectedPhoto = File(photo.path);
                              });
                            }
                          },
                          child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.4)),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt,
                                    size: 26, color: AppColors.primary),
                                SizedBox(height: 4),
                                Text('Camera',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final XFile? photo = await picker.pickImage(
                                source: ImageSource.gallery, imageQuality: 80);
                            if (photo != null) {
                              setState(() {
                                selectedPhoto = File(photo.path);
                              });
                            }
                          },
                          child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.accentBlue.withOpacity(0.4)),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_library,
                                    size: 26, color: AppColors.accentBlue),
                                SizedBox(height: 4),
                                Text('Gallery',
                                    style: TextStyle(
                                        color: AppColors.accentBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectedPhoto != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(selectedPhoto!,
                          height: 120, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Customer Digital Signature',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      GestureDetector(
                        onTap: () => signatureController.clear(),
                        child: const Text('Clear Pad',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 100,
                      color: Colors.white,
                      child: Signature(
                        controller: signatureController,
                        height: 100,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text('Delivery Remarks / Notes',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'e.g. Handed over to recipient in person',
                      hintStyle: TextStyle(color: subtextColor),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        Get.snackbar('Validation', 'Please enter Receiver Name',
                            snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      Navigator.pop(ctx);
                      await parcelController.submitPod(
                        parcelId: p.id,
                        trackingNumber: p.trackingNumber,
                        status: 'Delivered',
                        receiverName: nameController.text.trim(),
                        description: descController.text.trim(),
                        photoFile: selectedPhoto,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Submit POD & Mark Delivered',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _confirmLogout(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardBg : AppColorsLight.cardBg,
        title: Text('Sign Out', style: TextStyle(color: isDark ? Colors.white : AppColorsLight.textMain)),
        content: Text('Are you sure you want to sign out of the Driver App?',
            style: TextStyle(color: isDark ? const Color(0xFFd4d4d8) : AppColorsLight.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColorsLight.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              authController.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _launchExternalUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url);
      }
    } catch (e) {
      Get.snackbar('Link', 'Opening $urlString...',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url);
      }
    } catch (e) {
      Get.snackbar('Dialer', 'Opening phone dialer ($cleanPhone)...',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.isEmpty) return;
    final Uri url = Uri.parse('https://wa.me/$cleanPhone');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url);
      }
    } catch (e) {
      Get.snackbar('WhatsApp', 'Opening WhatsApp chat ($cleanPhone)...',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _openMap(String address) async {
    if (address.isEmpty) return;
    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url);
      }
    } catch (e) {
      Get.snackbar('Maps', 'Opening map for $address...',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _openAvatarPicker(BuildContext context, bool isDark) {
    final ImagePicker picker = ImagePicker();
    final cardColor = isDark ? AppColors.cardBg : AppColorsLight.cardBg;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textColor = isDark ? Colors.white : AppColorsLight.textMain;
    final subtextColor = isDark ? const Color(0xFFd4d4d8) : AppColorsLight.textMuted;

    final List<Map<String, String>> presets = [
      {'name': 'Orbit', 'url': 'https://api.dicebear.com/9.x/bottts-neutral/png?seed=orbit-01'},
      {'name': 'Nova', 'url': 'https://api.dicebear.com/9.x/bottts-neutral/png?seed=orbit-02'},
      {'name': 'Pixel', 'url': 'https://api.dicebear.com/9.x/bottts-neutral/png?seed=orbit-03'},
      {'name': 'Echo', 'url': 'https://api.dicebear.com/9.x/bottts-neutral/png?seed=orbit-04'},
      {'name': 'Mint', 'url': 'https://api.dicebear.com/9.x/bottts-neutral/png?seed=orbit-05'},
      {'name': 'Solar', 'url': 'https://api.dicebear.com/9.x/bottts-neutral/png?seed=orbit-06'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload a custom photo or pick an official website avatar',
                style: TextStyle(fontSize: 12, color: subtextColor),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final XFile? photo = await picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 800,
                          maxHeight: 800,
                        );
                        if (photo != null) {
                          authController.updateAvatar(avatarFile: File(photo.path));
                        }
                      },
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final XFile? photo = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          maxHeight: 800,
                        );
                        if (photo != null) {
                          authController.updateAvatar(avatarFile: File(photo.path));
                        }
                      },
                      icon: const Icon(Icons.photo_library, color: Colors.white, size: 18),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Website Preset Avatars',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: presets.length,
                itemBuilder: (c, idx) {
                  final p = presets[idx];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      authController.updateAvatar(presetAvatar: p['url']);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              p['url']!,
                              width: 48,
                              height: 48,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p['name']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _openLanguageSelectorModal(BuildContext context, bool isDark) {
    final cardColor = isDark ? AppColors.cardBg : AppColorsLight.cardBg;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textColor = isDark ? Colors.white : AppColorsLight.textMain;
    final subtextColor = isDark ? const Color(0xFFd4d4d8) : AppColorsLight.textMuted;

    final List<Map<String, String>> languages = [
      {'code': 'en', 'name': 'English', 'region': 'Global Default 🌐'},
      {'code': 'sw', 'name': 'Kiswahili', 'region': 'Tanzania 🇹🇿'},
      {'code': 'ur', 'name': 'اردو', 'region': 'Pakistan 🇵🇰'},
      {'code': 'ar', 'name': 'العربية', 'region': 'Saudi Arabia 🇸🇦'},
      {'code': 'tr', 'name': 'Türkçe', 'region': 'Turkey 🇹🇷'},
      {'code': 'hi', 'name': 'हिन्दी', 'region': 'India 🇮🇳'},
      {'code': 'fr', 'name': 'Français', 'region': 'France 🇫🇷'},
      {'code': 'zh', 'name': '中文 (簡)', 'region': 'China 🇨🇳'},
      {'code': 'es', 'name': 'Español', 'region': 'Spain 🇪🇸'},
      {'code': 'es-co', 'name': 'Español', 'region': 'Colombia 🇨🇴'},
      {'code': 'es-ar', 'name': 'Español', 'region': 'Argentina 🇦🇷'},
      {'code': 'es-do', 'name': 'Español', 'region': 'Dominicana 🇩🇴'},
      {'code': 'pt-pt', 'name': 'Português', 'region': 'Portugal 🇵🇹'},
      {'code': 'pt-br', 'name': 'Português', 'region': 'Brasil 🇧🇷'},
      {'code': 'ru', 'name': 'Русский', 'region': 'Russia 🇷🇺'},
      {'code': 'zh-tw', 'name': '繁體中文', 'region': 'Taiwan 🇹🇼'},
      {'code': 'de', 'name': 'Deutsch', 'region': 'Germany 🇩🇪'},
      {'code': 'id', 'name': 'Indonesian', 'region': 'Bahasa 🇮🇩'},
      {'code': 'nl-nl', 'name': 'Nederlands', 'region': 'Dutch 🇳🇱'},
      {'code': 'ko-kr', 'name': '한국어', 'region': 'Korea 🇰🇷'},
      {'code': 'vi-vn', 'name': 'Tiếng Việt', 'region': 'Vietnam 🇻🇳'},
      {'code': 'ja-jp', 'name': '日本語', 'region': 'Japan 🇯🇵'},
      {'code': 'ro-ro', 'name': 'Română', 'region': 'Romania 🇷🇴'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(
                'Select App Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your preferred language for the Rider Portal',
                style: TextStyle(fontSize: 12, color: subtextColor),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (c, idx) {
                    final item = languages[idx];
                    return Obx(() {
                      final isSelected = authController.selectedLanguage.value == item['code'];
                      return ListTile(
                        onTap: () {
                          authController.setAppLanguage(item['code']!);
                          Navigator.pop(ctx);
                          Get.snackbar(
                            'Language Updated',
                            'App language set to ${item['name']}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.primary,
                            colorText: Colors.white,
                          );
                        },
                        title: Text(item['name']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: textColor)),
                        subtitle: Text(item['region']!, style: TextStyle(fontSize: 11, color: subtextColor)),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openThemeSelectorModal(BuildContext context, bool isDark) {
    final cardColor = isDark ? AppColors.cardBg : AppColorsLight.cardBg;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textColor = isDark ? Colors.white : AppColorsLight.textMain;
    final subtextColor = isDark ? const Color(0xFFd4d4d8) : AppColorsLight.textMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Obx(() {
          final currentMode = authController.themePreference.value;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Theme Preference',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your preferred visual appearance mode',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
                const SizedBox(height: 20),
                
                _buildThemeOptionTile(
                  title: 'System Theme (Auto)',
                  subtitle: 'Matches device system light / dark settings',
                  icon: Icons.brightness_auto,
                  isSelected: currentMode == 'system',
                  onTap: () {
                    authController.setThemePreference('system');
                    Navigator.pop(ctx);
                  },
                  textColor: textColor,
                  subtextColor: subtextColor,
                  borderColor: borderColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),

                _buildThemeOptionTile(
                  title: 'Dark Mode',
                  subtitle: 'Sleek dark theme optimized for night duty',
                  icon: Icons.dark_mode_outlined,
                  isSelected: currentMode == 'dark',
                  onTap: () {
                    authController.setThemePreference('dark');
                    Navigator.pop(ctx);
                  },
                  textColor: textColor,
                  subtextColor: subtextColor,
                  borderColor: borderColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),

                _buildThemeOptionTile(
                  title: 'Light Mode',
                  subtitle: 'Clean high-contrast theme for daylight visibility',
                  icon: Icons.light_mode_outlined,
                  isSelected: currentMode == 'light',
                  onTap: () {
                    authController.setThemePreference('light');
                    Navigator.pop(ctx);
                  },
                  textColor: textColor,
                  subtextColor: subtextColor,
                  borderColor: borderColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
    required Color subtextColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : subtextColor, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: subtextColor),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _openChangePasswordDialog(BuildContext context, bool isDark) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    final cardColor = isDark ? AppColors.cardBg : AppColorsLight.cardBg;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textColor = isDark ? Colors.white : AppColorsLight.textMain;
    final subtextColor = isDark ? const Color(0xFFd4d4d8) : AppColorsLight.textMuted;

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Update your rider account security password',
                          style: TextStyle(fontSize: 11, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: currentPassCtrl,
                obscureText: true,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  labelStyle: TextStyle(color: subtextColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.key_outlined, size: 20),
                  labelStyle: TextStyle(color: subtextColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                  labelStyle: TextStyle(color: subtextColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('Cancel', style: TextStyle(color: subtextColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (currentPassCtrl.text.isEmpty || newPassCtrl.text.isEmpty) {
                          Get.snackbar('Validation Error', 'Please fill in all password fields',
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        if (newPassCtrl.text != confirmPassCtrl.text) {
                          Get.snackbar('Validation Error', 'New passwords do not match',
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        if (newPassCtrl.text.length < 6) {
                          Get.snackbar('Validation Error', 'Password must be at least 6 characters',
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        Get.back();
                        authController.changePassword(
                            currentPassCtrl.text, newPassCtrl.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
