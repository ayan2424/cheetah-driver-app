import 'package:get/get.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

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

  Future<void> fetchWallet() async {
    // Only drivers have delivery commissions / wallets
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
