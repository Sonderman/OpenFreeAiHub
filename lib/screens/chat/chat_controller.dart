import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/global/components/chat/think_block_widget.dart';
import 'package:freeaihub/core/global/services/ai_client_service.dart';
import 'package:freeaihub/core/models/chat/image_data_model.dart';
import 'package:freeaihub/screens/chat/managers/context_manager.dart';
import 'package:freeaihub/core/global/services/tts_service.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/models/chat/chat_session_model.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/screens/chat/handlers/error_handler.dart';
import 'package:freeaihub/screens/chat/handlers/image_handler.dart';
import 'package:freeaihub/screens/chat/handlers/document_handler.dart';
import 'package:freeaihub/screens/chat/handlers/message_handler.dart';
import 'package:freeaihub/screens/chat/handlers/prompt_handler.dart';
import 'package:freeaihub/screens/chat/managers/session_manager.dart';
import 'package:freeaihub/screens/chat/handlers/streaming_handler.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:freeaihub/core/global/services/media_library_service.dart';
import 'package:freeaihub/screens/chat/ai_tools/web_search_tool.dart';
import 'package:freeaihub/screens/chat/ai_tools/image_generation_tool.dart';
import 'package:freeaihub/screens/home/home_controller.dart';
import 'package:freeaihub/core/models/ai/ai_character_model.dart';

/// Refactored ChatController with modular handlers for better maintainability
/// This controller now delegates specific responsibilities to specialized handlers
class ChatController extends GetxController {
  final bool showDebugLogs = false;

  /// The AI model being used for this chat session
  final AIModel aiModel;

  // Core services
  late final AiClientService _clientService;
  late final TextToSpeechService ttsService;
  late final MediaLibraryService _mediaLibraryService;

  // Managers
  late final ContextManager contextManager;
  late final SessionManager sessionManager;

  // UI Controllers
  final TextEditingController promptController = TextEditingController();
  final FocusNode promptInputFocusNode = FocusNode();

  // Controller lifecycle flag
  bool _isDisposed = false;

  // Handlers - Modular components for specific responsibilities
  late final ErrorHandler errorHandler;
  late final ImageHandler imageHandler;
  late final DocumentHandler documentHandler;
  late final MessageHandler messageHandler;
  late final PromptHandler promptHandler;
  late final StreamingHandler streamingHandler;
  late final WebSearchTool webSearchTool;
  late final ImageGenerationTool imageGenerationTool;

  // Chat state
  final Rx<ChatSession?> currentSession = Rx<ChatSession?>(null);
  final RxList<ChatSession> sessions = <ChatSession>[].obs;
  final RxList<Message> messages = <Message>[].obs;

  // AI operation state (delegated to StreamingHandler)
  CancelToken? _cancelToken;

  // Memory cache for images (for compatibility with ChatView)
  Map<String, Uint8List> memoryCachedImages = {};

  // Capabilities
  final RxBool isWebSearchEnabled = false.obs;
  final RxBool isImageGenEnabled = false.obs;

  ChatController({required this.aiModel}) {
    _initializeServices();
    _initializeHandlers();
  }

  /// Initialize core services
  void _initializeServices() {
    _clientService = AiClientService(aiModel: aiModel);
    _mediaLibraryService = Get.find<MediaLibraryService>();
  }

