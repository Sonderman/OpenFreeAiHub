import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/global/services/hive_service.dart';
import 'package:freeaihub/core/models/ai/ai_character_model.dart';
import 'package:get/get.dart';
import 'package:uuid/v4.dart';

/// Service for managing user created AI characters
/// Provides CRUD operations and keeps a reactive list for UI updates.
class AiCharacterService extends GetxService {
  /// Hive service dependency
  final HiveService _hiveService = Get.find<HiveService>();

  /// Observable list of all characters
  final RxList<AiCharacterModel> characters = <AiCharacterModel>[].obs;

  /// Loading flag
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAiCharacters();
  }

  /// Internal: load all characters from Hive box
  Future<void> _loadAiCharacters() async {
    try {
      isLoading.value = true;
      final items = await _hiveService.loadAllAiCharacters();
      characters.assignAll(items);
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [AiCharacterService] - Loaded \\${items.length} characters from Hive');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [AiCharacterService] - Error loading characters: \\$e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Add new character, returns success
  Future<bool> addAiCharacter(AiCharacterModel character) async {
    try {
      // prevent duplicate id
      if (characters.any((c) => c.id == character.id)) {
        return false;
      }
      characters.insert(0, character);
      await _hiveService.saveAiCharacter(character);
      return true;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [AiCharacterService] - Error adding character: \\$e');
      }
      return false;
    }
  }

  /// Convenience method to create and add a character from form fields
  Future<bool> createAiCharacter({
    required String name,
    required String description,
    String? imageUrl,
    required String customInstructions,
    required double temperature,
  }) async {
    try {
      final id = UuidV4().generate();
      final model = AiCharacterModel(
        id: id,
        name: name,
        description: description,
        imageUrl: imageUrl,
        isActive: true,
        isPublic: false,
        isOfficial: false,
        parameters: AiCharacterParametersModel(
          customInstructions: customInstructions,
          temperature: temperature,
        ),
        defaultAiModelID: null,
      );
      return await addAiCharacter(model);
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [AiCharacterService] - Error creating character: \\$e');
      }
      return false;
    }
  }

  /// Delete a character
  Future<bool> deleteAiCharacter(String id) async {
    try {
      characters.removeWhere((c) => c.id == id);
      await _hiveService.deleteAiCharacter(id);
      return true;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [AiCharacterService] - Error deleting character: \\$e');
      }
      return false;
    }
  }

  /// Update existing character (replace by id)
  Future<bool> updateAiCharacter(AiCharacterModel updated) async {
    try {
      final index = characters.indexWhere((c) => c.id == updated.id);
      if (index == -1) return false;
      characters[index] = updated;
      await _hiveService.saveAiCharacter(updated);
      characters.refresh();
      return true;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [AiCharacterService] - Error updating character: \\$e');
      }
      return false;
    }
  }
}
