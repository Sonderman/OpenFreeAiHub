import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/global/services/ai_client_service.dart';
import 'package:freeaihub/core/models/ai/ai_character_model.dart';
import 'package:freeaihub/screens/chat/managers/context_manager.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/models/api/api_model.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/screens/chat/handlers/error_handler.dart';
import 'package:freeaihub/screens/chat/handlers/message_handler.dart';
import 'package:freeaihub/screens/chat/managers/session_manager.dart';
import 'package:get/get.dart';
import 'package:uuid/v4.dart';

/// Handles streaming responses and AI operations for chat
class StreamingHandler {
  final AIModel aiModel;
  final AiClientService clientService;
  final ErrorHandler errorHandler;
  final MessageHandler messageHandler;
  final bool showDebugLogs = false;
  final ContextManager contextManager;
  final Rx<AiCharacterModel?> character;

  // Callbacks for controller interaction
  final Function() markSessionAsUpdated;
  final Function() resetToolCallProcessingState;
  final Function() update;

  // Session handler for streaming state management
  final SessionManager sessionHandler; // Add session handler reference

  // Streaming state
  final RxBool isTyping = false.obs;
  String streamedText = '';
  CancelToken? _cancelToken;

  // Capabilities
  final RxBool isCapabilitiesEnabled = false.obs;
  final RxBool isWebSearchEnabled = false.obs;
  final RxBool isImageGenEnabled = false.obs;
  final RxBool isImageEditEnabled = false.obs;
  final RxBool isProcessingToolCall = false.obs;

  // Streaming structured response variables
  final RxString currentJsonChunk = ''.obs;
  final Rx<Map<String, dynamic>?> completeStructuredJson = Rx<Map<String, dynamic>?>(null);
  final RxBool isStreamingStructuredResponse = false.obs;
  final RxString structuredResponseBuffer = ''.obs;

  StreamingHandler({
    required this.aiModel,
    required this.clientService,
    required this.errorHandler,
    required this.messageHandler,
    required this.markSessionAsUpdated,
    required this.resetToolCallProcessingState,
    required this.update,
    required this.contextManager,
    required this.sessionHandler,
    required this.character,
  });

