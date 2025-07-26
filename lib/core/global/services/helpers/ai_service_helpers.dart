import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/models/chat/message.dart';

/// Helper class for AI service operations and conversions
class AiServiceHelpers {
  /// Private constructor to prevent instantiation
  AiServiceHelpers._();

  /// Converts messages for native Gemini API calls
  ///
  /// @param messages - List of Message objects to convert
  /// @param systemInstruction - Optional system instruction to include
  /// @return List of Map objects ready for native Gemini API use
  static List<Map<String, dynamic>> convertMessagesToGeminiNative({
    required List<Message> messages,
  }) {
    final List<Map<String, dynamic>> convertedContents = [];

    // Convert each message individually without combining
    for (final message in messages.where((e) => e.type != MessageType.thinkBlock)) {
      final geminiContent = {
        "role": message.author.type == AuthorType.ai ? "model" : "user",
        "parts": _convertMessageToGeminiParts(message),
      };

      convertedContents.add(geminiContent);
    }

    // Return in original order (do not reverse)
    return convertedContents.reversed.toList();
  }

  /// Converts a single message to Gemini native parts format
  static List<Map<String, dynamic>> _convertMessageToGeminiParts(Message message) {
    List<Map<String, dynamic>> parts = [];

    // Add text part if not empty
    if (message.text.trim().isNotEmpty) {
      parts.add({"text": message.text});
    }

    // Handle different message types
    switch (message.type) {
      case MessageType.image:
        final imageParts = _handleImageMessageGemini(message);
        parts.addAll(imageParts);
        break;

      case MessageType.document:
        final docParts = _handleDocumentMessageGemini(message);
        parts.addAll(docParts);
        break;

      case MessageType.text:
        // Check for attached images in metadata
        if (message.attachedImages != null && message.attachedImages!.isNotEmpty) {
          final imageParts = _handleImageMessageGemini(message);
          parts.addAll(imageParts);
        }

        // Check for attached documents in metadata
        if (message.metadata != null && message.metadata!['attachedDocuments'] != null) {
          final docParts = _handleAttachedDocumentsGemini(message);
          parts.addAll(docParts);
        }
        break;

      default:
        // Already handled text above
        break;
    }

    // Ensure at least one part exists
    if (parts.isEmpty) {
      parts.add({"text": message.text.isNotEmpty ? message.text : " "});
    }

    return parts;
  }

