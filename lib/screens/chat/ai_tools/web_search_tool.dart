import 'dart:async';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/global/services/ai_client_service.dart';
import 'package:freeaihub/core/global/services/duckduckgo_search_service.dart';
import 'package:freeaihub/core/global/services/web_scraper_service.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/core/models/tools/search/duckduckgo_search_model.dart';
import 'package:freeaihub/core/models/tools/web_scraper_model.dart';
import 'package:freeaihub/screens/chat/handlers/error_handler.dart';
import 'package:freeaihub/screens/chat/managers/session_manager.dart';
import 'package:get/get.dart';

enum WebSearchStatus { loading, scraping, analyzing, completed, noResults, error }

/// Progress callback for UI updates during web search
typedef WebSearchProgressCallback = void Function(WebSearchProgressUpdate update);

/// Progress update model for web search operations
class WebSearchProgressUpdate {
  final WebSearchStatus status;
  final String? message;
  final Map<String, dynamic>? data;

  WebSearchProgressUpdate({required this.status, this.message, this.data});
}

/// Input model for isolated web search operation
class WebSearchInput {
  final String query;
  final String region;
  final int maxResults;
  final String safeSearch;
  final int timeoutSeconds;
  final int limitToScrapeData;
  final int maxContentLength;
  final int scrapingTimeout;

  WebSearchInput({
    required this.query,
    this.region = 'us-en',
    this.maxResults = 10,
    this.safeSearch = 'moderate',
    this.timeoutSeconds = 15,
    this.limitToScrapeData = 5,
    this.maxContentLength = 3000,
    this.scrapingTimeout = 10,
  });

  /// Convert to JSON for isolate communication
  Map<String, dynamic> toJson() => {
    'query': query,
    'region': region,
    'maxResults': maxResults,
    'safeSearch': safeSearch,
    'timeoutSeconds': timeoutSeconds,
    'limitToScrapeData': limitToScrapeData,
    'maxContentLength': maxContentLength,
    'scrapingTimeout': scrapingTimeout,
  };

  /// Create from JSON for isolate communication
  factory WebSearchInput.fromJson(Map<String, dynamic> json) => WebSearchInput(
    query: json['query'],
    region: json['region'] ?? 'us-en',
    maxResults: json['maxResults'] ?? 10,
    safeSearch: json['safeSearch'] ?? 'moderate',
    timeoutSeconds: json['timeoutSeconds'] ?? 15,
    limitToScrapeData: json['limitToScrapeData'] ?? 5,
    maxContentLength: json['maxContentLength'] ?? 3000,
    scrapingTimeout: json['scrapingTimeout'] ?? 10,
  );
}

/// Result model for isolated web search operation
class WebSearchResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? searchResults;
  final List<Map<String, dynamic>>? scrapedData;
  final List<Map<String, dynamic>>? successfulScrapedData;

  WebSearchResult({
    required this.success,
    this.error,
    this.searchResults,
    this.scrapedData,
    this.successfulScrapedData,
  });

  /// Convert to JSON for isolate communication
  Map<String, dynamic> toJson() => {
    'success': success,
    'error': error,
    'searchResults': searchResults,
    'scrapedData': scrapedData,
    'successfulScrapedData': successfulScrapedData,
  };

  /// Create from JSON for isolate communication
  factory WebSearchResult.fromJson(Map<String, dynamic> json) => WebSearchResult(
    success: json['success'],
    error: json['error'],
    searchResults: json['searchResults'],
    scrapedData: json['scrapedData']?.cast<Map<String, dynamic>>(),
    successfulScrapedData: json['successfulScrapedData']?.cast<Map<String, dynamic>>(),
  );
}

/// Message types for isolate communication
enum IsolateMessageType { start, cancel, result, error, progress }

/// Message structure for isolate communication
class IsolateMessage {
  final IsolateMessageType type;
  final Map<String, dynamic>? data;

  IsolateMessage({required this.type, this.data});

  Map<String, dynamic> toJson() => {'type': type.name, 'data': data};

