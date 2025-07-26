import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/models/tools/search/duckduckgo_search_model.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// Service for performing DuckDuckGo search operations
///
/// This service provides search capabilities using DuckDuckGo's instant answer API
/// and HTML scraping for web search results. It extracts the top 5 website URLs
/// from search results.
///
/// Example usage:
/// ```dart
/// final searchService = DuckDuckGoSearchService();
/// final result = await searchService.search(
///   'Flutter development tips',
///   config: DuckDuckGoSearchConfig.standard,
/// );
///
/// if (result.success) {
///   print('Found ${result.results.length} results');
///   for (final item in result.topFiveResults) {
///     print('${item.title}: ${item.url}');
///   }
/// }
/// ```
class DuckDuckGoSearchService {
  final Dio _dio;

  /// Base URL for DuckDuckGo HTML search
  static const String _searchBaseUrl = 'https://html.duckduckgo.com/html';

  /// Base URL for DuckDuckGo Instant Answer API
  static const String _instantAnswerUrl = 'https://api.duckduckgo.com/';

  /// User agent string to mimic a real browser
  static const String _defaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';

  bool showDebugLogs = false;

  /// Creates a new instance of DuckDuckGoSearchService
  DuckDuckGoSearchService({bool showLogs = false}) : _dio = Dio() {
    showDebugLogs = showLogs;
    _configureDio();
  }

