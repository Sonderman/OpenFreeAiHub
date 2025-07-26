import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/models/chat/image_data_model.dart';
import 'package:freeaihub/screens/chat/handlers/error_handler.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/v4.dart';

/// Handles all image-related functionality for chat operations
class ImageHandler {
  final AIModel aiModel;
  final ErrorHandler errorHandler;

  /// List to store selected images pending to be sent with next text message
  final RxList<ImageData> selectedImages = <ImageData>[].obs;

  /// Memory cache for images
  Map<String, Uint8List> memoryCachedImages = {};

  ImageHandler({required this.aiModel, required this.errorHandler});

  /// Handles image selection from device gallery.
  /// Stores selected images to be sent with next text message.
  Future<void> handleImageSelection(XFile? image) async {
    try {
      // Check if the current AI model supports multimodal (image) inputs
      if (!aiModel.features.isMultimodal) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [ImageHandler] - Model ${aiModel.name} does not support images');
        }
        errorHandler.showError('This model does not support image inputs');
        return;
      }

      // Check image message limit
      if (selectedImages.length >= singleSessionImageLimit) {
        errorHandler.showError(
          "You can't send more than $singleSessionImageLimit images in a single session",
        );
        return;
      }

      // Check if too many images are already selected
      if (selectedImages.length >= maxImagesPerMessage) {
        errorHandler.showError("You can select maximum 4 images per message");
        return;
      }

      if (image == null) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [ImageHandler] - No image selected');
        }
        return;
      }

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ImageHandler] - Starting image selection: ${image.name}');
      }

      // Validate file extension
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      final fileExtension = image.path.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(fileExtension)) {
        errorHandler.showError('Unsupported image format. Please use JPG, PNG, or WebP');
        return;
      }

      // Read image bytes
      final bytes = await image.readAsBytes();

      // Validate file size
      const maxFileSize = 5 * 1024 * 1024; // 5MB
      if (bytes.length > maxFileSize) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [ImageHandler] - Image too large: ${bytes.length} bytes');
        }
        final sizeMB = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
        errorHandler.showError('Image is too large ($sizeMB MB). Maximum size is 5MB');
        return;
      }

      // Store image data for later use with text message
      final imageData = ImageData(
        id: UuidV4().generate(),
        name: image.name,
        path: image.path,
        size: bytes.length,
        extension: fileExtension,
      );

      selectedImages.add(imageData);

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ImageHandler] - Image selected and stored: ${image.name}');
      }

      // Clear any previous errors
      errorHandler.clearError();
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ImageHandler] - Error processing image: $e');
      }
      errorHandler.showError(
        'Failed to process image. Please try again.',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Remove a selected image by ID
  void removeSelectedImage(String imageId) {
    selectedImages.removeWhere((image) => image.id == imageId);
    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [ImageHandler] - Image removed: $imageId');
    }
  }

  /// Clear all selected images
  void clearSelectedImages() {
    selectedImages.clear();
    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [ImageHandler] - All selected images cleared');
    }
  }

  /// Get metadata for selected images
  List<Map<String, dynamic>> getSelectedImagesMetadata() {
    if (kDebugMode && showDebugLogs) {
      print(
        '[DEBUG] [ImageHandler] - Getting metadata for ${selectedImages.length} selected images',
      );
    }

    final metadata = selectedImages.map((img) => img.toJson()).toList();

    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [ImageHandler] - Created metadata for ${metadata.length} images');
      for (var i = 0; i < metadata.length; i++) {
        print(
          '[DEBUG] [ImageHandler] - Metadata $i: ${metadata[i]['name']} (${metadata[i]['size']} bytes)',
        );
      }
    }

    return metadata;
  }

  /// Check if any images are selected
  bool get hasSelectedImages => selectedImages.isNotEmpty;

  /// Get count of selected images
  int get selectedImageCount => selectedImages.length;
}