  factory IsolateMessage.fromJson(Map<String, dynamic> json) => IsolateMessage(
    type: IsolateMessageType.values.firstWhere((e) => e.name == json['type']),
    data: json['data'],
  );
}

/// Tool for handling web search functionality in chat
class WebSearchTool {
  final AIModel aiModel;
  final AiClientService clientService;
  final ErrorHandler errorHandler;
  final SessionManager sessionManager;

  // Web search specific variables
  String _webSearchAccumulatedText = '';
  String _headText = '';
  bool isThinkBlock = false;

  // Isolate management
  Isolate? _searchIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  WebSearchTool({
    required this.aiModel,
    required this.clientService,
    required this.errorHandler,
    required this.sessionManager,
  });

  /// Handles comprehensive web search with content scraping and AI analysis
  Future<void> handleWebSearch(
    String query,
    String messageId,
    RxList<Message> messages,
    bool isReasoning,
    CancelToken cancelToken, {
    String region = 'us-en',
    required Function() resetToolCallProcessingState,
    required Function() markSessionAsUpdated,
    required Function() autoSaveSession,
    required Function() update,
  }) async {
    _headText = '';
    _webSearchAccumulatedText = '';
    try {
      // Update message metadata with loading state
      final messageIndex = messages.indexWhere((element) => element.id == messageId);
      if (messageIndex == -1) {
        throw Exception('Message not found for web search');
      }

      // Initialize message metadata if null
      if (messages[messageIndex].metadata == null) {
        messages[messageIndex] = messages[messageIndex].copyWith(metadata: {});
      }

      _headText = "${messages[messageIndex].text}\n\n";

      // Set tool call status to processing and initial loading state
      messages[messageIndex].metadata!['tool_call_status'] = ToolCallStatus.processing.index;
      messages[messageIndex].metadata!['web_search_result'] = {
        'status': WebSearchStatus.loading.name,
        'query': query,
        'region': region,
        'timestamp': DateTime.now().toIso8601String(),
      };
      update();

      // Create input for isolated operation
      final input = WebSearchInput(
        query: query,
        region: region,
        limitToScrapeData: limitToScrapeDataForWebSearch,
      );

      // Progress callback for UI updates
      void onProgress(WebSearchProgressUpdate progressUpdate) {
        if (cancelToken.isCancelled) return;

        final currentMessageIndex = messages.indexWhere((element) => element.id == messageId);
        if (currentMessageIndex == -1) return;

        if (messages[currentMessageIndex].metadata == null) {
          messages[currentMessageIndex] = messages[currentMessageIndex].copyWith(metadata: {});
        }

        // Update metadata with progress
        messages[currentMessageIndex].metadata!['web_search_result'] = {
          'status': progressUpdate.status.name,
          'query': query,
          'region': region,
          'timestamp': DateTime.now().toIso8601String(),
          ...?progressUpdate.data,
        };

        if (progressUpdate.message != null) {
          messages[currentMessageIndex].metadata!['web_search_result']!['message'] =
              progressUpdate.message;
        }

        update();
      }

      // Perform web search and scraping in cancellable isolated thread
      if (cancelToken.isCancelled) {
        // Update status to cancelled before returning
        final currentMessageIndex = messages.indexWhere((element) => element.id == messageId);
        if (currentMessageIndex != -1) {
          messages[currentMessageIndex].metadata!['tool_call_status'] =
              ToolCallStatus.cancelled.index;
          messages[currentMessageIndex].metadata!['web_search_result']['status'] =
              WebSearchStatus.error.name;
          messages[currentMessageIndex].metadata!['web_search_result']['error'] =
              'Search cancelled by user';
        }
        resetToolCallProcessingState();
        update();
        return;
      }

      final webSearchResult = await _performCancellableWebSearchInIsolate(
        input,
        onProgress,
        cancelToken,
      );

      if (cancelToken.isCancelled) {
        // Update status to cancelled before returning
        final currentMessageIndex = messages.indexWhere((element) => element.id == messageId);
        if (currentMessageIndex != -1) {
          messages[currentMessageIndex].metadata!['tool_call_status'] =
              ToolCallStatus.cancelled.index;
          messages[currentMessageIndex].metadata!['web_search_result']['status'] =
              WebSearchStatus.error.name;
          messages[currentMessageIndex].metadata!['web_search_result']['error'] =
              'Search cancelled by user';
        }
        resetToolCallProcessingState();
        update();
        return;
      }

      // Handle web search result
      if (!webSearchResult.success) {
        throw Exception(webSearchResult.error ?? 'Web search failed');
      }

      if (webSearchResult.successfulScrapedData == null ||
          webSearchResult.successfulScrapedData!.isEmpty) {
        throw Exception('No successful scraped data found');
      }

      // Update UI with scraped data before AI analysis
      onProgress(
        WebSearchProgressUpdate(
          status: WebSearchStatus.analyzing,
          data: {
            'search_results': webSearchResult.searchResults,
            'scraped_data': webSearchResult.scrapedData,
          },
        ),
      );

      if (cancelToken.isCancelled) return;

      // Format data for AI analysis
      String toolCallResponse;
      try {
        toolCallResponse = formatWebSearchDataForAI(query, webSearchResult.successfulScrapedData!);
      } catch (formatError) {
        if (kDebugMode) {
          print('[DEBUG] [WebSearch] - Error formatting data for AI: $formatError');
        }
        throw Exception('Failed to format web search data: $formatError');
      }

      if (cancelToken.isCancelled) {
        // Update status to cancelled before returning
        final currentMessageIndex = messages.indexWhere((element) => element.id == messageId);
        if (currentMessageIndex != -1) {
          messages[currentMessageIndex].metadata!['tool_call_status'] =
              ToolCallStatus.cancelled.index;
          messages[currentMessageIndex].metadata!['web_search_result']['status'] =
              WebSearchStatus.error.name;
          messages[currentMessageIndex].metadata!['web_search_result']['error'] =
              'Search cancelled by user';
        }
        resetToolCallProcessingState();
        update();
        return;
      }

      // Perform AI analysis (this stays on main thread due to streaming)
      try {
        final currentMessageIndex = messages.indexWhere((element) => element.id == messageId);
        await clientService
            .analyzeWebSearchResultsAI(
              messageId,
              toolCallResponse,
              query,
              messages,
              cancelToken,
              onStreamWorker: (stringPart) =>
                  webSearchStreamWorker(stringPart, messages, currentMessageIndex, isReasoning),
            )
            .whenComplete(() {
              final currentMessageIndex = messages.indexWhere((element) => element.id == messageId);
              if (currentMessageIndex != -1) {
                messages[currentMessageIndex].metadata!['tool_call_status'] =
                    ToolCallStatus.success.index;
              }
              markSessionAsUpdated();
              autoSaveSession();
            });
      } catch (aiError) {
        if (kDebugMode) {
          print('[DEBUG] [WebSearch] - AI analysis failed: $aiError');
        }

        // Even if AI analysis fails, show search results
        final currentMessageIndex = messages.indexWhere((element) => element.id == messageId);
        if (currentMessageIndex != -1) {
          if (messages[currentMessageIndex].metadata == null) {
            messages[currentMessageIndex] = messages[currentMessageIndex].copyWith(metadata: {});
          }
          messages[currentMessageIndex].metadata!['web_search_result']!['status'] =
              WebSearchStatus.completed.name;
          messages[currentMessageIndex].metadata!['web_search_result']!['ai_analysis_error'] =
              aiError.toString();
        }

        resetToolCallProcessingState();
        update();
        return;
      }

      // Mark as completed
      final currentMessageIndex = messages.indexWhere((element) => element.id == messageId);
      if (currentMessageIndex != -1) {
        if (messages[currentMessageIndex].metadata == null) {
          messages[currentMessageIndex] = messages[currentMessageIndex].copyWith(metadata: {});
        }
        messages[currentMessageIndex].metadata!['tool_call_status'] = ToolCallStatus.success.index;
        messages[currentMessageIndex].metadata!['web_search_result']!['status'] =
            WebSearchStatus.completed.name;
      }

      resetToolCallProcessingState();
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] [WebSearch] - Error in web search: $e');
      }

