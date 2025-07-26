import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/global/components/chat/think_block_widget.dart';
import 'package:freeaihub/core/global/services/hive_service.dart';
import 'package:freeaihub/screens/chat/managers/context_manager.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/models/chat/chat_session_model.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/screens/chat/handlers/error_handler.dart';
import 'package:get/get.dart';
import 'package:uuid/v4.dart';
import 'package:freeaihub/core/models/ai/ai_character_model.dart';
import 'package:freeaihub/core/global/services/ai_character_service.dart';

/// Manages all session-related functionality for chat operations
/// Handles session lifecycle, persistence, state management, and context tracking
class SessionManager {
  final AIModel aiModel;

  final ErrorHandler errorHandler;
  final ContextManager contextManager;
  final bool showDebugLogs = false;

  // Session state
  final Rx<ChatSession?> currentSession;
  final RxList<ChatSession> sessions;
  final RxList<Message> messages;

  // Session update tracking
  bool _isSessionUpdated = false;
  bool _isStreamingActive = false; // New flag to track streaming state

  // Capability states to save with session
  RxBool? isWebSearchEnabled;
  RxBool? isImageGenEnabled;

  // (NEW) Currently selected AI character for the session
  final Rx<AiCharacterModel?> selectedCharacter = Rx<AiCharacterModel?>(null);

  SessionManager({
    required this.aiModel,
    required this.errorHandler,
    required this.contextManager,
    required this.currentSession,
    required this.sessions,
    required this.messages,
    this.isWebSearchEnabled,
    this.isImageGenEnabled,
  });

  /// Initializes a new chat session or loads an existing one
  /// Checks URL parameters for session ID and loads accordingly
  Future<void> initializeSession() async {
    try {
      // Load all sessions for this model
      sessions.value = await HiveService.to.getAllChatSessions(modelID: aiModel.id);

      // Check if we're loading an existing session from route parameters
      final sessionId = Get.parameters['sessionId'];
      if (sessionId != null && sessionId.isNotEmpty) {
        await loadSession(sessionId);
      } else {
        // Create new session
        await createNewSession();
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Error initializing session: $e');
      }
      errorHandler.showError(
        'Failed to initialize chat session. Please try again.',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Creates a new chat session with default values
  Future<void> createNewSession() async {
    try {
      currentSession.value = ChatSession(
        id: const UuidV4().generate(),
        title: 'New Chat',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [],
        aiModelID: aiModel.id,
        capabilities: _getCurrentCapabilities(),
        contextState: null, // New session starts with empty context
        selectedCharacterID: selectedCharacter.value?.id,
      );

      // Clear messages and reset context
      messages.clear();
      selectedCharacter.value = null;
      resetContextForNewSession();
      _isSessionUpdated = false;

      // Don't add to sessions list yet - only add when first message is sent
      // This prevents empty sessions from being saved

      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [SessionManager] - New session created (not yet in list): ${currentSession.value?.id}',
        );
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Error creating new session: $e');
      }
      throw Exception('Failed to create new session: $e');
    }
  }

  /// Saves the current chat session to storage
  /// Automatically generates title from first user message and saves context state
  /// Only saves sessions that have messages
  void saveCurrentSession() {
    if (currentSession.value == null || !_isSessionUpdated) {
      return;
    }

    // Don't save sessions without any messages
    if (messages.isEmpty) {
      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [SessionManager] - Skipping save for empty session: ${currentSession.value?.id}',
        );
      }
      _isSessionUpdated = false; // Reset flag since we're not saving
      return;
    }

