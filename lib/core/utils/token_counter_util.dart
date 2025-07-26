import 'package:flutter/foundation.dart';
import 'package:tiktoken_tokenizer_gpt4o_o1/tiktoken_tokenizer_gpt4o_o1.dart';

class TokenCounterUtil {
  static final Tiktoken _tokenizer = Tiktoken(OpenAiModel.gpt_4o);

  // Token statistics
  int totalTokens = 0;

  void onContextSizeChanged({required int newTokenCount}) {
    totalTokens = newTokenCount;
    if (kDebugMode) {
      print('[DEBUG] [TokenCounterService] New Total tokenCount: $totalTokens');
    }
  }

  /// Count tokens in a single text string
  static int countTextTokens(String text) {
    if (text.trim().isEmpty) return 0;
    try {
      return _tokenizer.count(text);
    } catch (e) {
      if (kDebugMode) {
        print('[TokenCounterService] Error counting tokens for text: $e');
      }
      // Fallback: rough estimation (4 characters per token on average)
      return (text.length / 4).ceil();
    }
  }

  /*
  /// Count tokens for a chat message including metadata
  static int countAllMessagesTokens(List<Message> messages) {
    int tokenCount = 0;

    for (var message in messages) {
      tokenCount += message.tokenCount;
    }
    if (kDebugMode) {
      print('[DEBUG] [TokenCounterService] All Messages tokenCount: $tokenCount');
    }
    return tokenCount;
  }

  static int countSingleMessageTokenCount(Message message) {
    int tokenCount = 0;
    if (message.type == MessageType.text) {
      tokenCount += countTextTokens(message.text);
    }
    if (message.metadata != null) {
      if (message.metadata!['attachedImages'] != null) {
        tokenCount += _countImageAttachmentTokens(message.metadata!['attachedImages']);
      }
      if (message.metadata!['attachedDocuments'] != null) {
        tokenCount += _countDocumentAttachmentTokens(message.metadata!['attachedDocuments']);
      }
    }
    if (kDebugMode) {
      print('[DEBUG] [TokenCounterService] Message tokenCount: $tokenCount');
    }
    return tokenCount;
  }

  static int _countImageAttachmentTokens(List imageAttachments) {
    int tokenCount = 0;
    for (var imageAttachment in imageAttachments) {
      tokenCount += countTextTokens(imageAttachment['base64URL']);
    }
    return tokenCount;
  }

  static int _countDocumentAttachmentTokens(List documentAttachments) {
    int tokenCount = 0;
    for (var documentAttachment in documentAttachments) {
      tokenCount += countTextTokens(documentAttachment['extractedText']);
    }
    return tokenCount;
  }
*/
}