  /// Handles image message conversion for native Gemini format
  static List<Map<String, dynamic>> _handleImageMessageGemini(Message message) {
    List<Map<String, dynamic>> parts = [];

    try {
      // Check for images in attachedImages array (new format)
      if (message.attachedImages != null && message.attachedImages!.isNotEmpty) {
        final attachedImages = message.attachedImages!;

        for (int i = 0; i < attachedImages.length; i++) {
          final imageData = attachedImages[i];
          final base64URL = base64Encode(File(imageData.path).readAsBytesSync());
          final mimeType = _detectMimeTypeFromBase64(base64URL);

          parts.add({
            "inlineData": {"mimeType": mimeType, "data": base64URL},
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] - Error processing image for Gemini native: $e');
      }
    }

    return parts;
  }

  /// Handles document message conversion for native Gemini format
  static List<Map<String, dynamic>> _handleDocumentMessageGemini(Message message) {
    List<Map<String, dynamic>> parts = [];

    try {
      if (message.metadata != null && message.metadata!['attachedDocuments'] != null) {
        final attachedDocuments = message.metadata!['attachedDocuments'] as List;
        for (var documentData in attachedDocuments) {
          final docContent = processDocumentContent(documentData);
          if (docContent.isNotEmpty) {
            parts.add({"text": docContent});
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] - Error processing document for Gemini native: $e');
      }
    }

    return parts;
  }

  /// Handles attached documents in text messages for native Gemini format
  static List<Map<String, dynamic>> _handleAttachedDocumentsGemini(Message message) {
    List<Map<String, dynamic>> parts = [];

    try {
      final attachedDocuments = message.metadata!['attachedDocuments'] as List;
      for (var documentData in attachedDocuments) {
        final docContent = processDocumentContent(documentData);
        if (docContent.isNotEmpty) {
          parts.add({"text": docContent});
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] - Error processing attached documents for Gemini native: $e');
      }
    }

    return parts;
  }

  /// Detects MIME type from base64 data signature
  static String _detectMimeTypeFromBase64(String base64Data) {
    // Remove data URL prefix if present
    String cleanData = base64Data;
    if (cleanData.startsWith('data:')) {
      final commaIndex = cleanData.indexOf(',');
      if (commaIndex != -1) {
        cleanData = cleanData.substring(commaIndex + 1);
      }
    }

    // Check base64 signature
    if (cleanData.startsWith('/9j/')) {
      return 'image/jpeg';
    } else if (cleanData.startsWith('iVBOR')) {
      return 'image/png';
    } else if (cleanData.startsWith('R0lGOD')) {
      return 'image/gif';
    } else if (cleanData.startsWith('UklGR')) {
      return 'image/webp';
    }

    // Default to JPEG if can't detect
    return 'image/jpeg';
  }

  /// Converts messages for HTTP-based API calls
  ///
  /// @param messages - List of Message objects to convert
  /// @param aiModel - AI model configuration for feature checking
  /// @return List of Map objects ready for HTTP API use
  static List<Map<String, dynamic>> convertMessagesToHttp({
    required List<Message> messages,
    required AIModel aiModel,
  }) {
    final convertedMessages = messages
        .where((e) => e.type != MessageType.thinkBlock)
        .map((message) => _convertSingleMessageToHttp(message, aiModel))
        .toList();

    return convertedMessages;
  }

  /// Converts a single Message object to HTTP format
  ///
  /// @param message - Message object to convert
  /// @param aiModel - AI model configuration for feature checking
  /// @return Map object ready for HTTP API use
  static Map<String, dynamic> _convertSingleMessageToHttp(Message message, AIModel aiModel) {
    if (message.author.type == AuthorType.ai) {
      if (message.metadata != null &&
          message.metadata!['tool_call_status'] != null &&
          message.metadata!['tool_call_status'] == ToolCallStatus.success.index) {
        return _processAiToolMessageHttp(message, aiModel);
      }
      return {"role": "assistant", "content": message.text};
    } else {
      switch (message.type) {
        case MessageType.text:
          return _handleTextMessageHttp(message, aiModel);

        case MessageType.image:
          return _handleImageMessageHttp(message, aiModel);

        case MessageType.document:
          return _handleDocumentMessageHttp(message, aiModel);

        default:
          return {"role": "user", "content": message.text};
      }
    }
  }

  static Map<String, dynamic> _processAiToolMessageHttp(Message message, AIModel aiModel) {
    final metadata = message.metadata!;

    switch (metadata['tool_call']?["name"]) {
      case "image_generation":
        if (!aiModel.features.isVision) {
          return {
            "role": "assistant",
            "content": "${message.text}\n\n[This model does not support image inputs.]",
          };
        }

        // Safely get base64 data with null check
        final base64Data = metadata['base64URL'];

        // If no base64 data is available, return text-only response
        if (base64Data == null || base64Data.toString().isEmpty) {
          return {
            "role": "assistant",
            "content": message.text.isNotEmpty ? message.text : "Image generation completed.",
          };
        }

        // Create multimodal response with image
        List<dynamic> contentParts = [];

        // Add text content if available
        if (message.text.isNotEmpty) {
          contentParts.add({
            "type": "text",
            "text": "[Assistant]\n\n${message.text}\n\n[Tool Call Response: Image Generation]",
          });
        }

        // Add image content
        contentParts.add({
          "type": "image_url",
          "image_url": {"url": base64Data.toString()},
        });

        return {"role": "user", "content": contentParts};

      case "web_search":
        // Handle web search tool responses
        return {"role": "assistant", "content": message.text};

      default:
        // Default handling for other tool calls
        return {"role": "assistant", "content": message.text};
    }
  }

  /// Enhanced text message handling with improved multimodal support
  ///
  /// @param message - Text message to convert
  /// @param aiModel - AI model configuration for feature checking
  /// @return Map object for HTTP API use
  static Map<String, dynamic> _handleTextMessageHttp(Message message, AIModel aiModel) {
    // Check if this text message has attached images or documents
    if ((message.metadata != null &&
            message.metadata!['attachedImages'] != null &&
            aiModel.features.isMultimodal) ||
        (message.metadata != null && message.metadata!['attachedDocuments'] != null)) {
      List<dynamic> contentParts = [];

      // Add text content if not empty
      if (message.text.trim().isNotEmpty) {
        contentParts.add({"type": "text", "text": message.text});
      }

      // Add image content parts if multimodal model supports it
      if (message.metadata!['attachedImages'] != null && aiModel.features.isMultimodal) {
        final attachedImages = message.metadata!['attachedImages'] as List;

        for (var imageData in attachedImages) {
          try {
            String imageUrl = imageData['base64URL'] ?? '';

            if (imageUrl.isNotEmpty) {
              contentParts.add({
                "type": "image_url",
                "image_url": {"url": imageUrl},
              });
            }
          } catch (e) {
            if (kDebugMode) {
              print('[DEBUG] - Error processing attached image: $e');
            }
            // Continue with other images
            continue;
          }
        }
      } else if (message.metadata!['attachedImages'] != null && !aiModel.features.isMultimodal) {
        // Model doesn't support images but user attached some

        // Add a note about unsupported images
        contentParts.add({
          "type": "text",
          "text": "[Note: Images were attached but this model doesn't support image analysis.]",
        });
      }

      // Add document content as text if available
      if (message.metadata!['attachedDocuments'] != null) {
        final attachedDocuments = message.metadata!['attachedDocuments'] as List;
        for (var documentData in attachedDocuments) {
          final docContent = processDocumentContent(documentData);
          contentParts.add({"type": "text", "text": docContent});
        }
      }

      // If no content parts were added, fallback to text only
      if (contentParts.isEmpty) {
        return {"role": "user", "content": message.text};
      }

      return {"role": "user", "content": contentParts};
    } else {
      // Regular text message without attachments
      return {"role": "user", "content": message.text};
    }
  }

  /// Handles image message conversion for HTTP format
  ///
  /// @param message - Image message to convert
  /// @param aiModel - AI model configuration for feature checking
  /// @return Map object for HTTP API use
  static Map<String, dynamic> _handleImageMessageHttp(Message message, AIModel aiModel) {
    if (!aiModel.features.isMultimodal) {
      return {"role": "user", "content": '[Image not supported by this model]'};
    }

    try {
      // Check for images in attachedImages array (new format)
      if (message.attachedImages != null && message.attachedImages!.isNotEmpty) {
        final attachedImages = message.attachedImages!;

        List<dynamic> contentParts = [];

        // Add text content if available
        if (message.text.trim().isNotEmpty) {
          contentParts.add({"type": "text", "text": message.text});
        }

        // Process each attached image
        for (int i = 0; i < attachedImages.length; i++) {
          final imageData = attachedImages[i];
          final base64URL = base64Encode(File(imageData.path).readAsBytesSync());

          if (base64URL.toString().isNotEmpty) {
            contentParts.add({
              "type": "image_url",
              "image_url": {"url": "data:image/${imageData.extension};base64,$base64URL"},
            });
          }
        }

        if (contentParts.isEmpty) {
          return {"role": "user", "content": '[No valid image data found]'};
        }

        return {"role": "user", "content": contentParts};
      } else {
        return {"role": "user", "content": '[No valid image data found]'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] - Error processing image message: $e');
      }
      return {"role": "user", "content": '[Error processing image]'};
    }
  }

  /// Handles document message conversion for HTTP format
  ///
  /// @param message - Document message to convert
  /// @param aiModel - AI model configuration for feature checking
  /// @return Map object for HTTP API use
  static Map<String, dynamic> _handleDocumentMessageHttp(Message message, AIModel aiModel) {
    try {
      List<dynamic> contentParts = [];

      // Add text content if available
      if (message.text.trim().isNotEmpty) {
        contentParts.add({"type": "text", "text": message.text});
      }

      // Process document content if available in metadata
      if (message.metadata != null && message.metadata!['attachedDocuments'] != null) {
        final attachedDocuments = message.metadata!['attachedDocuments'] as List;

        for (var documentData in attachedDocuments) {
          final docContent = processDocumentContent(documentData);
          contentParts.add({"type": "text", "text": docContent});
        }
      } else if (message.metadata != null) {
        // Handle single document metadata (legacy format or direct document)
        final docContent = processDocumentContent(message.metadata!);
        contentParts.add({"type": "text", "text": docContent});
      }

      // If no content parts were added, fallback to text only
      if (contentParts.isEmpty) {
        return {
          "role": "user",
          "content": message.text.isNotEmpty
              ? message.text
              : '[Document attached but content not available]',
        };
      }

      return {"role": "user", "content": contentParts};
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] - Error processing document message: $e');
      }
      return {
        "role": "user",
        "content": message.text.isNotEmpty ? message.text : '[Error processing document]',
      };
    }
  }

  /// Processes document content for AI messages
  ///
  /// @param documentData - Document metadata containing content and info
  /// @return Formatted document content string
  static String processDocumentContent(Map<String, dynamic> documentData) {
    // Check if this is a PDF with extracted text
    if (documentData['hasExtractedText'] == true &&
        documentData['extractedText'] != null &&
        documentData['extractedText'].toString().isNotEmpty) {
      // Use extracted text content for PDF documents
      final extractedText = documentData['extractedText'].toString();
      String docContent =
          "Document: ${documentData['name']} (${documentData['type']}, "
          "${(documentData['size'] / 1024).toStringAsFixed(1)} KB, "
          "${documentData['wordCount']} words)\n\n"
          "Content:\n$extractedText";
      return docContent;
    } else {
      // For other documents or PDFs without text, add metadata only
      String docContent =
          "Document attached: ${documentData['name']} "
          "(${documentData['type']}, ${(documentData['size'] / 1024).toStringAsFixed(1)} KB)";

      if (documentData['extractionError'] != null) {
        docContent += "\nNote: Text extraction failed for this PDF document.";
      }

      return docContent;
    }
  }

  /// Cleans base64 image data for Google API compatibility
  ///
  /// @param base64Data - Raw base64 image data
  /// @return Cleaned and formatted base64 data
  static String cleanBase64ForGoogle(String base64Data) {
    // Clean base64 data - remove any unwanted characters
    String cleanBase64Data = base64Data.trim();

    // Remove curly braces if present (sometimes added by mistake)
    cleanBase64Data = cleanBase64Data.replaceAll('{', '').replaceAll('}', '');

    // For Google Gemini API, ensure proper base64 format
    if (!cleanBase64Data.startsWith('data:image/')) {
      // Determine image type (default to jpeg if not specified)
      String imageType = 'jpeg';
      if (cleanBase64Data.startsWith('/9j/')) {
        imageType = 'jpeg';
      } else if (cleanBase64Data.startsWith('iVBOR')) {
        imageType = 'png';
      } else if (cleanBase64Data.startsWith('R0lGOD')) {
        imageType = 'gif';
      } else if (cleanBase64Data.startsWith('UklGR')) {
        imageType = 'webp';
      }

      cleanBase64Data = 'data:image/$imageType;base64,$cleanBase64Data';
    }

    return cleanBase64Data;
  }
}

/// Helper class for parsing streaming JSON responses that may contain markdown content
/// Handles partial JSON chunks and attempts to extract meaningful content progressively
class StreamingJsonParser {
  String _accumulatedJson = '';
  String _lastExtractedContent = '';

