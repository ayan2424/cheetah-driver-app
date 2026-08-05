import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/parcel_model.dart';
import '../services/api_service.dart';
import '../services/offline_sync_service.dart';
import 'auth_controller.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

class ParcelController extends GetxController {
  var isLoading = false.obs;
  var isSubmittingPod = false.obs;
  var parcelsList = <ParcelModel>[].obs;
  var filteredParcels = <ParcelModel>[].obs;
  var activeFilter = 'all'.obs;
  var searchQuery = ''.obs;

  final TextEditingController searchController = TextEditingController();

  var stats = ParcelStats(
    outForDelivery: 0,
    inTransit: 0,
    deliveredToday: 0,
    codTotal: 0.0,
  ).obs;

  final AuthController authController = Get.find();

  @override
  void onInit() {
    super.onInit();
    fetchParcels();
    // Auto-fetch whenever userToken becomes available
    ever(authController.userToken, (String token) {
      if (token.isNotEmpty) {
        fetchParcels();
      }
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchParcels() async {
    isLoading.value = true;
    var token = authController.userToken.value;

    // If token is empty, await session load first
    if (token.isEmpty) {
      await authController.loadUserSession();
      token = authController.userToken.value;
    }

    if (token.isEmpty) {
      isLoading.value = false;
      return;
    }

    final res = await ApiService.fetchParcels(token);
    isLoading.value = false;

    if (res['success'] == true) {
      parcelsList.value = res['parcels'];
      stats.value = res['stats'];
      _applyFilterAndSearch();
    } else {
      final err = (res['error'] ?? '').toString().toLowerCase();
      if (err.contains('invalid api token') ||
          err.contains('session expired') ||
          err.contains('token is required')) {
        authController.handleSessionExpired();
        return;
      }
      Get.snackbar(
        'Error',
        res['error'] ?? 'Failed to load parcels',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void searchParcels(String query) {
    searchQuery.value = query.toLowerCase().trim();
    if (searchController.text != query) {
      searchController.text = query;
      searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: searchController.text.length),
      );
    }
    _applyFilterAndSearch();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _applyFilterAndSearch();
  }

  void applyFilter(String filter) {
    activeFilter.value = filter;
    _applyFilterAndSearch();
  }

  void _applyFilterAndSearch() {
    Iterable<ParcelModel> result = parcelsList;
    if (activeFilter.value != 'all') {
      result = result.where((p) => p.status == activeFilter.value);
    }
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value;
      result = result.where(
        (p) =>
            p.trackingNumber.toLowerCase().contains(q) ||
            p.receiverName.toLowerCase().contains(q) ||
            p.receiverAddress.toLowerCase().contains(q) ||
            p.receiverPhone.toLowerCase().contains(q),
      );
    }
    filteredParcels.value = result.toList();
  }

  Future<bool> submitPod({
    required int parcelId,
    required String trackingNumber,
    required String status,
    required String receiverName,
    required String description,
    String? deliveryOtp,
    File? photoFile,
    Uint8List? signatureBytes,
  }) async {
    isSubmittingPod.value = true;
    final token = authController.userToken.value;

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.mobile) && 
        !connectivityResult.contains(ConnectivityResult.wifi)) {
      
      final payload = {
        'token': token,
        'parcelId': parcelId.toString(),
        'trackingNumber': trackingNumber,
        'status': status,
        'receiverName': receiverName,
        'description': description,
        'deliveryOtp': deliveryOtp,
        'photo_path': photoFile?.path,
        'signature_base64': signatureBytes != null ? base64Encode(signatureBytes) : null,
      };

      await OfflineSyncService.savePodToQueue(payload);
      
      Get.snackbar(
        'Offline Mode',
        'No internet. POD saved to queue and will sync automatically.',
        snackPosition: SnackPosition.BOTTOM,
      );
      isSubmittingPod.value = false;
      return true;
    }

    final res = await ApiService.updateStatusWithPod(
      token: token,
      parcelId: parcelId.toString(),
      trackingNumber: trackingNumber,
      status: status,
      receiverName: receiverName,
      description: description,
      deliveryOtp: deliveryOtp,
      photoFile: photoFile,
      signatureBytes: signatureBytes,
    );

    isSubmittingPod.value = false;

    if (res['success'] == true) {
      Get.snackbar(
        'Success',
        'POD Submitted & Status Updated!',
        snackPosition: SnackPosition.BOTTOM,
      );
      // Wait for the refresh so the cash log includes this delivery before the
      // POD sheet/success route can return control to the rider.
      await fetchParcels();
      return true;
    } else {
      Get.snackbar(
        'Error',
        res['error'] ?? 'Failed to update status',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
