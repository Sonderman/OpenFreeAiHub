import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/global/services/ai_client_service.dart';
import 'package:freeaihub/core/global/services/media_library_service.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/data/model_definisions.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/screens/chat/handlers/error_handler.dart';
import 'package:get/get.dart';

/// Tool for handling image generation functionality in chat
class ImageGenerationTool {
  final AIModel aiModel;
  final AiClientService clientService;
  final ErrorHandler errorHandler;
  final MediaLibraryService mediaLibraryService;
  final bool showDebugLogs;

  ImageGenerationTool({
    required this.aiModel,
    required this.clientService,
    required this.errorHandler,
    required this.mediaLibraryService,
    this.showDebugLogs = true,
  });

  /// Handles image generation with improved error handling and resource management
  Future<void> handleImageGenerationHidream({
    required String prompt,
    required String resolution,
    required String messageId,
    required RxList<Message> messages,
    CancelToken? cancelToken,
    required Function() resetToolCallProcessingState,
    required Function() update,
    Function()? markSessionAsUpdated,
    Function()? autoSaveSession,
  }) async {
    if (prompt.trim().isEmpty) {
      errorHandler.showError('Prompt cannot be empty');
      return;
    }

    // Validate resolution format
    if (!RegExp(r'^\d+x\d+$').hasMatch(resolution)) {
      errorHandler.showError('Invalid resolution format. Use format like "1024x1024"');
      return;
    }

    final data = {
      "seed": math.Random().nextInt(1000000),
      "shift": 3,
      "prompt": prompt.trim(),
      "resolution": resolution,
      "guidance_scale": 5.0,
      "num_inference_steps": 50,
    };

    if (kDebugMode && showDebugLogs) {
      print("[DEBUG] [ImageGeneration] - Starting image generation with resolution: $resolution");
    }

    try {
      // Find the message to update
      final messageIndex = messages.indexWhere((element) => element.id == messageId);
      if (messageIndex == -1) {
        throw ChatException('Message not found for image generation');
      }

      final imageData = await clientService.inChatImageGenerationHidream(
        generationModel: ModelDefinitions.hidreamI1,
        data: data,
        cancelToken: cancelToken,
      );

      if (imageData == null) {
        throw ChatException(
          'No image data received from generation service',
          code: "no-image-data",
        );
      }

      if (imageData.isEmpty) {
        throw ChatException('Empty image data received');
      }

      // Convert to base64
      final base64Data = base64Encode(imageData);

      // Update message metadata with generated image
      var message = messages[messageIndex];
      message.metadata!["tool_call_status"] = ToolCallStatus.success.index;
      message.metadata!['base64URL'] = "data:image/jpeg;base64,$base64Data";
      message.metadata!['Rawbase64'] = base64Data;
      message.metadata!['generation_data'] = {
        'prompt': prompt,
        'resolution': resolution,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Automatically save to media library without watermark
      await _saveImageToMediaLibrary(
        imageBytes: imageData,
        prompt: prompt,
        messageId: messageId,
        messages: messages,
        generationData: message.metadata!['generation_data'] as Map<String, dynamic>?,
      );

      // Reset tool call processing state after successful completion
      resetToolCallProcessingState();

      // Mark session as updated and auto-save
      markSessionAsUpdated?.call();
      autoSaveSession?.call();

      update();

      if (kDebugMode && showDebugLogs) {
        print("[DEBUG] [ImageGeneration] - Image generation completed successfully");
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ImageGeneration] - Error: $e');
      }

      // Update message with error status
      final messageIndex = messages.indexWhere((element) => element.id == messageId);
      if (messageIndex != -1) {
        messages[messageIndex].metadata!["tool_call_status"] = ToolCallStatus.error.index;
        messages[messageIndex].metadata!["error_message"] = e.toString();
      }

      // Reset tool call processing state on error
      resetToolCallProcessingState();

      errorHandler.showError(
        'Image generation failed. Please try again.',
        exception: e is Exception ? e : Exception(e.toString()),
      );
      update();
    }
  }

