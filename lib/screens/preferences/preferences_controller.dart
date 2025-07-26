import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:get/get.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/models/user_preferences.dart';
import 'package:freeaihub/core/themes/app_theme.dart';
import 'package:freeaihub/core/themes/theme_controller.dart';

/// Controller for the main Preferences screen
/// Handles user preference changes and updates
class PreferencesController extends GetxController {
  // Text controllers for form inputs
  final nameController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final selectedLanguage = 'English'.obs;
  final selectedThemeMode = AppThemeMode.system.obs;
  final selectedColorScheme = FlexScheme.deepOrangeM3.obs;
  final isNameValid = true.obs;

  // Get app instance for accessing user preferences
  AppInstance get appInstance => Get.find<AppInstance>();

  // Get theme controller for immediate theme updates
  ThemeController get themeController => Get.find<ThemeController>();

  // Store original preferences to restore if user cancels
  late UserPreferences _originalPreferences;

  @override
  void onInit() {
    super.onInit();
    // Listen to name changes for validation
    nameController.addListener(_validateName);

    // Store original preferences for restoration if needed
    _originalPreferences = appInstance.userPreferences;

    // Initialize with current preferences
    _initializeWithCurrentPreferences();
  }

  @override
  void onClose() {
    nameController.dispose();

    // Restore original preferences if user didn't save changes
    if (_shouldRestoreOriginalPreferences()) {
      appInstance.userPreferencesRx.value = _originalPreferences;
    }

    super.onClose();
  }

  /// Check if we should restore original preferences
  bool _shouldRestoreOriginalPreferences() {
    final current = appInstance.userPreferences;
    return current.themeMode != _originalPreferences.themeMode ||
        current.colorScheme != _originalPreferences.colorScheme;
  }

  /// Initialize form with current user preferences
  void _initializeWithCurrentPreferences() {
    final currentPrefs = appInstance.userPreferences;
    nameController.text = currentPrefs.userName == 'User' ? '' : currentPrefs.userName;
    selectedLanguage.value = currentPrefs.chatLanguage;
    selectedThemeMode.value = currentPrefs.themeMode;
    selectedColorScheme.value = currentPrefs.colorScheme;
  }

  /// Validate user name input
  void _validateName() {
    final name = nameController.text.trim();
    isNameValid.value = name.isNotEmpty && name.length >= 2;
  }

  /// Update selected language
  void updateLanguage(String language) {
    selectedLanguage.value = language;
  }

  /// Update selected theme mode
  void updateThemeMode(AppThemeMode themeMode) {
    selectedThemeMode.value = themeMode;

    // Apply theme change immediately for live preview
    _applyThemeChangesTemporarily();
  }

  /// Update selected color scheme
  void updateColorScheme(FlexScheme colorScheme) {
    selectedColorScheme.value = colorScheme;

    // Apply color scheme change immediately for live preview
    _applyThemeChangesTemporarily();
  }

  /// Apply theme changes temporarily for live preview (without saving)
  void _applyThemeChangesTemporarily() {
    // Create temporary preferences for live preview
    final tempPreferences = UserPreferences(
      userName: appInstance.userPreferences.userName,
      chatLanguage: appInstance.userPreferences.chatLanguage,
      preferencesCompleted: appInstance.userPreferences.preferencesCompleted,
      themeMode: selectedThemeMode.value,
      colorScheme: selectedColorScheme.value,
    );

    // Temporarily update app instance for theme preview
    appInstance.userPreferencesRx.value = tempPreferences;

    // Force UI update to reflect theme changes
    update();
  }

  /// Check if form is valid for submission
  bool get isFormValid => isNameValid.value && nameController.text.trim().isNotEmpty;

  /// Save preferences and show success message
  Future<void> savePreferences() async {
    if (!isFormValid) return;

    try {
      isLoading.value = true;

      // Create new preferences object
      final newPreferences = UserPreferences(
        userName: nameController.text.trim(),
        chatLanguage: selectedLanguage.value,
        preferencesCompleted: true,
        themeMode: selectedThemeMode.value,
        colorScheme: selectedColorScheme.value,
      );

      // Update preferences in app instance
      appInstance.updateUserPreferences(newPreferences);

      // Update original preferences since changes are now saved
      _originalPreferences = newPreferences;

      // Show success message with improved design
      Get.snackbar(
        'Success!',
        'Your preferences have been saved successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(Get.context!).colorScheme.primaryContainer,
        colorText: Theme.of(Get.context!).colorScheme.onPrimaryContainer,
        icon: Icon(
          Icons.check_circle,
          color: Theme.of(Get.context!).colorScheme.onPrimaryContainer,
        ),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        snackStyle: SnackStyle.FLOATING,
      );
    } catch (e) {
      _showErrorSnackbar();
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset preferences to defaults
  void resetToDefaults() {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset to Default Settings'),
        content: const Text(
          'All your preferences will be reset to default values. Do you confirm this action?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              _resetPreferences();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  /// Reset preferences to default values
  Future<void> _resetPreferences() async {
    try {
      isLoading.value = true;

      final defaultPreferences = UserPreferences.defaultPreferences.copyWith(
        preferencesCompleted: true,
      );

      appInstance.updateUserPreferences(defaultPreferences);

      // Update original preferences since changes are now saved
      _originalPreferences = defaultPreferences;

      // Update UI with defaults
      nameController.text = '';
      selectedLanguage.value = 'English';
      selectedThemeMode.value = AppThemeMode.system;
      selectedColorScheme.value = FlexScheme.deepOrangeM3;

      Get.snackbar(
        'Success!',
        'Preferences have been reset to default values.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        snackStyle: SnackStyle.FLOATING,
      );
    } catch (e) {
      _showErrorSnackbar();
    } finally {
      isLoading.value = false;
    }
  }

  /// Show error snackbar with improved design
  void _showErrorSnackbar() {
    Get.snackbar(
      'Error!',
      'An error occurred while saving preferences. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
      snackStyle: SnackStyle.FLOATING,
    );
  }

  /// Get theme mode display name
  String getThemeModeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  /// Get theme mode icon
  IconData getThemeModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  /// Get all available theme modes
  List<AppThemeMode> get availableThemeModes => AppThemeMode.values;

  /// Get all available color schemes
  Map<FlexScheme, String> get availableColorSchemes => AppTheme.getAvailableColorSchemes();

  /// Get color scheme display name
  String getColorSchemeDisplayName(FlexScheme scheme) {
    return AppTheme.getColorSchemeDisplayName(scheme);
  }
}
