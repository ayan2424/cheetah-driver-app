import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/parcel_model.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

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
      Get.snackbar('Error', res['error'] ?? 'Failed to load parcels',
          snackPosition: SnackPosition.BOTTOM);
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
      result = result.where((p) =>
          p.trackingNumber.toLowerCase().contains(q) ||
          p.receiverName.toLowerCase().contains(q) ||
          p.receiverAddress.toLowerCase().contains(q) ||
          p.receiverPhone.toLowerCase().contains(q));
    }
    filteredParcels.value = result.toList();
  }

  Future<bool> submitPod({
    required int parcelId,
    required String trackingNumber,
    required String status,
    required String receiverName,
    required String description,
    File? photoFile,
  }) async {
    isSubmittingPod.value = true;
    final token = authController.userToken.value;

    final res = await ApiService.updateStatusWithPod(
      token: token,
      parcelId: parcelId.toString(),
      trackingNumber: trackingNumber,
      status: status,
      receiverName: receiverName,
      description: description,
      photoFile: photoFile,
    );

    isSubmittingPod.value = false;

    if (res['success'] == true) {
      Get.snackbar('Success', 'POD Submitted & Status Updated!',
          snackPosition: SnackPosition.BOTTOM);
      fetchParcels(); // Refresh list
      return true;
    } else {
      Get.snackbar('Error', res['error'] ?? 'Failed to update status',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }
}
