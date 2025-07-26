import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/screens/chat/handlers/error_handler.dart';

/// Validation result with details about the validation outcome
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? warningMessage;
  final Map<String, dynamic>? metadata;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warningMessage,
    this.metadata,
  });

  factory ValidationResult.success({String? warning, Map<String, dynamic>? metadata}) {
    return ValidationResult(isValid: true, warningMessage: warning, metadata: metadata);
  }

  factory ValidationResult.error(String error, {Map<String, dynamic>? metadata}) {
    return ValidationResult(isValid: false, errorMessage: error, metadata: metadata);
  }

  factory ValidationResult.warning(String warning, {Map<String, dynamic>? metadata}) {
    return ValidationResult(isValid: true, warningMessage: warning, metadata: metadata);
  }
}

/// Handles all input validation for chat operations
/// Validates prompts, images, files, and other user inputs
class ValidationHandler {
  final AIModel aiModel;
  final ErrorHandler errorHandler;

  // Validation limits and constraints
  static const int maxPromptLength = 32000; // 32k characters
  static const int minPromptLength = 1;
  static const int maxImageSize = 20 * 1024 * 1024; // 20MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedFileTypes = ['pdf', 'txt', 'doc', 'docx', 'csv', 'json'];
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB

  // Content safety patterns
  static final List<RegExp> _maliciousPatterns = [
    RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'on\w+\s*=', caseSensitive: false),
    RegExp(r'eval\s*\(', caseSensitive: false),
  ];

  ValidationHandler({required this.aiModel, required this.errorHandler});

  /// Validates prompt text input
  ValidationResult validatePrompt(String prompt) {
    try {
      // Check if prompt is empty or only whitespace
      if (prompt.trim().isEmpty) {
        return ValidationResult.error('Prompt cannot be empty');
      }

      // Check minimum length
      if (prompt.trim().length < minPromptLength) {
        return ValidationResult.error('Prompt is too short');
      }

      // Check maximum length
      if (prompt.length > maxPromptLength) {
        return ValidationResult.error(
          'Prompt is too long. Maximum $maxPromptLength characters allowed, got ${prompt.length}',
        );
      }

      // Check for potentially malicious content
      final securityCheck = _checkContentSecurity(prompt);
      if (!securityCheck.isValid) {
        return securityCheck;
      }

      // Check for excessive repetition
      final repetitionCheck = _checkRepetition(prompt);
      if (!repetitionCheck.isValid) {
        return repetitionCheck;
      }

      // Check encoding and special characters
      final encodingCheck = _checkEncoding(prompt);
      if (!encodingCheck.isValid) {
        return encodingCheck;
      }

      // Performance warning for very long prompts
      if (prompt.length > maxPromptLength * 0.8) {
        return ValidationResult.warning(
          'Long prompt may affect response time',
          metadata: {'prompt_length': prompt.length},
        );
      }

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ValidationHandler] - Prompt validation passed: ${prompt.length} chars');
      }

      return ValidationResult.success(
        metadata: {'prompt_length': prompt.length, 'word_count': prompt.split(' ').length},
      );
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ValidationHandler] - Error validating prompt: $e');
      }
      return ValidationResult.error('Prompt validation failed');
    }
  }

  /// Validates image data and metadata
  ValidationResult validateImage(
    Uint8List imageData,
    String fileName, {
    String? mimeType,
    Map<String, dynamic>? metadata,
  }) {
    try {
      // Check if AI model supports images
      if (!aiModel.features.isMultimodal) {
        return ValidationResult.error('This AI model does not support image inputs');
      }

      // Check if image data is empty
      if (imageData.isEmpty) {
        return ValidationResult.error('Image data is empty');
      }

      // Check file size
      if (imageData.length > maxImageSize) {
        final sizeMB = (imageData.length / (1024 * 1024)).toStringAsFixed(1);
        final maxSizeMB = (maxImageSize / (1024 * 1024)).round();
        return ValidationResult.error(
          'Image is too large: ${sizeMB}MB. Maximum ${maxSizeMB}MB allowed',
        );
      }

      // Check file extension
      final extension = _getFileExtension(fileName).toLowerCase();
      if (!allowedImageTypes.contains(extension)) {
        return ValidationResult.error(
          'Unsupported image format: $extension. Allowed: ${allowedImageTypes.join(', ')}',
        );
      }

      // Check image format by analyzing headers
      final formatCheck = _validateImageFormat(imageData, extension);
      if (!formatCheck.isValid) {
        return formatCheck;
      }

      // Check image dimensions (basic validation)
      final dimensionsCheck = _validateImageDimensions(imageData);
      if (!dimensionsCheck.isValid) {
        return dimensionsCheck;
      }

      // Warning for large images
      if (imageData.length > maxImageSize * 0.7) {
        final sizeMB = (imageData.length / (1024 * 1024)).toStringAsFixed(1);
        return ValidationResult.warning(
          'Large image (${sizeMB}MB) may affect processing time',
          metadata: {'file_size': imageData.length, 'file_name': fileName, 'format': extension},
        );
      }

      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [ValidationHandler] - Image validation passed: $fileName (${imageData.length} bytes)',
        );
      }

      return ValidationResult.success(
        metadata: {
          'file_size': imageData.length,
          'file_name': fileName,
          'format': extension,
          'mime_type': mimeType,
        },
      );
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ValidationHandler] - Error validating image: $e');
      }
      return ValidationResult.error('Image validation failed');
    }
  }

  /// Validates multiple images for a single message
  ValidationResult validateImageList(List<Map<String, dynamic>> images) {
    try {
      // Check if AI model supports images
      if (!aiModel.features.isMultimodal) {
        return ValidationResult.error('This AI model does not support image inputs');
      }

      // Check maximum number of images
      if (images.length > maxImagesPerMessage) {
        return ValidationResult.error(
          'Too many images. Maximum $maxImagesPerMessage images per message allowed',
        );
      }

      if (images.isEmpty) {
        return ValidationResult.success();
      }

      int totalSize = 0;
      final validationResults = <String, ValidationResult>{};

      // Validate each image
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final imageData = image['data'] as Uint8List?;
        final fileName = image['name']?.toString() ?? 'image_$i';

        if (imageData == null) {
          return ValidationResult.error('Image data missing for: $fileName');
        }

        final result = validateImage(imageData, fileName);
        validationResults[fileName] = result;

        if (!result.isValid) {
          return result; // Return first error
        }

        totalSize += imageData.length;
      }

      // Check total size of all images
      const maxTotalSize = maxImageSize * 2; // 40MB total
      if (totalSize > maxTotalSize) {
        final totalSizeMB = (totalSize / (1024 * 1024)).toStringAsFixed(1);
        final maxTotalSizeMB = (maxTotalSize / (1024 * 1024)).round();
        return ValidationResult.error(
          'Total image size too large: ${totalSizeMB}MB. Maximum ${maxTotalSizeMB}MB allowed',
        );
      }

      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [ValidationHandler] - Image list validation passed: ${images.length} images',
        );
      }

      return ValidationResult.success(
        metadata: {
          'image_count': images.length,
          'total_size': totalSize,
          'validation_results': validationResults,
        },
      );
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ValidationHandler] - Error validating image list: $e');
      }
      return ValidationResult.error('Image list validation failed');
    }
  }

  /// Validates file uploads
  ValidationResult validateFile(Uint8List fileData, String fileName, {String? mimeType}) {
    try {
      // Check if file data is empty
      if (fileData.isEmpty) {
        return ValidationResult.error('File data is empty');
      }

      // Check file size
      if (fileData.length > maxFileSize) {
        final sizeMB = (fileData.length / (1024 * 1024)).toStringAsFixed(1);
        final maxSizeMB = (maxFileSize / (1024 * 1024)).round();
        return ValidationResult.error(
          'File is too large: ${sizeMB}MB. Maximum ${maxSizeMB}MB allowed',
        );
      }

      // Check file extension
      final extension = _getFileExtension(fileName).toLowerCase();
      if (!allowedFileTypes.contains(extension)) {
        return ValidationResult.error(
          'Unsupported file format: $extension. Allowed: ${allowedFileTypes.join(', ')}',
        );
      }

      // Check for potentially malicious files
      final securityCheck = _checkFileSecurity(fileData, extension);
      if (!securityCheck.isValid) {
        return securityCheck;
      }

      if (kDebugMode && showDebugLogs) {
        print(
          '[DEBUG] [ValidationHandler] - File validation passed: $fileName (${fileData.length} bytes)',
        );
      }

      return ValidationResult.success(
        metadata: {
          'file_size': fileData.length,
          'file_name': fileName,
          'format': extension,
          'mime_type': mimeType,
        },
      );
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ValidationHandler] - Error validating file: $e');
      }
      return ValidationResult.error('File validation failed');
    }
  }

  /// Validates message content before sending
  ValidationResult validateMessage(String message, {List<Map<String, dynamic>>? images}) {
    try {
      // Validate text content
      if (message.trim().isNotEmpty) {
        final promptResult = validatePrompt(message);
        if (!promptResult.isValid) {
          return promptResult;
        }
      }

      // Validate images if present
      if (images != null && images.isNotEmpty) {
        final imageResult = validateImageList(images);
        if (!imageResult.isValid) {
          return imageResult;
        }
      }

      // Check if message has any content
      if (message.trim().isEmpty && (images == null || images.isEmpty)) {
        return ValidationResult.error('Message must contain text or images');
      }

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ValidationHandler] - Message validation passed');
      }

      return ValidationResult.success(
        metadata: {
          'has_text': message.trim().isNotEmpty,
          'has_images': images?.isNotEmpty ?? false,
          'image_count': images?.length ?? 0,
        },
      );
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ValidationHandler] - Error validating message: $e');
      }
      return ValidationResult.error('Message validation failed');
    }
  }

  /// Validates AI model capabilities for specific operations
  ValidationResult validateModelCapabilities(String operation) {
    try {
      switch (operation.toLowerCase()) {
        case 'multimodal':
        case 'image':
          if (!aiModel.features.isMultimodal) {
            return ValidationResult.error('This AI model does not support image processing');
          }
          break;

        case 'streaming':
          // Most models support streaming, but we could add specific checks
          break;

        case 'function_calling':
        case 'tool_calls':
          // Check if model supports function calling
          // This would depend on your AIModel structure
          break;

        default:
          return ValidationResult.warning('Unknown operation: $operation');
      }

      return ValidationResult.success();
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ValidationHandler] - Error validating model capabilities: $e');
      }
      return ValidationResult.error('Model capability validation failed');
    }
  }

  /// Checks content for security issues
  ValidationResult _checkContentSecurity(String content) {
    for (final pattern in _maliciousPatterns) {
      if (pattern.hasMatch(content)) {
        return ValidationResult.error('Content contains potentially malicious code');
      }
    }

    // Check for suspicious patterns
    if (content.contains('data:') && content.contains('base64')) {
      if (content.length > 1000) {
        // Suspicious if very long data URL
        return ValidationResult.warning('Content contains embedded data');
      }
    }

    return ValidationResult.success();
  }

  /// Checks for excessive repetition in text
  ValidationResult _checkRepetition(String text) {
    if (text.length < 100) return ValidationResult.success();

    // Check for repeated words (simple heuristic)
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final wordCounts = <String, int>{};

    for (final word in words) {
      if (word.length > 3) {
        // Only check words longer than 3 chars
        wordCounts[word] = (wordCounts[word] ?? 0) + 1;
      }
    }

    // Check if any word appears too frequently
    final maxFrequency = (words.length * 0.3).round(); // 30% threshold
    for (final entry in wordCounts.entries) {
      if (entry.value > maxFrequency && entry.value > 10) {
        return ValidationResult.warning(
          'Text contains excessive repetition of word: "${entry.key}"',
        );
      }
    }

    return ValidationResult.success();
  }

  /// Checks text encoding and special characters
  ValidationResult _checkEncoding(String text) {
    // Check for null bytes and other problematic characters
    if (text.contains('\x00')) {
      return ValidationResult.error('Text contains null bytes');
    }

    // Check for excessive special characters
    final specialCharCount = text.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '').length;
    if (specialCharCount > text.length * 0.5) {
      return ValidationResult.warning('Text contains many special characters');
    }

    return ValidationResult.success();
  }

  /// Validates image format by checking file headers
  ValidationResult _validateImageFormat(Uint8List data, String extension) {
    if (data.length < 8) {
      return ValidationResult.error('Image file is too small to be valid');
    }

    // Check common image format signatures
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        if (data[0] != 0xFF || data[1] != 0xD8) {
          return ValidationResult.error('Invalid JPEG format');
        }
        break;
      case 'png':
        if (data[0] != 0x89 || data[1] != 0x50 || data[2] != 0x4E || data[3] != 0x47) {
          return ValidationResult.error('Invalid PNG format');
        }
        break;
      case 'gif':
        final header = String.fromCharCodes(data.take(3));
        if (header != 'GIF') {
          return ValidationResult.error('Invalid GIF format');
        }
        break;
      case 'webp':
        final riff = String.fromCharCodes(data.take(4));
        final webp = String.fromCharCodes(data.skip(8).take(4));
        if (riff != 'RIFF' || webp != 'WEBP') {
          return ValidationResult.error('Invalid WebP format');
        }
        break;
    }

    return ValidationResult.success();
  }

  /// Basic image dimension validation (placeholder)
  ValidationResult _validateImageDimensions(Uint8List data) {
    // This is a simplified check. In practice, you'd use an image library
    // to get actual dimensions and validate them

    // Check minimum file size (very basic heuristic)
    if (data.length < 1024) {
      // Less than 1KB is suspicious for an image
      return ValidationResult.warning('Image file seems very small');
    }

    return ValidationResult.success();
  }

  /// Checks files for security issues
  ValidationResult _checkFileSecurity(Uint8List data, String extension) {
    // Check for executable signatures
    if (data.length >= 2) {
      // Check for MZ header (Windows executables)
      if (data[0] == 0x4D && data[1] == 0x5A) {
        return ValidationResult.error('Executable files are not allowed');
      }
    }

    // Check for script files disguised as documents
    if (extension == 'txt' || extension == 'json') {
      final content = String.fromCharCodes(data.take(1000));
      final securityCheck = _checkContentSecurity(content);
      if (!securityCheck.isValid) {
        return securityCheck;
      }
    }

    return ValidationResult.success();
  }

  /// Extracts file extension from filename
  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return '';
    return fileName.substring(lastDot + 1);
  }

  /// Gets validation statistics for monitoring
  Map<String, dynamic> getValidationStatistics() {
    // This would track validation metrics over time
    // For now, return basic configuration info
    return {
      'max_prompt_length': maxPromptLength,
      'max_image_size_mb': (maxImageSize / (1024 * 1024)).round(),
      'max_images_per_message': maxImagesPerMessage,
      'allowed_image_types': allowedImageTypes,
      'allowed_file_types': allowedFileTypes,
      'model_supports_multimodal': aiModel.features.isMultimodal,
      'model_name': aiModel.name,
    };
  }
}
