import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/models/chat/image_data_model.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/screens/chat/handlers/error_handler.dart';
import 'package:freeaihub/screens/chat/managers/session_manager.dart';
import 'package:get/get.dart';
import 'package:uuid/v4.dart';

/// Handles all message-related functionality for chat operations
class MessageHandler {
  final SessionManager sessionManager;
  final ErrorHandler errorHandler;
  final RxList<Message> messages;

  final bool showDebugLogs = false;

  MessageHandler({
    required this.sessionManager,
    required this.errorHandler,
    required this.messages,
  });

  /// Creates a text message with optional image and document attachments
  void createUserMessage({
    required String text,
    List<ImageData>? attachedImages,
    List<Map<String, dynamic>>? attachedDocuments,
  }) {
    Map<String, dynamic>? metadata;
    MessageType messageType = MessageType.text;

    if (attachedDocuments != null && attachedDocuments.isNotEmpty) {
      metadata ??= {};
      metadata['attachedDocuments'] = attachedDocuments;
      messageType = MessageType.document;
    }

    if (attachedImages != null && attachedImages.isNotEmpty) {
      messageType = MessageType.image;
    }

    final message = Message(
      author: MessageAuthor(type: AuthorType.user, name: "You"),
      type: messageType,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: UuidV4().generate(),
      text: text,
      metadata: metadata,
      attachedImages: attachedImages,
      tokenCount: 0,
    );

    addMessage(message);
  }

