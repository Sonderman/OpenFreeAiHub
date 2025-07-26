import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/data/model_definisions.dart';
import 'package:freeaihub/main.dart';
import 'package:freeaihub/core/routes/app_routes.dart';
import 'package:get/get.dart';

// Controller for managing the splash screen logic.
// Handles initial app setup, service checks, and navigation to the appropriate screen.
class SplashController extends GetxController {
  // Observable boolean to track loading state.
  final isLoading = true.obs;

  // Observable string to display loading status text.
  final textStatus = "Loading...".obs;

  @override
  void onInit() async {
    super.onInit();
    // Initialize services required for the app.
    await setServices();

    appInstance.activeModels.clear();
    for (var model in ModelDefinitions.availableModels.values) {
      appInstance.activeModels.add(model);
    }

    // Check if the user has completed the welcome preferences.
    // If not, navigate to the welcome preferences screen.
    if (!appInstance.isPreferencesCompleted) {
      Get.offAllNamed(AppRoutes.welcomePreferences);
      return;
    }

    Get.offAllNamed(AppRoutes.home);
  }
}