  /// Adds a new chunk to the accumulated JSON and attempts to extract content
  /// Returns a map with both delta and full extracted content
  Map<String, String> addChunk(String chunk) {
    _accumulatedJson += chunk;

    // Try to extract content from the current accumulated JSON
    final extractedContent = _extractContentFromPartialJson(_accumulatedJson);

    // Calculate the delta (new content since last extraction)
    String deltaContent = '';
    if (extractedContent.length > _lastExtractedContent.length) {
      deltaContent = extractedContent.substring(_lastExtractedContent.length);
    }

    // Update last extracted content
    _lastExtractedContent = extractedContent;

    return {'delta': deltaContent, 'full': extractedContent};
  }

  /// Gets just the delta content for the last chunk (for backward compatibility)
  String addChunkDelta(String chunk) {
    final result = addChunk(chunk);
    return result['delta'] ?? '';
  }

  /// Attempts to extract the response content from partial JSON
  /// Uses multiple strategies to handle incomplete JSON structures
  String _extractContentFromPartialJson(String partialJson) {
    try {
      // Strategy 1: Try to parse as complete JSON
      final parsed = jsonDecode(partialJson) as Map<String, dynamic>;
      return parsed['response']?.toString() ?? '';
    } catch (e) {
      // Strategy 2: Try to extract content using regex patterns for common structures
      return _extractUsingPatterns(partialJson);
    }
  }

