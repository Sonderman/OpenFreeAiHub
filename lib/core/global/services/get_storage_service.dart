import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/data/local_storage_keys.dart';
import 'package:freeaihub/core/models/user_preferences.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

//GetStorageService get storageService => Get.find<GetStorageService>();

class GetStorageService extends GetxService {
  late final GetStorage _globalStorage;
  late final GetStorage _preferencesStorage;
  static GetStorageService to = Get.find<GetStorageService>();

  @override
  void onInit() {
    super.onInit();
    _globalStorage = GetStorage();
    _preferencesStorage = GetStorage("Preferences");
  }

  Future<int> getAppOpenCount({bool increment = true}) async {
    int appOpenCount = _globalStorage.read(LocalStorageKeys.appOpenCount.value) ?? 0;
    if (increment) {
      appOpenCount++;
      _globalStorage.write(LocalStorageKeys.appOpenCount.value, appOpenCount);
    }
    return appOpenCount;
  }

  Future<bool> saveData({required String key, required dynamic value}) async {
    try {
      await _globalStorage.write(key, value);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving data: $e');
      }
      return false;
    }
  }

  T getData<T>({required String key}) {
    return _globalStorage.read(key) as T;
  }

  // UserPreferences methods
  Future<UserPreferences> getUserPreferences() async {
    try {
      // Try to load from new unified storage first
      final data = _preferencesStorage.read(LocalStorageKeys.userPreferences.value);
      if (data != null) {
        return UserPreferences.fromJson(Map<String, dynamic>.from(data));
      }

      return UserPreferences.defaultPreferences;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user preferences: $e');
      }
      return UserPreferences.defaultPreferences;
    }
  }

  void saveUserPreferences(UserPreferences preferences) {
    try {
      // Save as unified object
      _preferencesStorage.write(LocalStorageKeys.userPreferences.value, preferences.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user preferences: $e');
      }
      throw Exception('Failed to save user preferences: $e');
    }
  }
}