  /// Main method for running AI operations with enhanced error handling and performance optimizations.
  /// Handles the AI response stream and updates UI accordingly.
  /// Now includes enhanced image processing support for multimodal models.
  Future<void> runAiOperations(String? prompt, CancelToken? cancelToken) async {
    if (prompt == "systemRerun") {
      prompt = "";
    }

    // Prevent multiple simultaneous operations
    if (isTyping.value) {
      return;
    }

    try {
      // Set typing indicator and streaming state
      isTyping.value = true;
      sessionHandler.setStreamingActive(true); // Prevent session updates during streaming
      errorHandler.clearError();
      _cancelToken = cancelToken;

      // Get message history for context (limit to prevent memory issues)
      const maxHistoryLength = 50;
      var history = messageHandler.messages.take(maxHistoryLength).toList();

      bool isCompleted = false;
      final startTime = DateTime.now();

      try {
        // Determine operation type based on capabilities
        isCapabilitiesEnabled.value = isWebSearchEnabled.value || isImageGenEnabled.value;

        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Capability check:');
          print('[DEBUG] [StreamingHandler] - Web search enabled: ${isWebSearchEnabled.value}');
          print('[DEBUG] [StreamingHandler] - Image gen enabled: ${isImageGenEnabled.value}');
          print('[DEBUG] [StreamingHandler] - Image edit enabled: ${isImageEditEnabled.value}');
          print(
            '[DEBUG] [StreamingHandler] - Overall capabilities enabled: ${isCapabilitiesEnabled.value}',
          );
        }

        if (isCapabilitiesEnabled.value) {
          if (kDebugMode && showDebugLogs) {
            print('[DEBUG] [StreamingHandler] - Using structured response with streaming');
          }

          // Use streaming structured response for capabilities
          isStreamingStructuredResponse.value = true;
          currentJsonChunk.value = '';
          completeStructuredJson.value = null;
          structuredResponseBuffer.value = '';

          // Build the list of enabled tools based on current capability flags
          final List<String> enabledTools = [];
          if (isWebSearchEnabled.value) enabledTools.add('web_search');
          if (isImageGenEnabled.value) enabledTools.add('image_generation');

          isCompleted = await clientService
              .getStructuredResponse(
                prompt: prompt ?? "",
                character: character.value,
                onResponse: onCapableResponse,
                history: history,
                isStreaming: true,
                onJsonChunk: onStreamingJsonChunk,
                onExtractedContent: onStreamingExtractedContent,
                onComplete: onStreamingJsonComplete,
                cancelToken: _cancelToken,
                tools: enabledTools,
              )
              .timeout(
                const Duration(minutes: 5), // Add timeout for structured response
                onTimeout: () {
                  if (kDebugMode && showDebugLogs) {
                    print(
                      '[DEBUG] [StreamingHandler] - Structured response timed out after 5 minutes',
                    );
                  }
                  return false; // Return false on timeout
                },
              );
        } else {
          // Ensure streaming structured response mode is disabled
          isStreamingStructuredResponse.value = false;
          currentJsonChunk.value = '';
          completeStructuredJson.value = null;
          structuredResponseBuffer.value = '';

          // Use HTTP stream response methods based on provider with enhanced image support
          if (aiModel.apiModel.provider == ApiProviders.google) {
            if (kDebugMode && showDebugLogs) {
              print('[DEBUG] [StreamingHandler] - Using Google provider stream response');
              print('[DEBUG] [StreamingHandler] - Model: ${aiModel.apiModel.modelName}');
            }
            isCompleted = await clientService.getGeminiNativeStreamResponse(
              prompt: prompt,
              worker: streamedWorker,
              history: history,
              cancelToken: _cancelToken,
              onUsageChunk: _extractUsageFromChunk,
            );
          } else {
            if (kDebugMode && showDebugLogs) {
              print('[DEBUG] [StreamingHandler] - Using standard provider stream response');
              print('[DEBUG] [StreamingHandler] - Provider: ${aiModel.apiModel.provider}');
              print('[DEBUG] [StreamingHandler] - Model: ${aiModel.apiModel.modelName}');
              print('[DEBUG] [StreamingHandler] - Base URL: ${aiModel.apiModel.baseURL}');
            }
            isCompleted = await clientService.getHttpStreamResponse(
              prompt: prompt,
              character: character.value,
              worker: streamedWorker,
              history: history,
              cancelToken: _cancelToken,
              onUsageChunk: _extractUsageFromChunk,
            );
          }
        }

        final duration = DateTime.now().difference(startTime);
        _handleOperationCompletion(isCompleted, duration);
      } on DioException catch (e) {
        _handleDioException(e);
      }
    } catch (e) {
      _handleGeneralException(e);
    } finally {
      _cleanup();
    }
  }

  /// Enhanced structured response handler with better error handling
  void onCapableResponse(String? response) {
    try {
      // Safety check: This method should only be called when capabilities are enabled
      if (!isCapabilitiesEnabled.value) {
        return;
      }

      if (response == null || response.trim().isEmpty) {
        throw Exception('No response received');
      }

      Map<String, dynamic> responseMap = jsonDecode(response);

      // Use safe message handling to handle different message types
      final responseText = responseMap['response']?.toString().trim() ?? "";
      final metadata = responseMap['tool_call'] != null
          ? {
              'tool_call': responseMap['tool_call'],
              'tool_call_status': ToolCallStatus.pending.index,
              'responseTime': DateTime.now().toIso8601String(),
            }
          : {'responseTime': DateTime.now().toIso8601String()};

      // Set tool call processing state if tool call is present
      if (responseMap['tool_call'] != null) {
        isProcessingToolCall.value = true;
      }

      // Check if we need to create a new AI message or update existing one
      bool needsNewMessage =
          messageHandler.messages.isEmpty ||
          (messageHandler.messages.isNotEmpty &&
              messageHandler.messages[0].author.type != AuthorType.ai);

      if (needsNewMessage) {
        // Create new AI message
        messageHandler.addMessage(
          Message(
            author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
            type: MessageType.text,
            id: UuidV4().generate(),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            text: responseText,
            metadata: metadata,
            tokenCount: 0,
          ),
        );
      } else {
        // Update existing AI message
        messageHandler.updateMessageSafely(0, responseText, metadata);
      }

      // Update token count for completed AI message
      _updateCompletedMessageTokenCount();
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Error processing response: $e');
      }

      // When an error occurs, remove the "thinking" message from the chat UI
      if (messageHandler.isNotEmpty && messageHandler.messages[0].author.type == AuthorType.ai) {
        messageHandler.messages.removeAt(0);
      }

      // Show a snackbar with a user-friendly error message
      errorHandler.showError(
        'Failed to process AI response. Please try again.',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Handles streaming JSON chunks for structured responses
  /// Accumulates and processes JSON data as it arrives
  void onStreamingJsonChunk(String jsonChunk) {
    try {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - onStreamingJsonChunk called');
        print('[DEBUG] [StreamingHandler] - Capabilities enabled: ${isCapabilitiesEnabled.value}');
        print('[DEBUG] [StreamingHandler] - Chunk length: ${jsonChunk.length}');
        print(
          '[DEBUG] [StreamingHandler] - Chunk content: "${jsonChunk.length > 50 ? "${jsonChunk.substring(0, 50)}..." : jsonChunk}"',
        );
      }

      // Safety check: This method should only be called when capabilities are enabled
      if (!isCapabilitiesEnabled.value) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Capabilities not enabled, returning');
        }
        return;
      }

      if (jsonChunk.trim().isEmpty) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Empty chunk, returning');
        }
        return;
      }

      // Accumulate JSON chunks - this method should ONLY accumulate, not process
      currentJsonChunk.value += jsonChunk;
      structuredResponseBuffer.value += jsonChunk;

      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [StreamingHandler] - Total buffer length: ${structuredResponseBuffer.value.length}',
        );
        print('[DEBUG] [StreamingHandler] - Chunk accumulated successfully');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Error processing chunk: $e');
        print('[DEBUG] [StreamingHandler] - Chunk content: "$jsonChunk"');
        print(
          '[DEBUG] [StreamingHandler] - Buffer length: ${structuredResponseBuffer.value.length}',
        );
        print('[DEBUG] [StreamingHandler] - Stack trace: ${StackTrace.current}');
      }
      // Don't show error to user for individual chunk processing - wait for completion
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Chunk processing error logged, continuing...');
      }
    }
  }

  /// Handles extracted content from streaming JSON parser
  /// This provides cleaner progressive updates to the UI
  void onStreamingExtractedContent(String extractedContent) {
    try {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - onStreamingExtractedContent called');
        print('[DEBUG] [StreamingHandler] - Capabilities enabled: ${isCapabilitiesEnabled.value}');
        print('[DEBUG] [StreamingHandler] - Content length: ${extractedContent.length}');
        print('[DEBUG] [StreamingHandler] - Messages count: ${messageHandler.messages.length}');
      }

      // Safety check: This method should only be called when capabilities are enabled
      if (!isCapabilitiesEnabled.value) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Capabilities not enabled, returning');
        }
        return;
      }

      if (extractedContent.trim().isEmpty) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Empty content, returning');
        }
        return;
      }

      // Clean the extracted content
      String cleanedContent = _cleanResponseText(extractedContent);

      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [StreamingHandler] - Original content: "${extractedContent.length > 100 ? "${extractedContent.substring(0, 100)}..." : extractedContent}"',
        );
        print(
          '[DEBUG] [StreamingHandler] - Cleaned content: "${cleanedContent.length > 100 ? "${cleanedContent.substring(0, 100)}..." : cleanedContent}"',
        );
      }

      // Check if we need to create a new AI message (first extracted content received)
      bool needsNewMessage =
          messageHandler.messages.isEmpty ||
          (messageHandler.messages.isNotEmpty &&
              messageHandler.messages[0].author.type != AuthorType.ai);

      if (needsNewMessage && cleanedContent.trim().isNotEmpty) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Creating new AI message for structured response');
        }

        // Create regular text message for structured response
        messageHandler.addMessage(
          Message(
            author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
            type: MessageType.text,
            id: UuidV4().generate(),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            text: cleanedContent.trim(),
            tokenCount: 0,
            metadata: {
              'isStreamingExtracted': true,
              'extractedContentLength': extractedContent.length,
              'cleanedContentLength': cleanedContent.length,
              'lastExtractedTime': DateTime.now().toIso8601String(),
              'isProgressive': true,
            },
          ),
        );

        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - New AI message created successfully');
        }
        return;
      }

      // Update existing AI message with the progressive content if it's an AI message
      if (messageHandler.isNotEmpty && messageHandler.messages[0].author.type == AuthorType.ai) {
        try {
          messageHandler.updateMessageSafely(0, cleanedContent, {
            'isStreamingExtracted': true,
            'extractedContentLength': extractedContent.length,
            'cleanedContentLength': cleanedContent.length,
            'lastExtractedTime': DateTime.now().toIso8601String(),
            'isProgressive': true,
          });

          if (kDebugMode && showDebugLogs) {
            print('[DEBUG] [StreamingHandler] - AI message updated successfully');
          }
        } catch (updateError) {
          if (kDebugMode && showDebugLogs) {
            print('[DEBUG] [StreamingHandler] - Error updating message: $updateError');
          }
        }
      } else {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - First message is not AI message, creating new one');
        }

        // Create new AI message if the first message is not from AI
        if (cleanedContent.trim().isNotEmpty) {
          messageHandler.addMessage(
            Message(
              author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
              type: MessageType.text,
              id: UuidV4().generate(),
              createdAt: DateTime.now().millisecondsSinceEpoch,
              text: cleanedContent.trim(),
              tokenCount: 0,
              metadata: {
                'isStreamingExtracted': true,
                'extractedContentLength': extractedContent.length,
                'cleanedContentLength': cleanedContent.length,
                'lastExtractedTime': DateTime.now().toIso8601String(),
                'isProgressive': true,
              },
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Error processing extracted content: $e');
        print('[DEBUG] [StreamingHandler] - Content: "$extractedContent"');
        print('[DEBUG] [StreamingHandler] - Stack trace: ${StackTrace.current}');
      }
      // Show error to user if nothing is working
      errorHandler.showError('Error processing AI response: $e');
    }
  }

  /// Handles completion of streaming structured response
  /// Processes the complete JSON and updates UI accordingly
  void onStreamingJsonComplete(Map<String, dynamic>? completeJson) {
    try {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - onStreamingJsonComplete called');
        print('[DEBUG] [StreamingHandler] - Complete JSON is null: ${completeJson == null}');
        print('[DEBUG] [StreamingHandler] - Capabilities enabled: ${isCapabilitiesEnabled.value}');
        print(
          '[DEBUG] [StreamingHandler] - Streaming active: ${isStreamingStructuredResponse.value}',
        );
        print(
          '[DEBUG] [StreamingHandler] - Buffer length: ${structuredResponseBuffer.value.length}',
        );
      }

      // Safety check: This method should only be called when capabilities are enabled
      if (!isCapabilitiesEnabled.value) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Capabilities not enabled, returning');
        }
        return;
      }

      // Check if streaming was already cancelled/stopped
      if (!isStreamingStructuredResponse.value) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Streaming not active, returning');
        }
        return;
      }

      // Check if operation was cancelled
      if (_cancelToken?.isCancelled == true) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Operation cancelled, returning');
        }
        return;
      }

      isStreamingStructuredResponse.value = false;
      completeStructuredJson.value = completeJson;

      // Handle case where JSON is null (cancelled or incomplete)
      if (completeJson == null) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Handling null/incomplete JSON');
        }

        // Check if this is a false positive (too early completion with very little data)
        if (structuredResponseBuffer.value.length < 20) {
          if (kDebugMode && showDebugLogs) {
            print(
              '[DEBUG] [StreamingHandler] - Buffer too small for completion (${structuredResponseBuffer.value.length} chars), ignoring false positive',
            );
          }
          // Don't handle as incomplete - this might be a false positive early completion
          // Keep streaming active and wait for more data or real completion
          isStreamingStructuredResponse.value = true; // Keep streaming active
          return;
        }

        _handleIncompleteJson();
        return;
      }

      // Process the complete structured response
      _processCompleteStructuredResponse(completeJson);

      // Mark operation as complete and stop typing indicator
      markSessionAsUpdated();
      sessionHandler.saveCurrentSession();

      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [StreamingHandler] - Structured response completed, stopping typing indicator',
        );
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Error processing complete JSON: $e');
      }
      _handleJsonProcessingError(e);
    } finally {
      // Clean up streaming variables and STOP TYPING INDICATOR
      currentJsonChunk.value = '';
      structuredResponseBuffer.value = '';

      // Only stop typing indicator if we're not in a false positive scenario
      // Check if we handled this as a false positive above
      if (!isStreamingStructuredResponse.value) {
        // This is critical - stop typing indicator when structured response completes
        isTyping.value = false;

        // Also reset tool call processing state
        isProcessingToolCall.value = false;

        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Typing indicator stopped in onStreamingJsonComplete');
          print(
            '[DEBUG] [StreamingHandler] - isProcessingToolCall reset to: ${isProcessingToolCall.value}',
          );
        }
      } else {
        if (kDebugMode && showDebugLogs) {
          print(
            '[DEBUG] [StreamingHandler] - Keeping typing indicator active (false positive scenario)',
          );
        }
      }
    }
  }

  /// Callback for processing streamed AI response chunks.
  /// Updates the message text in real-time as chunks arrive.
  /// Also extracts usage information when available.
  void streamedWorker(String stringPart) {
    streamedText += stringPart;

    // Try to extract usage information from the chunk
    _extractUsageFromChunk(stringPart);

    if (kDebugMode && showDebugLogs && stringPart.trim().isNotEmpty) {
      print(
        '[DEBUG] [StreamingHandler] - streamedWorker chunk: "${stringPart.length > 20 ? "${stringPart.substring(0, 20)}..." : stringPart}"',
      );
      print('[DEBUG] [StreamingHandler] - Total streamed text length: ${streamedText.length}');
      if (streamedText.contains("<think>")) {
        print('[DEBUG] [StreamingHandler] - Think block detected in stream');
      }
    }

    // Check if we need to create a new AI message (first chunk received)
    bool needsNewMessage =
        messageHandler.messages.isEmpty ||
        (messageHandler.messages.isNotEmpty &&
            messageHandler.messages[0].author.type != AuthorType.ai);

    if (needsNewMessage && streamedText.trim().isNotEmpty) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Creating new AI message for first chunk');
      }

      if (streamedText.trim().startsWith("<think>")) {
        // Create think block message
        messageHandler.addMessage(
          Message(
            author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
            type: MessageType.thinkBlock,
            text: streamedText.trim(),
            id: UuidV4().generate(),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            tokenCount: 0,
            metadata: {
              'regenerating': false,
              'thinkBlockStartTime': DateTime.now().millisecondsSinceEpoch,
            },
          ),
        );
      } else {
        // Create regular text message
        messageHandler.addMessage(
          Message(
            author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
            type: MessageType.text,
            id: UuidV4().generate(),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            text: streamedText.trim(),
            tokenCount: 0,
          ),
        );
      }
      return;
    }

    // If no messages to update, return early
    if (messageHandler.messages.isEmpty) return;

    if (streamedText.trim().startsWith("<think>")) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Handling think block creation/update');
        print(
          '[DEBUG] [StreamingHandler] - Current message type: ${messageHandler.messages[0].type}',
        );
      }

      // Handle think block creation and updates
      if (messageHandler.messages[0].type == MessageType.text &&
          messageHandler.messages[0].author.type == AuthorType.ai) {
        // Convert initial AI message to think block
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Converting AI text message to think block');
        }
        final existingMessage = messageHandler.messages[0];
        messageHandler.messages[0] = Message(
          author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
          type: MessageType.thinkBlock,
          id: existingMessage.id,
          createdAt: existingMessage.createdAt,
          text: streamedText.trim(),
          tokenCount: 0,
          metadata: {'thinkBlockStartTime': DateTime.now().millisecondsSinceEpoch},
        );
      } else if (messageHandler.messages[0].type == MessageType.thinkBlock &&
          messageHandler.messages[0].author.type == AuthorType.ai) {
        // Update existing think block content
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Updating existing think block');
        }
        final currentMessage = messageHandler.messages[0];
        messageHandler.messages[0] = currentMessage.copyWith(
          id: currentMessage.id,
          text: streamedText.trim(),
          metadata: {
            ...?currentMessage.metadata,
            'regenerating': currentMessage.metadata?['regenerating'] ?? false,
            'thinkBlockStartTime':
                currentMessage.metadata?['thinkBlockStartTime'] ??
                DateTime.now().millisecondsSinceEpoch,
          },
        );
      } else if (messageHandler.messages[0].author.type == AuthorType.user) {
        // If the first message is a user message and we're starting a think block,
        // create a new think block message
        if (kDebugMode && showDebugLogs) {
          print(
            '[DEBUG] [StreamingHandler] - Creating new think block because first message is from user',
          );
        }
        messageHandler.addMessage(
          Message(
            author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
            type: MessageType.thinkBlock,
            text: streamedText.trim(),
            id: UuidV4().generate(),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            tokenCount: 0,
            metadata: {
              'regenerating': false,
              'thinkBlockStartTime': DateTime.now().millisecondsSinceEpoch,
            },
          ),
        );
      }

      // Check if think block is complete
      if (streamedText.contains("</think>")) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Think block completion detected');
        }
        _handleThinkBlockCompletion();
      }
    } else {
      // Handle regular streaming
      _handleRegularStreaming();
    }
  }

  /// Extract usage information from streaming chunk
  void _extractUsageFromChunk(String chunk) {
    try {
      // Skip empty chunks
      if (chunk.trim().isEmpty) return;

      // Try to extract usage information based on provider
      bool usageExtracted = false;

      if (aiModel.apiModel.provider == ApiProviders.google) {
        usageExtracted = contextManager.processGoogleChunk(chunk);
      } else {
        usageExtracted = contextManager.processStreamingChunk(chunk);
      }

      if (usageExtracted && kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Usage information extracted from chunk');
        print('[DEBUG] [StreamingHandler] - Total tokens: ${contextManager.totalTokens}');
        print('[DEBUG] [StreamingHandler] - Completion tokens: ${contextManager.completionTokens}');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Error extracting usage from chunk: $e');
      }
    }
  }

  /// Handle think block completion
  void _handleThinkBlockCompletion() {
    final contentAfterThinking = streamedText.split("</think>").last.trim();

    // Mark think block timer as stopped when response starts
    if (messageHandler.messages[0].type == MessageType.thinkBlock) {
      final currentMessage = messageHandler.messages[0];
      messageHandler.messages[0] = currentMessage.copyWith(
        text: streamedText.substring(0, streamedText.indexOf("</think>") + 8),
        id: currentMessage.id,
        metadata: {
          ...?currentMessage.metadata,
          'responseStarted': true, // Flag to stop timer when response begins
          // Keep the start time for final display
          'thinkBlockStartTime': currentMessage.metadata?['thinkBlockStartTime'],
          'thinkBlockEndTime': DateTime.now().millisecondsSinceEpoch, // Add end time
        },
      );
    }

    // If there's content after thinking, add it as a new message
    if (contentAfterThinking.isNotEmpty) {
      // Insert the actual response as a new message after the think block
      messageHandler.messages.insert(
        0,
        Message(
          author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
          type: MessageType.text,
          id: UuidV4().generate(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          text: contentAfterThinking,
          tokenCount: 0,
        ),
      );

      // Update streamedText to only the content after thinking for future updates
      streamedText = contentAfterThinking;
    }
  }

  /// Handle regular streaming (non-think block)
  void _handleRegularStreaming() {
    // Critical fix: Only update messages that belong to AI, not user messages
    if (messageHandler.messages[0].type == MessageType.text &&
        messageHandler.messages[0].author.type == AuthorType.ai) {
      // Update regular AI text message content
      final currentMessage = messageHandler.messages[0];
      messageHandler.messages[0] = currentMessage.copyWith(text: streamedText.trim());
    } else if (messageHandler.messages[0].type == MessageType.thinkBlock &&
        messageHandler.messages[0].author.type == AuthorType.ai &&
        streamedText.trim().isNotEmpty) {
      // If we have a think block but new content is coming, this is post-thinking content
      // Mark think block timer as stopped and add response as new message
      final currentMessage = messageHandler.messages[0];
      messageHandler.messages[0] = currentMessage.copyWith(
        id: currentMessage.id,
        metadata: {
          ...?currentMessage.metadata,
          'responseStarted': true,
          // Keep timing metadata
          'thinkBlockStartTime': currentMessage.metadata?['thinkBlockStartTime'],
          'thinkBlockEndTime': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Insert the response content as a new message
      messageHandler.messages.insert(
        0,
        Message(
          author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
          type: MessageType.text,
          id: UuidV4().generate(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          text: streamedText.trim(),
          tokenCount: 0,
        ),
      );
    } else if (messageHandler.messages[0].author.type == AuthorType.user) {
      // If the first message is a user message, we need to create a new AI message
      // This shouldn't normally happen if needsNewMessage check works correctly,
      // but adding this as a safety measure
      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [StreamingHandler] - Safety check: Creating AI message because first message is from user',
        );
      }
      messageHandler.addMessage(
        Message(
          author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
          type: MessageType.text,
          id: UuidV4().generate(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          text: streamedText.trim(),
          tokenCount: 0,
        ),
      );
    }
  }

  /// Handle incomplete JSON
  void _handleIncompleteJson() {
    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [StreamingHandler] - _handleIncompleteJson called');
      print('[DEBUG] [StreamingHandler] - Buffer length: ${structuredResponseBuffer.value.length}');
      print(
        '[DEBUG] [StreamingHandler] - Operation cancelled: ${_cancelToken?.isCancelled == true}',
      );
    }

    // Try to parse the buffer as a complete JSON object first.
    // This now handles cases where non-JSON text (like <think> tags) precedes or follows the JSON.
    try {
      if (structuredResponseBuffer.value.trim().isNotEmpty) {
        String buffer = structuredResponseBuffer.value;
        final jsonStartIndex = buffer.indexOf('{');

        if (jsonStartIndex != -1) {
          int balance = 0;
          int jsonEndIndex = -1;

          for (int i = jsonStartIndex; i < buffer.length; i++) {
            if (buffer[i] == '{') {
              balance++;
            } else if (buffer[i] == '}') {
              balance--;
            }
            if (balance == 0) {
              jsonEndIndex = i;
              break;
            }
          }

          if (jsonEndIndex != -1) {
            String potentialJson = buffer.substring(jsonStartIndex, jsonEndIndex + 1);
            final parsedJson = jsonDecode(potentialJson);
            if (kDebugMode) {
              print(
                '[DEBUG] [StreamingHandler] - Successfully parsed (balanced) buffered JSON in _handleIncompleteJson.',
              );
            }
            _processCompleteStructuredResponse(parsedJson);
            return; // Success, so we exit here.
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[DEBUG] [StreamingHandler] - Failed to parse buffered JSON, proceeding with incomplete logic. Error: $e',
        );
      }
    }

    // Check if operation was cancelled
    if (_cancelToken?.isCancelled == true) {
      if (kDebugMode) {
        print('[DEBUG] [StreamingHandler] - Operation was cancelled, handling gracefully');
      }

      // Try to extract partial response for display
      String partialResponse = '';
      try {
        partialResponse = _extractResponseFromPartialJson(structuredResponseBuffer.value);
        partialResponse = _cleanResponseText(partialResponse);
      } catch (e) {
        if (kDebugMode) {
          print('[DEBUG] [StreamingHandler] - Could not extract partial response: $e');
        }
      }

      // Check if we need to create a new AI message or update existing one
      bool needsNewMessage =
          messageHandler.messages.isEmpty ||
          (messageHandler.messages.isNotEmpty &&
              messageHandler.messages[0].author.type != AuthorType.ai);

      if (needsNewMessage) {
        // Create new AI message if we have meaningful content
        if (partialResponse.trim().isNotEmpty) {
          messageHandler.addMessage(
            Message(
              author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
              type: MessageType.text,
              id: UuidV4().generate(),
              createdAt: DateTime.now().millisecondsSinceEpoch,
              text: partialResponse,
              tokenCount: 0,
              metadata: {
                'cancelled': true,
                'partialResponse': partialResponse,
                'isStreamingJson': false,
                'cancelTime': DateTime.now().toIso8601String(),
                'preservedContent': true,
              },
            ),
          );

          if (kDebugMode) {
            print(
              '[DEBUG] [StreamingHandler] - Created new AI message with partial response: "${partialResponse.length > 50 ? "${partialResponse.substring(0, 50)}..." : partialResponse}"',
            );
          }
        }
      } else if (messageHandler.messages.isNotEmpty) {
        // Check if we have meaningful content to preserve
        if (partialResponse.trim().isNotEmpty) {
          // Preserve the partial response without adding cancellation notice
          messageHandler.updateMessageSafely(0, partialResponse, {
            'cancelled': true,
            'partialResponse': partialResponse,
            'isStreamingJson': false,
            'cancelTime': DateTime.now().toIso8601String(),
            'preservedContent': true,
          });

          if (kDebugMode) {
            print(
              '[DEBUG] [StreamingHandler] - Preserving partial response: "${partialResponse.length > 50 ? "${partialResponse.substring(0, 50)}..." : partialResponse}"',
            );
          }
        } else {
          // No meaningful content, preserve whatever is currently in the message
          final currentMessage = messageHandler.messages[0];
          String currentText = currentMessage.text;

          messageHandler.updateMessageSafely(0, currentText, {
            'cancelled': true,
            'isStreamingJson': false,
            'cancelTime': DateTime.now().toIso8601String(),
            'preservedContent': true,
          });

          if (kDebugMode) {
            print(
              '[DEBUG] [StreamingHandler] - Preserving current message content on cancellation',
            );
          }
        }
      }
      return;
    }

    // Handle incomplete JSON (not cancelled)
    // Additional safety check: If buffer is too small, this might be a false positive
    if (structuredResponseBuffer.value.length < 10) {
      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [StreamingHandler] - Buffer too small for incomplete handling (${structuredResponseBuffer.value.length} chars), skipping',
        );
      }
      // Don't create error message for very small buffers - might be false positive
      isTyping.value = false;
      isProcessingToolCall.value = false;
      return;
    }

    String partialResponse = '';
    try {
      partialResponse = _extractResponseFromPartialJson(structuredResponseBuffer.value);
      partialResponse = _cleanResponseText(partialResponse);
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] [StreamingHandler] - Error extracting partial response: $e');
      }
    }

    // Check if we need to create a new AI message or update existing one
    bool needsNewMessage =
        messageHandler.messages.isEmpty ||
        (messageHandler.messages.isNotEmpty &&
            messageHandler.messages[0].author.type != AuthorType.ai);

    String displayText = partialResponse.trim().isNotEmpty
        ? "$partialResponse\n\n[Response incomplete]"
        : "Error: Failed to parse response";

    Map<String, dynamic> incompleteMetadata = {
      'jsonParseError': true,
      'partialResponse': partialResponse,
      'rawBuffer': structuredResponseBuffer.value,
      'errorTime': DateTime.now().toIso8601String(),
    };

    if (needsNewMessage) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Creating new AI message for incomplete JSON');
      }

      // Create new AI message for incomplete response
      messageHandler.addMessage(
        Message(
          author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
          type: MessageType.text,
          id: UuidV4().generate(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          text: displayText,
          metadata: incompleteMetadata,
          tokenCount: 0,
        ),
      );
    } else if (messageHandler.messages.isNotEmpty) {
      // Update existing AI message
      messageHandler.updateMessageSafely(0, displayText, incompleteMetadata);
    }

    // Stop typing indicator when handling incomplete JSON
    isTyping.value = false;
    isProcessingToolCall.value = false;

    // No need to clear isTypingDots metadata - typing indicator is now separate from messages

    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [StreamingHandler] - Typing indicator stopped in _handleIncompleteJson');
      print('[DEBUG] [StreamingHandler] - isProcessingToolCall reset in _handleIncompleteJson');
    }
  }

  /// Process complete structured response
  void _processCompleteStructuredResponse(Map<String, dynamic> completeJson) {
    // Extract response text from JSON (this is what user will see)
    String responseText = '';
    final responseValue = completeJson['response'];

    if (responseValue != null) {
      // Convert to string and clean aggressively
      String rawResponseText = responseValue.toString();

      // Apply multiple cleaning passes
      responseText = _cleanResponseText(rawResponseText);

      // Additional safety check - if it still has quotes, try manual removal
      if (responseText.contains('"')) {
        if (kDebugMode) {
          print(
            '[DEBUG] [StreamingHandler] - Response still contains quotes, applying manual cleaning',
          );
        }

        // Manual quote removal as last resort
        responseText = responseText.replaceAll('"', '');

        if (kDebugMode) {
          print('[DEBUG] [StreamingHandler] - After manual quote removal: "$responseText"');
        }
      }

      responseText = responseText.trim();
    }

    final toolCall = completeJson['tool_call'];

    // Create metadata for the complete response
    Map<String, dynamic> metadata = {
      'isStructuredResponse': true,
      'completeJson': completeJson, // Keep for debugging but don't show in UI
      'completionTime': DateTime.now().toIso8601String(),
      'jsonValid': true,
      'originalResponseValue': responseValue, // Keep original for debugging
    };

    // Handle tool calls if present (background processing)
    String messageId = '';
    if (toolCall != null) {
      metadata['tool_call'] = toolCall;
      metadata['tool_call_status'] = ToolCallStatus.pending.index;

      if (kDebugMode) {
        print('[DEBUG] [StreamingHandler] - Tool call detected: $toolCall');
      }
    }

    // Check if we need to create a new AI message or update existing one
    bool needsNewMessage =
        messageHandler.messages.isEmpty ||
        (messageHandler.messages.isNotEmpty &&
            messageHandler.messages[0].author.type != AuthorType.ai);

    // Prepare final display text
    String finalDisplayText = responseText;
    if (finalDisplayText.trim().isEmpty) {
      finalDisplayText = "Response completed.";
    }

    if (needsNewMessage) {
      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [StreamingHandler] - Creating new AI message for complete structured response',
        );
      }

      // Create new AI message
      final newMessage = Message(
        author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
        type: MessageType.text,
        id: UuidV4().generate(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        text: finalDisplayText,
        metadata: metadata,
        tokenCount: 0,
      );

      messageHandler.addMessage(newMessage);
      messageId = newMessage.id;
    } else {
      // Update existing AI message
      messageHandler.updateMessageSafely(0, finalDisplayText, metadata);
      if (messageHandler.messages.isNotEmpty) {
        messageId = messageHandler.messages[0].id;
      }
    }

    // Update token count for completed AI message
    _updateCompletedMessageTokenCount();
  }

  /// Handle JSON processing error
  void _handleJsonProcessingError(dynamic e) {
    // Handle parsing errors gracefully
    String partialResponse = '';
    try {
      partialResponse = _extractResponseFromPartialJson(structuredResponseBuffer.value);
      partialResponse = _cleanResponseText(partialResponse);
    } catch (extractError) {
      if (kDebugMode) {
        print('[DEBUG] [StreamingHandler] - Could not extract partial response: $extractError');
      }
    }

    // Check if we need to create a new AI message for error display
    bool needsNewMessage =
        messageHandler.messages.isEmpty ||
        (messageHandler.messages.isNotEmpty &&
            messageHandler.messages[0].author.type != AuthorType.ai);

    String displayText = partialResponse.trim().isNotEmpty
        ? "$partialResponse\n\n[Response processing error]"
        : "Error processing response";

    Map<String, dynamic> errorMetadata = {
      'processingError': true,
      'error': e.toString(),
      'partialResponse': partialResponse,
      'errorTime': DateTime.now().toIso8601String(),
    };

    if (needsNewMessage) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Creating new AI message for JSON processing error');
      }

      // Create new AI message for error
      messageHandler.addMessage(
        Message(
          author: MessageAuthor(type: AuthorType.ai, name: "Assistant"),
          type: MessageType.text,
          id: UuidV4().generate(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          text: displayText,
          metadata: errorMetadata,
          tokenCount: 0,
        ),
      );
    } else if (messageHandler.isNotEmpty) {
      // Update existing AI message
      messageHandler.updateMessageSafely(0, displayText, errorMetadata);
    }

    // Stop typing indicator when processing error occurs
    isTyping.value = false;
    isProcessingToolCall.value = false;

    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [StreamingHandler] - Typing indicator stopped in _handleJsonProcessingError');
      print(
        '[DEBUG] [StreamingHandler] - isProcessingToolCall reset in _handleJsonProcessingError',
      );
    }
  }

  /// Handle operation completion
  void _handleOperationCompletion(bool isCompleted, Duration duration) {
    bool wasCancelledByUser = _cancelToken?.isCancelled == true;

    if (!isCompleted) {
      if (wasCancelledByUser) {
        _handleCancellation(duration);
      } else {
        _handleFailure(duration);
      }
    } else {
      _handleSuccess(duration);
    }
  }

  /// Update token count for completed AI message
  void _updateCompletedMessageTokenCount() {
    try {
      if (messageHandler.isNotEmpty) {
        final latestMessage = messageHandler.messages[0];

        // Only update AI messages that don't already have a token count
        if (latestMessage.author.type == AuthorType.ai && latestMessage.tokenCount == 0) {
          // For Native Gemini API, manually calculate completion tokens if they're 0
          if (aiModel.apiModel.provider == ApiProviders.google &&
              contextManager.completionTokens == 0 &&
              streamedText.isNotEmpty) {
            if (kDebugMode && showDebugLogs) {
              print(
                '[DEBUG] [StreamingHandler] - Native Gemini completion tokens are 0, calculating manually',
              );
              print('[DEBUG] [StreamingHandler] - Streamed text length: ${streamedText.length}');
            }

            // Try to estimate completion tokens from total first
            contextManager.estimateCompletionTokensFromTotal();

            // If still 0, use streamed text length
            if (contextManager.completionTokens == 0) {
              contextManager.updateCompletionTokensFromStreamedText(streamedText);
            }
          }

          // For AI messages, try to get token count from context manager
          // If context manager has token info from API, use that; otherwise estimate
          final calculatedTokenCount = contextManager.completionTokens > 0
              ? contextManager.completionTokens
              : contextManager.countSingleMessageTokenCount(latestMessage);

          // Update the message with the calculated token count
          messageHandler.messages[0] = latestMessage.copyWith(tokenCount: calculatedTokenCount);

          if (kDebugMode && showDebugLogs) {
            print(
              '[DEBUG] [StreamingHandler] - Updated AI message token count: $calculatedTokenCount',
            );
            print(
              '[DEBUG] [StreamingHandler] - Context total tokens: ${contextManager.totalTokens}',
            );
            print(
              '[DEBUG] [StreamingHandler] - Context completion tokens: ${contextManager.completionTokens}',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Error updating message token count: $e');
      }
    }
  }

  /// Handle successful completion
  void _handleSuccess(Duration duration) {
    if (messageHandler.isNotEmpty) {
      final currentMessage = messageHandler.messages[0];
      String lastMessage = currentMessage.text;

      if (lastMessage.contains("</think>") && !lastMessage.contains("<think>")) {
        messageHandler.messages[0] = currentMessage.copyWith(
          text: "<think>$lastMessage",
          metadata: {'completed': true, 'duration': duration.inMilliseconds, 'hasThinkBlock': true},
        );
      } else {
        messageHandler.messages[0] = currentMessage.copyWith(
          metadata: {
            ...?currentMessage.metadata,
            'completed': true,
            'duration': duration.inMilliseconds,
          },
        );
      }
    }

    // Update token count for completed AI message
    _updateCompletedMessageTokenCount();

    // Session will be marked as updated in cleanup after streaming state is reset
    // Auto-save session after AI response completion
    sessionHandler.saveCurrentSession();

    if (kDebugMode) {
      print(
        '[DEBUG] [StreamingHandler] - AI operation completed successfully in ${duration.inMilliseconds}ms',
      );
    }
  }

  /// Handle cancellation
  void _handleCancellation(Duration duration) {
    if (kDebugMode) {
      print(
        '[DEBUG] [StreamingHandler] - AI operation cancelled by user after ${duration.inMilliseconds}ms',
      );
    }

    if (messageHandler.isNotEmpty) {
      final currentMessage = messageHandler.messages[0];
      _preserveContentOnCancellation(currentMessage, duration);
    }
  }

  /// Handle operation failure
  void _handleFailure(Duration duration) {
    if (kDebugMode) {
      print(
        '[DEBUG] [StreamingHandler] - AI operation failed or incomplete after ${duration.inMilliseconds}ms',
      );
    }

    errorHandler.showError('AI response failed. You can try again.');
  }

  /// Preserve content when operation is cancelled
  void _preserveContentOnCancellation(Message currentMessage, Duration duration) {
    if (currentMessage.type == MessageType.thinkBlock &&
        currentMessage.metadata?['ThinkBlock'] != null) {
      final thinkBlockContent = currentMessage.metadata?['ThinkBlock'] as String? ?? '';
      final isThinkBlockComplete =
          thinkBlockContent.contains("</think>") ||
          currentMessage.metadata?['responseStarted'] == true;

      if (!isThinkBlockComplete) {
        messageHandler.messages.removeAt(0);
        if (kDebugMode) {
          print('[DEBUG] [StreamingHandler] - Deleted incomplete think block on cancellation');
        }
      } else {
        messageHandler.messages[0] = currentMessage.copyWith(
          metadata: {
            ...?currentMessage.metadata,
            'cancelled': true,
            'duration': duration.inMilliseconds,
            'preservedContent': true,
          },
        );
      }
    } else if (currentMessage.type == MessageType.text) {
      messageHandler.messages[0] = currentMessage.copyWith(
        metadata: {
          ...?currentMessage.metadata,
          'cancelled': true,
          'duration': duration.inMilliseconds,
          'preservedContent': true,
        },
      );
    }
  }

  /// Handle DioException
  void _handleDioException(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      if (kDebugMode) {
        print('[DEBUG] [StreamingHandler] - AI operation cancelled by user');
      }
      _handleCancellationFromDio();
    } else {
      // Re-throw non-cancellation errors to be handled by the outer catch block
      throw e;
    }
  }

  /// Handle cancellation from DioException
  void _handleCancellationFromDio() {
    if (messageHandler.isNotEmpty) {
      final currentMessage = messageHandler.messages[0];

      if (currentMessage.type == MessageType.thinkBlock &&
          currentMessage.metadata?['ThinkBlock'] != null) {
        final thinkBlockContent = currentMessage.metadata?['ThinkBlock'] as String? ?? '';
        final isThinkBlockComplete =
            thinkBlockContent.contains("</think>") ||
            currentMessage.metadata?['responseStarted'] == true;

        if (!isThinkBlockComplete) {
          messageHandler.messages.removeAt(0);
        } else {
          messageHandler.messages[0] = currentMessage.copyWith(
            metadata: {...?currentMessage.metadata, 'cancelled': true, 'preservedContent': true},
          );
        }
      } else if (currentMessage.type == MessageType.text) {
        messageHandler.messages[0] = currentMessage.copyWith(
          metadata: {...?currentMessage.metadata, 'cancelled': true, 'preservedContent': true},
        );
      }
    }
  }

  /// Handle general exceptions
  void _handleGeneralException(dynamic e) {
    if (kDebugMode) {
      print('[DEBUG] [StreamingHandler] - Error in AI operation: $e');
    }

    // When an error occurs, remove the "thinking" message from the chat UI
    // to prevent it from getting stuck.
    if (messageHandler.isNotEmpty) {
      final currentMessage = messageHandler.messages[0];
      // We only want to remove the temporary AI message (e.g., the thinking indicator).
      if (currentMessage.author.type == AuthorType.ai) {
        messageHandler.messages.removeAt(0);
      }
    }

    // Determine the most appropriate error message to show.
    String errorMessage = "An error occurred. Please try again.";
    if (e is DioException) {
      errorMessage = _getDioErrorMessage(e);
    } else if (e is ChatException) {
      errorMessage = e.message;
    }

    // Show the error in a snackbar at the top of the screen.
    // The error is no longer displayed in a chat bubble.
    errorHandler.showError(errorMessage, exception: e is Exception ? e : Exception(e.toString()));
  }

  /// Get appropriate error message for DioException
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Connection timeout. Please check your network and try again.";
      case DioExceptionType.badResponse:
        return "Server error. Please try again later.";
      case DioExceptionType.connectionError:
        return "Network connection error. Please check your internet connection.";
      default:
        return "Network error occurred. Please try again.";
    }
  }

  /// Clean up after operation completion
  void _cleanup() {
    isTyping.value = false;
    streamedText = '';
    _cancelToken = null;

    // Reset streaming state and mark session as updated after completion
    sessionHandler.setStreamingActive(false);
    sessionHandler.markSessionAsUpdatedAfterStreaming();

    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [StreamingHandler] - Cleanup completed');
    }
  }

  /// Cancel current operation
  void cancelOperation() {
    try {
      _cancelToken?.cancel();
      isTyping.value = false;

      // Reset tool call processing state when stopped
      resetToolCallProcessingState();

      // Handle streaming structured response cancellation
      if (isStreamingStructuredResponse.value) {
        _handleStreamingCancellation();
        return;
      }

      // Handle regular message cancellation
      if (messageHandler.isNotEmpty) {
        _handleRegularCancellation();
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Error stopping operation: $e');
      }
      _ensureCleanup();
    }
  }

  /// Handle streaming response cancellation
  void _handleStreamingCancellation() {
    String partialResponse = '';
    try {
      if (structuredResponseBuffer.value.trim().isNotEmpty) {
        partialResponse = _extractResponseFromPartialJson(structuredResponseBuffer.value);
        partialResponse = _cleanResponseText(partialResponse);
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Could not extract partial response: $e');
      }
    }

    if (messageHandler.isNotEmpty) {
      final currentMessage = messageHandler.messages[0];

      // Check if this is an empty AI message that hasn't started responding yet
      if (currentMessage.type == MessageType.thinkBlock &&
          currentMessage.text.trim().isEmpty &&
          partialResponse.trim().isEmpty) {
        // This is an empty message with no content, remove it completely
        messageHandler.messages.removeAt(0);
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [StreamingHandler] - Removed empty message in streaming cancellation');
        }
      } else if (partialResponse.trim().isNotEmpty) {
        // Has some content, preserve it
        messageHandler.updateMessageSafely(0, partialResponse, {
          'cancelled': true,
          'partialResponse': partialResponse,
          'isStreamingJson': false,
          'cancelTime': DateTime.now().toIso8601String(),
          'preservedContent': true,
        });
      } else {
        // Check if current message is empty TextMessage
        if (currentMessage.type == MessageType.text &&
            (currentMessage.text.trim().isEmpty ||
                currentMessage.text.trim() == "Waiting Response...")) {
          // Empty message, remove it completely
          messageHandler.messages.removeAt(0);
          if (kDebugMode && showDebugLogs) {
            print(
              '[DEBUG] [StreamingHandler] - Removed empty AI message in streaming cancellation',
            );
          }
        } else {
          // Has some content, mark as cancelled
          if (currentMessage.type == MessageType.text) {
            messageHandler.messages[0] = currentMessage.copyWith(
              metadata: {
                ...?currentMessage.metadata,
                'cancelled': true,
                'isStreamingJson': false,
                'cancelTime': DateTime.now().toIso8601String(),
                'preservedContent': true,
              },
            );
          }
        }
      }
    }

    isStreamingStructuredResponse.value = false;
    currentJsonChunk.value = '';
    structuredResponseBuffer.value = '';
    completeStructuredJson.value = null;
  }

  /// Handle regular message cancellation
  void _handleRegularCancellation() {
    final currentMessage = messageHandler.messages[0];

    // Check if this is an empty AI message that hasn't started responding yet
    if (currentMessage.type == MessageType.thinkBlock && currentMessage.text.trim().isEmpty) {
      // This is an empty message with no content, remove it completely
      messageHandler.messages.removeAt(0);
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Removed empty message on cancellation');
      }
      return;
    }

    // Check if this is an empty TextMessage with no meaningful content
    if (currentMessage.type == MessageType.text &&
        (currentMessage.text.trim().isEmpty ||
            currentMessage.text.trim() == "Waiting Response...")) {
      // This is an empty or placeholder message, remove it completely
      messageHandler.messages.removeAt(0);
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Removed empty AI message on cancellation');
      }
      return;
    }

    // Handle messages with actual content
    if (currentMessage.type == MessageType.thinkBlock &&
        currentMessage.metadata?['ThinkBlock'] != null) {
      final thinkBlockContent = currentMessage.metadata?['ThinkBlock'] as String? ?? '';
      final isThinkBlockComplete =
          thinkBlockContent.contains("</think>") ||
          currentMessage.metadata?['responseStarted'] == true;

      if (!isThinkBlockComplete) {
        messageHandler.messages.removeAt(0);
      } else {
        messageHandler.messages[0] = currentMessage.copyWith(
          metadata: {
            ...?currentMessage.metadata,
            'cancelled': true,
            'isProcessing': false,
            'preservedContent': true,
          },
        );
      }
    } else if (currentMessage.type == MessageType.text && currentMessage.text.trim().isNotEmpty) {
      // Only preserve non-empty text messages
      messageHandler.messages[0] = currentMessage.copyWith(
        metadata: {
          ...?currentMessage.metadata,
          'cancelled': true,
          'isProcessing': false,
          'preservedContent': true,
        },
      );
    }
  }

  /// Ensure cleanup even if there's an error
  void _ensureCleanup() {
    try {
      isStreamingStructuredResponse.value = false;
      currentJsonChunk.value = '';
      structuredResponseBuffer.value = '';
      completeStructuredJson.value = null;
    } catch (cleanupError) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [StreamingHandler] - Error during cleanup: $cleanupError');
      }
    }
  }

  /// Cleans response text by removing JSON quotes and escape characters
  String _cleanResponseText(String text) {
    if (text.isEmpty) return text;

    String cleaned = text;

    // Remove all types of quotes from beginning and end
    // Handle regular quotes, smart quotes, and any other quote-like characters
    final quoteChars = ['"', "'", '"', '"', ''', ''', '`'];

    // Remove leading quotes
    bool removedLeading = true;
    while (removedLeading && cleaned.isNotEmpty) {
      removedLeading = false;
      for (String quote in quoteChars) {
        if (cleaned.startsWith(quote)) {
          cleaned = cleaned.substring(quote.length);
          removedLeading = true;
          break;
        }
      }
    }

    // Remove trailing quotes
    bool removedTrailing = true;
    while (removedTrailing && cleaned.isNotEmpty) {
      removedTrailing = false;
      for (String quote in quoteChars) {
        if (cleaned.endsWith(quote)) {
          cleaned = cleaned.substring(0, cleaned.length - quote.length);
          removedTrailing = true;
          break;
        }
      }
    }

    // Handle escaped characters
    cleaned = cleaned
        .replaceAll(r'\"', '"') // Escaped quotes
        .replaceAll(r'\n', '\n') // Escaped newlines
        .replaceAll(r'\r', '\r') // Escaped carriage returns
        .replaceAll(r'\t', '\t') // Escaped tabs
        .replaceAll(r'\\', '\\'); // Escaped backslashes

    // Final check - if it still starts/ends with any quote character, remove it
    if (cleaned.isNotEmpty) {
      String firstChar = cleaned.substring(0, 1);
      String lastChar = cleaned.substring(cleaned.length - 1);

      if (quoteChars.contains(firstChar)) {
        cleaned = cleaned.substring(1);
      }

      if (cleaned.isNotEmpty && quoteChars.contains(lastChar)) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }
    }

    return cleaned;
  }

  /// Extracts response text from partial JSON string
  String _extractResponseFromPartialJson(String partialJson) {
    try {
      if (partialJson.trim().isEmpty) return '';

      String workingJson = partialJson.trim();

      // Early validation - don't try to parse if JSON is too incomplete
      if (workingJson.length < 20) {
        // Increased minimum length to avoid premature parsing
        if (kDebugMode) {
          print(
            '[DEBUG] [StreamingHandler] - JSON too short to parse: ${workingJson.length} chars (minimum 20)',
          );
        }
        return '';
      }

      // Don't try to parse if we don't have at least the response key
      if (!workingJson.contains('"response"')) {
        if (kDebugMode) {
          print('[DEBUG] [StreamingHandler] - No response key found in JSON');
        }
        return '';
      }

      // Try regex extraction first (safer than JSON parsing for partial data)
      // Look for "response": pattern in the JSON - most specific pattern first
      final responsePattern = RegExp(r'"response"\s*:\s*"([^"]*)"');
      final match = responsePattern.firstMatch(workingJson);

      if (match != null && match.groupCount >= 1) {
        final responseText = match.group(1);
        if (responseText != null && responseText.isNotEmpty) {
          if (kDebugMode) {
            print('[DEBUG] [StreamingHandler] - Extracted via complete pattern: "$responseText"');
          }
          return responseText; // Already extracted without quotes
        }
      }

      // Try to find incomplete response (response text that's still being streamed)
      final incompletePattern = RegExp(r'"response"\s*:\s*"([^"]*)', multiLine: true);
      final incompleteMatch = incompletePattern.firstMatch(workingJson);

      if (incompleteMatch != null && incompleteMatch.groupCount >= 1) {
        final responseText = incompleteMatch.group(1);
        if (responseText != null && responseText.isNotEmpty) {
          if (kDebugMode) {
            print('[DEBUG] [StreamingHandler] - Extracted via incomplete pattern: "$responseText"');
          }
          return responseText; // Already extracted without quotes
        }
      }

      if (kDebugMode) {
        print('[DEBUG] [StreamingHandler] - No extraction method succeeded');
      }
      return '';
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] [StreamingHandler] - Error extracting response from partial JSON: $e');
        print('[DEBUG] [StreamingHandler] - Partial JSON length: ${partialJson.length}');
        print(
          '[DEBUG] [StreamingHandler] - Partial JSON preview: ${partialJson.length > 100 ? "${partialJson.substring(0, 100)}..." : partialJson}',
        );
      }
      return '';
    }
  }
}