  /// Initialize modular handlers
  void _initializeHandlers() {
    errorHandler = ErrorHandler();
    imageHandler = ImageHandler(aiModel: aiModel, errorHandler: errorHandler);
    documentHandler = DocumentHandler(aiModel: aiModel, errorHandler: errorHandler);
    contextManager = ContextManager(maxContextTokens: aiModel.maxTokens);
    // Initialize session handler with proper dependencies
    sessionManager = SessionManager(
      aiModel: aiModel,
      errorHandler: errorHandler,
      currentSession: currentSession,
      sessions: sessions,
      messages: messages,
      isWebSearchEnabled: isWebSearchEnabled,
      isImageGenEnabled: isImageGenEnabled,
      contextManager: contextManager,
    );

    messageHandler = MessageHandler(
      sessionManager: sessionManager,
      errorHandler: errorHandler,
      messages: messages,
    );
    promptHandler = PromptHandler(
      aiModel: aiModel,
      errorHandler: errorHandler,
      clientService: _clientService,
    );

    streamingHandler = StreamingHandler(
      aiModel: aiModel,
      clientService: _clientService,
      errorHandler: errorHandler,
      messageHandler: messageHandler,
      markSessionAsUpdated: sessionManager.markSessionAsUpdated,
      resetToolCallProcessingState: _resetToolCallProcessingState,
      update: update,
      contextManager: contextManager,
      sessionHandler: sessionManager,
      character: sessionManager.selectedCharacter,
    );

    webSearchTool = WebSearchTool(
      aiModel: aiModel,
      clientService: _clientService,
      errorHandler: errorHandler,
      sessionManager: sessionManager,
    );

    imageGenerationTool = ImageGenerationTool(
      aiModel: aiModel,
      clientService: _clientService,
      errorHandler: errorHandler,
      mediaLibraryService: _mediaLibraryService,
    );
  }

  @override
  void onInit() {
    super.onInit();
    _initializeSession();
    _initializeTextToSpeechService();
  }

  @override
  void onClose() {
    // Notify home screen to refresh latest conversations if it exists
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().refreshHomeView();
    }

    // Perform cleanup BEFORE marking the controller as disposed so that cleanup logic executes.
    _cleanup();

