import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/models/user_preferences.dart';
import 'package:freeaihub/core/global/services/get_storage_service.dart';
import 'package:get/get.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

AppInstance get appInstance => Get.find<AppInstance>();

class AppInstance {
  bool isTablet = false;
  List<AIModel> activeModels = [];

  // User preferences - made observable
  late Rx<UserPreferences> userPreferencesRx;
  UserPreferences get userPreferences => userPreferencesRx.value;

  AppInstance() {
    // Initialize with default preferences first, then load from storage
    userPreferencesRx = UserPreferences.defaultPreferences.obs;
  }

  // Initialize user preferences from local storage
  Future<void> initializeUserPreferences() async {
    try {
      final getStorageService = Get.find<GetStorageService>();
      final loadedPreferences = await getStorageService.getUserPreferences();
      userPreferencesRx.value = loadedPreferences;
    } catch (e) {
      // If error occurs, keep default preferences (already set)
      if (kDebugMode) {
        print('Error loading user preferences: $e. Keeping defaults.');
      }
    }
  }

  // Update user preferences and save to storage
  void updateUserPreferences(UserPreferences newPreferences) {
    try {
      final localStorageService = Get.find<GetStorageService>();
      userPreferencesRx.value = newPreferences; // This will notify listeners (like ThemeController)
      localStorageService.saveUserPreferences(newPreferences);
    } catch (e) {
      throw Exception('Failed to update user preferences: $e');
    }
  }

  // Convenience getters for quick access
  String get userName => userPreferences.userName;
  String get chatLanguage => userPreferences.chatLanguage;
  bool get isPreferencesCompleted => userPreferences.preferencesCompleted;
  AppThemeMode get themeMode => userPreferences.themeMode;
  FlexScheme get colorScheme => userPreferences.colorScheme;

  static final Map<CategoryTypes, String> categories = {
    CategoryTypes.chat: "Chat",
    CategoryTypes.imageGeneration: "Image Generation",
    CategoryTypes.audioGeneration: "Audio Generation",
    CategoryTypes.videoGeneration: "Video Generation",
  };
}