  /// Configures the Dio HTTP client with appropriate settings
  void _configureDio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers['Accept'] =
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8';
    _dio.options.headers['Accept-Language'] = 'en-US,en;q=0.9';
    _dio.options.headers['Accept-Encoding'] = 'gzip, deflate, br';
    _dio.options.headers['DNT'] = '1';
    _dio.options.headers['Connection'] = 'keep-alive';
    _dio.options.headers['Upgrade-Insecure-Requests'] = '1';
    _dio.options.headers['Sec-Fetch-Dest'] = 'document';
    _dio.options.headers['Sec-Fetch-Mode'] = 'navigate';
    _dio.options.headers['Sec-Fetch-Site'] = 'none';
  }

  /// Performs a search using DuckDuckGo and returns the top results
  ///
  /// @param query - The search query string
  /// @param config - Configuration options for the search (optional)
  /// @returns DuckDuckGoSearchResult containing the search results or error information
  Future<DuckDuckGoSearchResult> search(
    String query, {
    DuckDuckGoSearchConfig config = const DuckDuckGoSearchConfig(),
  }) async {
    try {
      // Validate query
      if (query.trim().isEmpty) {
        return DuckDuckGoSearchResult.failure(query: query, error: 'Search query cannot be empty');
      }

      if (kDebugMode && showDebugLogs) {
        print('[DuckDuckGoSearchService] Searching for: "$query"');
      }

      // Try Instant Answer API first (it's more reliable)
      final instantResult = await _searchUsingInstantAnswer(query, config);
      if (instantResult.hasResults) {
        return instantResult;
      }

      // Fallback to HTML scraping
      if (kDebugMode && showDebugLogs) {
        print(
          '[DuckDuckGoSearchService] Instant Answer API returned no results, trying HTML scraping',
        );
      }

      return await _searchUsingHtmlScraping(query, config);
    } catch (e) {
      final errorMessage = 'Search failed: ${e.toString()}';
      if (kDebugMode && showDebugLogs) {
        print('[DuckDuckGoSearchService] Search error: $errorMessage');
      }
      return DuckDuckGoSearchResult.failure(query: query, error: errorMessage);
    }
  }

  /// Search using DuckDuckGo Instant Answer API
  Future<DuckDuckGoSearchResult> _searchUsingInstantAnswer(
    String query,
    DuckDuckGoSearchConfig config,
  ) async {
    try {
      final params = {'q': query.trim(), 'format': 'json', 'no_html': '1', 'skip_disambig': '1'};

      final options = Options(
        headers: {'User-Agent': _defaultUserAgent, 'Accept': 'application/json'},
      );

      final response = await _dio.get(_instantAnswerUrl, queryParameters: params, options: options);

      if (response.statusCode == 200 && response.data != null) {
        // Handle both Map and String responses
        Map<String, dynamic> data;

        if (response.data is String) {
          // If response is a string, try to parse it as JSON
          try {
            data = jsonDecode(response.data) as Map<String, dynamic>;
          } catch (e) {
            if (kDebugMode && showDebugLogs) {
              print('[DuckDuckGoSearchService] Failed to parse JSON response: $e');
            }
            return DuckDuckGoSearchResult.success(query: query, results: []);
          }
        } else if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
        } else {
          if (kDebugMode && showDebugLogs) {
            print(
              '[DuckDuckGoSearchService] Unexpected response type: ${response.data.runtimeType}',
            );
          }
          return DuckDuckGoSearchResult.success(query: query, results: []);
        }

        final results = <DuckDuckGoSearchItem>[];

        // Extract related topics which often contain useful links
        final relatedTopics = data['RelatedTopics'] as List?;
        if (relatedTopics != null) {
          for (final topic in relatedTopics) {
            if (topic is Map<String, dynamic>) {
              final firstUrl = topic['FirstURL'] as String?;
              final text = topic['Text'] as String?;

              if (firstUrl != null && text != null && firstUrl.isNotEmpty && text.isNotEmpty) {
                results.add(
                  DuckDuckGoSearchItem(
                    title: text.split(' - ').first,
                    url: firstUrl,
                    snippet: text,
                    displayUrl: _extractDisplayUrl(firstUrl),
                  ),
                );
              }
            }
          }
        }

        // Extract abstract information
        final abstractUrl = data['AbstractURL'] as String?;
        final abstractText = data['Abstract'] as String?;
        final abstractSource = data['AbstractSource'] as String?;

        if (abstractUrl != null &&
            abstractText != null &&
            abstractUrl.isNotEmpty &&
            abstractText.isNotEmpty) {
          results.insert(
            0,
            DuckDuckGoSearchItem(
              title: abstractSource ?? 'Main Result',
              url: abstractUrl,
              snippet: abstractText,
              displayUrl: _extractDisplayUrl(abstractUrl),
            ),
          );
        }

        if (results.isNotEmpty) {
          if (kDebugMode && showDebugLogs) {
            print('[DuckDuckGoSearchService] Instant Answer API found ${results.length} results');
          }
          return DuckDuckGoSearchResult.success(
            query: query,
            results: results.take(config.maxResults).toList(),
          );
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DuckDuckGoSearchService] Instant Answer API error: $e');
      }
    }

    return DuckDuckGoSearchResult.success(query: query, results: []);
  }

  /// Search using HTML scraping (fallback method)
  Future<DuckDuckGoSearchResult> _searchUsingHtmlScraping(
    String query,
    DuckDuckGoSearchConfig config,
  ) async {
    try {
      // Configure request options with proper encoding handling
      final options = Options(
        headers: {
          'User-Agent': _defaultUserAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'identity', // Disable compression to avoid encoding issues
          'DNT': '1',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
        followRedirects: true,
        maxRedirects: 3,
        sendTimeout: Duration(seconds: config.timeoutSeconds),
        receiveTimeout: Duration(seconds: config.timeoutSeconds),
        responseType: ResponseType.plain, // Ensure we get plain text
      );

      // Prepare search parameters
      final searchParams = {
        'q': query.trim(),
        'kl': config.region,
        'safe': config.safeSearch,
        's': '0', // Start from first result
      };

      if (kDebugMode && showDebugLogs) {
        print('[DuckDuckGoSearchService] HTML scraping parameters: $searchParams');
      }

      // Perform the search request
      final response = await _dio.get(
        _searchBaseUrl,
        queryParameters: searchParams,
        options: options,
      );

      if (response.statusCode != 200) {
        return DuckDuckGoSearchResult.failure(
          query: query,
          error: 'HTTP ${response.statusCode}: Failed to fetch search results',
        );
      }

      // Ensure we have valid HTML content
      final htmlContent = response.data as String;
      if (htmlContent.isEmpty || htmlContent.length < 100) {
        if (kDebugMode && showDebugLogs) {
          print('[DuckDuckGoSearchService] Received empty or too short HTML content');
        }
        return DuckDuckGoSearchResult.failure(
          query: query,
          error: 'Empty or invalid HTML response',
        );
      }

      // Check if content looks like HTML (not binary or corrupted)
      if (!htmlContent.contains('<html') && !htmlContent.contains('<!DOCTYPE')) {
        if (kDebugMode && showDebugLogs) {
          print('[DuckDuckGoSearchService] Response does not appear to be HTML');
          print(
            '[DuckDuckGoSearchService] Content preview: ${htmlContent.substring(0, min(100, htmlContent.length))}',
          );
        }
        return DuckDuckGoSearchResult.failure(query: query, error: 'Invalid HTML response format');
      }

      // Parse the HTML response
      final document = html_parser.parse(htmlContent);

      // Extract search results from the HTML
      final searchResults = _extractSearchResults(document, config.maxResults);

      if (kDebugMode && showDebugLogs) {
        print('[DuckDuckGoSearchService] HTML scraping found ${searchResults.length} results');
      }

      return DuckDuckGoSearchResult.success(query: query, results: searchResults);
    } on DioException catch (e) {
      final errorMessage = _getDioErrorMessage(e);
      if (kDebugMode && showDebugLogs) {
        print('[DuckDuckGoSearchService] HTML scraping DioException: $errorMessage');
      }
      return DuckDuckGoSearchResult.failure(query: query, error: errorMessage);
    } catch (e) {
      final errorMessage = 'HTML scraping error: ${e.toString()}';
      if (kDebugMode && showDebugLogs) {
        print('[DuckDuckGoSearchService] HTML scraping unexpected error: $e');
      }
      return DuckDuckGoSearchResult.failure(query: query, error: errorMessage);
    }
  }

  /// Extracts search results from DuckDuckGo HTML response
  List<DuckDuckGoSearchItem> _extractSearchResults(dom.Document document, int maxResults) {
    final results = <DuckDuckGoSearchItem>[];

    try {
      // Try multiple CSS selectors as DuckDuckGo structure can vary
      final possibleSelectors = [
        '.result',
        '.results_links',
        '.result__body',
        '.web-result',
        'div[data-testid="result"]',
        '.results .result',
        'div.result',
        'div[class*="result"]',
      ];

      List<dom.Element> resultElements = [];

      // Try each selector until we find results
      for (final selector in possibleSelectors) {
        resultElements = document.querySelectorAll(selector);
        if (resultElements.isNotEmpty) {
          if (kDebugMode && showDebugLogs) {
            print('[DuckDuckGoSearchService] Using selector: $selector');
            print('[DuckDuckGoSearchService] Found ${resultElements.length} elements');
          }
          break;
        }
      }

      // If no results with standard selectors, try broader approach
      if (resultElements.isEmpty) {
        // Look for any div with links that might be results
        final allDivs = document.querySelectorAll('div');
        for (final div in allDivs) {
          final link = div.querySelector('a[href*="http"]');
          if (link != null && link.attributes['href'] != null) {
            final href = link.attributes['href']!;
            // Skip DuckDuckGo internal links
            if (!href.contains('duckduckgo.com') &&
                !href.contains('/d.js') &&
                !href.contains('?uddg=') &&
                _isValidUrl(href)) {
              resultElements.add(div);
            }
          }
        }

        if (kDebugMode && showDebugLogs) {
          print(
            '[DuckDuckGoSearchService] Using fallback method, found ${resultElements.length} potential results',
          );
        }
      }

      if (resultElements.isEmpty) {
        if (kDebugMode && showDebugLogs) {
          print('[DuckDuckGoSearchService] No result elements found with any method');
          // Debug: print page structure
          final bodyText = document.body?.text ?? '';
          print(
            '[DuckDuckGoSearchService] Page contains text: ${bodyText.length > 200 ? '${bodyText.substring(0, 200)}...' : bodyText}',
          );
        }
        return results;
      }

      for (final element in resultElements) {
        if (results.length >= maxResults) break;

        try {
          // Try multiple approaches to extract title and URL
          String? title;
          String? url;
          String? snippet;

          // Method 1: Standard DuckDuckGo selectors
          final titleElement =
              element.querySelector('.result__title a') ??
              element.querySelector('.result-title a') ??
              element.querySelector('h2 a') ??
              element.querySelector('h3 a') ??
              element.querySelector('a[href*="http"]');

          if (titleElement != null) {
            title = titleElement.text.trim();
            url = titleElement.attributes['href'];
          }

          // Method 2: If no title found, look for any link with text
          if (title == null || url == null) {
            final anyLink = element.querySelector('a[href*="http"]');
            if (anyLink != null) {
              title = anyLink.text.trim();
              url = anyLink.attributes['href'];

              // If title is empty, try getting from parent or sibling elements
              if (title.isEmpty) {
                final parent = anyLink.parent;
                if (parent != null) {
                  title = parent.text.trim();
                  // Clean up the title to remove extra whitespace
                  title = title.replaceAll(RegExp(r'\s+'), ' ');
                }
              }
            }
          }

          // Extract snippet
          final snippetElement =
              element.querySelector('.result__snippet') ??
              element.querySelector('.result-snippet') ??
              element.querySelector('.snippet') ??
              element.querySelector('span[class*="snippet"]');

          if (snippetElement != null) {
            snippet = snippetElement.text.trim();
          } else {
            // Fallback: get text content but exclude the title
            final elementText = element.text.trim();
            if (elementText.isNotEmpty && title != null) {
              snippet = elementText.replaceFirst(title, '').trim();
              // Limit snippet length
              if (snippet.length > 200) {
                snippet = '${snippet.substring(0, 200)}...';
              }
            }
          }

          // Validate and clean the data
          if (title != null && url != null && title.isNotEmpty && url.isNotEmpty) {
            // Clean URL - remove DuckDuckGo redirect wrappers
            if (url.contains('duckduckgo.com/l/?')) {
              // Extract actual URL from DuckDuckGo redirect
              final uri = Uri.parse(url);
              final uddgParam = uri.queryParameters['uddg'];
              if (uddgParam != null) {
                try {
                  url = Uri.decodeFull(uddgParam);
                } catch (e) {
                  // Keep original URL if decoding fails
                }
              }
            }

            if (_isValidUrl(url!)) {
              final searchItem = DuckDuckGoSearchItem(
                title: title,
                url: url,
                snippet: snippet ?? '',
                displayUrl: _extractDisplayUrl(url),
              );

              results.add(searchItem);

              if (kDebugMode && showDebugLogs) {
                print('[DuckDuckGoSearchService] Added result: $title -> $url');
              }
            } else {
              if (kDebugMode && showDebugLogs) {
                print('[DuckDuckGoSearchService] Skipped invalid URL: $url');
              }
            }
          } else {
            if (kDebugMode && showDebugLogs) {
              print('[DuckDuckGoSearchService] Skipped element - missing title or URL');
            }
          }
        } catch (e) {
          // Skip this result if parsing fails
          if (kDebugMode && showDebugLogs) {
            print('[DuckDuckGoSearchService] Failed to parse result element: $e');
          }
          continue;
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DuckDuckGoSearchService] Failed to extract search results: $e');
      }
    }

    if (kDebugMode && showDebugLogs) {
      print('[DuckDuckGoSearchService] Successfully extracted ${results.length} results');
    }

    return results;
  }

  /// Validates if a URL is properly formatted
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Extracts a display-friendly URL from the full URL
  String? _extractDisplayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  /// Converts DioException to a user-friendly error message
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout - please check your internet connection';
      case DioExceptionType.sendTimeout:
        return 'Request timeout - please try again';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout - please try again';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode ?? 'Unknown'}';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error - please check your internet connection';
      case DioExceptionType.badCertificate:
        return 'SSL certificate error';
      case DioExceptionType.unknown:
        return 'Network error: ${e.message ?? 'Unknown error'}';
    }
  }

  /// Disposes of the HTTP client resources
  void dispose() {
    _dio.close();
  }
}
