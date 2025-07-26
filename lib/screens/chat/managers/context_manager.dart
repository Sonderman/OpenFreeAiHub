import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/models/chat/message.dart';

/// Manages chat context and token usage based on API response data
/// Extracts and tracks total_tokens from streaming responses
class ContextManager {
  final bool showDebugLogs = false;
  // Current context token counts
  int _totalTokens = 0;
  int _promptTokens = 0;
  int _completionTokens = 0;

  // Session statistics
  int _sessionTotalTokens = 0;
  int _systemInstructionTokens = 0;

  // Context limits and warnings
  static const double warningThreshold = 0.8; // 80%
  static const double criticalThreshold = 0.95; // 95%

  // Maximum context window (can be updated based on model)
  int _maxContextTokens = 32768; // Default for most models

  // Getters for token information
  int get totalTokens => _totalTokens;
  int get promptTokens => _promptTokens;
  int get completionTokens => _completionTokens;
  int get sessionTotalTokens => _sessionTotalTokens;
  int get systemInstructionTokens => _systemInstructionTokens;
  int get maxContextTokens => _maxContextTokens;

  // Usage percentage calculations
  double get contextUsagePercentage =>
      _maxContextTokens > 0 ? _totalTokens / _maxContextTokens : 0.0;
  bool get isNearLimit => contextUsagePercentage >= warningThreshold;
  bool get isAtLimit => contextUsagePercentage >= criticalThreshold;

  // Memory efficiency check
  bool get needsContextTrimming => contextUsagePercentage > 0.9;

  ContextManager({int maxContextTokens = 32768, int systemInstructionTokens = 0}) {
    _maxContextTokens = maxContextTokens;
    _systemInstructionTokens = systemInstructionTokens;
  }

