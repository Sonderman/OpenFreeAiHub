import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/global/services/hive_service.dart';
import 'package:freeaihub/core/models/library/media_item.dart';
import 'package:get/get.dart';
import 'package:uuid/v4.dart';

/// Service for managing media library functionality
/// Automatically saves and manages generated images and chat images
class MediaLibraryService extends GetxService {
  final HiveService _hiveService = Get.find<HiveService>();

  /// Observable list of all media items
  final RxList<MediaItem> mediaItems = <MediaItem>[].obs;

  /// Loading state
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMediaItems();
  }

  /// Load all media items from storage
  Future<void> _loadMediaItems() async {
    try {
      isLoading.value = true;

      final items = await _hiveService.loadAllMediaItems();
      mediaItems.assignAll(items);

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MediaLibraryService] - Loaded ${items.length} media items from Hive');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MediaLibraryService] - Error loading media items from Hive: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Add a media item to the library
  Future<bool> addMediaItem(MediaItem item) async {
    try {
      // Check for duplicates
      if (mediaItems.any((existing) => existing.id == item.id)) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [MediaLibraryService] - Media item already exists: ${item.id}');
        }
        return false;
      }

      // Add to the beginning of the list (most recent first)
      mediaItems.insert(0, item);

      try {
        await _hiveService.saveMediaItem(item);
        if (kDebugMode && showDebugLogs) {
          print(
            '[DEBUG] [MediaLibraryService] - Added media item: ${item.id} (${item.source.displayName})',
          );
        }
        return true;
      } catch (e) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [MediaLibraryService] - Error adding media item to Hive: $e');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MediaLibraryService] - Error adding media item: $e');
      }
      return false;
    }
  }

  /// Automatically save image from chat
  Future<bool> saveChatImage({
    required String base64Data,
    required String description,
    String? messageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Clean base64 data and calculate size
      String cleanBase64 = base64Data;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',')[1];
      }

      final imageBytes = base64Decode(cleanBase64);
      int totalSizeBytes = imageBytes.length;

      final item = MediaItem.fromChatImage(
        id: messageId ?? UuidV4().generate(),
        description: description.isNotEmpty ? description : 'Chat Image',
        base64Data: cleanBase64,
        sizeBytes: totalSizeBytes,
        metadata: metadata,
      );

      return await addMediaItem(item);
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MediaLibraryService] - Error saving chat image: $e');
      }
      return false;
    }
  }

  /// Automatically save image from Hidream generator with watermark support
  Future<bool> saveHidreamImage({
    required Uint8List imageBytes,
    required String prompt,
    Map<String, dynamic>? generationParams,
  }) async {
    try {
      final base64Data = base64Encode(imageBytes);

      final item = MediaItem.fromHidreamImage(
        id: UuidV4().generate(),
        prompt: prompt,
        base64Data: base64Data,
        sizeBytes: imageBytes.length,
        generationParams: generationParams,
      );

      return await addMediaItem(item);
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MediaLibraryService] - Error saving Hidream image: $e');
      }
      return false;
    }
  }

  /// Automatically save image from Pollinations AI generator with watermark support
  Future<bool> savePollinationsImage({
    required Uint8List imageBytes,
    required String prompt,
    Map<String, dynamic>? generationParams,
  }) async {
    try {
      final base64Data = base64Encode(imageBytes);

      final item = MediaItem.fromPollinationsImage(
        id: UuidV4().generate(),
        prompt: prompt,
        base64Data: base64Data,
        sizeBytes: imageBytes.length,
        generationParams: generationParams,
      );

      return await addMediaItem(item);
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MediaLibraryService] - Error saving Pollinations image: $e');
      }
      return false;
    }
  }

  /// Update media item (e.g., modify metadata)
  Future<bool> updateMediaItem(MediaItem updatedItem) async {
    try {
      final index = mediaItems.indexWhere((item) => item.id == updatedItem.id);
      if (index == -1) return false;

      mediaItems[index] = updatedItem;

      await _hiveService.saveMediaItem(updatedItem);
      return true;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MediaLibraryService] - Error updating media item in Hive: $e');
      }
      return false;
    }
  }

  /// Delete a media item
  Future<bool> deleteMediaItem(String id) async {
    try {
      final removedItem = mediaItems.firstWhereOrNull((item) => item.id == id);
      if (removedItem == null) return false;

      mediaItems.removeWhere((item) => item.id == id);

      await _hiveService.deleteMediaItem(id);
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MediaLibraryService] - Deleted media item from Hive: $id');
      }

      return true;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MediaLibraryService] - Error deleting media item from Hive: $e');
      }
      return false;
    }
  }
}
