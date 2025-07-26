import 'package:freeaihub/core/models/chat/chat_session_model.dart';
import 'package:freeaihub/core/models/hive/hive_registrar.g.dart';
import 'package:freeaihub/core/models/library/media_item.dart';
import 'package:freeaihub/core/models/ai/ai_character_model.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

class HiveService extends GetxService {
  static HiveService get to => Get.find<HiveService>();
  late final Box<ChatSession> _chatSessionBox;
  late final Box<MediaItem> _mediaItemBox;
  late final Box<AiCharacterModel> _aiCharacterBox;

  Future<void> init() async {
    // Initialize Hive
    final appDocumentDir = await getApplicationDocumentsDirectory();
    print("Setting up Hive");
    Hive
      ..init(appDocumentDir.path)
      ..registerAdapters();

    // Open boxes
    _chatSessionBox = await Hive.openBox<ChatSession>('chat_sessions');
    _mediaItemBox = await Hive.openBox<MediaItem>('media_items');
    _aiCharacterBox = await Hive.openBox<AiCharacterModel>('ai_characters');
  }

  Future<void> saveChatSession(ChatSession session) async {
    try {
      await _chatSessionBox.put(session.id, session);
    } catch (e) {
      throw Exception('Failed to save chat session: $e');
    }
  }

  Future<ChatSession?> loadChatSession(String id) async {
    try {
      return _chatSessionBox.get(id);
    } catch (e) {
      throw Exception('Failed to load chat session: $e');
    }
  }

  Future<List<ChatSession>> getAllChatSessions({String? modelID}) async {
    try {
      var sessions = _chatSessionBox.values.toList();
      if (modelID != null) {
        sessions = sessions.where((s) => s.aiModelID == modelID).toList();
      }
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (e) {
      throw Exception('Failed to get chat sessions: $e');
    }
  }

  Future<void> deleteChatSession(String id) async {
    try {
      await _chatSessionBox.delete(id);
    } catch (e) {
      throw Exception('Failed to delete chat session: $e');
    }
  }

  Future<void> clearAllChatSessions() async {
    try {
      await _chatSessionBox.clear();
    } catch (e) {
      throw Exception('Failed to clear chat sessions: $e');
    }
  }

  // Media Item operations
  Future<void> saveMediaItem(MediaItem item) async {
    try {
      await _mediaItemBox.put(item.id, item);
    } catch (e) {
      throw Exception('Failed to save media item: $e');
    }
  }

  Future<void> saveAllMediaItems(List<MediaItem> items) async {
    try {
      final map = {for (var item in items) item.id: item};
      await _mediaItemBox.putAll(map);
    } catch (e) {
      throw Exception('Failed to save all media items: $e');
    }
  }

  Future<List<MediaItem>> loadAllMediaItems() async {
    try {
      final items = _mediaItemBox.values.toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      throw Exception('Failed to load media items: $e');
    }
  }

  Future<void> deleteMediaItem(String id) async {
    try {
      await _mediaItemBox.delete(id);
    } catch (e) {
      throw Exception('Failed to delete media item: $e');
    }
  }

  Future<void> clearAllMediaItems() async {
    try {
      await _mediaItemBox.clear();
    } catch (e) {
      throw Exception('Failed to clear all media items: $e');
    }
  }

  // ================= Ai Characters =================

  Future<void> saveAiCharacter(AiCharacterModel character) async {
    try {
      await _aiCharacterBox.put(character.id, character);
    } catch (e) {
      throw Exception('Failed to save AI character: $e');
    }
  }

  Future<List<AiCharacterModel>> loadAllAiCharacters() async {
    try {
      final items = _aiCharacterBox.values.toList();
      // Sort by name alphabetically (if name present)
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    } catch (e) {
      throw Exception('Failed to load AI characters: $e');
    }
  }

  Future<void> deleteAiCharacter(String id) async {
    try {
      await _aiCharacterBox.delete(id);
    } catch (e) {
      throw Exception('Failed to delete AI character: $e');
    }
  }

  Future<void> clearAllAiCharacters() async {
    try {
      await _aiCharacterBox.clear();
    } catch (e) {
      throw Exception('Failed to clear AI characters: $e');
    }
  }
}
