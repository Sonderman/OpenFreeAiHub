import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:freeaihub/core/global/services/connectiviy_service.dart';
import 'package:freeaihub/core/routes/app_routes.dart';

class OfflineController extends GetxController {
  final ConnectivityService _connectivityService = Get.find();

  Future<void> retryConnection() async {
    // Show loading indicator
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    // Check connection after short delay
    await Future.delayed(const Duration(seconds: 1));
    final isConnected = _connectivityService.isConnected.value;

    if (isConnected) {
      Get.back(); // Close loading
      Get.offAllNamed(AppRoutes.home); // Navigate to home screen
    } else {
      Get.back(); // Close loading
      Get.snackbar(
        'Still Offline',
        'Unable to establish internet connection',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> exitApp() async {
    try {
      Get.back(); // Close offline screen
      await SystemNavigator.pop(); // Exit app
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not exit application',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }
}