    try {
      String title = _generateSessionTitle();

      // Get current context state
      final contextState = _getCurrentContextState();

      // Update session with current data including context state
      currentSession.value = currentSession.value!.copyWith(
        messages: messages.toList(),
        updatedAt: DateTime.now(),
        title: title,
        capabilities: _getCurrentCapabilities(),
        contextState: contextState,
        selectedCharacterID: selectedCharacter.value?.id,
      );

      // Save to storage
      HiveService.to.saveChatSession(currentSession.value!);

      // Update sessions list
      _updateSessionsList();

      _isSessionUpdated = false; // Reset flag after saving

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Session saved successfully with context state');
        if (contextState != null) {
          print(
            '[DEBUG] [SessionManager] - Context state: ${contextState['totalTokens']} total tokens',
          );
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Error saving session: $e');
      }
      errorHandler.showError(
        'Failed to save session',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Loads a specific chat session by ID
  /// Saves current session before loading if needed
  Future<void> loadSession(String sessionId) async {
    if (sessionId.trim().isEmpty) {
      errorHandler.showError('Invalid session ID');
      return;
    }

    try {
      // Save current session if it has updates
      if (currentSession.value != null && _isSessionUpdated) {
        saveCurrentSession();
      }

      // Clean up think block timers before loading new session
      ThinkBlockWidget.cleanupAllTimers();

      // Load session from storage
      final session = await HiveService.to.loadChatSession(sessionId);

      if (session != null) {
        // Validate AI model compatibility
        if (session.aiModelID != aiModel.id) {
          errorHandler.showError(
            'Session AI Model mismatch. This session was created with a different AI model.',
          );
          return;
        }

        // Update current state
        currentSession.value = session;

        messages.value = session.messages;

        // Load capabilities from session
        _loadCapabilities(session.capabilities);

        // Load context state from session
        _loadContextState(session.contextState);

        // Load selected character from session
        _loadSelectedCharacter(session.selectedCharacterID);

        _isSessionUpdated = false; // Reset flag as session is freshly loaded
      } else {
        errorHandler.showError('Session not found.');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionHandler] - Error loading session: $e');
      }
      errorHandler.showError(
        'Failed to load session',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Deletes a chat session by ID
  /// Creates new session if current session is deleted
  void deleteSession(String sessionId) async {
    if (sessionId.trim().isEmpty) {
      errorHandler.showError('Invalid session ID');
      return;
    }

    try {
      final wasCurrentSession = currentSession.value?.id == sessionId;

      // Delete from storage
      HiveService.to.deleteChatSession(sessionId);

      // Remove from sessions list
      sessions.removeWhere((session) => session.id == sessionId);

      // If current session was deleted, create a new one
      if (wasCurrentSession) {
        await startNewSession(saveCurrentFirst: false);
      }

      // Force refresh the sessions list to update UI
      sessions.refresh();

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Session deleted successfully: $sessionId');
        if (wasCurrentSession) {
          print(
            '[DEBUG] [SessionManager] - New session created after deletion: ${currentSession.value?.id}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Error deleting session: $e');
      }
      errorHandler.showError(
        'Failed to delete session',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Starts a new chat session
  /// Optionally saves current session before creating new one
  Future<void> startNewSession({bool saveCurrentFirst = true}) async {
    try {
      // Save current session if needed
      if (saveCurrentFirst && currentSession.value != null && _isSessionUpdated) {
        saveCurrentSession();
      }

      // Clean up think block timers
      ThinkBlockWidget.cleanupAllTimers();

      // Create new session
      await createNewSession();

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionHandler] - New session started successfully');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionHandler] - Error starting new session: $e');
      }
      errorHandler.showError(
        'Failed to start new session',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Creates a new session (compatibility method with SessionManager)
  /// This method provides backward compatibility with the old SessionManager interface
  Future<void> newSession({bool switchToNew = true}) async {
    await startNewSession(saveCurrentFirst: switchToNew);
  }

  /// Marks the current session as updated (needs saving)
  void markSessionAsUpdated() {
    // Only mark as updated if not streaming to prevent constant saves during streaming
    if (!_isStreamingActive) {
      _isSessionUpdated = true;

      // If this is the first message in the session, add it to the sessions list
      if (currentSession.value != null && messages.isNotEmpty) {
        final existingIndex = sessions.indexWhere((s) => s.id == currentSession.value!.id);
        if (existingIndex == -1) {
          // Session not in list yet, add it now that it has messages
          _updateSessionsList();
          if (kDebugMode && showDebugLogs) {
            print(
              '[DEBUG] [SessionManager] - Session added to list after first message: ${currentSession.value?.id}',
            );
          }
        }
      }

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Session marked as updated');
      }
    } else {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Session update skipped during streaming');
      }
    }
  }

  /// Clears all chat sessions for current AI model
  Future<void> clearAllSessions() async {
    try {
      // Get all session IDs for current model
      final modelSessions = await HiveService.to.getAllChatSessions(modelID: aiModel.id);

      // Delete each session
      for (final session in modelSessions) {
        await HiveService.to.deleteChatSession(session.id);
      }

      // Clear local lists
      sessions.clear();

      // Create new session
      await createNewSession();

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionHandler] - All sessions cleared for model: ${aiModel.id}');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionHandler] - Error clearing sessions: $e');
      }
      errorHandler.showError(
        'Failed to clear sessions',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Gets session statistics for debugging and analytics
  Map<String, dynamic> getSessionStatistics() {
    final totalSessions = sessions.length;
    final currentSessionMessageCount = messages.length;
    final averageMessagesPerSession = sessions.isNotEmpty
        ? sessions.fold<int>(0, (sum, session) => sum + session.messages.length) / sessions.length
        : 0;

    return {
      'totalSessions': totalSessions,
      'currentSessionId': currentSession.value?.id ?? 'none',
      'currentSessionMessageCount': currentSessionMessageCount,
      'averageMessagesPerSession': averageMessagesPerSession.round(),
      'isSessionUpdated': _isSessionUpdated,
      'aiModelId': aiModel.id,
      'aiModelName': aiModel.name,
      'contextStatus': contextManager.getContextStatus(),
    };
  }

  /// Resets context manager when starting a new session
  void resetContextForNewSession() {
    contextManager.resetSession();
    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [SessionManager] - Context reset for new session');
    }
  }

  /// Gets current context usage percentage for UI display
  double get contextUsagePercentage => contextManager.contextUsagePercentage;

  /// Checks if context is near limit
  bool get isContextNearLimit => contextManager.isNearLimit;

  /// Checks if context needs trimming
  bool get needsContextTrimming => contextManager.needsContextTrimming;

  /// Generates a title for the session based on messages
  String _generateSessionTitle() {
    String title = 'New Chat';

    if (messages.isNotEmpty) {
      // Get title from the most recent user message (messages are stored newest first)
      final mostRecentUserMessage = messages.firstWhere(
        (msg) => msg.author.type == AuthorType.user,
        orElse: () => messages.first,
      );

      if (mostRecentUserMessage.text.isNotEmpty) {
        final messageText = mostRecentUserMessage.text;
        // Remove think blocks and their contents
        final cleanedText = messageText.replaceAll(RegExp(r'<think>[\s\S]*?<\/think>'), '');
        final trimmedTitle = cleanedText.trim();

        if (trimmedTitle.isNotEmpty) {
          title = trimmedTitle.substring(0, min(30, trimmedTitle.length));
          // Add ellipsis if truncated
          if (trimmedTitle.length > 30) {
            title += '...';
          }
        }
      } else if (mostRecentUserMessage.type == MessageType.image &&
          mostRecentUserMessage.text.isEmpty) {
        title = 'Image Message';
      }
    }

    return title;
  }

  /// Updates session title based on the most recent user message
  /// This should be called whenever a new user message is added
  void updateSessionTitle() {
    if (currentSession.value == null) return;

    try {
      final newTitle = _generateSessionTitle();

      // Only update if the title has actually changed
      if (currentSession.value!.title != newTitle) {
        currentSession.value = currentSession.value!.copyWith(
          title: newTitle,
          updatedAt: DateTime.now(),
        );

        // Update sessions list
        _updateSessionsList();

        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [SessionHandler] - Session title updated to: $newTitle');
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionHandler] - Error updating session title: $e');
      }
    }
  }

  /// Updates the sessions list with current session
  void _updateSessionsList() {
    if (currentSession.value == null) return;

    final existingIndex = sessions.indexWhere((s) => s.id == currentSession.value!.id);

    if (existingIndex != -1) {
      // Update existing session
      sessions[existingIndex] = currentSession.value!;
    } else {
      // Add new session to the beginning of the list
      sessions.insert(0, currentSession.value!);
    }

    sessions.refresh();
  }

  /// Checks if current session needs saving
  bool get needsSaving => _isSessionUpdated && currentSession.value != null;

  /// Sets the streaming state to prevent session updates during streaming
  void setStreamingActive(bool isActive) {
    _isStreamingActive = isActive;
    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [SessionHandler] - Streaming state changed: $isActive');
    }
  }

  /// Marks session as updated after streaming is complete
  void markSessionAsUpdatedAfterStreaming() {
    _isSessionUpdated = true;

    // If this is the first message in the session, add it to the sessions list
    if (currentSession.value != null && messages.isNotEmpty) {
      final existingIndex = sessions.indexWhere((s) => s.id == currentSession.value!.id);
      if (existingIndex == -1) {
        // Session not in list yet, add it now that it has messages
        _updateSessionsList();
        if (kDebugMode && showDebugLogs) {
          print(
            '[DEBUG] [SessionManager] - Session added to list after streaming: ${currentSession.value?.id}',
          );
        }
      }
    }

    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [SessionManager] - Session marked as updated after streaming completion');
    }
  }

  /// Gets current session info for debugging
  Map<String, dynamic> get currentSessionInfo => {
    'id': currentSession.value?.id ?? 'none',
    'title': currentSession.value?.title ?? 'none',
    'messageCount': messages.length,
    'needsSaving': needsSaving,
    'createdAt': currentSession.value?.createdAt.toIso8601String() ?? 'none',
    'updatedAt': currentSession.value?.updatedAt.toIso8601String() ?? 'none',
  };

  /// Gets current capabilities state to save with session
  Map<String, bool>? _getCurrentCapabilities() {
    // Return null if no capabilities are available
    if (isWebSearchEnabled == null && isImageGenEnabled == null) {
      return null;
    }

    final capabilities = <String, bool>{};

    if (isWebSearchEnabled != null) {
      capabilities['webSearch'] = isWebSearchEnabled!.value;
    }
    if (isImageGenEnabled != null) {
      capabilities['imageGeneration'] = isImageGenEnabled!.value;
    }

    return capabilities.isEmpty ? null : capabilities;
  }

  /// Gets current context state from context manager to save with session
  Map<String, dynamic>? _getCurrentContextState() {
    try {
      final contextStatus = contextManager.getContextStatus();

      // Only save essential context information
      return {
        'totalTokens': contextStatus['totalTokens'],
        'promptTokens': contextStatus['promptTokens'],
        'completionTokens': contextStatus['completionTokens'],
        'sessionTotalTokens': contextStatus['sessionTotalTokens'],
        'maxTokens': contextStatus['maxTokens'],
        'systemInstructionTokens': contextManager.systemInstructionTokens,
      };
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Error getting context state: $e');
      }
      return null;
    }
  }