    // Now mark as disposed and call super.
    _isDisposed = true;
    super.onClose();
  }

  /// Initialize text-to-speech service with error handling
  void _initializeTextToSpeechService() {
    try {
      ttsService = Get.find<TextToSpeechService>();
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ChatController] - Failed to initialize TTS service: $e');
      }
      errorHandler.showError('Text-to-speech service unavailable');
    }
  }

  /// Initialize session
  Future<void> _initializeSession() async {
    try {
      await sessionManager.initializeSession();
      errorHandler.clearError();
    } catch (e) {
      errorHandler.showError(
        'Failed to initialize chat session. Please try again.',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Cleanup resources when controller is disposed
  void _cleanup() {
    if (_isDisposed) {
      // Already disposed, skip cleanup
      return;
    }

    try {
      // Handle session persistence / cleanup
      // 1. If there are messages, save the session (if marked as needing save)
      // 2. If **all** messages have been deleted and the session was previously saved,
      //    automatically delete the now-empty session so that it doesn't linger in storage.

      if (messages.isNotEmpty) {
        // Persist non-empty session if it was modified
        if (sessionManager.needsSaving) {
          sessionManager.saveCurrentSession();
        }
      } else {
        // No messages left – if this session was previously saved, delete it
        final currentId = sessionManager.currentSession.value?.id;
        if (currentId != null && sessionManager.sessions.any((s) => s.id == currentId)) {
          sessionManager.deleteSession(currentId);
        }
      }

      _cancelToken?.cancel();

      // Safely dispose controllers with try-catch
      try {
        promptController.dispose();
      } catch (e) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [ChatController] - promptController already disposed: $e');
        }
      }

      try {
        if (promptInputFocusNode.hasFocus) {
          promptInputFocusNode.unfocus();
        }
        promptInputFocusNode.dispose();
      } catch (e) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [ChatController] - promptInputFocusNode already disposed: $e');
        }
      }

      ttsService.stop();
      imageHandler.clearSelectedImages();

      // Reset tool call processing state
      _resetToolCallProcessingState();

      // Clean up think block timers on controller disposal
      ThinkBlockWidget.cleanupCompletedTimers();
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ChatController] - Error during cleanup: $e');
      }
    }
  }

  /// Handles text message sending using MessageHandler and ImageHandler
  void handleSendPressed(String message) {
    if (_isDisposed) return; // Don't process if controller is disposed

    // Prevent sending new messages during tool call processing
    if (streamingHandler.isProcessingToolCall.value) {
      errorHandler.showError('Please wait for the current tool call to complete');
      return;
    }

    try {
      // Validate input - allow empty text if there are selected images or documents
      if (message.trim().isEmpty &&
          !imageHandler.hasSelectedImages &&
          !documentHandler.hasSelectedDocuments) {
        errorHandler.showError('Please enter a message, select an image, or attach a document');
        return;
      }

      // Prepare the actual prompt for AI processing
      String actualPrompt = message.trim();

      // If text is empty but we have attachments, use a default prompt
      if (actualPrompt.isEmpty &&
          (imageHandler.hasSelectedImages || documentHandler.hasSelectedDocuments)) {
        if (imageHandler.hasSelectedImages && documentHandler.hasSelectedDocuments) {
          actualPrompt = "Please analyze these attached images and documents.";
        } else if (imageHandler.hasSelectedImages) {
          actualPrompt = "Please analyze and describe this image.";
        } else if (documentHandler.hasSelectedDocuments) {
          actualPrompt = "Please analyze and summarize this document.";
        }
      }

      // Create text message with image and document attachments
      messageHandler.createUserMessage(
        text: message.trim(), // Keep original text (empty if user didn't type anything)
        attachedImages: imageHandler.hasSelectedImages
            ? imageHandler.selectedImages.toList()
            : null,
        attachedDocuments: documentHandler.hasSelectedDocuments
            ? documentHandler.getSelectedDocumentsMetadata()
            : null,
      );

      promptController.clear();
      imageHandler.clearSelectedImages();
      documentHandler.clearSelectedDocuments();

      // Clear any previous errors
      errorHandler.clearError();

      // Start AI processing with the actual prompt
      runAiOperations(actualPrompt);
    } catch (e) {
      errorHandler.showError(
        'Failed to send message',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Main method for running AI operations - delegates to StreamingHandler
  /// Enhanced with better image data handling and multimodal support
  Future<void> runAiOperations(String? prompt) async {
    if (_isDisposed) return; // Don't process if controller is disposed

    try {
      // Ensure we have a valid prompt
      final actualPrompt = prompt?.trim();

      // Set capabilities in streaming handler
      streamingHandler.isWebSearchEnabled.value = isWebSearchEnabled.value;
      streamingHandler.isImageGenEnabled.value = isImageGenEnabled.value;

      // Log multimodal content detection for debugging
      if (kDebugMode && showDebugLogs) {
        final hasImagesInCurrentMessages = messages.any(
          (msg) =>
              (msg.metadata != null && msg.metadata!['attachedImages'] != null) ||
              msg.type == MessageType.image,
        );
        if (hasImagesInCurrentMessages) {
          print(
            '[DEBUG] [ChatController] - Current session contains images, enabling multimodal processing',
          );
          print(
            '[DEBUG] [ChatController] - AI Model multimodal support: ${aiModel.features.isMultimodal}',
          );
        }
      }

      // Create cancel token
      _cancelToken ??= CancelToken();

      // Delegate to streaming handler
      await streamingHandler.runAiOperations(actualPrompt, _cancelToken);
      if (kDebugMode) {
        print(
          '[DEBUG] [ChatController] - Context total tokens: ${streamingHandler.contextManager.totalTokens}',
        );
        print(
          '[DEBUG] [ChatController] - Context completion tokens: ${streamingHandler.contextManager.completionTokens}',
        );
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ChatController] - Error in runAiOperations: $e');
      }
      errorHandler.showError(
        'AI operation failed',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    } finally {
      // Reset tool call processing state
      _resetToolCallProcessingState();
    }
  }

  /// Auto-save session with error handling
  void _autoSaveSession() {
    if (sessionManager.needsSaving) {
      sessionManager.saveCurrentSession();
    }
  }

  // Delegate methods to handlers

  /// Handle image selection - delegates to ImageHandler
  Future<void> handleImageSelection(XFile? image) async {
    await imageHandler.handleImageSelection(image);
  }

  /// Handle prompt enhancement - delegates to PromptHandler
  Future<void> handlePromptEnhancing(TextEditingController textController) async {
    await promptHandler.handlePromptEnhancing(textController);
  }

  /// Delete message - delegates to MessageHandler
  Future<void> deleteMessage(String id, {bool thereIsThinkBlock = false}) async {
    // Cancel any ongoing streaming or tool call operations
    if (streamingHandler.isTyping.value || streamingHandler.isProcessingToolCall.value) {
      streamingHandler.cancelOperation();

      // Wait a bit for the cancellation to complete before proceeding with deletion
      await Future.delayed(const Duration(milliseconds: 100));
    }

    messageHandler.deleteMessage(id, thereIsThinkBlock: thereIsThinkBlock);

    // Auto-save session after message deletion
    _autoSaveSession();
  }

  /// Delete all messages following a specific message - delegates to MessageHandler
  Future<void> deleteAllFollowingMessages(String id, {bool thereIsThinkBlock = false}) async {
    // Cancel any ongoing streaming or tool call operations
    if (streamingHandler.isTyping.value || streamingHandler.isProcessingToolCall.value) {
      streamingHandler.cancelOperation();

      // Wait a bit for the cancellation to complete before proceeding with deletion
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await messageHandler.deleteAllFollowingMessages(id, thereIsThinkBlock: thereIsThinkBlock);

    // Auto-save session after deleting multiple messages
    _autoSaveSession();
  }

  /// Edit message - delegates to MessageHandler
  Future<void> editMessage(
    String id,
    String newText, {
    List<Map<String, dynamic>>? newImages,
  }) async {
    await messageHandler.editMessage(id, newText, newImages: newImages);

    // Auto-save session after message edit
    _autoSaveSession();
  }

  /// Get message statistics - delegates to MessageHandler
  Map<String, dynamic> getMessageStatistics() {
    return messageHandler.getMessageStatistics();
  }

  /// Regenerate last response using MessageHandler
  Future<void> regenerateLastResponse() async {
    try {
      final lastPromptData = messageHandler.findLastUserPromptAndAIResponse();

      if (lastPromptData == null) {
        errorHandler.showError('Cannot find the original prompt to regenerate');
        return;
      }

      final lastUserPrompt = lastPromptData['prompt'] as String;
      final aiMessageIndex = lastPromptData['aiMessageIndex'] as int;
      final thinkBlockIndex = lastPromptData['thinkBlockIndex'] as int?;

      // Remove only the AI response (preserve think block if it exists)
      messageHandler.messages.removeAt(aiMessageIndex);

      // If there was a think block, mark it for potential update
      if (thinkBlockIndex != null && aiMessageIndex < messageHandler.messages.length) {
        if (messageHandler.messages[aiMessageIndex].type == MessageType.thinkBlock) {
          final currentThinkBlock = messageHandler.messages[aiMessageIndex];
          messageHandler.messages[aiMessageIndex] = currentThinkBlock.copyWith(
            metadata: {
              ...?currentThinkBlock.metadata,
              'regenerating': true,
              'thinkBlockStartTime': currentThinkBlock.metadata?['thinkBlockStartTime'],
              'messageId': currentThinkBlock.id,
            },
          );
        }
      }

      // Mark session as updated since we modified messages
      sessionManager.markSessionAsUpdated();

      // Auto-save session after removing the old response
      _autoSaveSession();

      // Regenerate with the original prompt (ensure it's not empty)
      final actualPrompt = lastUserPrompt.trim().isEmpty
          ? "Please analyze and describe this image."
          : lastUserPrompt;
      runAiOperations(actualPrompt);
    } catch (e) {
      errorHandler.showError(
        'Failed to regenerate response',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // Session management methods

  /// Save current session
  Future<void> saveCurrentSession() async {
    try {
      sessionManager.saveCurrentSession();
    } catch (e) {
      errorHandler.showError(
        'Failed to save session',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Load specific session
  Future<void> loadSpecificSession(String id) async {
    if (id.trim().isEmpty) {
      errorHandler.showError('Invalid session ID');
      return;
    }

    try {
      ThinkBlockWidget.cleanupAllTimers();
      await sessionManager.loadSession(id);
      // PATCH: Eski web_search tool_call mesajlarını güncelle
      for (var i = 0; i < messages.length; i++) {
        var msg = messages[i];
        if (msg.metadata != null &&
            msg.metadata!['tool_call'] != null &&
            msg.metadata!['tool_call']['name'] == 'web_search' &&
            msg.metadata!['web_search_result'] == null) {
          final newMeta = Map<String, dynamic>.from(msg.metadata!);
          newMeta['web_search_result'] = {
            'status': 'completed',
            'query': msg.metadata!['tool_call']['arguments']['search_query'] ?? '',
            'timestamp': DateTime.now().toIso8601String(),
          };
          messages[i] = msg.copyWith(metadata: newMeta);
        }
      }
      errorHandler.clearError();
    } catch (e) {
      errorHandler.showError(
        'Failed to load session',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Delete current session
  void deleteCurrentSession(String id) {
    if (id.trim().isEmpty) {
      errorHandler.showError('Invalid session ID');
      return;
    }

    try {
      sessionManager.deleteSession(id);
      errorHandler.clearError();
    } catch (e) {
      errorHandler.showError(
        'Failed to delete session',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Start new session
  Future<void> startNewSession() async {
    try {
      // Clear current state
      streamingHandler.isTyping.value = false;
      _cancelToken?.cancel();
      _cancelToken = null;
      errorHandler.clearError();
      imageHandler.clearSelectedImages();
      documentHandler.clearSelectedDocuments();

      // Reset tool call processing state
      _resetToolCallProcessingState();

      ThinkBlockWidget.cleanupAllTimers();
      await sessionManager.newSession();
    } catch (e) {
      errorHandler.showError(
        'Failed to start new session',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Cancel ongoing AI operation - delegates to StreamingHandler
  void onClickStopButton() {
    streamingHandler.cancelOperation();
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  // Getters for accessing handler properties

  /// Get selected images from ImageHandler
  RxList<ImageData> get selectedImages => imageHandler.selectedImages;

  /// Get selected documents from DocumentHandler
  RxList<Map<String, dynamic>> get selectedDocuments => documentHandler.selectedDocuments;

  /// Get error state from ErrorHandler
  RxString get errorMessage => errorHandler.errorMessage;
  RxBool get hasError => errorHandler.hasError;

  /// Get prompt enhancement state from PromptHandler
  RxBool get isEnhancingPrompt => promptHandler.isEnhancingPrompt;

  /// Get streaming state from StreamingHandler
  RxBool get isTyping => streamingHandler.isTyping;
  RxBool get isProcessingToolCall => streamingHandler.isProcessingToolCall;
  RxBool get isCapabilitiesEnabled => streamingHandler.isCapabilitiesEnabled;
  RxBool get isStreamingStructuredResponse => streamingHandler.isStreamingStructuredResponse;

  /// Clear error state
  void clearError() => errorHandler.clearError();

  /// Remove selected image
  void removeSelectedImage(String imageId) => imageHandler.removeSelectedImage(imageId);

  /// Clear selected images
  void clearSelectedImages() => imageHandler.clearSelectedImages();

  /// Remove selected document
  void removeSelectedDocument(String documentId) =>
      documentHandler.removeSelectedDocument(documentId);

  /// Clear selected documents
  void clearSelectedDocuments() => documentHandler.clearSelectedDocuments();

  /// Handle document selection
  Future<void> handleDocumentSelection() => documentHandler.handleDocumentSelection();

  /// Get formatted title based on AI character selection
  String get formattedTitle {
    if (sessionManager.selectedCharacter.value != null) {
      return "${sessionManager.selectedCharacter.value!.name} (${aiModel.shortName})";
    }
    return aiModel.shortName;
  }

  // Getters for tool access
  CancelToken get cancelToken {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  /// Get reset tool call processing state callback
  Function() get resetToolCallProcessingStateCallback => _resetToolCallProcessingState;

  /// Get mark session as updated callback
  Function() get markSessionAsUpdatedCallback => sessionManager.markSessionAsUpdated;

  /// Get auto save session callback
  Function() get autoSaveSessionCallback => _autoSaveSession;

  /// Reset tool call processing state
  void _resetToolCallProcessingState() {
    streamingHandler.isProcessingToolCall.value = false;
  }

  /// Select an AI character for this chat session
  void selectCharacter(AiCharacterModel character) {
    sessionManager.selectedCharacter.value = character;
    // Mark session as updated to ensure character selection is persisted
    sessionManager.markSessionAsUpdated();
  }
}
