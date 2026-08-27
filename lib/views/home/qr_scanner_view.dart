import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_translations.dart';

class QrScannerView extends StatefulWidget {
  @override
  _QrScannerViewState createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final MobileScannerController controller = MobileScannerController();

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
      appBar: AppBar(
        title: Text('Scan Parcel AWB'.localize(lang)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              controller.stop();
              Get.back(result: code);
            }
          }
        },
      ),
    );
  }
}
