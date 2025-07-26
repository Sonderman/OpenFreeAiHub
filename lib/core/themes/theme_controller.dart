import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/models/user_preferences.dart';
import 'app_theme.dart';

class ThemeController extends GetxController with WidgetsBindingObserver {
  // AppInstance for accessing user preferences
  final AppInstance appInstance = Get.find<AppInstance>();

  // Observable for the current Flutter ThemeMode
  late final Rx<ThemeMode> _themeModeRx;
  ThemeMode get themeMode => _themeModeRx.value;

  // Observable for the current FlexScheme
  late final Rx<FlexScheme> _colorSchemeRx;
  FlexScheme get colorScheme => _colorSchemeRx.value;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    // Initialize from user preferences
    _themeModeRx = appInstance.userPreferences.flutterThemeMode.obs;
    _colorSchemeRx = appInstance.userPreferences.colorScheme.obs;
    // Listen to changes in user preferences
    ever(appInstance.userPreferencesRx, _updateThemeFromPreferences);
    _updateSystemBrightnessChanges();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (appInstance.userPreferences.themeMode == AppThemeMode.system) {
      _updateSystemBrightnessChanges();
    }
  }

  /// Updates the theme based on system brightness changes if themeMode is system.
  void _updateSystemBrightnessChanges() {
    if (appInstance.userPreferences.themeMode == AppThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _themeModeRx.value = brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
      // When themeMode is system, update both ThemeMode and the actual ThemeData
      Get.changeThemeMode(_themeModeRx.value);

      // Ensure the ThemeData also reflects the brightness change so that
      // custom color schemes are applied correctly when switching between
      // light and dark variants.
      final updatedTheme = AppTheme.getThemeFromPreferences(
        colorScheme: _colorSchemeRx.value,
        isDark: _isDarkForMode(_themeModeRx.value),
      );

      // Apply the updated theme to the entire application.
      Get.changeTheme(updatedTheme);
    }
  }

  /// Callback for when user preferences change in AppInstance.
  void _updateThemeFromPreferences(UserPreferences preferences) {
    // Update stored color scheme first so we can build the theme later.
    _colorSchemeRx.value = preferences.colorScheme;

    // Determine the desired Flutter ThemeMode.
    final newFlutterThemeMode = preferences.flutterThemeMode;

    // If themeMode actually changed, notify GetX and update internal rx value.
    if (_themeModeRx.value != newFlutterThemeMode) {
      _themeModeRx.value = newFlutterThemeMode;
      Get.changeThemeMode(newFlutterThemeMode);
    }

    // Build the correct ThemeData based on the **updated** mode.
    final updatedTheme = AppTheme.getThemeFromPreferences(
      colorScheme: _colorSchemeRx.value,
      isDark: _isDarkForMode(_themeModeRx.value),
    );

    // Apply the new theme (or updated color scheme).
    Get.changeTheme(updatedTheme);

    // If the user selected system mode, make sure brightness listener kicks in.
    if (newFlutterThemeMode == ThemeMode.system) {
      _updateSystemBrightnessChanges();
    }
  }

  /// Helper to determine dark mode for a given ThemeMode value.
  bool _isDarkForMode(ThemeMode mode) {
    if (mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  // Check if dark mode is currently active based on the effective ThemeMode
  bool get isDarkMode {
    if (_themeModeRx.value == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeModeRx.value == ThemeMode.dark;
  }

  // Get current theme data based on user preferences
  ThemeData get currentTheme {
    return AppTheme.getThemeFromPreferences(colorScheme: _colorSchemeRx.value, isDark: isDarkMode);
  }

  // Methods below are kept for potential direct manipulation if needed,
  // but primary updates should come from UserPreferences changes.

  /// Directly changes the theme mode in ThemeController (e.g., for temporary override).
  /// Note: This does not update UserPreferences.
  void changeThemeMode(ThemeMode mode) {
    _themeModeRx.value = mode;
    Get.changeThemeMode(mode);
    Get.changeTheme(currentTheme);
  }

  /// Directly changes the color scheme in ThemeController (e.g., for temporary override).
  /// Note: This does not update UserPreferences.
  void changeColorScheme(FlexScheme scheme) {
    _colorSchemeRx.value = scheme;
    Get.changeTheme(currentTheme);
  }
}