  /// Updates context limits based on AI model
  void updateModelContext({required int maxTokens}) {
    _maxContextTokens = maxTokens;
    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [ContextManager] Updated max context tokens: $_maxContextTokens');
    }
  }

  /// Extracts usage information from streaming response chunk
  /// Returns extracted usage data or null if not found
  Map<String, int>? extractUsageFromChunk(String chunk) {
    try {
      // Parse the chunk to look for usage information
      if (chunk.trim().isEmpty) return null;

      // Handle SSE format: "data: {json}"
      String jsonString = chunk;
      if (chunk.startsWith('data: ')) {
        jsonString = chunk.substring(6).trim();
      }

      if (jsonString.isEmpty || jsonString == '[DONE]') return null;

      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Check if usage information is present
      final usage = data['usage'];
      if (usage != null && usage is Map<String, dynamic>) {
        return {
          'total_tokens': usage['total_tokens'] ?? 0,
          'prompt_tokens': usage['prompt_tokens'] ?? 0,
          'completion_tokens': usage['completion_tokens'] ?? 0,
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ContextManager] Error extracting usage from chunk: $e');
      }
      return null;
    }
  }

  /// Updates context with usage information from API response
  void updateFromUsage({required int totalTokens, int? promptTokens, int? completionTokens}) {
    _totalTokens = totalTokens;
    _promptTokens = promptTokens ?? 0;
    _completionTokens = completionTokens ?? 0;

    // Update session total (accumulate over multiple interactions)
    _sessionTotalTokens += _completionTokens;

    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [ContextManager] Updated from API usage:');
      print('[DEBUG] [ContextManager] - Total tokens: $_totalTokens');
      print('[DEBUG] [ContextManager] - Prompt tokens: $_promptTokens');
      print('[DEBUG] [ContextManager] - Completion tokens: $_completionTokens');
      print('[DEBUG] [ContextManager] - Session total: $_sessionTotalTokens');
      print(
        '[DEBUG] [ContextManager] - Context usage: ${(contextUsagePercentage * 100).toStringAsFixed(1)}%',
      );
    }
  }

  /// Process a streaming chunk and update context if usage info is found
  /// Returns true if usage information was found and processed
  bool processStreamingChunk(String chunk) {
    final usage = extractUsageFromChunk(chunk);
    if (usage != null) {
      updateFromUsage(
        totalTokens: usage['total_tokens']!,
        promptTokens: usage['prompt_tokens'],
        completionTokens: usage['completion_tokens'],
      );
      return true;
    }
    return false;
  }

  /// Checks for usage information in Google provider response
  /// Google may have different usage format
  Map<String, int>? extractGoogleUsage(String chunk) {
    try {
      if (chunk.trim().isEmpty) return null;

      String jsonString = chunk;
      if (chunk.startsWith('data: ')) {
        jsonString = chunk.substring(6).trim();
      }

      if (jsonString.isEmpty || jsonString == '[DONE]') return null;

      // Skip non-JSON chunks (text content from streaming)
      if (!jsonString.startsWith('{') && !jsonString.startsWith('[')) {
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Check standard usage format first
      var usage = data['usage'];
      if (usage != null && usage is Map<String, dynamic>) {
        return {
          'total_tokens': usage['total_tokens'] ?? 0,
          'prompt_tokens': usage['prompt_tokens'] ?? 0,
          'completion_tokens': usage['completion_tokens'] ?? 0,
        };
      }

      // Check Google-specific usage format (Native Gemini API)
      usage = data['usageMetadata'];
      if (usage != null && usage is Map<String, dynamic>) {
        // Native Gemini API format
        final totalTokens = usage['totalTokenCount'] ?? 0;
        final promptTokens = usage['promptTokenCount'] ?? 0;

        // For completion tokens, calculate from total - prompt
        // Or use candidatesTokenCount if available
        int completionTokens = usage['candidatesTokenCount'] ?? 0;

        // If candidatesTokenCount is not available or is 0, calculate from total - prompt
        if (completionTokens == 0 && totalTokens > promptTokens) {
          completionTokens = totalTokens - promptTokens;
        }

        // Make sure completion tokens is not negative
        if (completionTokens < 0) completionTokens = 0;

        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [ContextManager] Native Gemini usage detected:');
          print(
            '[DEBUG] [ContextManager] - Total: $totalTokens, Prompt: $promptTokens, Completion: $completionTokens',
          );
          if (usage['candidatesTokenCount'] != null) {
            print(
              '[DEBUG] [ContextManager] - Raw candidatesTokenCount: ${usage['candidatesTokenCount']}',
            );
          }
          if (completionTokens == 0 && totalTokens == promptTokens) {
            print(
              '[DEBUG] [ContextManager] - WARNING: Completion tokens still 0, may need manual calculation',
            );
          }
        }

        return {
          'total_tokens': totalTokens,
          'prompt_tokens': promptTokens,
          'completion_tokens': completionTokens,
        };
      }

      // Check for alternative Google format
      final candidates = data['candidates'];
      if (candidates != null && candidates is List && candidates.isNotEmpty) {
        final candidate = candidates[0];
        if (candidate['tokenCount'] != null) {
          return {
            'total_tokens': candidate['tokenCount'] ?? 0,
            'prompt_tokens': 0,
            'completion_tokens': candidate['tokenCount'] ?? 0,
          };
        }
      }

      return null;
    } catch (e) {
      // Silently handle JSON parsing errors for text chunks
      // Text content chunks will naturally fail JSON parsing, which is expected
      return null;
    }
  }

  /// Process Google streaming chunk
  bool processGoogleChunk(String chunk) {
    final usage = extractGoogleUsage(chunk);
    if (usage != null) {
      updateFromUsage(
        totalTokens: usage['total_tokens']!,
        promptTokens: usage['prompt_tokens'],
        completionTokens: usage['completion_tokens'],
      );
      return true;
    }
    return false;
  }

  /// Reset context for new session
  void resetSession() {
    _totalTokens = 0;
    _promptTokens = 0;
    _completionTokens = 0;
    _sessionTotalTokens = 0;

    if (kDebugMode) {
      print('[DEBUG] [ContextManager] Session reset');
    }
  }

  /// Update session total tokens directly (for session restoration)
  void updateSessionTotalTokens(int sessionTotal) {
    _sessionTotalTokens = sessionTotal;
    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [ContextManager] Session total tokens updated to: $_sessionTotalTokens');
    }
  }

  /// Reset only completion tokens (for new AI response)
  void resetCompletion() {
    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [ContextManager] Resetting completion tokens from: $_completionTokens');
    }
    _completionTokens = 0;
    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [ContextManager] Completion tokens reset to: $_completionTokens');
    }
  }

  /// Get context status for UI display
  Map<String, dynamic> getContextStatus() {
    return {
      'totalTokens': _totalTokens,
      'promptTokens': _promptTokens,
      'completionTokens': _completionTokens,
      'sessionTotalTokens': _sessionTotalTokens,
      'maxTokens': _maxContextTokens,
      'usagePercentage': contextUsagePercentage,
      'isNearLimit': isNearLimit,
      'isAtLimit': isAtLimit,
      'needsTrimming': needsContextTrimming,
    };
  }

  /// Calculate estimated tokens for message trimming
  int getEstimatedTrimTokens() {
    if (!needsContextTrimming) return 0;

    // Calculate how many tokens to trim to get back to 70% usage
    const targetPercentage = 0.7;
    final targetTokens = (_maxContextTokens * targetPercentage).round();
    final tokensToTrim = _totalTokens - targetTokens;

    return tokensToTrim > 0 ? tokensToTrim : 0;
  }

  /// Manually calculate completion tokens for Native Gemini API
  /// Used when the API doesn't provide accurate completion token counts
  void updateCompletionTokensFromStreamedText(String streamedText) {
    try {
      // If we already have completion tokens from API, don't override
      if (_completionTokens > 0) {
        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [ContextManager] Completion tokens already set: $_completionTokens');
        }
        return;
      }

      // Calculate completion tokens based on streamed text length
      // Using approximate 4 characters per token ratio
      final estimatedCompletionTokens = (streamedText.length / 4).ceil();

      // Update completion tokens
      _completionTokens = estimatedCompletionTokens;

      // Recalculate total tokens if needed
      // For Gemini, if total was prompt + 0 completion, update it
      if (_totalTokens == _promptTokens) {
        _totalTokens = _promptTokens + _completionTokens;
      }

      // Update session total
      _sessionTotalTokens += _completionTokens;

      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ContextManager] Manually calculated completion tokens:');
        print('[DEBUG] [ContextManager] - Streamed text length: ${streamedText.length}');
        print('[DEBUG] [ContextManager] - Estimated completion tokens: $estimatedCompletionTokens');
        print('[DEBUG] [ContextManager] - Updated total tokens: $_totalTokens');
        print('[DEBUG] [ContextManager] - Updated session total: $_sessionTotalTokens');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ContextManager] Error calculating completion tokens: $e');
      }
    }
  }

  /// Alternative method to update completion tokens when API doesn't provide them
  /// Uses simple estimation based on total minus prompt tokens
  void estimateCompletionTokensFromTotal() {
    try {
      // If we already have completion tokens, don't override
      if (_completionTokens > 0) {
        return;
      }

      // If total tokens > prompt tokens, the difference should be completion tokens
      if (_totalTokens > _promptTokens) {
        final estimatedCompletion = _totalTokens - _promptTokens;
        _completionTokens = estimatedCompletion;

        // Update session total
        _sessionTotalTokens += _completionTokens;

        if (kDebugMode && showDebugLogs) {
          print('[DEBUG] [ContextManager] Estimated completion tokens from total:');
          print('[DEBUG] [ContextManager] - Total: $_totalTokens, Prompt: $_promptTokens');
          print('[DEBUG] [ContextManager] - Estimated completion: $estimatedCompletion');
          print('[DEBUG] [ContextManager] - Updated session total: $_sessionTotalTokens');
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [ContextManager] Error estimating completion tokens: $e');
      }
    }
  }

  /// Compatibility method for legacy code - delegates to updateFromUsage
  void onContextSizeChanged({required int newTokenCount}) {
    _totalTokens = newTokenCount;
    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [ContextManager] Context size changed: $_totalTokens tokens');
    }
  }

  /// Compatibility method - basic token count estimation
  /// This is a fallback when API doesn't provide usage info
  int countSingleMessageTokenCount(Message message) {
    int tokenCount = 0;
    if (message.type == MessageType.text) {
      // Basic estimation: ~4 characters per token
      tokenCount += (message.text.length / 4).ceil().toInt();
    }

    // Add estimated tokens for attachments
    if (message.metadata != null) {
      if (message.metadata!['attachedImages'] != null) {
        final images = message.metadata!['attachedImages'] as List;
        tokenCount += images.length * 170; // Estimated tokens per image
      }
      if (message.metadata!['attachedDocuments'] != null) {
        final docs = message.metadata!['attachedDocuments'] as List;
        for (var doc in docs) {
          final String extractedText = doc['extractedText'] ?? '';
          tokenCount += (extractedText.length / 4).ceil().toInt();
        }
      }
    }

    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] [ContextManager] Estimated message tokens: $tokenCount');
    }
    return tokenCount;
  }
}
