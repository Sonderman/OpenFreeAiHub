import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/data/model_definisions.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/global/services/ai_client_service.dart';
import 'package:freeaihub/core/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../home_controller.dart';

/// Custom app bar for the home screen with settings and debug actions
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: AutoSizeText(
        appName,
        minFontSize: appInstance.isTablet ? 28 : 12,
        maxLines: 2,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      automaticallyImplyLeading: false,
      actions: [_buildPreferencesButton(), if (isDebugMod) ..._buildDebugActions()],
    );
  }

  /// Builds the preferences button
  Widget _buildPreferencesButton() {
    return IconButton(
      icon: Icon(Icons.settings),
      onPressed: () => Get.toNamed(AppRoutes.preferences),
      tooltip: 'Preferences',
    );
  }

  /// Builds debug-only action buttons
  List<Widget> _buildDebugActions() {
    return [_buildClearStorageButton(), _buildRefreshModelsButton()];
  }

  /// Builds the clear storage debug button
  Widget _buildClearStorageButton() {
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () {
        GetStorage().erase();
        Get.snackbar(
          'Debug',
          'GetStorage data cleared',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }

  /// Builds the refresh models debug button
  Widget _buildRefreshModelsButton() {
    return IconButton(icon: Icon(Icons.refresh), onPressed: () => _refreshModels());
  }

  /// Refreshes available AI models (debug only)
  Future<void> _refreshModels() async {
    final controller = Get.find<HomeController>();

    EasyLoading.show(
      status: "Checking Available Models...",
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.black,
    );

    List<String> availableModelsFromFirestore = [];
    appInstance.activeModels.clear();

    try {
      // Load active models from remote config
      for (var model in ModelDefinitions.availableModels.entries) {
        if (model.value.category == CategoryTypes.chat) {
          bool isAvailable = await AiClientService.checkAvailability(model: model.value);
          if (kDebugMode) {
            print("Model ${model.value.apiModel.modelName} is available : $isAvailable");
          }
          if (isAvailable) {
            appInstance.activeModels.add(model.value);
            availableModelsFromFirestore.add(model.key);
          }
        } else {
          appInstance.activeModels.add(model.value);
          availableModelsFromFirestore.add(model.key);
        }
      }

      if (kDebugMode) {
        print("Available Model Count : ${appInstance.activeModels.length}");
      }

      Get.snackbar(
        'Debug',
        'Models refreshed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      Get.snackbar(
        'Debug',
        'Error!!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      controller.update();
      EasyLoading.dismiss();
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

/// Sliver version of the home app bar to be used inside NestedScrollView headers
class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: false,
      floating: true,
      snap: true,
      centerTitle: true,
      title: AutoSizeText(
        appName,
        minFontSize: appInstance.isTablet ? 28 : 12,
        maxLines: 2,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      automaticallyImplyLeading: false,
      actions: [_buildPreferencesButton(), if (isDebugMod) ..._buildDebugActions()],
    );
  }

  // Re-use helper methods from below (duplicated here for simplicity)
  Widget _buildPreferencesButton() {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () => Get.toNamed(AppRoutes.preferences),
      tooltip: 'Preferences',
    );
  }

  List<Widget> _buildDebugActions() {
    return [_buildClearStorageButton(), _buildRefreshModelsButton()];
  }

  Widget _buildClearStorageButton() {
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () {
        GetStorage("Preferences").erase();
        Get.snackbar(
          'Debug',
          'GetStorage data cleared',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }

  Widget _buildRefreshModelsButton() {
    return IconButton(icon: const Icon(Icons.refresh), onPressed: () => _refreshModels());
  }

  Future<void> _refreshModels() async {
    final controller = Get.find<HomeController>();

    EasyLoading.show(
      status: "Checking Available Models...",
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.black,
    );

    List<String> availableModelsFromFirestore = [];
    appInstance.activeModels.clear();

    try {
      // Load active models from remote config
      for (var model in ModelDefinitions.availableModels.entries) {
        if (model.value.category == CategoryTypes.chat) {
          bool isAvailable = await AiClientService.checkAvailability(model: model.value);
          if (kDebugMode) {
            // ignore: avoid_print
            print("Model ${model.value.apiModel.modelName} is available : $isAvailable");
          }
          if (isAvailable) {
            appInstance.activeModels.add(model.value);
            availableModelsFromFirestore.add(model.key);
          }
        } else {
          appInstance.activeModels.add(model.value);
          availableModelsFromFirestore.add(model.key);
        }
      }

      if (kDebugMode) {
        // ignore: avoid_print
        print("Available Model Count : ${appInstance.activeModels.length}");
      }

      Get.snackbar(
        'Debug',
        'Models refreshed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print(e);
      }
      Get.snackbar(
        'Debug',
        'Error!!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      controller.update();
      EasyLoading.dismiss();
    }
  }
}