  /// Handles image generation with improved error handling and resource management
  Future<void> handleImageGenerationPollinations({
    required String prompt,
    required String resolution,
    required String messageId,
    required RxList<Message> messages,
    CancelToken? cancelToken,
    required Function() resetToolCallProcessingState,
    required Function() update,
    Function()? markSessionAsUpdated,
    Function()? autoSaveSession,
  }) async {
    if (prompt.trim().isEmpty) {
      errorHandler.showError('Prompt cannot be empty');
      return;
    }

    // Validate resolution format
    if (!RegExp(r'^\d+x\d+$').hasMatch(resolution)) {
      errorHandler.showError('Invalid resolution format. Use format like "1024x1024"');
      return;
    }

    final dimensions = resolution.split('x');

    final Map<String, dynamic> data = {
      "seed": math.Random().nextInt(1000000).toString(),
      "model": "flux",
      "prompt": prompt.trim(),
      "width": dimensions[0],
      "height": dimensions[1],
      "enhance": "true",
      "nologo": "true",
      "nofeed": "true",
      "private": "true",
      "safe": "true",
      "token": aiModel.apiModel.apiKey,
    };

    if (kDebugMode && showDebugLogs) {
      print("[DEBUG] [ImageGeneration] - Starting image generation with resolution: $resolution");
    }

    try {
      // Find the message to update
      final messageIndex = messages.indexWhere((element) => element.id == messageId);
      if (messageIndex == -1) {
        throw ChatException('Message not found for image generation');
      }
      final imageData = await clientService.inChatImageGenerationPollinations(
        generationModel: ModelDefinitions.pollinationsAiImage,
        data: data,
        cancelToken: cancelToken,
      );

      if (imageData == null) {
        throw ChatException('No image data received from generation service');
      }

      if (imageData.isEmpty) {
        throw ChatException('Empty image data received');
      }

      // Convert to base64
      final base64Data = base64Encode(imageData);

      // Update message metadata with generated image
      var message = messages[messageIndex];
      message.metadata!["tool_call_status"] = ToolCallStatus.success.index;
      message.metadata!['base64URL'] = "data:image/jpeg;base64,$base64Data";
      message.metadata!['Rawbase64'] = base64Data;
      message.metadata!['generation_data'] = {
        'prompt': prompt,
        'resolution': resolution,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Automatically save to media library without watermark
      await _saveImageToMediaLibrary(
        imageBytes: imageData,
        prompt: prompt,
        messageId: messageId,
        messages: messages,
        generationData: message.metadata!['generation_data'] as Map<String, dynamic>?,
      );

      // Reset tool call processing state after successful completion
      resetToolCallProcessingState();

      // Mark session as updated and auto-save
      markSessionAsUpdated?.call();
      autoSaveSession?.call();

      update();

      if (kDebugMode && showDebugLogs) {
        print("[DEBUG] [ImageGeneration] - Image generation completed successfully");
      }
    } catch (e) {
      final messageIndex = messages.indexWhere((element) => element.id == messageId);
      if (cancelToken!.isCancelled) {
        if (messageIndex != -1) {
          messages[messageIndex].metadata!["tool_call_status"] = ToolCallStatus.cancelled.index;
        }
      } else {
        if (messageIndex != -1) {
          messages[messageIndex].metadata!["tool_call_status"] = ToolCallStatus.error.index;
          messages[messageIndex].metadata!["error_message"] = e.toString();
        }
        errorHandler.showError(
          'Image generation failed. Please try again.',
          exception: e is Exception ? e : Exception(e.toString()),
        );
      }
      // Reset tool call processing state on error
      resetToolCallProcessingState();
      update();
    }
  }

  /// Automatically save generated image to media library
  Future<void> _saveImageToMediaLibrary({
    required Uint8List imageBytes,
    required String prompt,
    required String messageId,
    required RxList<Message> messages,
    Map<String, dynamic>? generationData,
  }) async {
    try {
      final success = await mediaLibraryService.saveChatImage(
        base64Data: base64Encode(imageBytes),
        description: prompt.isNotEmpty ? prompt : 'Chat Generated Image',
        messageId: messageId,
        metadata: {
          'source': 'chat',
          'generation_data': generationData,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (success && kDebugMode && showDebugLogs) {
        print('[DEBUG] [ImageGeneration] - Image automatically saved to media library');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ImageGeneration] - Error saving to media library: $e');
      }
    }
  }
}