      final messageIndex = messages.indexWhere((element) => element.id == messageId);
      if (messageIndex != -1) {
        if (messages[messageIndex].metadata == null) {
          messages[messageIndex] = messages[messageIndex].copyWith(metadata: {});
        }

        // Check if this was a cancellation
        bool wasCancelled =
            cancelToken.isCancelled ||
            e.toString().contains('Operation cancelled') ||
            e.toString().contains('cancelled by user');

        if (wasCancelled) {
          // Set cancelled status
          messages[messageIndex].metadata!['tool_call_status'] = ToolCallStatus.cancelled.index;
          messages[messageIndex].metadata!['web_search_result'] = {
            'status': WebSearchStatus.error.name,
            'query': query,
            'region': region,
            'error': 'Search cancelled by user',
            'timestamp': DateTime.now().toIso8601String(),
          };
        } else {
          // Set error status for actual errors
          messages[messageIndex].metadata!['tool_call_status'] = ToolCallStatus.error.index;
          messages[messageIndex].metadata!['web_search_result'] = {
            'status': WebSearchStatus.error.name,
            'query': query,
            'region': region,
            'error': e.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          };
        }
      }

      resetToolCallProcessingState();

      // Only show error dialog for actual errors, not cancellations
      if (!cancelToken.isCancelled && !e.toString().contains('Operation cancelled')) {
        errorHandler.showError(
          'Web search failed. Please try again.',
          exception: e is Exception ? e : Exception(e.toString()),
        );
      }
    } finally {
      // Clean up isolate resources
      await _cleanupIsolate();
      update();
    }
  }

  /// Performs web search and scraping in cancellable isolated thread
  Future<WebSearchResult> _performCancellableWebSearchInIsolate(
    WebSearchInput input,
    WebSearchProgressCallback onProgress,
    CancelToken cancelToken,
  ) async {
    try {
      // Setup isolate communication
      _receivePort = ReceivePort();
      final completer = Completer<WebSearchResult>();
      bool sendPortReceived = false;

      // Listen for messages from isolate
      _receivePort!.listen((message) {
        try {
          // First message should be the SendPort from isolate
          if (!sendPortReceived && message is SendPort) {
            _sendPort = message;
            sendPortReceived = true;
            return;
          }

          // All subsequent messages should be IsolateMessage JSON
          final isolateMessage = IsolateMessage.fromJson(message);

          switch (isolateMessage.type) {
            case IsolateMessageType.result:
              if (!completer.isCompleted) {
                final result = WebSearchResult.fromJson(isolateMessage.data!);
                completer.complete(result);
              }
              break;
            case IsolateMessageType.error:
              if (!completer.isCompleted) {
                completer.complete(
                  WebSearchResult(
                    success: false,
                    error: isolateMessage.data?['error'] ?? 'Unknown error',
                  ),
                );
              }
              break;
            case IsolateMessageType.progress:
              // Handle progress updates
              final progressData = isolateMessage.data;
              if (progressData != null) {
                onProgress(
                  WebSearchProgressUpdate(
                    status: WebSearchStatus.scraping,
                    message: progressData['message'],
                    data: progressData['data'],
                  ),
                );
              }
              break;
            default:
              break;
          }
        } catch (e) {
          if (kDebugMode) {
            print('[DEBUG] [WebSearch] - Error parsing isolate message: $e');
          }
          if (!completer.isCompleted) {
            completer.complete(
              WebSearchResult(success: false, error: 'Failed to parse isolate message: $e'),
            );
          }
        }
      });

      // Spawn the isolate
      _searchIsolate = await Isolate.spawn(_isolateEntryPoint, {
        'sendPort': _receivePort!.sendPort,
        'input': input.toJson(),
      });

      // Wait for SendPort to be established
      int attempts = 0;
      while (!sendPortReceived && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (!sendPortReceived) {
        throw Exception('Failed to establish communication with isolate');
      }

      // Listen for cancellation
      late StreamSubscription cancelSubscription;
      cancelSubscription = cancelToken.whenCancel.asStream().listen((_) {
        // Send cancel message to isolate
        _sendPort?.send(IsolateMessage(type: IsolateMessageType.cancel).toJson());

        if (!completer.isCompleted) {
          completer.complete(WebSearchResult(success: false, error: 'Operation cancelled by user'));
        }

        cancelSubscription.cancel();
      });

      // Wait for result or timeout
      final result = await completer.future.timeout(
        Duration(seconds: input.timeoutSeconds + 30), // Add extra buffer
        onTimeout: () {
          _sendPort?.send(IsolateMessage(type: IsolateMessageType.cancel).toJson());
          return WebSearchResult(success: false, error: 'Web search operation timed out');
        },
      );

      cancelSubscription.cancel();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] [WebSearch] - Error in cancellable isolated operation: $e');
      }
      return WebSearchResult(success: false, error: e.toString());
    }
  }

  /// Clean up isolate resources
  Future<void> _cleanupIsolate() async {
    try {
      _searchIsolate?.kill();
      _searchIsolate = null;
      _receivePort?.close();
      _receivePort = null;
      _sendPort = null;
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] [WebSearch] - Error cleaning up isolate: $e');
      }
    }
  }

  /// Formats scraped web data for AI analysis
  String formatWebSearchDataForAI(String query, List<Map<String, dynamic>> scrapedData) {
    final buffer = StringBuffer();
    buffer.writeln('Web search results for query: "$query"');
    buffer.writeln('Found ${scrapedData.length} relevant websites with detailed content:');
    buffer.writeln();

    for (int i = 0; i < scrapedData.length; i++) {
      final data = scrapedData[i];

      buffer.writeln('--- Website ${i + 1} ---');
      buffer.writeln('Title: ${data['title'] ?? 'No title'}');
      buffer.writeln('URL: ${data['url']}');

      if (data['author'] != null) {
        buffer.writeln('Author: ${data['author']}');
      }

      if (data['publish_date'] != null) {
        buffer.writeln('Published: ${data['publish_date']}');
      }

      if (data['reading_time'] != null) {
        buffer.writeln('Reading time: ${data['reading_time']} minutes');
      }

      buffer.writeln('Description: ${data['description'] ?? 'No description'}');

      final content = data['content']?.toString() ?? '';
      if (content.isNotEmpty && content != data['description']) {
        // Limit content length and clean it
        String cleanContent = content.trim();
        if (cleanContent.length > 1500) {
          cleanContent = '${cleanContent.substring(0, 1500)}...';
        }
        buffer.writeln('Content: $cleanContent');
      } else {
        if (kDebugMode) {
          print(
            '[DEBUG] [FormatWebSearchData] - No content available for site ${i + 1}, using description only',
          );
        }
      }

      if (data['keywords'] != null && (data['keywords'] as List).isNotEmpty) {
        buffer.writeln('Keywords: ${(data['keywords'] as List).join(', ')}');
      }

      buffer.writeln();
    }

    buffer.writeln(
      'Please analyze this information and provide a comprehensive response based on the search results.',
    );

    final formattedData = buffer.toString();

    if (kDebugMode) {
      print('[DEBUG] [FormatWebSearchData] - Final formatted data length: ${formattedData.length}');
    }

    return formattedData;
  }

  /// Stream worker for web search AI analysis
  void webSearchStreamWorker(
    String stringPart,
    RxList<Message> messages,
    int currenMessageIndex,
    bool isReasoning,
  ) {
    // Accumulate text for each new chunk
    _webSearchAccumulatedText += stringPart;

    if (isReasoning) {
      if (_shouldIgnoreThisChunk(_webSearchAccumulatedText)) {
        return;
      }
    }

    final currentMessage = messages[currenMessageIndex];

    // Update message with accumulated text (append)
    messages[currenMessageIndex] = Message(
      author: MessageAuthor(name: 'Assistant', type: AuthorType.ai),
      type: MessageType.text,
      id: currentMessage.id,
      createdAt: currentMessage.createdAt,
      text: _headText + _webSearchAccumulatedText,
      metadata: {...?currentMessage.metadata, 'ai_analysis_in_progress': true},
      tokenCount: 0,
    );

    // Mark session as updated
    sessionManager.markSessionAsUpdated();
  }

  /// Checks if a text chunk should be ignored (think blocks)
  bool _shouldIgnoreThisChunk(String text) {
    if (text.isEmpty) return true;
    if (text.contains('<think>')) {
      isThinkBlock = true;
      _webSearchAccumulatedText = '';
      return true;
    }
    if (isThinkBlock) {
      if (text.contains('</think>')) {
        isThinkBlock = false;
        _webSearchAccumulatedText = '';
        return true;
      }
      return true;
    }
    return false;
  }
}

