import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/data/local_storage_keys.dart';
import 'package:freeaihub/core/data/model_definisions.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/routes/app_routes.dart';
import 'package:freeaihub/core/global/components/dialogs.dart';
import 'package:freeaihub/core/global/services/get_storage_service.dart';
import 'package:get/get.dart';

/// Home controller that manages the main screen functionality and navigation
/// Now includes TabController for tab-based navigation between main view and quick actions
class HomeController extends GetxController with GetSingleTickerProviderStateMixin {
  // TabController for managing tab navigation
  late TabController tabController;

  // Track current tab index
  final RxInt currentTabIndex = 1.obs;

  @override
  void onInit() {
    // Initialize TabController with 2 tabs (Main View and Quick Actions)
    tabController = TabController(length: 2, vsync: this, initialIndex: currentTabIndex.value);

    // Listen to tab changes
    tabController.addListener(() {
      currentTabIndex.value = tabController.index;
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () {
        int? value = GetStorageService.to.getData<int?>(
          key: LocalStorageKeys.welcomeDialogShown.value,
        );
        value ??= 0;
        if ((value) <= welcomeDialogLimit || isDebugMod) {
          showDialog(
            barrierDismissible: false,
            context: Get.context!,
            builder: (BuildContext context) => welcomeDialog(
              onContinue: () {
                Get.back();
                GetStorageService.to.saveData(
                  key: LocalStorageKeys.welcomeDialogShown.value,
                  value: value! + 1,
                );
              },
            ),
          );
        }
      });
    });
    super.onInit();
  }

  @override
  void onClose() {
    // Dispose TabController when controller is disposed
    tabController.dispose();
    super.onClose();
  }

  /// Navigate to Library View
  void navigateToLibraryView() {
    tabController.animateTo(0);
  }

  /// Navigate to Main View
  void navigateToMainView() {
    tabController.animateTo(1);
  }

  /// Navigates to the appropriate screen based on AI model category with iOS-style transitions
  void viewSelector(AIModel model) {
    // Navigate to appropriate screen with iOS-style transitions
    switch (model.category) {
      case CategoryTypes.chat:
        // Use cupertino transition for chat screens
        Get.toNamed(AppRoutes.chat, arguments: model);
        break;
      case CategoryTypes.imageGeneration:
        // Check model ID to determine which image generation screen to use
        if (model.id == ModelDefinitions.pollinationsAiImage.id) {
          Get.toNamed(AppRoutes.pollinations, arguments: model);
        } else {
          // Default to hidream for other image generation models
          Get.toNamed(AppRoutes.hidream, arguments: model);
        }
        break;
      case CategoryTypes.audioGeneration:
        // Use cupertino transition for audio generation screens
        Get.toNamed(AppRoutes.orpheus, arguments: model);
        break;
      default:
        // Handle unknown category types
        break;
    }
  }

  /// Refreshes home view when called from other screens (e.g., after closing chat)
  void refreshHomeView() {
    update();
  }
}
