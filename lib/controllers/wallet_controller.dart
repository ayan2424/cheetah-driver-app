import 'package:get/get.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

/// [WalletController] manages courier delivery earnings, pending commissions, and payout history.
///
/// Logistics Accounting Context:
/// - Courier riders earn per-parcel delivery commissions configured in the Cheetah central system settings.
/// - When a parcel transitions to 'Delivered', the driver's commission is credited to `pending_balance`.
/// - Branch accountants issue payouts from the web admin portal, moving funds from pending to `total_paid`.
/// - Scoping Rule: Warehouse pickers work on hourly/shift wages and do not have individual COD/commission wallets.
class WalletController extends GetxController {
  var isLoading = false.obs;
  var pendingBalance = 0.0.obs;
  var totalEarned = 0.0.obs;
  var totalPaid = 0.0.obs;
  var history = [].obs;

  final AuthController authController = Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    fetchWallet();
  }

  /// Synchronizes courier commission balances and disbursement transaction history.
  Future<void> fetchWallet() async {
    // Only drivers have delivery commissions / wallets; pickers are exempt
    if (authController.userRole.value == 'picker') {
      isLoading.value = false;
      return;
    }

    final token = authController.userToken.value;
    if (token.isEmpty) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    final res = await ApiService.fetchDriverWallet(token: token);
    
    if (res['success'] == true && res['wallet'] != null) {
      pendingBalance.value = (res['wallet']['pending_balance'] as num).toDouble();
      totalEarned.value = (res['wallet']['total_earned'] as num).toDouble();
      totalPaid.value = (res['wallet']['total_paid'] as num).toDouble();
      history.value = res['wallet']['history'] ?? [];
    }
    
    isLoading.value = false;
  }
}