/// Entry point for the search isolate
void _isolateEntryPoint(Map<String, dynamic> params) async {
  final sendPort = params['sendPort'] as SendPort;
  final receivePort = ReceivePort();

  // Send our receive port back to main isolate
  sendPort.send(receivePort.sendPort);

  try {
    final input = WebSearchInput.fromJson(params['input']);
    bool isCancelled = false;

    // Listen for cancel messages
    late StreamSubscription cancelSubscription;
    cancelSubscription = receivePort.listen((message) {
      try {
        final isolateMessage = IsolateMessage.fromJson(message);
        if (isolateMessage.type == IsolateMessageType.cancel) {
          isCancelled = true;
          cancelSubscription.cancel();
        }
      } catch (e) {
        // Ignore parsing errors for cancel message
      }
    });

    // Perform the actual web search
    final result = await _performWebSearchOperation(input, (message) {
      if (!isCancelled) {
        sendPort.send(IsolateMessage(type: IsolateMessageType.progress, data: message).toJson());
      }
    }, () => isCancelled);

    cancelSubscription.cancel();

    if (!isCancelled) {
      // Send result back to main isolate
      sendPort.send(
        IsolateMessage(type: IsolateMessageType.result, data: result.toJson()).toJson(),
      );
    }
  } catch (e) {
    // Send error back to main isolate
    sendPort.send(
      IsolateMessage(type: IsolateMessageType.error, data: {'error': e.toString()}).toJson(),
    );
  }
}

