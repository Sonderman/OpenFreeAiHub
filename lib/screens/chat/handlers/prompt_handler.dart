import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/data/model_definisions.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/global/services/ai_client_service.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/screens/chat/handlers/error_handler.dart';
import 'package:get/get.dart';

/// Handles prompt enhancement functionality for chat operations
class PromptHandler {
  final AIModel aiModel;
  final ErrorHandler errorHandler;
  final AiClientService clientService;

  final RxBool isEnhancingPrompt = false.obs;

  PromptHandler({required this.aiModel, required this.errorHandler, required this.clientService});

  /// Enhanced prompt enhancement with better error handling
  Future<void> handlePromptEnhancing(TextEditingController textController) async {
    if (textController.text.trim().isEmpty) {
      errorHandler.showError('Please enter a prompt to enhance');
      return;
    }

    if (isEnhancingPrompt.value) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [PromptHandler] - Enhancement already in progress');
      }
      return;
    }

    final originalText = textController.text.trim();

    try {
      isEnhancingPrompt.value = true;

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [PromptHandler] - Starting prompt enhancement');
        print(
          '[DEBUG] [PromptHandler] - Original text: ${originalText.substring(0, originalText.length > 50 ? 50 : originalText.length)}...',
        );
      }

      // Find the first active chat model that does not have reasoning feature
      AIModel? enhancementModel;
      final chatModels = appInstance.activeModels
          .where((model) => model.category == CategoryTypes.chat)
          .toList();

      if (chatModels.any((element) => element.id == aiModel.id) && !aiModel.features.isReasoning) {
        enhancementModel = aiModel;
      } else {
        for (final model in chatModels) {
          if (!model.features.isReasoning) {
            enhancementModel = model;
            break;
          }
        }
      }

      enhancementModel ??= ModelDefinitions.pollinationsAiChatGpt4_1;

      final enhancedText = await clientService.enhancePrompt(
        customModel: enhancementModel,
        prompt: originalText,
        language: appInstance.userPreferences.chatLanguage,
      );

      if (enhancedText == null || enhancedText.trim().isEmpty) {
        throw ChatException('No enhanced text received');
      }

      // Only update if the enhanced text is significantly different
      if (enhancedText.trim() != originalText) {
        textController.text = enhancedText.trim();

        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [PromptHandler] - Prompt enhanced successfully');
          print(
            '[DEBUG] [PromptHandler] - Enhanced text: ${enhancedText.substring(0, enhancedText.length > 50 ? 50 : enhancedText.length)}...',
          );
        }
      } else {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [PromptHandler] - No enhancement needed');
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [PromptHandler] - Error during prompt enhancement: $e');
      }
      errorHandler.showError(
        'Failed to enhance prompt. Please try again.',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    } finally {
      isEnhancingPrompt.value = false;
    }
  }

  /// Check if prompt enhancement is currently in progress
  bool get isEnhancing => isEnhancingPrompt.value;
}