  /// Extracts content using regex patterns when JSON parsing fails
  String _extractUsingPatterns(String partialJson) {
    try {
      // Pattern 1: Look for "response":"content" pattern with better handling of escaped content
      // This pattern handles escaped quotes, newlines, and other special characters
      final responsePattern = RegExp(
        r'"response"\s*:\s*"((?:[^"\\]|\\["\\/bfnrt]|\\u[0-9a-fA-F]{4})*)',
        multiLine: true,
        dotAll: true,
      );
      final match = responsePattern.firstMatch(partialJson);
      if (match != null) {
        String content = match.group(1) ?? '';
        // Unescape JSON string properly
        content = _unescapeJsonString(content);

        return content;
      }

      // Pattern 2: Look for complete response field with proper JSON structure
      // This handles multiline content including code blocks
      final completePattern = RegExp(
        r'"response"\s*:\s*"((?:[^"\\]|\\["\\/bfnrt]|\\u[0-9a-fA-F]{4})*)"',
        multiLine: true,
        dotAll: true,
      );
      final completeMatch = completePattern.firstMatch(partialJson);
      if (completeMatch != null) {
        String content = completeMatch.group(1) ?? '';
        // Unescape JSON string properly
        content = _unescapeJsonString(content);

        return content;
      }

      // Pattern 3: Fallback pattern for partial content extraction
      // This tries to extract any content after "response": even if incomplete
      final fallbackPattern = RegExp(r'"response"\s*:\s*"([^"]*)', multiLine: true, dotAll: true);
      final fallbackMatch = fallbackPattern.firstMatch(partialJson);
      if (fallbackMatch != null) {
        String content = fallbackMatch.group(1) ?? '';
        // Basic unescape for fallback
        content = content
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\r', '\r')
            .replaceAll(r'\t', '\t')
            .replaceAll(r'\"', '"')
            .replaceAll(r'\\', '\\');

        return content;
      }

      return '';
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return '';
    }
  }

