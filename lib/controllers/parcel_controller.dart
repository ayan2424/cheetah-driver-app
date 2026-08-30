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

/// [ParcelController] manages the courier's assigned delivery manifest, multi-status filtering,
/// real-time search queries, summary statistics, and online/offline Proof of Delivery (POD) submissions.
///
/// Core Capabilities:
/// 1. Manifest Isolation & Sync: Fetches parcels assigned strictly to the authenticated driver.
/// 2. Instant Substring Search: Evaluates tracking numbers, recipient names, addresses, and phone numbers in-memory.
/// 3. Resilient POD Flow: Seamlessly catches offline network states and redirects delivery submissions
///    to the encrypted [OfflineSyncService] queue without interrupting courier workflow.
/// 4. Post-Delivery Ledger Reconciliation: Automatically refreshes parcel lists and COD totals upon successful POD.
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
    // Auto-fetch whenever userToken becomes available (e.g. after login or session restore)
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

  /// Synchronizes assigned delivery manifest and performance metrics from the server.
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

  /// Filters parcels by tracking number, recipient name, delivery street, or phone number.
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

  /// Clears active search field and resets filtered list view.
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _applyFilterAndSearch();
  }

  /// Applies status tab filter ('all', 'Out for Delivery', 'In Transit', 'Delivered', etc.).
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

  /// Submits Proof of Delivery (POD) package to the server or stores it in local encrypted queue.
  ///
  /// Offline Fallback Logic:
  /// - Inspects active network interfaces via [Connectivity].
  /// - If no cellular or Wi-Fi connectivity is detected, immediately serializes the payload
  ///   (including local photo path and base64 signature) and saves it to [OfflineSyncService].
  /// - Returns `true` so UI flow smoothly advances without blocking the courier on the road.
  ///
  /// Online Flow:
  /// - Sends multipart HTTP request to Cheetah API with token authorization.
  /// - Awaits list refresh so COD cash collection and delivered count reflect immediately in the UI.
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

    // Check connectivity before initiating network upload
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.mobile) && 
        !connectivityResult.contains(ConnectivityResult.wifi)) {
      
      final payload = {
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
        'Offline Mode 📦',
        'No internet connection. Delivery saved locally and will auto-sync when online.',
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
        'Success 🎉',
        'Proof of Delivery Submitted & Status Updated!',
        snackPosition: SnackPosition.BOTTOM,
      );
      // Synchronize manifest and COD totals so UI updates before bottom sheet dismisses
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