  /// Adds a message to the chat
  void addMessage(Message message) {
    try {
      messages.insert(0, message);

      // Only mark session as updated for user messages to prevent constant updates during AI streaming
      if (message.author.type == AuthorType.user) {
        sessionManager.markSessionAsUpdated();
        // Update session title if this is a user message
        sessionManager.updateSessionTitle();
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MessageHandler] - Error adding message: $e');
      }
      errorHandler.showError('Failed to add message');
    }
  }

  /// Safely updates a message at the given index, handling different message types properly.
  /// This prevents type cast errors when updating CustomMessage as TextMessage.
  void updateMessageSafely(int index, String text, Map<String, dynamic> metadata) {
    if (index >= messages.length) {
      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [MessageHandler] - Index $index out of bounds (messages length: ${messages.length})',
        );
      }
      return;
    }

    final currentMessage = messages[index];

    // Preserve original message type and important metadata (like attachments)
    Map<String, dynamic> finalMetadata = Map<String, dynamic>.from(metadata);

    // Preserve attachments from original message
    if (currentMessage.metadata != null) {
      if (currentMessage.metadata!['attachedImages'] != null) {
        finalMetadata['attachedImages'] = currentMessage.metadata!['attachedImages'];
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [MessageHandler] - Preserving attached images in metadata');
        }
      }
      if (currentMessage.metadata!['attachedDocuments'] != null) {
        finalMetadata['attachedDocuments'] = currentMessage.metadata!['attachedDocuments'];
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [MessageHandler] - Preserving attached documents in metadata');
        }
      }
    }

    MessageType finalType = currentMessage.type;

    // Handle different message types appropriately
    if (currentMessage.type == MessageType.text ||
        currentMessage.type == MessageType.thinkBlock ||
        currentMessage.type == MessageType.image ||
        currentMessage.type == MessageType.document) {
      // For typing dots messages (thinkBlock with isTypingDots), convert to text message
      if (currentMessage.type == MessageType.thinkBlock &&
          currentMessage.metadata?['isTypingDots'] == true &&
          text.trim().isNotEmpty) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [MessageHandler] - Converting typing dots message to text message');
          print(
            '[DEBUG] [MessageHandler] - Text content: "${text.length > 50 ? "${text.substring(0, 50)}..." : text}"',
          );
        }
        finalType = MessageType.text; // Convert typing dots to text message
      }
      // For image and document messages, preserve their original type
      else if (currentMessage.type == MessageType.image ||
          currentMessage.type == MessageType.document) {
        finalType = currentMessage.type; // Keep original type
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [MessageHandler] - Preserving message type: $finalType');
        }
      }

      messages[index] = currentMessage.copyWith(
        text: text,
        metadata: finalMetadata,
        attachedImages: currentMessage.attachedImages,
        type: finalType,
      );

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MessageHandler] - Message updated with type: $finalType');
        print('[DEBUG] [MessageHandler] - Final metadata keys: ${finalMetadata.keys.toList()}');
      }
    }

    // Do not mark session as updated during message updates to prevent constant saves during streaming
    // Session will be marked as updated after streaming completion in StreamingHandler cleanup
  }

  /// Deletes a message with the specified ID from the current chat session.
  /// Enhanced with better validation and error handling.
  ///
  /// Parameters:
  ///   - id: The unique identifier of the message to delete
  ///   - thereIsThinkBlock: Whether there's an associated think block to delete
  ///
  /// Throws:
  ///   - Shows error snackbar if deletion fails
  void deleteMessage(String id, {bool thereIsThinkBlock = false}) {
    if (id.trim().isEmpty) {
      errorHandler.showError('Invalid message ID');
      return;
    }

    try {
      if (thereIsThinkBlock) {
        final index = messages.indexWhere((element) => element.id == id);
        if (index == -1) {
          throw ChatException('Message not found');
        }

        // Remove the main message
        messages.removeAt(index);

        // Remove think block if it exists at the same index
        if (index < messages.length && messages[index].type == MessageType.thinkBlock) {
          messages.removeAt(index);
        }
      } else {
        final removedCount = messages.length;
        messages.removeWhere((message) => message.id == id);

        if (messages.length == removedCount) {
          throw ChatException('Message not found');
        }
      }

      sessionManager.markSessionAsUpdated();
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MessageHandler] - Error deleting message: $e');
      }
      errorHandler.showError(
        'Failed to delete message',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Delete all messages following a specific message (useful for regeneration)
  Future<void> deleteAllFollowingMessages(String id, {bool thereIsThinkBlock = false}) async {
    if (id.trim().isEmpty) {
      errorHandler.showError('Invalid message ID');
      return;
    }

    try {
      final index = messages.indexWhere((element) => element.id == id);
      if (index == -1) {
        throw ChatException('Message not found');
      }

      final initialCount = messages.length;
      final removeCount = index;

      if (removeCount > 0) {
        messages.removeRange(0, index);
        sessionManager.markSessionAsUpdated();

        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [MessageHandler] - Deleted $removeCount messages following: $id');
          print('[DEBUG] [MessageHandler] - Messages count: $initialCount -> ${messages.length}');
        }
      } else {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [MessageHandler] - No messages to delete following: $id');
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MessageHandler] - Error deleting messages: $e');
      }
      errorHandler.showError(
        'Failed to delete messages',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Updates the text of a message with the specified ID in the current chat session.
  /// Enhanced with validation and optimistic updates.
  ///
  /// Parameters:
  ///   - id: The unique identifier of the message to edit
  ///   - newText: The new text content for the message
  ///   - newImages: Optional list of new images to attach to the message
  ///
  /// Throws:
  ///   - Shows error snackbar if message is not found or update fails
  Future<void> editMessage(
    String id,
    String newText, {
    List<Map<String, dynamic>>? newImages,
  }) async {
    if (id.trim().isEmpty) {
      errorHandler.showError('Invalid message ID');
      return;
    }

    // Allow empty text if there are images attached
    if (newText.trim().isEmpty && (newImages == null || newImages.isEmpty)) {
      errorHandler.showError('Message cannot be empty');
      return;
    }

    try {
      final index = messages.indexWhere((message) => message.id == id);
      if (index == -1) {
        throw ChatException('Message not found');
      }

      final message = messages[index];

      // Store original data for rollback if needed
      final originalText = message.text;
      final originalMetadata = message.metadata;

      // Prepare new metadata
      Map<String, dynamic> newMetadata = {
        ...?originalMetadata,
        'edited': true,
        'editTime': DateTime.now().toIso8601String(),
        'originalText': originalText,
      };

      List<ImageData>? updatedAttachedImages;

      if (newImages != null && newImages.isNotEmpty) {
        // Update metadata with new images
        newMetadata['attachedImages'] = newImages
            .map(
              (img) => {
                'id': img['id'],
                'name': img['name'],
                'path': img['path'],
                'size': img['size'],
                'extension': img['extension'],
                'format': img['format'],
                'base64URL': img['base64URL'],
              },
            )
            .toList();

        // Convert map list to ImageData list for UI rendering
        updatedAttachedImages = newImages
            .map(
              (img) => ImageData(
                id: img['id'] ?? '',
                name: img['name'] ?? '',
                path: img['path'] ?? '',
                size: (img['size'] ?? 0) as int,
                extension: (img['extension'] ?? '') as String,
              ),
            )
            .toList();
      } else {
        // No images provided – clear any existing images
        newMetadata.remove('attachedImages');
        updatedAttachedImages = null;
      }

      // Determine new message type based on attachments
      MessageType updatedType = message.type;
      if (updatedAttachedImages != null && updatedAttachedImages.isNotEmpty) {
        updatedType = MessageType.image;
      } else if (message.type == MessageType.image &&
          (updatedAttachedImages == null || updatedAttachedImages.isEmpty)) {
        updatedType = MessageType.text;
      }

      // Optimistic update with new attachments and type
      messages[index] = message.copyWith(
        text: newText.trim(),
        metadata: newMetadata.isNotEmpty ? newMetadata : null,
        attachedImages: updatedAttachedImages,
        type: updatedType,
      );

      sessionManager.markSessionAsUpdated();

      // Update session title if this is a user message
      if (message.author.type == AuthorType.user) {
        sessionManager.updateSessionTitle();
      }

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MessageHandler] - Message updated: $id');
        if (message.author.type == AuthorType.user) {
          print('[DEBUG] [MessageHandler] - Session title updated for edited user message');
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MessageHandler] - Error updating message: $e');
      }
      errorHandler.showError(
        'Failed to edit message',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Get message statistics for debugging and optimization
  Map<String, dynamic> getMessageStatistics() {
    final textMessages = messages.where((message) => message.type == MessageType.text);
    final imageMessages = messages.where((message) => message.type == MessageType.image);
    final thinkBlocks = messages.where((message) => message.type == MessageType.thinkBlock);

    final totalTextLength = textMessages.fold<int>(0, (sum, msg) => sum + msg.text.length);
    final averageTextLength = textMessages.isNotEmpty ? totalTextLength / textMessages.length : 0;

    return {
      'totalMessages': messages.length,
      'textMessages': textMessages.length,
      'imageMessages': imageMessages.length,
      'thinkBlocks': thinkBlocks.length,
      'totalTextLength': totalTextLength,
      'averageTextLength': averageTextLength.round(),
      'lastMessageTime': messages.isNotEmpty
          ? DateTime.fromMillisecondsSinceEpoch(messages.first.createdAt ?? 0)
          : null,
    };
  }

  /// Find the last user message and associated AI response(s) for regeneration
  Map<String, dynamic>? findLastUserPromptAndAIResponse() {
    try {
      if (messages.isEmpty) return null;

      // Find the last user message and associated AI response(s)
      String? lastUserPrompt;
      int aiMessageIndex = -1;
      int thinkBlockIndex = -1;

      // First, find the AI response
      for (int i = 0; i < messages.length; i++) {
        if (messages[i].author.type == AuthorType.ai) {
          aiMessageIndex = i;
          break;
        }
      }

      if (aiMessageIndex == -1) return null;

      // Check if there's a think block right after the AI response
      if (aiMessageIndex + 1 < messages.length &&
          messages[aiMessageIndex + 1].type == MessageType.thinkBlock &&
          messages[aiMessageIndex + 1].metadata?['ThinkBlock'] != null) {
        thinkBlockIndex = aiMessageIndex + 1;
      }

      // Find the user prompt that triggered this AI response
      int startIndex = thinkBlockIndex != -1 ? thinkBlockIndex + 1 : aiMessageIndex + 1;
      for (int i = startIndex; i < messages.length; i++) {
        if (messages[i].author.type == AuthorType.user && messages[i].type == MessageType.text) {
          lastUserPrompt = messages[i].text;
          break;
        }
      }

      if (lastUserPrompt == null || lastUserPrompt.trim().isEmpty) {
        return null;
      }

      return {
        'prompt': lastUserPrompt,
        'aiMessageIndex': aiMessageIndex,
        'thinkBlockIndex': thinkBlockIndex,
      };
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [MessageHandler] - Error finding last user prompt: $e');
      }
      return null;
    }
  }

  /// Clear all messages
  void clearMessages() {
    messages.clear();
  }

  /// Get message count
  int get messageCount => messages.length;

  /// Check if messages are empty
  bool get isEmpty => messages.isEmpty;

  /// Check if messages are not empty
  bool get isNotEmpty => messages.isNotEmpty;
}
