import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/global/services/media_library_service.dart';
import 'package:freeaihub/core/models/library/media_item.dart';
import 'package:get/get.dart';

/// Controller for managing media library view state and operations
class MediaLibraryController extends GetxController {
  /// Media library service
  final MediaLibraryService _mediaService = Get.find<MediaLibraryService>();

  @override
  void onInit() async {
    super.onInit();

    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [MediaLibraryController] - Controller initialized');
    }
  }

  /// Get all media items sorted by creation date
  List<MediaItem> get mediaItems {
    List<MediaItem> items = _mediaService.mediaItems.toList();
    // Sort items by creation date, newest first
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Delete a media item
  Future<void> deleteMediaItem(MediaItem item) async {
    try {
      final success = await _mediaService.deleteMediaItem(item.id);

      if (success) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [MediaLibraryController] - Media item deleted: ${item.id}');
        }
        update();
        Get.snackbar(
          'Deleted',
          '${item.title} has been deleted',
          duration: const Duration(seconds: 2),
        );
      } else {
        throw Exception('Failed to delete media item');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MediaLibraryController] - Error deleting media item: $e');
      }

      Get.snackbar(
        'Error',
        'Failed to delete ${item.title}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }
}