  /// Properly unescapes a JSON string value
  String _unescapeJsonString(String jsonString) {
    try {
      // Handle standard JSON escape sequences
      String result = jsonString;

      // Replace escape sequences in order
      result = result.replaceAll(r'\"', '"'); // Escaped quotes
      result = result.replaceAll(r'\\', '\\'); // Escaped backslashes
      result = result.replaceAll(r'\/', '/'); // Escaped forward slashes
      result = result.replaceAll(r'\b', '\b'); // Backspace
      result = result.replaceAll(r'\f', '\f'); // Form feed
      result = result.replaceAll(r'\n', '\n'); // Newline
      result = result.replaceAll(r'\r', '\r'); // Carriage return
      result = result.replaceAll(r'\t', '\t'); // Tab

      // Handle Unicode escape sequences (\uXXXX)
      final unicodePattern = RegExp(r'\\u([0-9a-fA-F]{4})');
      result = result.replaceAllMapped(unicodePattern, (match) {
        final hexCode = match.group(1)!;
        final codePoint = int.parse(hexCode, radix: 16);
        return String.fromCharCode(codePoint);
      });

      return result;
    } catch (e) {
      // Return original string if unescaping fails
      return jsonString;
    }
  }

  /// Gets the complete accumulated JSON
  String getAccumulatedJson() => _accumulatedJson;

  /// Gets the last extracted content
  String getLastExtractedContent() => _lastExtractedContent;

  /// Resets the parser state
  void reset() {
    _accumulatedJson = '';
    _lastExtractedContent = '';
  }

  /// Attempts to parse the final complete JSON
  Map<String, dynamic>? parseComplete() {
    try {
      return jsonDecode(_accumulatedJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

class StreamingJsonHelper {
  /// Validates if a JSON string is complete and parseable
  static bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Attempts to parse partial JSON and returns the valid portion
  static Map<String, dynamic>? tryParsePartialJson(String partialJson) {
    // Try to parse as-is first
    try {
      return jsonDecode(partialJson) as Map<String, dynamic>;
    } catch (e) {
      // If that fails, try to find the last complete object
      int lastCompleteIndex = -1;
      int braceCount = 0;

      for (int i = 0; i < partialJson.length; i++) {
        if (partialJson[i] == '{') {
          braceCount++;
        } else if (partialJson[i] == '}') {
          braceCount--;
          if (braceCount == 0) {
            lastCompleteIndex = i;
          }
        }
      }

      if (lastCompleteIndex > 0) {
        try {
          final completeJson = partialJson.substring(0, lastCompleteIndex + 1);
          return jsonDecode(completeJson) as Map<String, dynamic>;
        } catch (e) {
          return null;
        }
      }

      return null;
    }
  }

  /// Formats JSON string for better display in UI
  static String formatJsonForDisplay(String jsonString) {
    try {
      final parsed = jsonDecode(jsonString);
      return JsonEncoder.withIndent('  ').convert(parsed);
    } catch (e) {
      return jsonString; // Return original if parsing fails
    }
  }
}
