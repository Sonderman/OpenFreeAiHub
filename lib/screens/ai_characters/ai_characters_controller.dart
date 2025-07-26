import 'package:freeaihub/core/global/services/ai_character_service.dart';
import 'package:freeaihub/core/models/ai/ai_character_model.dart';
import 'package:get/get.dart';

/// Controller for the 'My AI Characters' list screen
class AiCharactersController extends GetxController {
  final AiCharacterService _service = Get.find<AiCharacterService>();

  /// Public getter for characters
  List<AiCharacterModel> get characters => _service.characters.toList();

  /// Whether characters are being loaded
  bool get isLoading => _service.isLoading.value;

  /// Delete character convenience
  Future<void> deleteCharacter(AiCharacterModel character) async {
    await _service.deleteAiCharacter(character.id);
    update();
  }

  /// Refresh list
  Future<void> refreshCharacters() async {
    update(); // characters list is reactive already
  }
}
