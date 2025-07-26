/// Model classes for DuckDuckGo search results
class DuckDuckGoSearchResult {
  final bool success;
  final String? error;
  final List<DuckDuckGoSearchItem> results;
  final String query;

  const DuckDuckGoSearchResult({
    required this.success,
    this.error,
    required this.results,
    required this.query,
  });

  /// Factory constructor for successful search results
  factory DuckDuckGoSearchResult.success({
    required String query,
    required List<DuckDuckGoSearchItem> results,
  }) {
    return DuckDuckGoSearchResult(success: true, results: results, query: query);
  }

  /// Factory constructor for failed search results
  factory DuckDuckGoSearchResult.failure({required String query, required String error}) {
    return DuckDuckGoSearchResult(success: false, error: error, results: [], query: query);
  }

  /// Factory constructor from JSON data
  factory DuckDuckGoSearchResult.fromJson(Map<String, dynamic> json) {
    return DuckDuckGoSearchResult(
      success: json['success'] ?? false,
      error: json['error'],
      query: json['query'] ?? '',
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => DuckDuckGoSearchItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'error': error,
      'query': query,
      'results': results.map((item) => item.toJson()).toList(),
    };
  }

  /// Returns true if the search has results
  bool get hasResults => success && results.isNotEmpty;

  /// Returns the first 5 results
  List<DuckDuckGoSearchItem> get topFiveResults => results.take(5).toList();
}

/// Represents a single search result item from DuckDuckGo
class DuckDuckGoSearchItem {
  final String title;
  final String url;
  final String snippet;
  final String? displayUrl;

  const DuckDuckGoSearchItem({
    required this.title,
    required this.url,
    required this.snippet,
    this.displayUrl,
  });

  /// Factory constructor from JSON data
  factory DuckDuckGoSearchItem.fromJson(Map<String, dynamic> json) {
    return DuckDuckGoSearchItem(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      snippet: json['snippet'] ?? '',
      displayUrl: json['displayUrl'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'title': title, 'url': url, 'snippet': snippet, 'displayUrl': displayUrl};
  }

  @override
  String toString() {
    return 'DuckDuckGoSearchItem(title: $title, url: $url, snippet: $snippet)';
  }
}

/// Configuration class for DuckDuckGo search requests
class DuckDuckGoSearchConfig {
  final int maxResults;
  final String region;
  final String safeSearch;
  final int timeoutSeconds;

  const DuckDuckGoSearchConfig({
    this.maxResults = 5,
    this.region = 'us-en',
    this.safeSearch = 'moderate',
    this.timeoutSeconds = 15,
  });

  /// Returns a conservative configuration
  static const DuckDuckGoSearchConfig conservative = DuckDuckGoSearchConfig(
    maxResults: 3,
    safeSearch: 'strict',
    timeoutSeconds: 10,
  );

  /// Returns a standard configuration
  static const DuckDuckGoSearchConfig standard = DuckDuckGoSearchConfig(
    maxResults: 5,
    safeSearch: 'moderate',
    timeoutSeconds: 15,
  );

  /// Returns an extended configuration
  static const DuckDuckGoSearchConfig extended = DuckDuckGoSearchConfig(
    maxResults: 8,
    safeSearch: 'off',
    timeoutSeconds: 20,
  );
}