/// Perform web search operation with cancellation support
Future<WebSearchResult> _performWebSearchOperation(
  WebSearchInput input,
  Function(Map<String, dynamic>) onProgress,
  bool Function() isCancelled,
) async {
  try {
    if (kDebugMode) {
      print('[DEBUG] [WebSearch-Isolate] - Starting web search for: ${input.query}');
    }

    // Check for cancellation before starting
    if (isCancelled()) {
      return WebSearchResult(success: false, error: 'Operation cancelled');
    }

    // Step 1: Perform DuckDuckGo search
    final searchService = DuckDuckGoSearchService(showLogs: false);
    onProgress({'message': 'Searching for: ${input.query}', 'step': 'search'});

    final searchResult = await searchService.search(
      input.query,
      config: DuckDuckGoSearchConfig(
        maxResults: input.maxResults,
        region: input.region,
        safeSearch: input.safeSearch,
        timeoutSeconds: input.timeoutSeconds,
      ),
    );

    if (isCancelled()) {
      searchService.dispose();
      return WebSearchResult(success: false, error: 'Operation cancelled');
    }

    if (!searchResult.success || !searchResult.hasResults) {
      searchService.dispose();
      return WebSearchResult(success: false, error: 'No search results found for: ${input.query}');
    }

    if (kDebugMode) {
      print('[DEBUG] [WebSearch-Isolate] - Found ${searchResult.results.length} search results');
    }

    // Step 2: Scrape content from search results
    final webScraper = WebScraperService();
    final scrapedData = <Map<String, dynamic>>[];
    final successfulScrapedData = <Map<String, dynamic>>[];
    int successfulScrapeCount = 0;

    for (int i = 0; i < searchResult.results.length; i++) {
      if (isCancelled()) {
        webScraper.dispose();
        searchService.dispose();
        return WebSearchResult(success: false, error: 'Operation cancelled');
      }

      final searchItem = searchResult.results[i];

      onProgress({
        'message': 'Scraping website ${i + 1}/${searchResult.results.length}',
        'step': 'scraping',
        'progress': (i + 1) / searchResult.results.length,
      });

      if (kDebugMode) {
        print(
          '[DEBUG] [WebSearch-Isolate] - Scraping website ${i + 1}/${searchResult.results.length}: ${searchItem.url}',
        );
      }

      try {
        final scrapingResult = await webScraper.scrapeUrl(
          searchItem.url,
          config: WebScrapingConfig(
            maxContentLength: input.maxContentLength,
            calculateReadingTime: false,
            extractLinks: false,
            extractImages: false,
            extractSocialMetadata: true,
            extractStructuredData: false,
            timeoutSeconds: input.scrapingTimeout,
          ),
        );

        if (isCancelled()) {
          webScraper.dispose();
          searchService.dispose();
          return WebSearchResult(success: false, error: 'Operation cancelled');
        }

        if (scrapingResult.success && scrapingResult.data != null) {
          final data = scrapingResult.data!;
          final scrapedSite = {
            'url': searchItem.url,
            'title': data.title ?? searchItem.title,
            'description': data.description ?? searchItem.snippet,
            'content': data.content ?? '',
            'author': data.author,
            'publish_date': data.publishDate?.toIso8601String(),
            'reading_time': data.readingTimeMinutes,
            'word_count': data.wordCount,
            'language': data.language,
            'keywords': data.keywords,
            'meta_tags': data.metaTags,
            'social_metadata': data.socialMetadata?.toJson(),
            'search_snippet': searchItem.snippet,
            'display_url': searchItem.displayUrl,
          };

          scrapedData.add(scrapedSite);

          if (successfulScrapeCount < input.limitToScrapeData) {
            successfulScrapedData.add(scrapedSite);
            successfulScrapeCount++;
          }
        } else {
          scrapedData.add({
            'url': searchItem.url,
            'title': searchItem.title,
            'description': searchItem.snippet,
            'content': searchItem.snippet,
            'scraping_error': scrapingResult.error,
            'search_snippet': searchItem.snippet,
            'display_url': searchItem.displayUrl,
          });

          if (kDebugMode) {
            print(
              '[DEBUG] [WebSearch-Isolate] - Scraping failed for ${searchItem.url}: ${scrapingResult.error}',
            );
          }
        }
      } catch (e) {
        if (isCancelled()) {
          webScraper.dispose();
          searchService.dispose();
          return WebSearchResult(success: false, error: 'Operation cancelled');
        }

        scrapedData.add({
          'url': searchItem.url,
          'title': searchItem.title,
          'description': searchItem.snippet,
          'content': searchItem.snippet,
          'scraping_error': e.toString(),
          'search_snippet': searchItem.snippet,
          'display_url': searchItem.displayUrl,
        });

        if (kDebugMode) {
          print('[DEBUG] [WebSearch-Isolate] - Exception scraping ${searchItem.url}: $e');
        }
      }
    }

    // Clean up resources
    searchService.dispose();
    webScraper.dispose();

    if (isCancelled()) {
      return WebSearchResult(success: false, error: 'Operation cancelled');
    }

    if (kDebugMode) {
      print(
        '[DEBUG] [WebSearch-Isolate] - Scraping completed. Success: $successfulScrapeCount/${scrapedData.length}',
      );
    }

    return WebSearchResult(
      success: true,
      searchResults: searchResult.toJson(),
      scrapedData: scrapedData,
      successfulScrapedData: successfulScrapedData,
    );
  } catch (e) {
    if (kDebugMode) {
      print('[DEBUG] [WebSearch-Isolate] - Error in isolated operation: $e');
    }

    return WebSearchResult(success: false, error: e.toString());
  }
}
