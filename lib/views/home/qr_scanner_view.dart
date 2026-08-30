import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_translations.dart';
import '../../utils/constants.dart';

/// [QrScannerView] provides a hardware camera scanner for rapid 1D barcode and 2D QR code intake.
///
/// Features:
/// - Tactile Haptic Feedback (`HapticFeedback.mediumImpact()`) on successful scan.
/// - Flashlight/Torch toggle for low-light cargo trucks and warehouse basements.
/// - Visual viewfinder overlay with high-visibility target reticle.
class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final MobileScannerController controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String lang = 'en';
    if (Get.isRegistered<AuthController>()) {
      lang = Get.find<AuthController>().selectedLanguage.value;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Scan AWB Barcode'.localize(lang),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          // Flashlight / Torch Toggle
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: state.torchState == TorchState.on
                      ? Colors.amberAccent
                      : Colors.white70,
                );
              },
            ),
            tooltip: 'Toggle Flashlight',
            onPressed: () => controller.toggleTorch(),
          ),
          // Camera Switch (Front/Back)
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white70),
            tooltip: 'Switch Camera',
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Live Camera Stream
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_hasScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null && code.trim().isNotEmpty) {
                  _hasScanned = true;
                  // Provide instant tactile haptic feedback to the rider
                  HapticFeedback.mediumImpact();
                  controller.stop();
                  Get.back(result: code.trim());
                }
              }
            },
          ),

          // High-Visibility Viewfinder Reticle Overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2.5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Corner Guides
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 3),
                          left: BorderSide(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 3),
                          right: BorderSide(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 3),
                          left: BorderSide(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 3),
                          right: BorderSide(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Helper Tip
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Align AWB Barcode or QR Code within frame'.localize(lang),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