  /// Loads capabilities from session data
  void _loadCapabilities(Map<String, bool>? capabilities) {
    if (capabilities == null) return;

    try {
      if (capabilities.containsKey('webSearch') && isWebSearchEnabled != null) {
        isWebSearchEnabled!.value = capabilities['webSearch'] ?? false;
      }
      if (capabilities.containsKey('imageGeneration') && isImageGenEnabled != null) {
        isImageGenEnabled!.value = capabilities['imageGeneration'] ?? false;
      }

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Capabilities loaded: $capabilities');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Error loading capabilities: $e');
      }
    }
  }

  /// Loads context state from session data and restores context manager state
  void _loadContextState(Map<String, dynamic>? contextState) {
    if (contextState == null) return;

    try {
      // Update context manager with saved values
      final totalTokens = contextState['totalTokens'] ?? 0;
      final promptTokens = contextState['promptTokens'] ?? 0;
      final completionTokens = contextState['completionTokens'] ?? 0;
      final sessionTotalTokens = contextState['sessionTotalTokens'] ?? 0;
      final maxTokens = contextState['maxTokens'] ?? contextManager.maxContextTokens;
      final systemInstructionTokens = contextState['systemInstructionTokens'] ?? 0;

      // Update context manager with loaded values
      contextManager.updateFromUsage(
        totalTokens: totalTokens,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
      );

      // Update max context tokens if needed
      if (maxTokens != contextManager.maxContextTokens) {
        contextManager.updateModelContext(maxTokens: maxTokens);
      }

      // Update session total tokens
      contextManager.updateSessionTotalTokens(sessionTotalTokens);

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Context state loaded:');
        print(
          '[DEBUG] [SessionManager] - Total: $totalTokens, Prompt: $promptTokens, Completion: $completionTokens',
        );
        print('[DEBUG] [SessionManager] - Session Total: $sessionTotalTokens, Max: $maxTokens');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Error loading context state: $e');
      }
    }
  }

  /// (NEW) Load selected character based on stored ID
  void _loadSelectedCharacter(String? characterId) {
    selectedCharacter.value = null;
    if (characterId == null) return;

    try {
      if (!Get.isRegistered<AiCharacterService>()) return;

      final service = Get.find<AiCharacterService>();

      AiCharacterModel? character;
      try {
        character = service.characters.firstWhere((c) => c.id == characterId);
      } catch (_) {
        character = null;
      }

      if (character != null) {
        selectedCharacter.value = character;
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [SessionManager] - Error loading selected character: $e');
      }
    }
  }
}
