import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/models/user_preferences.dart';
import 'package:freeaihub/core/routes/app_routes.dart';

class WelcomePreferencesController extends GetxController {
  // Text controllers for form inputs
  final nameController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final selectedLanguage = 'English'.obs;
  final isNameValid = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to name changes for validation
    nameController.addListener(_validateName);

    // Initialize with current preferences
    _initializeWithCurrentPreferences();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  // Initialize form with current user preferences
  void _initializeWithCurrentPreferences() {
    final currentPrefs = appInstance.userPreferences;
    nameController.text = currentPrefs.userName == 'User' ? '' : currentPrefs.userName;
    selectedLanguage.value = currentPrefs.chatLanguage;
  }

  // Validate user name input
  void _validateName() {
    final name = nameController.text.trim();
    isNameValid.value = name.isNotEmpty && name.length >= 2;
  }

  // Update selected language
  void updateLanguage(String language) {
    selectedLanguage.value = language;
  }

  // Check if form is valid for submission
  bool get isFormValid => isNameValid.value && nameController.text.trim().isNotEmpty;

  // Save preferences and navigate to home
  Future<void> savePreferencesAndContinue() async {
    if (!isFormValid) return;

    try {
      isLoading.value = true;

      // Create new preferences object
      final newPreferences = UserPreferences(
        userName: nameController.text.trim(),
        chatLanguage: selectedLanguage.value,
        preferencesCompleted: true,
      );

      // Update preferences in app instance
      appInstance.updateUserPreferences(newPreferences);

      // Navigate to home screen
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      showErrorSnackbar();
    } finally {
      isLoading.value = false;
    }
  }

  // Skip preferences setup (optional)
  void skipPreferences() {
    Get.dialog(
      AlertDialog(
        title: const Text('Skip Preferences'),
        content: const Text(
          'You can change your preferences later in settings. Do you want to continue?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();

              try {
                // Create default preferences
                final defaultPreferences = UserPreferences(
                  userName: 'User',
                  chatLanguage: 'English',
                  preferencesCompleted: true,
                );

                // Update preferences in app instance
                appInstance.updateUserPreferences(defaultPreferences);

                Get.offAllNamed(AppRoutes.home);
              } catch (e) {
                showErrorSnackbar();
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Error snackbar
  void showErrorSnackbar() {
    Get.snackbar(
      'Error',
      'An error occurred while saving preferences. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red,
    );
  }
}
