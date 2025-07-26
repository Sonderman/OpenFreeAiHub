import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart' as dio_p;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/data/instructions/global_capable_instruction.dart';
import 'package:freeaihub/core/data/instructions/tool_call_instructions.dart';
import 'package:freeaihub/core/data/instructions/instructions_data.dart';
import 'package:freeaihub/core/global/services/helpers/ai_service_helpers.dart';
import 'package:freeaihub/core/models/ai/ai_character_model.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/models/api/api_model.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AiClientService {
  // Private fields
  final AIModel _aiModel;
  final bool showDebugLogs = true;

  /// The current AI model configuration
  AIModel get aiModel => _aiModel;

  /// Creates a new AI client service instance
  ///
  /// @param aiModel - The AI model configuration to use
  /// Must contain valid API credentials and model details
  AiClientService({required AIModel aiModel}) : _aiModel = aiModel;

  /// Sends tool call response to AI for analysis
  Future<bool> analyzeWebSearchResultsAI(
    String messageId,
    String toolCallResponse,
    String query,
    RxList<Message> messages,
    CancelToken? cancelToken, {
    required Function(String) onStreamWorker,
  }) async {
    try {
      // Get current message history (excluding the current AI message being processed)
      var history = [messages[1]]; //messages.skip(1).take(10).toList();

      // Get AI analysis
      bool isCompleted = false;

      try {
        isCompleted = await getStreamResponse(
          systemInstruction: webSearchAnalysisInstructions(
            query: query,
            scrapedDatas: toolCallResponse,
            preferredLanguage: appInstance.userPreferences.chatLanguage,
          ),
          character: null,
          worker: onStreamWorker,
          history: history,
          cancelToken: cancelToken,
          useNativeGemini: false, // Use OpenAI compatible by default for web search analysis
        );
        return isCompleted;
      } catch (clientError) {
        if (kDebugMode) {
          print('[DEBUG] - AI client service failed in web search analysis: $clientError');
          throw Exception('AI client service failed: $clientError');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] - Error in analyzeWebSearchResultsAI: $e');
      }
      rethrow;
    }
  }

  Future<Uint8List?> inChatImageGenerationHidream({
    required AIModel generationModel,
    required Object data,
    dio_p.CancelToken? cancelToken,
  }) async {
    try {
      final dio_p.Dio dio = dio_p.Dio();
      final dio_p.Response<Uint8List> res = await dio.post(
        generationModel.apiModel.baseURL,
        options: dio_p.Options(
          headers: generationModel.apiModel.headers,
          responseType: dio_p.ResponseType.bytes,
        ),
        data: jsonEncode(data),
        cancelToken: cancelToken,
      );

      // Check for successful response
      if (res.statusCode != 200) {
        return null;
      }
      return res.data;
    } catch (e) {
      // Handle cancellation specifically
      if (e is dio_p.DioException && e.type == dio_p.DioExceptionType.cancel) {
        Get.snackbar('Cancelled', 'Image generation was cancelled');
      } else {
        if (kDebugMode && showDebugLogs) {
          print(e);
        }
        Get.snackbar('Error', 'Image generation failed. Please try again');
      }
      return null;
    }
  }

  Future<Uint8List?> inChatImageGenerationPollinations({
    required AIModel generationModel,
    required Map<String, dynamic> data,
    dio_p.CancelToken? cancelToken,
  }) async {
    try {
      final uri = Uri.parse(
        '${generationModel.apiModel.baseURL}/prompt/${data["prompt"]}',
      ).replace(queryParameters: data);

      if (kDebugMode) {
        print('Pollinations API URL: $uri');
      }

      final dio_p.Dio dio = dio_p.Dio();
      final dio_p.Response<Uint8List> res = await dio.get(
        uri.toString(),
        options: dio_p.Options(
          headers: generationModel.apiModel.headers,
          responseType: dio_p.ResponseType.bytes,
        ),
        cancelToken: cancelToken,
      );

      // Check for successful response
      if (res.statusCode != 200) {
        return null;
      }
      return res.data;
    } catch (e) {
      // Handle cancellation specifically
      if (e is dio_p.DioException && e.type == dio_p.DioExceptionType.cancel) {
        Get.snackbar('Cancelled', 'Image generation was cancelled');
      } else {
        if (kDebugMode && showDebugLogs) {
          print(e);
        }
        Get.snackbar('Error', 'Image generation failed. Please try again');
      }
      return null;
    }
  }

  /// Generates an image using the AI model's image generation API
  /// [cancelToken] - Optional token to cancel the request
  /// [data] - The request payload containing image generation parameters
  /// Returns Uint8List of image bytes or null if generation fails
  Future<Uint8List?> generateTextToImage({
    dio_p.CancelToken? cancelToken,
    required Object data,
  }) async {
    try {
      final dio_p.Dio dio = dio_p.Dio();
      final dio_p.Response<Uint8List> res = await dio.post(
        aiModel.apiModel.baseURL,
        options: dio_p.Options(
          headers: aiModel.apiModel.headers,
          responseType: dio_p.ResponseType.bytes,
        ),
        data: jsonEncode(data),
        cancelToken: cancelToken,
      );

      // Check for successful response
      if (res.statusCode != 200) {
        return null;
      }
      return res.data;
    } on dio_p.DioException catch (e) {
      // Handle cancellation specifically
      if (e.type == dio_p.DioExceptionType.cancel) {
        Get.snackbar('Cancelled', 'Image generation was cancelled');
      } else {
        if (kDebugMode && showDebugLogs) {
          print(e);
        }
        Get.snackbar('Error', 'Image generation failed. Please try again');
      }
      return null;
    } catch (e) {
      // Log error in debug mode
      if (kDebugMode && showDebugLogs) {
        print(e);
      }
      Get.snackbar('Error', 'Image generation failed. Please try again');
      return null;
    }
  }

  /// Generates voice audio from text using the AI model's TTS API
  ///
  /// @param cancelToken - Optional token to cancel the request
  /// @param data - Request payload containing text and voice parameters
  /// @return Uint8List of audio bytes or null if generation fails
  Future<Uint8List?> generateTextToVoice({
    dio_p.CancelToken? cancelToken,
    required Object data,
  }) async {
    try {
      final dio_p.Dio dio = dio_p.Dio();
      final dio_p.Response<Uint8List> res = await dio.post(
        aiModel.apiModel.baseURL,
        options: dio_p.Options(
          headers: aiModel.apiModel.headers,
          responseType: dio_p.ResponseType.bytes,
        ),
        data: jsonEncode(data),
        cancelToken: cancelToken,
      );

      // Check for successful response
      if (res.statusCode != 200) {
        return null;
      }
      return res.data;
    } on dio_p.DioException catch (e) {
      // Handle cancellation specifically
      if (e.type == dio_p.DioExceptionType.cancel) {
        Get.snackbar('Cancelled', 'Voice generation was cancelled');
      }
      return null;
    } catch (e) {
      // Log error in debug mode
      if (kDebugMode && showDebugLogs) {
        print(e);
      }
      Get.snackbar('Error', 'Voice generation failed. Please try again');
      return null;
    }
  }

  /// Generates a new image based on an input image using AI
  ///
  /// @param cancelToken - Optional token to cancel the request
  /// @param data - Request payload containing input image and parameters
  /// @return Uint8List of image bytes or null if generation fails
  Future<Uint8List?> generateImageToImage({
    dio_p.CancelToken? cancelToken,
    required Object data,
  }) async {
    try {
      final dio_p.Dio dio = dio_p.Dio();
      final dio_p.Response<Uint8List> res = await dio.post(
        aiModel.apiModel.baseURL2!,
        options: dio_p.Options(
          headers: aiModel.apiModel.headers,
          responseType: dio_p.ResponseType.bytes,
        ),
        data: jsonEncode(data),
        cancelToken: cancelToken,
      );

      // Check for successful response
      if (res.statusCode != 200) {
        return null;
      }
      return res.data;
    } on dio_p.DioException catch (e) {
      // Handle cancellation specifically
      if (e.type == dio_p.DioExceptionType.cancel) {
        Get.snackbar('Cancelled', 'Image generation was cancelled');
      } else {
        if (kDebugMode && showDebugLogs) {
          print(e);
        }
        Get.snackbar('Error', 'Image generation failed. Please try again');
      }
      return null;
    } catch (e) {
      // Log error in debug mode
      if (kDebugMode && showDebugLogs) {
        print(e);
      }
      Get.snackbar('Error', 'Image generation failed. Please try again');
      return null;
    }
  }

  /// Enhances/improves a user's prompt using AI
  ///
  /// @param customModel - AI model configuration to use for enhancement
  /// @param prompt - Original prompt text to enhance
  /// @return Enhanced prompt text or null if enhancement fails
  Future<String?> enhancePrompt({
    required AIModel customModel,
    required String prompt,
    String? language,
  }) async {
    try {
      final dio_p.Dio dio = dio_p.Dio();

      final requestData = {
        "model": customModel.apiModel.modelName,
        "messages": [
          {
            "role": "system",
            "content":
                "Your only task is to enhance the prompt that provided by the user. Do not add any additional information. Just enhance the prompt in ${language ?? "English"} language.",
          },
          {
            "role": "user",
            "content":
                "Generate an enhanced version of this prompt in English (reply with only the enhanced prompt - no conversation, explanations, lead-in, bullet points, placeholders, or surrounding quotes):\n$prompt",
          },
        ],
        "temperature": 0.5,
      };

      final response = await dio.post(
        "${customModel.apiModel.baseURL}/chat/completions",
        options: dio_p.Options(headers: customModel.apiModel.headers),
        data: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData != null &&
            responseData['choices'] != null &&
            (responseData['choices'] as List).isNotEmpty &&
            responseData['choices'][0]['message'] != null &&
            responseData['choices'][0]['message']['content'] != null) {
          String? text = responseData['choices'][0]['message']['content'];
          if (text == null) return null;
          // Remove only leading and trailing double quotes
          if (text.startsWith('"')) {
            text = text.substring(1);
          }
          if (text.endsWith('"')) {
            text = text.substring(0, text.length - 1);
          }

          return text;
        }
      }
      return null;
    } catch (e) {
      // Log error in debug mode
      if (kDebugMode && showDebugLogs) {
        print(e);
      }
      return null;
    }
  }

  /// Generates a description of an image using AI vision capabilities
  ///
  /// @param customModel - AI model configuration with vision support
  /// @param base64Image - Image data encoded as base64 string
  /// @param prompt - Optional context/instructions for the description
  /// @return Image description text or null if description fails
  Future<Map<String, dynamic>?> describeImage({
    required AIModel customModel,
    required String base64Image,
    required String prompt,
  }) async {
    try {
      final dio_p.Dio dio = dio_p.Dio();

      final requestData = {
        "model": customModel.apiModel.modelName,
        "response_format": {"type": "json_object"},
        "messages": [
          {"role": "system", "content": imageDescriptionInstruction},
          {
            "role": "user",
            "content": [
              {
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,{$base64Image}", "detail": "high"},
              },
              {"type": "text", "text": "Source Instruction: $prompt"},
            ],
          },
        ],
        "temperature": 0.2,
      };

      final response = await dio.post(
        "${customModel.apiModel.baseURL}/chat/completions",
        options: dio_p.Options(headers: customModel.apiModel.headers),
        data: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData != null &&
            responseData['choices'] != null &&
            (responseData['choices'] as List).isNotEmpty &&
            responseData['choices'][0]['message'] != null &&
            responseData['choices'][0]['message']['content'] != null) {
          final output = responseData['choices'][0]['message']['content'];
          if (output != null) {
            return jsonDecode(output);
          }
        }
      }
      return null;
    } catch (e) {
      // Log error in debug mode
      if (kDebugMode && showDebugLogs) {
        print(e);
      }
      return null;
    }
  }

  /// Checks if an AI model's API endpoint is available and responsive
  ///
  /// @param model - AI model configuration to check
  /// @return True if API responds successfully, false otherwise
  static Future<bool> checkAvailability({required AIModel model}) async {
    try {
      final dio_p.Dio dio = dio_p.Dio();
      dio_p.Response response;
      if (model.apiModel.provider == ApiProviders.google) {
        response = await dio.get(
          "${model.apiModel.baseURL}/openai/models/${model.apiModel.modelName}",
          options: dio_p.Options(
            headers: {"Authorization": "Bearer ${model.apiModel.apiKey}"},
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
      } else {
        response = await dio.post(
          "${model.apiModel.baseURL}/completions",
          options: dio_p.Options(
            headers: model.apiModel.headers,
            receiveTimeout: const Duration(seconds: 10),
          ),
          data: jsonEncode({
            "model": model.apiModel.modelName,
            "stream": false,
            "prompt": "hi",
            "max_tokens": 50,
          }),
        );
      }
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  /// Gets a streaming response from the AI model with improved image support
  /// [prompt] - The user's input prompt
  /// [worker] - Callback function to handle each response chunk
  /// [history] - Chat message history for context
  /// [cancelToken] - Optional token to cancel the request
  /// [systemInstruction] - Optional custom system instruction
  /// [useNativeGemini] - Whether to use native Gemini API format (default: false)
  /// Returns true if successful, throws on error
  Future<bool> getStreamResponse({
    String? prompt,
    required AiCharacterModel? character,
    String? systemInstruction,
    required Function(String) worker,
    required List<Message> history,
    dio_p.CancelToken? cancelToken,
    Function(int)? updateTotalTokens,
    bool useNativeGemini = false,
  }) async {
    try {
      // Choose the appropriate HTTP stream response method based on provider
      if (aiModel.apiModel.provider == ApiProviders.google) {
        // Use native Gemini API if requested, otherwise use OpenAI compatible
        if (useNativeGemini) {
          return await getGeminiNativeStreamResponse(
            prompt: prompt,
            worker: worker,
            history: history,
            temperature: 0.7,
            cancelToken: cancelToken,
            systemInstruction: systemInstruction,
          );
        } else {
          return await getHttpStreamResponseGoogle(
            prompt: prompt,
            worker: worker,
            history: history,
            temperature: 0.7,
            cancelToken: cancelToken,
            systemInstruction: systemInstruction,
          );
        }
      } else {
        return await getHttpStreamResponse(
          prompt: prompt,
          worker: worker,
          history: history,
          cancelToken: cancelToken,
          systemInstruction: systemInstruction,
          character: character,
        );
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] - Error in stream response: $e');
      }
      return false;
    }
  }

  /// Gets a streaming HTTP response from the AI model with image support
  ///
  /// @param prompt - Current user prompt/message
  /// @param worker - Callback function to process each response chunk
  /// @param history - Chat message history for context including images
  /// @param cancelToken - Optional token to cancel the stream
  /// @param systemInstruction - Optional custom system instruction
  /// @param onUsageChunk - Optional callback for usage information extraction
  /// @return True if stream completes successfully, false on error
  Future<bool> getHttpStreamResponse({
    required String? prompt,
    required AiCharacterModel? character,
    required Function(String) worker,
    required List<Message> history,
    dio_p.CancelToken? cancelToken,
    String? systemInstruction,
    Function(String)? onUsageChunk, // Callback for usage information
  }) async {
    try {
      // Convert chat history to HTTP message format using helper
      final historyMessages = AiServiceHelpers.convertMessagesToHttp(
        messages: history,
        aiModel: aiModel,
      );

      // Prepare system instruction - use custom or default
      final systemMessage = {
        'role': 'system',
        'content':
            systemInstruction ??
            globalSystemInstruction(
              model: aiModel,
              datetime: DateFormat('EEEE, dd MMMM yyyy HH:mm').format(DateTime.now()),
              preferredLanguage: appInstance.userPreferences.chatLanguage,
              userName: appInstance.userPreferences.userName,
              character: character,
            ),
      };

      final data = {
        "model": aiModel.apiModel.modelName,
        "messages": [
          systemMessage,
          ...historyMessages.reversed, // Reverse to maintain proper order
        ],
        if (aiModel.features.isReasoning) "reasoning": {"effort": "high"},
        "stream": true,
        "temperature": character?.parameters.temperature ?? 0.7,
      };

      final dio_p.Dio dio = dio_p.Dio();

      final dio_p.Response response = await dio.post(
        "${aiModel.apiModel.baseURL}/chat/completions",
        options: dio_p.Options(
          headers: aiModel.apiModel.headers,
          responseType: dio_p.ResponseType.stream,
        ),
        data: jsonEncode(data),
        cancelToken: cancelToken,
      );

      // Process the streaming response with better UTF-8 handling
      String buffer = '';
      List<int> byteBuffer = [];

      await for (final chunk in response.data.stream) {
        if (cancelToken?.isCancelled == true) {
          break;
        }

        try {
          if (chunk.isEmpty) continue;

          // Add bytes to buffer
          byteBuffer.addAll(chunk);

          // Try to decode as much as possible while preserving incomplete sequences
          String decodedData = '';

          try {
            decodedData = utf8.decode(byteBuffer, allowMalformed: false);
            byteBuffer.clear();
          } catch (e) {
            // Find largest valid UTF-8 sequence
            int bestValidIndex = 0;
            String bestDecoded = '';

            for (int i = byteBuffer.length; i > 0; i--) {
              try {
                String testDecoded = utf8.decode(byteBuffer.sublist(0, i), allowMalformed: false);
                bestDecoded = testDecoded;
                bestValidIndex = i;
                break;
              } catch (e) {
                continue;
              }
            }

            if (bestValidIndex > 0) {
              decodedData = bestDecoded;
              byteBuffer = byteBuffer.sublist(bestValidIndex);
            } else {
              if (byteBuffer.length > 100) {
                decodedData = utf8.decode(byteBuffer, allowMalformed: true);
                byteBuffer.clear();
              } else {
                continue;
              }
            }
          }

          if (decodedData.isEmpty) continue;

          buffer += decodedData;

          // Process complete lines
          final lines = buffer.split('\n');

          if (!buffer.endsWith('\n')) {
            buffer = lines.last;
            lines.removeLast();
          } else {
            buffer = '';
          }

          for (String line in lines) {
            line = line.trim();
            if (line.isEmpty) continue;

            if (line.contains('[DONE]')) {
              if (kDebugMode && showDebugLogs) {
                print('[DEBUG] - Stream completed with [DONE] signal');
              }
              return true;
            }

            if (line.startsWith('data: ')) {
              final jsonString = line.substring(6).trim();
              if (jsonString.isEmpty) continue;

              // Call usage callback if provided (for context tracking)
              onUsageChunk?.call(line);

              try {
                final Map<String, dynamic> jsonData = jsonDecode(jsonString);

                // Extract content from stream
                if (jsonData['choices'] != null &&
                    (jsonData['choices'] as List).isNotEmpty &&
                    jsonData['choices'][0]['delta'] != null &&
                    jsonData['choices'][0]['delta']['content'] != null) {
                  final String content = jsonData['choices'][0]['delta']['content'];
                  if (content.isNotEmpty) {
                    worker(content);
                  }
                }
              } catch (parseError) {
                if (kDebugMode && showDebugLogs) {
                  print('[DEBUG] - Error parsing chunk JSON: $parseError');
                }
                continue;
              }
            }
          }
        } catch (e) {
          if (kDebugMode && showDebugLogs) {
            print('[DEBUG] - Error processing stream chunk: $e');
          }
        }
      }

      return true;
    } on dio_p.DioException catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] - DioException in OpenAI compatible Gemini stream: $e');
        if (e.response != null) {
          print('[DEBUG] - Status Code: ${e.response?.statusCode}');
          print('[DEBUG] - Request URL: ${e.requestOptions.uri}');
          print('[DEBUG] - Error Response: ${e.response?.data}');
        }
      }
      // Re-throw the exception to be handled by the StreamingHandler
      rethrow;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] - Unexpected error in getHttpStreamResponse: $e');
      }
      // Re-throw the exception to be handled by the StreamingHandler
      rethrow;
    }
  }

  /// Native Gemini API streaming response using original Gemini format
  /// This method uses the native Gemini API format instead of OpenAI compatibility layer
  Future<bool> getGeminiNativeStreamResponse({
    required String? prompt,
    required Function(String) worker,
    required List<Message> history,
    double temperature = 0.7,
    dio_p.CancelToken? cancelToken,
    String? systemInstruction,
    Function(String)? onUsageChunk,
  }) async {
    // Prepare system instruction
    final systemInstructionText =
        systemInstruction ??
        globalSystemInstruction(
          model: aiModel,
          datetime: DateFormat('EEEE, dd MMMM yyyy HH:mm').format(DateTime.now()),
          preferredLanguage: appInstance.userPreferences.chatLanguage,
          userName: appInstance.userPreferences.userName,
        );

    List<Message> combinedHistory = List.from(history);

    if (prompt != null && prompt.trim().isNotEmpty) {
      final currentUserMessage = Message(
        id: 'current_${DateTime.now().millisecondsSinceEpoch}',
        text: prompt,
        author: MessageAuthor(type: AuthorType.user),
        type: MessageType.text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        tokenCount: 0,
      );
      combinedHistory.add(currentUserMessage);
    }

    try {
      final supportsSystemInstruction = !aiModel.apiModel.modelName.toLowerCase().contains('gemma');

      if (!supportsSystemInstruction && systemInstructionText.isNotEmpty) {
        final systemMessage = Message(
          id: 'system_${DateTime.now().millisecondsSinceEpoch}',
          text: systemInstructionText,
          author: MessageAuthor(type: AuthorType.user),
          type: MessageType.text,
          tokenCount: 0,
        );
        combinedHistory.add(systemMessage);
      }

      final geminiContents = AiServiceHelpers.convertMessagesToGeminiNative(
        messages: combinedHistory,
      );

      final requestData = {
        "contents": geminiContents,
        "generationConfig": {
          "temperature": temperature,
          "maxOutputTokens": 8192,
          "responseMimeType": "text/plain",
        },
        if (supportsSystemInstruction)
          "systemInstruction": {
            "parts": [
              {"text": systemInstructionText},
            ],
          },
      };

      final dio_p.Dio dio = dio_p.Dio();
      final dio_p.Response response = await dio.post(
        "https://generativelanguage.googleapis.com/v1beta/models/${aiModel.apiModel.modelName}:streamGenerateContent?key=${aiModel.apiModel.apiKey}",
        options: dio_p.Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          responseType: dio_p.ResponseType.stream,
        ),
        data: jsonEncode(requestData),
        cancelToken: cancelToken,
      );

      String buffer = '';
      List<int> byteBuffer = [];

      await for (final data in response.data.stream) {
        if (cancelToken?.isCancelled == true) {
          break;
        }

        try {
          if (data.isEmpty) continue;

          byteBuffer.addAll(data);
          String decodedData = '';

          try {
            decodedData = utf8.decode(byteBuffer, allowMalformed: false);
            byteBuffer.clear();
          } catch (e) {
            int bestValidIndex = 0;
            String bestDecoded = '';

            for (int i = byteBuffer.length; i > 0; i--) {
              try {
                String testDecoded = utf8.decode(byteBuffer.sublist(0, i), allowMalformed: false);
                bestDecoded = testDecoded;
                bestValidIndex = i;
                break;
              } catch (e) {
                continue;
              }
            }

            if (bestValidIndex > 0) {
              decodedData = bestDecoded;
              byteBuffer = byteBuffer.sublist(bestValidIndex);
            } else {
              if (byteBuffer.length > 100) {
                decodedData = utf8.decode(byteBuffer, allowMalformed: true);
                byteBuffer.clear();
              } else {
                continue;
              }
            }
          }

          if (decodedData.isEmpty) continue;
          buffer += decodedData;

          String tempBuffer = '';
          int braceCount = 0;
          bool inString = false;
          bool escapeNext = false;

          for (int i = 0; i < buffer.length; i++) {
            final char = buffer[i];
            tempBuffer += char;

            if (escapeNext) {
              escapeNext = false;
              continue;
            }

            if (char == '\\' && inString) {
              escapeNext = true;
              continue;
            }

            if (char == '"') {
              inString = !inString;
            }

            if (!inString) {
              if (char == '{') {
                braceCount++;
              } else if (char == '}') {
                braceCount--;

                if (braceCount == 0 && tempBuffer.trim().isNotEmpty) {
                  var jsonString = tempBuffer.trim();
                  if (jsonString.startsWith(',')) {
                    jsonString = jsonString.substring(1).trim();
                  }

                  if (jsonString.isEmpty) {
                    tempBuffer = '';
                    braceCount = 0;
                    buffer = buffer.substring(i + 1);
                    i = -1;
                    continue;
                  }

                  try {
                    String cleanedJsonString = jsonString.trim();
                    if (cleanedJsonString.startsWith('[{') && !cleanedJsonString.endsWith(']')) {
                      cleanedJsonString = cleanedJsonString.substring(1);
                    }
                    if (cleanedJsonString.startsWith('[{') && cleanedJsonString.endsWith('}')) {
                      cleanedJsonString = cleanedJsonString.substring(1, cleanedJsonString.length);
                    }

                    final Map<String, dynamic> jsonData = jsonDecode(cleanedJsonString);
                    onUsageChunk?.call(cleanedJsonString);

                    if (jsonData['candidates'] != null &&
                        (jsonData['candidates'] as List).isNotEmpty &&
                        jsonData['candidates'][0]['content'] != null &&
                        jsonData['candidates'][0]['content']['parts'] != null) {
                      final parts = jsonData['candidates'][0]['content']['parts'] as List;

                      for (final part in parts) {
                        if (part is Map<String, dynamic> && part['text'] != null) {
                          final String streamedText = part['text'];
                          if (streamedText.isNotEmpty && !streamedText.contains('\uFFFD')) {
                            worker(streamedText);
                          }
                        }
                      }
                    }

                    if (jsonData['candidates'] != null &&
                        (jsonData['candidates'] as List).isNotEmpty &&
                        jsonData['candidates'][0]['finishReason'] != null) {
                      final finishReason = jsonData['candidates'][0]['finishReason'];
                      if (finishReason == 'STOP' || finishReason == 'MAX_TOKENS') {
                        return true;
                      }
                    }
                  } catch (parseError) {
                    continue;
                  }

                  tempBuffer = '';
                  braceCount = 0;
                  buffer = buffer.substring(i + 1);
                  i = -1;
                  continue;
                }
              }
            }
          }

          buffer = tempBuffer;
        } catch (e) {
          if (kDebugMode && showDebugLogs) {
            print('[DEBUG] - Error processing native Gemini stream chunk: $e');
          }
        }
      }

      return true;
    } on dio_p.DioException catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] - DioException in native Gemini stream: $e');
      }
      return false;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] - Error in native Gemini stream response: $e');
      }
      return false;
    }
  }

  /// Enhanced Google streaming response with improved image support
  Future<bool> getHttpStreamResponseGoogle({
    required String? prompt,
    required Function(String) worker,
    required List<Message> history,
    double temperature = 0.7,
    dio_p.CancelToken? cancelToken,
    String? systemInstruction,
    Function(String)? onUsageChunk, // Callback for usage information
  }) async {
    try {
      // Convert chat history to HTTP message format for Google compatibility using helper
      final historyMessages = AiServiceHelpers.convertMessagesToHttp(
        messages: history,
        aiModel: aiModel,
      );

      // Prepare system instruction - use custom or default
      final systemRole = aiModel.apiModel.modelName.toLowerCase().contains('gemma')
          ? 'user'
          : 'system';
      final systemContent =
          systemInstruction ??
          globalSystemInstruction(
            model: aiModel,
            datetime: DateFormat('EEEE, dd MMMM yyyy HH:mm').format(DateTime.now()),
            preferredLanguage: appInstance.userPreferences.chatLanguage,
            userName: appInstance.userPreferences.userName,
          );

      // Prepare OpenAI compatible request data
      final List<Map<String, dynamic>> messages = [
        // Add system instruction if model supports it
        // Gemma models don't support system role, use user instead
        {'role': systemRole, 'content': systemContent},
        ...historyMessages.reversed, // Reverse to maintain proper order
      ];

      // Log multimodal content detection for debugging
      if (kDebugMode && showDebugLogs) {
        final hasImages = messages.any(
          (msg) =>
              msg['content'] is List &&
              (msg['content'] as List).any(
                (content) => content is Map && content['type'] == 'image_url',
              ),
        );
        if (hasImages) {
          print('[DEBUG] - Sending multimodal request to Google Gemini with images');
        }
      }

      final requestData = {
        "model": aiModel.apiModel.modelName,
        "messages": messages,
        "stream": true,
        "temperature": temperature,
      };

      // Create HTTP client and make streaming request
      final dio_p.Dio dio = dio_p.Dio();

      final dio_p.Response response = await dio.post(
        "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
        options: dio_p.Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'text/event-stream; charset=utf-8',
            'Authorization': 'Bearer ${aiModel.apiModel.apiKey}',
          },
          responseType: dio_p.ResponseType.stream,
        ),
        data: jsonEncode(requestData),
        cancelToken: cancelToken,
      );

      // Process the stream
      String buffer = ''; // Buffer to accumulate incomplete chunks
      List<int> byteBuffer = []; // Buffer for incomplete UTF-8 sequences

      await for (final data in response.data.stream) {
        if (cancelToken?.isCancelled == true) {
          break;
        }

        try {
          if (data.isEmpty) continue;

          // Add bytes to buffer
          byteBuffer.addAll(data);

          // Try to decode as much as possible while preserving incomplete sequences
          String decodedData = '';

          // Try to decode the entire buffer first
          try {
            decodedData = utf8.decode(byteBuffer, allowMalformed: false);
            byteBuffer.clear();
          } catch (e) {
            // If full decode fails, find largest valid sequence
            int bestValidIndex = 0;
            String bestDecoded = '';

            // Check from end backwards to find longest valid sequence
            for (int i = byteBuffer.length; i > 0; i--) {
              try {
                String testDecoded = utf8.decode(byteBuffer.sublist(0, i), allowMalformed: false);
                bestDecoded = testDecoded;
                bestValidIndex = i;
                break;
              } catch (e) {
                // Continue trying shorter sequences
                continue;
              }
            }

            if (bestValidIndex > 0) {
              decodedData = bestDecoded;
              byteBuffer = byteBuffer.sublist(bestValidIndex);
            } else {
              // No valid sequence found, wait for more data
              if (byteBuffer.length > 100) {
                decodedData = utf8.decode(byteBuffer, allowMalformed: true);
                byteBuffer.clear();
              } else {
                continue; // Wait for more data
              }
            }
          }

          // Only proceed if we have valid decoded data
          if (decodedData.isEmpty) continue;

          buffer += decodedData; // Add to string buffer

          // Process complete lines from buffer
          final lines = buffer.split('\n');

          // Keep the last line in buffer if it's incomplete (doesn't end with \n)
          if (!buffer.endsWith('\n')) {
            buffer = lines.last;
            lines.removeLast();
          } else {
            buffer = '';
          }

          for (String line in lines) {
            line = line.trim();
            if (line.isEmpty) continue;

            if (line.contains('[DONE]')) {
              return true;
            }

            // Parse SSE format: "data: {json}"
            if (line.startsWith('data: ')) {
              final jsonString = line.substring(6).trim();
              if (jsonString.isEmpty) continue;

              // Call usage callback if provided (for context tracking)
              onUsageChunk?.call(line);

              try {
                final Map<String, dynamic> jsonData = jsonDecode(jsonString);

                if (jsonData['choices'] != null &&
                    (jsonData['choices'] as List).isNotEmpty &&
                    jsonData['choices'][0]['delta'] != null &&
                    jsonData['choices'][0]['delta']['content'] != null) {
                  final String streamedText = jsonData['choices'][0]['delta']['content'];
                  if (streamedText.isNotEmpty) {
                    // Don't send corrupted text to worker (only actual replacement characters)
                    if (!streamedText.contains('\uFFFD')) {
                      worker(streamedText);
                    } else if (kDebugMode && showDebugLogs) {
                      print(
                        '[DEBUG] - Skipping corrupted chunk from worker: replacement character found',
                      );
                    }
                  }
                }
              } catch (parseError) {
                if (kDebugMode && showDebugLogs) {
                  // Log error for debugging purposes
                  print('[DEBUG] - Error parsing JSON: $parseError');
                  print('[DEBUG] - Raw JSON: $jsonString');
                }
                // Continue processing other lines even if one fails
                continue;
              }
            }
          }
        } catch (e) {
          if (kDebugMode && showDebugLogs) {
            print('[DEBUG] - Error processing stream chunk: $e');
          }
        }
      }

      return true;
    } on dio_p.DioException catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] - DioException in OpenAI compatible Gemini stream: $e');
        if (e.response != null) {
          print('[DEBUG] - Status Code: ${e.response?.statusCode}');
          print('[DEBUG] - Request URL: ${e.requestOptions.uri}');
          print('[DEBUG] - Error Response: ${e.response?.data}');
        }
      }
      // Re-throw the exception to be handled by the StreamingHandler
      rethrow;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] - Unexpected error in getHttpStreamResponse: $e');
      }
      // Re-throw the exception to be handled by the StreamingHandler
      rethrow;
    }
  }

  /// Enhanced structured response with image support
  Future<bool> getHttpsStructuredResponse({
    required String prompt,
    required Function(String response) onResponse,
    required List<Message> history,
    required AiCharacterModel? character,
    List<String>? tools,
    String? systemInstruction,
  }) async {
    try {
      // Convert chat history to HTTP message format using helper
      final historyMessages = AiServiceHelpers.convertMessagesToHttp(
        messages: history,
        aiModel: aiModel,
      );

      // Prepare system instruction - use custom or default
      final systemMessage = {
        'role': 'system',
        'content':
            systemInstruction ??
            globalCapableSystemInstruction(
              model: aiModel,
              datetime: DateFormat('EEEE, dd MMMM yyyy HH:mm').format(DateTime.now()),
              userName: appInstance.userPreferences.userName,
              preferredLanguage: appInstance.userPreferences.chatLanguage,
              character: character,
              tools: tools,
            ),
      };

      final data = {
        "model": aiModel.apiModel.modelName,
        "messages": [
          systemMessage,
          ...historyMessages.reversed, // Reverse to maintain proper order
        ],
        "stream": false,
        "temperature": character?.parameters.temperature ?? 0.7,
        "response_format": aiModel.apiModel.provider == ApiProviders.pollinations
            ? {"type": "json_object"}
            : ToolResponseSchema.generate(),
      };

      // Log image detection for debugging
      if (kDebugMode && showDebugLogs) {
        final hasImages = historyMessages.any(
          (msg) =>
              msg['content'] is List &&
              (msg['content'] as List).any(
                (content) => content is Map && content['type'] == 'image_url',
              ),
        );
        if (hasImages) {
          print('[DEBUG] - Sending structured request with image content to AI model');
        }
      }

      final dio_p.Dio dio = dio_p.Dio();
      final dio_p.Response response = await dio.post(
        "${aiModel.apiModel.baseURL}/chat/completions", // Ensure this is the correct endpoint
        options: dio_p.Options(headers: aiModel.apiModel.headers),
        data: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        // Ensure the response structure is correctly parsed
        final responseData = response.data;
        if (responseData != null &&
            responseData['choices'] != null &&
            (responseData['choices'] as List).isNotEmpty &&
            responseData['choices'][0]['message'] != null &&
            responseData['choices'][0]['message']['content'] != null) {
          onResponse(responseData['choices'][0]['message']['content']);
        }
        return true;
      } else {
        return false;
      }
    } catch (e, s) {
      if (kDebugMode && showDebugLogs) {
        print('Error in getStructuredResponse (dio): $e');
        print('Stack trace: $s');
        if (e is dio_p.DioException) {
          print('DioException Response: ${e.response?.data}');
        }
      }

      return false;
    }
  }

  /// Enhanced streaming structured response with image support
  Future<bool> getHttpStreamingStructuredResponse({
    required String prompt,
    required AiCharacterModel? character,
    required Function(String jsonChunk) onJsonChunk,
    required Function(Map<String, dynamic>? completeJson) onComplete,
    required List<Message> history,
    Function(String extractedContent)? onExtractedContent,

    dio_p.CancelToken? cancelToken,
    String? systemInstruction,
    List<String>? tools,
  }) async {
    try {
      // Convert chat history to HTTP message format using helper
      final historyMessages = AiServiceHelpers.convertMessagesToHttp(
        messages: history,
        aiModel: aiModel,
      );

      // Prepare system instruction - use custom or default
      final systemMessage = {
        'role': 'system',
        'content':
            systemInstruction ??
            globalCapableSystemInstruction(
              model: aiModel,
              datetime: DateFormat('EEEE, dd MMMM yyyy HH:mm').format(DateTime.now()),
              preferredLanguage: appInstance.userPreferences.chatLanguage,
              userName: appInstance.userPreferences.userName,
              character: character,
              tools: tools,
            ),
      };

      final data = {
        "model": aiModel.apiModel.modelName,
        "messages": [
          systemMessage,
          ...historyMessages.reversed, // Reverse to maintain proper order
        ],
        "stream": true,
        "temperature": character?.parameters.temperature ?? 0.7,
        "response_format": aiModel.apiModel.provider == ApiProviders.pollinations
            ? {"type": "json_object"}
            : ToolResponseSchema.generate(),
      };

      // Log image detection for debugging
      if (kDebugMode && showDebugLogs) {
        final hasImages = historyMessages.any(
          (msg) =>
              msg['content'] is List &&
              (msg['content'] as List).any(
                (content) => content is Map && content['type'] == 'image_url',
              ),
        );
        if (hasImages) {
          print('[DEBUG] - Sending streaming structured request with image content to AI model');
        }
      }

      // Create and process the stream
      final dio_p.Dio dio = dio_p.Dio();
      final stream = await dio.post(
        "${aiModel.apiModel.baseURL}/chat/completions",
        options: dio_p.Options(
          headers: aiModel.apiModel.headers,
          responseType: dio_p.ResponseType.stream,
        ),
        data: jsonEncode(data),
        cancelToken: cancelToken,
      );

      String buffer = ''; // Buffer to accumulate incomplete chunks
      List<int> byteBuffer = []; // Buffer for incomplete UTF-8 sequences
      // Initialize the streaming JSON parser for better content extraction
      final jsonParser = StreamingJsonParser();

      await for (final data in stream.data.stream) {
        if (cancelToken?.isCancelled == true) {
          break;
        }

        try {
          if (data.isEmpty) continue;

          // Add bytes to buffer
          byteBuffer.addAll(data);

          // Try to decode as much as possible while preserving incomplete sequences
          String decodedData = '';

          // Try to decode the entire buffer first
          try {
            decodedData = utf8.decode(byteBuffer, allowMalformed: false);
            byteBuffer.clear();
          } catch (e) {
            // If full decode fails, find largest valid sequence
            int bestValidIndex = 0;
            String bestDecoded = '';

            // Check from end backwards to find longest valid sequence
            for (int i = byteBuffer.length; i > 0; i--) {
              try {
                String testDecoded = utf8.decode(byteBuffer.sublist(0, i), allowMalformed: false);
                bestDecoded = testDecoded;
                bestValidIndex = i;
                break;
              } catch (e) {
                // Continue trying shorter sequences
                continue;
              }
            }

            if (bestValidIndex > 0) {
              decodedData = bestDecoded;
              byteBuffer = byteBuffer.sublist(bestValidIndex);
            } else {
              // No valid sequence found, wait for more data
              if (byteBuffer.length > 100) {
                // Prevent infinite buffer growth
                decodedData = utf8.decode(byteBuffer, allowMalformed: true);
                byteBuffer.clear();
              } else {
                continue; // Wait for more data
              }
            }
          }

          // Only proceed if we have valid decoded data
          if (decodedData.isEmpty) continue;

          buffer += decodedData;

          // Process complete lines from buffer
          final lines = buffer.split('\n');

          // Keep the last line in buffer if it's incomplete (doesn't end with \n)
          if (!buffer.endsWith('\n')) {
            buffer = lines.last;
            lines.removeLast();
          } else {
            buffer = '';
          }

          for (String line in lines) {
            line = line.trim();
            if (line.isEmpty) continue;

            if (line.contains('[DONE]')) {
              // Try to parse the complete JSON using the parser
              final completeJson = jsonParser.parseComplete();
              onComplete(completeJson);

              return true;
            }

            // Parse SSE format: "data: {json}"
            if (line.startsWith('data: ')) {
              final jsonString = line.substring(6).trim();
              if (jsonString.isEmpty) continue;

              try {
                final Map<String, dynamic> jsonData = jsonDecode(jsonString);

                if (jsonData['choices'] != null &&
                    (jsonData['choices'] as List).isNotEmpty &&
                    jsonData['choices'][0]['delta'] != null &&
                    jsonData['choices'][0]['delta']['content'] != null) {
                  final String streamedText = jsonData['choices'][0]['delta']['content'];
                  if (streamedText.isNotEmpty) {
                    // Don't send corrupted text to worker (only actual replacement characters)
                    if (!streamedText.contains('\uFFFD')) {
                      // Use the streaming parser to extract meaningful content
                      final extractionResult = jsonParser.addChunk(streamedText);
                      //final deltaContent = extractionResult['delta'] ?? '';
                      final fullContent = extractionResult['full'] ?? '';

                      // Send the raw chunk for JSON display
                      onJsonChunk(streamedText);

                      // Send extracted content to UI for progressive display
                      if (fullContent.isNotEmpty && onExtractedContent != null) {
                        onExtractedContent(fullContent);
                      }
                    }
                  }
                }
              } catch (parseError) {
                if (kDebugMode && showDebugLogs) {
                  // Log error for debugging purposes
                  print('[DEBUG] - Error parsing JSON: $parseError');
                  print('[DEBUG] - Raw JSON: $jsonString');
                }
                // Continue processing other lines even if one fails
                continue;
              }
            }
          }
        } catch (e) {
          if (kDebugMode && showDebugLogs) {
            print('[DEBUG] - Error processing stream chunk: $e');
          }
        }
      }

      // If we reach here without [DONE], try to parse accumulated JSON
      final completeJson = jsonParser.parseComplete();
      onComplete(completeJson);

      return true;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] - Error in HTTP streaming structured response: $e');
      }
      onComplete(null);
      return false;
    }
  }

  /// Gets a structured JSON response from the AI model
  /// [prompt] - The user's input prompt
  /// [onResponse] - Callback function for non-streaming mode (receives complete response)
  /// [onJsonChunk] - Optional callback for streaming mode (receives each JSON chunk)
  /// [onComplete] - Optional callback for streaming mode (receives complete parsed JSON)
  /// [onExtractedContent] - Optional callback for streaming mode (receives extracted content progressively)
  /// [history] - Chat message history for context
  /// [isStreaming] - Whether to use streaming mode (default: false)
  /// [cancelToken] - Optional token to cancel the request/stream
  /// Returns true if successful, false on error
  Future<bool> getStructuredResponse({
    required String prompt,
    required AiCharacterModel? character,
    required Function(String? response) onResponse,
    required List<Message> history,
    Function(String jsonChunk)? onJsonChunk,
    Function(Map<String, dynamic>? completeJson)? onComplete,
    Function(String extractedContent)? onExtractedContent,
    bool isStreaming = true,
    dio_p.CancelToken? cancelToken,
    List<String>? tools,
  }) async {
    // If streaming mode is requested and callbacks are provided, use streaming
    if (isStreaming && onJsonChunk != null && onComplete != null) {
      return await getHttpStreamingStructuredResponse(
        prompt: prompt,
        character: character,
        onJsonChunk: onJsonChunk,
        onComplete: onComplete,
        history: history,
        onExtractedContent: onExtractedContent,
        cancelToken: cancelToken,
        tools: tools,
      );
    }

    // Use HTTP-based structured response method instead
    try {
      return await getHttpsStructuredResponse(
        prompt: prompt,
        onResponse: onResponse,
        history: history,
        character: character,
        tools: tools,
      );
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] - Error in structured response: $e');
      }
      return false;
    }
  }
}
