import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/models/tools/web_scraper_model.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// Service for scraping web pages and extracting useful information
///
/// This service provides comprehensive web scraping capabilities including:
/// - Content extraction (title, description, main text)
/// - Metadata extraction (social media tags, SEO data)
/// - Image and link extraction
/// - Structured data parsing
/// - Reading time calculation
///
/// Example usage:
/// ```dart
/// final scraper = WebScraperService();
/// final result = await scraper.scrapeUrl(
///   'https://example.com',
///   config: WebScrapingConfig.comprehensive(),
/// );
///
/// if (result.success) {
///   print('Title: ${result.data?.title}');
///   print('Content: ${result.data?.content}');
/// }
/// ```
class WebScraperService {
  final Dio _dio;
  static const int _averageWordsPerMinute = 200;

  /// Creates a new instance of WebScraperService
  WebScraperService() : _dio = Dio() {
    _configureDio();
  }

  /// Configures the Dio HTTP client with default settings
  void _configureDio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers['Accept'] =
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
    _dio.options.headers['Accept-Language'] = 'en-US,en;q=0.5';
    _dio.options.headers['Accept-Encoding'] = 'gzip, deflate';
    _dio.options.headers['DNT'] = '1';
    _dio.options.headers['Connection'] = 'keep-alive';
    _dio.options.headers['Upgrade-Insecure-Requests'] = '1';
  }

  /// Scrapes a web page and extracts useful information
  ///
  /// @param url - The URL to scrape
  /// @param config - Configuration options for scraping (optional)
  /// @returns WebScrapingResult containing the extracted data or error information
  Future<WebScrapingResult> scrapeUrl(
    String url, {
    WebScrapingConfig config = const WebScrapingConfig(),
  }) async {
    try {
      // Validate URL
      if (!_isValidUrl(url)) {
        return WebScrapingResult.failure(url: url, error: 'Invalid URL format');
      }

      // Configure request options
      final options = Options(
        headers: {'User-Agent': config.userAgent, ...config.customHeaders},
        followRedirects: config.followRedirects,
        maxRedirects: config.maxRedirects,
        sendTimeout: Duration(seconds: config.timeoutSeconds),
        receiveTimeout: Duration(seconds: config.timeoutSeconds),
      );

      // Perform HTTP request
      final response = await _dio.get(url, options: options);

      if (response.statusCode != 200) {
        return WebScrapingResult.failure(
          url: url,
          error: 'HTTP ${response.statusCode}: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }

      // Parse HTML content
      final document = html_parser.parse(response.data);

      // Extract web page data
      final webPageData = await _extractWebPageData(document, url, config);

      return WebScrapingResult.success(
        url: url,
        data: webPageData,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return WebScrapingResult.failure(
        url: url,
        error: _getDioErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return WebScrapingResult.failure(url: url, error: 'Unexpected error: ${e.toString()}');
    }
  }

  /// Extracts structured data from a web page
  Future<WebPageData> _extractWebPageData(
    dom.Document document,
    String url,
    WebScrapingConfig config,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Extract basic information
    final title = _extractTitle(document);
    final description = _extractDescription(document);
    final content = _extractMainContent(document);
    final language = _extractLanguage(document);
    final author = _extractAuthor(document);
    final publishDate = _extractPublishDate(document);
    final keywords = _extractKeywords(document);

    // Calculate reading metrics
    int? wordCount;
    int? readingTime;
    if (config.calculateReadingTime && content != null) {
      wordCount = _calculateWordCount(content);
      readingTime = _calculateReadingTime(wordCount);
    }

    // Extract links and images
    final links = config.extractLinks ? _extractLinks(document, url) : <String>[];
    final images = config.extractImages ? _extractImages(document, url) : <WebImage>[];

    // Extract metadata
    final metaTags = _extractMetaTags(document);
    final socialMetadata = config.extractSocialMetadata ? _extractSocialMetadata(document) : null;
    final structuredData = config.extractStructuredData
        ? _extractStructuredData(document)
        : <String, dynamic>{};

    // Extract new features
    final contactInfo = config.extractContactInfo ? _extractContactInfo(document) : null;
    final navigationData = config.extractNavigation ? _extractNavigationData(document, url) : null;
    final mediaContent = config.extractMedia ? _extractMediaContent(document, url) : null;
    final tables = config.extractTables ? _extractTables(document) : <TableData>[];
    final forms = config.extractForms ? _extractForms(document, url) : <WebFormData>[];
    final headings = config.extractHeadings ? _extractHeadings(document) : <Heading>[];

    // Analysis features
    final contentType = config.classifyContent ? _classifyContentType(document, url) : null;
    final seoAnalysis = config.analyzeSeo
        ? _performSeoAnalysis(document, title, description, images)
        : null;
    final pageStructure = config.analyzePageStructure ? _analyzePageStructure(document) : null;
    final sentimentAnalysis = config.analyzeSentiment && content != null
        ? _analyzeSentiment(content)
        : null;

    // Extract specialized content
    final comments = config.extractComments ? _extractComments(document) : <Comment>[];
    final productInfo = config.extractProductInfo ? _extractProductInfo(document) : null;
    final articleInfo = config.extractArticleInfo ? _extractArticleInfo(document) : null;

    // Performance metrics
    stopwatch.stop();
    final performanceMetrics = config.collectPerformanceMetrics
        ? _createPerformanceMetrics(stopwatch.elapsedMilliseconds, document)
        : null;

    // Apply content length limit if specified
    String? finalContent = content;
    if (config.maxContentLength != null &&
        content != null &&
        content.length > config.maxContentLength!) {
      finalContent = content.substring(0, config.maxContentLength!);
    }

    return WebPageData(
      title: title,
      description: description,
      content: finalContent,
      links: links,
      images: images,
      metaTags: metaTags,
      language: language,
      author: author,
      publishDate: publishDate,
      keywords: keywords,
      structuredData: structuredData,
      socialMetadata: socialMetadata,
      readingTimeMinutes: readingTime,
      wordCount: wordCount,
      pageStructure: pageStructure,
      contactInfo: contactInfo,
      navigationData: navigationData,
      mediaContent: mediaContent,
      tables: tables,
      forms: forms,
      contentType: contentType,
      seoAnalysis: seoAnalysis,
      performanceMetrics: performanceMetrics,
      comments: comments,
      productInfo: productInfo,
      articleInfo: articleInfo,
      headings: headings,
      sentimentAnalysis: sentimentAnalysis,
    );
  }

  /// Extracts the page title
  String? _extractTitle(dom.Document document) {
    // Try Open Graph title first
    final ogTitle = document.querySelector('meta[property="og:title"]')?.attributes['content'];
    if (ogTitle != null && ogTitle.isNotEmpty) return ogTitle.trim();

    // Try Twitter title
    final twitterTitle = document
        .querySelector('meta[name="twitter:title"]')
        ?.attributes['content'];
    if (twitterTitle != null && twitterTitle.isNotEmpty) return twitterTitle.trim();

    // Try regular title tag
    final titleElement = document.querySelector('title');
    if (titleElement != null && titleElement.text.isNotEmpty) {
      return titleElement.text.trim();
    }

    // Try h1 tag as fallback
    final h1Element = document.querySelector('h1');
    if (h1Element != null && h1Element.text.isNotEmpty) {
      return h1Element.text.trim();
    }

    return null;
  }

  /// Extracts the page description
  String? _extractDescription(dom.Document document) {
    // Try Open Graph description first
    final ogDescription = document
        .querySelector('meta[property="og:description"]')
        ?.attributes['content'];
    if (ogDescription != null && ogDescription.isNotEmpty) return ogDescription.trim();

    // Try Twitter description
    final twitterDescription = document
        .querySelector('meta[name="twitter:description"]')
        ?.attributes['content'];
    if (twitterDescription != null && twitterDescription.isNotEmpty) {
      return twitterDescription.trim();
    }

    // Try meta description
    final metaDescription = document
        .querySelector('meta[name="description"]')
        ?.attributes['content'];
    if (metaDescription != null && metaDescription.isNotEmpty) return metaDescription.trim();

    return null;
  }

  /// Extracts the main content of the page
  String? _extractMainContent(dom.Document document) {
    // Common content selectors (ordered by priority)
    final contentSelectors = [
      'article',
      '[role="main"]',
      'main',
      '.content',
      '.post-content',
      '.entry-content',
      '.article-content',
      '.post-body',
      '.story-body',
      '#content',
      '#main-content',
      '.main-content',
    ];

    // Try each selector
    for (final selector in contentSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final text = _extractTextContent(element);
        if (text.isNotEmpty && text.length > 100) {
          return text;
        }
      }
    }

    // Fallback: extract from body but filter out navigation, footer, etc.
    final body = document.querySelector('body');
    if (body != null) {
      // Remove unwanted elements
      final unwantedSelectors = [
        'nav',
        'header',
        'footer',
        'aside',
        '.sidebar',
        '.navigation',
        '.menu',
        '.ad',
        '.advertisement',
        '.popup',
        '.modal',
        'script',
        'style',
        '.cookie',
        '.social-share',
        '.comments',
      ];

      for (final selector in unwantedSelectors) {
        body.querySelectorAll(selector).forEach((element) => element.remove());
      }

      final text = _extractTextContent(body);
      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  /// Extracts clean text content from an HTML element
  String _extractTextContent(dom.Element element) {
    final text = element.text;
    if (text.isEmpty) return '';

    // Clean up the text
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(RegExp(r'\n+'), '\n') // Replace multiple newlines with single newline
        .trim();
  }

  /// Extracts the page language
  String? _extractLanguage(dom.Document document) {
    // Try html lang attribute
    final htmlLang = document.querySelector('html')?.attributes['lang'];
    if (htmlLang != null && htmlLang.isNotEmpty) return htmlLang;

    // Try meta language
    final metaLang = document
        .querySelector('meta[http-equiv="content-language"]')
        ?.attributes['content'];
    if (metaLang != null && metaLang.isNotEmpty) return metaLang;

    return null;
  }

  /// Extracts the page author
  String? _extractAuthor(dom.Document document) {
    // Try meta author
    final metaAuthor = document.querySelector('meta[name="author"]')?.attributes['content'];
    if (metaAuthor != null && metaAuthor.isNotEmpty) return metaAuthor.trim();

    // Try article author
    final articleAuthor = document.querySelector('[rel="author"]')?.text;
    if (articleAuthor != null && articleAuthor.isNotEmpty) return articleAuthor.trim();

    // Try byline
    final byline = document.querySelector('.byline, .author, .writer')?.text;
    if (byline != null && byline.isNotEmpty) return byline.trim();

    return null;
  }

  /// Extracts the publication date
  DateTime? _extractPublishDate(dom.Document document) {
    // Try schema.org datePublished
    final schemaDate =
        document.querySelector('[itemprop="datePublished"]')?.attributes['datetime'] ??
        document.querySelector('[itemprop="datePublished"]')?.attributes['content'];
    if (schemaDate != null) {
      final date = DateTime.tryParse(schemaDate);
      if (date != null) return date;
    }

    // Try meta article:published_time
    final metaPublished = document
        .querySelector('meta[property="article:published_time"]')
        ?.attributes['content'];
    if (metaPublished != null) {
      final date = DateTime.tryParse(metaPublished);
      if (date != null) return date;
    }

    // Try time element with datetime attribute
    final timeElement = document.querySelector('time[datetime]')?.attributes['datetime'];
    if (timeElement != null) {
      final date = DateTime.tryParse(timeElement);
      if (date != null) return date;
    }

    return null;
  }

  /// Extracts keywords from the page
  List<String> _extractKeywords(dom.Document document) {
    final keywords = <String>[];

    // Try meta keywords
    final metaKeywords = document.querySelector('meta[name="keywords"]')?.attributes['content'];
    if (metaKeywords != null && metaKeywords.isNotEmpty) {
      keywords.addAll(metaKeywords.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty));
    }

    // Try article:tag meta tags
    final tagElements = document.querySelectorAll('meta[property="article:tag"]');
    for (final element in tagElements) {
      final tag = element.attributes['content'];
      if (tag != null && tag.isNotEmpty) {
        keywords.add(tag.trim());
      }
    }

    return keywords.toSet().toList(); // Remove duplicates
  }

  /// Extracts links from the page
  List<String> _extractLinks(dom.Document document, String baseUrl) {
    final links = <String>[];
    final linkElements = document.querySelectorAll('a[href]');

    for (final element in linkElements) {
      final href = element.attributes['href'];
      if (href != null && href.isNotEmpty) {
        final absoluteUrl = _makeAbsoluteUrl(href, baseUrl);
        if (absoluteUrl != null && _isValidUrl(absoluteUrl)) {
          links.add(absoluteUrl);
        }
      }
    }

    return links.toSet().toList(); // Remove duplicates
  }

  /// Extracts images from the page
  List<WebImage> _extractImages(dom.Document document, String baseUrl) {
    final images = <WebImage>[];
    final imgElements = document.querySelectorAll('img[src]');

    for (final element in imgElements) {
      final src = element.attributes['src'];
      if (src != null && src.isNotEmpty) {
        final absoluteUrl = _makeAbsoluteUrl(src, baseUrl);
        if (absoluteUrl != null && _isValidUrl(absoluteUrl)) {
          final alt = element.attributes['alt'];
          final width = int.tryParse(element.attributes['width'] ?? '');
          final height = int.tryParse(element.attributes['height'] ?? '');

          images.add(WebImage(url: absoluteUrl, alt: alt, width: width, height: height));
        }
      }
    }

    return images;
  }

  /// Extracts meta tags from the page
  Map<String, String> _extractMetaTags(dom.Document document) {
    final metaTags = <String, String>{};
    final metaElements = document.querySelectorAll('meta');

    for (final element in metaElements) {
      final name = element.attributes['name'] ?? element.attributes['property'];
      final content = element.attributes['content'];

      if (name != null && content != null && name.isNotEmpty && content.isNotEmpty) {
        metaTags[name] = content;
      }
    }

    return metaTags;
  }

  /// Extracts social media metadata (Open Graph, Twitter Card)
  SocialMetadata _extractSocialMetadata(dom.Document document) {
    return SocialMetadata(
      ogTitle: document.querySelector('meta[property="og:title"]')?.attributes['content'],
      ogDescription: document
          .querySelector('meta[property="og:description"]')
          ?.attributes['content'],
      ogImage: document.querySelector('meta[property="og:image"]')?.attributes['content'],
      ogSiteName: document.querySelector('meta[property="og:site_name"]')?.attributes['content'],
      ogType: document.querySelector('meta[property="og:type"]')?.attributes['content'],
      twitterCard: document.querySelector('meta[name="twitter:card"]')?.attributes['content'],
      twitterTitle: document.querySelector('meta[name="twitter:title"]')?.attributes['content'],
      twitterDescription: document
          .querySelector('meta[name="twitter:description"]')
          ?.attributes['content'],
      twitterImage: document.querySelector('meta[name="twitter:image"]')?.attributes['content'],
      twitterSite: document.querySelector('meta[name="twitter:site"]')?.attributes['content'],
      twitterCreator: document.querySelector('meta[name="twitter:creator"]')?.attributes['content'],
    );
  }

  /// Extracts structured data (JSON-LD, microdata)
  Map<String, dynamic> _extractStructuredData(dom.Document document) {
    final structuredData = <String, dynamic>{};

    // Extract JSON-LD data
    final jsonLdElements = document.querySelectorAll('script[type="application/ld+json"]');
    final jsonLdData = <Map<String, dynamic>>[];

    for (final element in jsonLdElements) {
      try {
        final jsonData = json.decode(element.text);
        if (jsonData is Map<String, dynamic>) {
          jsonLdData.add(jsonData);
        } else if (jsonData is List) {
          for (final item in jsonData) {
            if (item is Map<String, dynamic>) {
              jsonLdData.add(item);
            }
          }
        }
      } catch (e) {
        // Ignore invalid JSON
        if (kDebugMode) {
          print('Failed to parse JSON-LD: $e');
        }
      }
    }

    if (jsonLdData.isNotEmpty) {
      structuredData['jsonLd'] = jsonLdData;
    }

    // Extract microdata (basic implementation)
    final microdataElements = document.querySelectorAll('[itemscope]');
    final microdataData = <Map<String, dynamic>>[];

    for (final element in microdataElements) {
      final itemType = element.attributes['itemtype'];
      if (itemType != null) {
        final microdataItem = <String, dynamic>{'@type': itemType};

        final propElements = element.querySelectorAll('[itemprop]');
        for (final propElement in propElements) {
          final propName = propElement.attributes['itemprop'];
          final propValue = propElement.attributes['content'] ?? propElement.text.trim();

          if (propName != null && propValue.isNotEmpty) {
            microdataItem[propName] = propValue;
          }
        }

        if (microdataItem.length > 1) {
          microdataData.add(microdataItem);
        }
      }
    }

    if (microdataData.isNotEmpty) {
      structuredData['microdata'] = microdataData;
    }

    return structuredData;
  }

  /// Calculates the word count of the given text
  int _calculateWordCount(String text) {
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  /// Calculates the estimated reading time in minutes
  int _calculateReadingTime(int wordCount) {
    if (wordCount == 0) return 0;
    final minutes = (wordCount / _averageWordsPerMinute).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  /// Converts a relative URL to an absolute URL
  String? _makeAbsoluteUrl(String url, String baseUrl) {
    try {
      final baseUri = Uri.parse(baseUrl);
      final resolvedUri = baseUri.resolve(url);
      return resolvedUri.toString();
    } catch (e) {
      return null;
    }
  }

  /// Validates if a string is a valid URL
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Converts DioException to a readable error message
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badResponse:
        return 'Bad response: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error';
      case DioExceptionType.badCertificate:
        return 'Bad certificate';
      case DioExceptionType.unknown:
        return 'Unknown error: ${e.message}';
    }
  }

  /// Disposes of the service and cleans up resources
  void dispose() {
    _dio.close();
  }

  /// Extracts contact information from the page
  ContactInfo _extractContactInfo(dom.Document document) {
    final emails = <String>[];
    final phoneNumbers = <String>[];
    final addresses = <String>[];
    final socialLinks = <String, String>{};

    // Extract emails using regex
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final bodyText = document.body?.text ?? '';
    final emailMatches = emailRegex.allMatches(bodyText);
    for (final match in emailMatches) {
      final email = match.group(0);
      if (email != null && !emails.contains(email)) {
        emails.add(email);
      }
    }

    // Extract emails from mailto links
    final mailtoLinks = document.querySelectorAll('a[href^="mailto:"]');
    for (final link in mailtoLinks) {
      final href = link.attributes['href'];
      if (href != null) {
        final email = href.replaceFirst('mailto:', '').split('?').first;
        if (!emails.contains(email)) {
          emails.add(email);
        }
      }
    }

    // Extract phone numbers
    final phoneRegex = RegExp(r'(?:\+?1[-.\s]?)?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}');
    final phoneMatches = phoneRegex.allMatches(bodyText);
    for (final match in phoneMatches) {
      final phone = match.group(0);
      if (phone != null && !phoneNumbers.contains(phone)) {
        phoneNumbers.add(phone.trim());
      }
    }

    // Extract phone numbers from tel links
    final telLinks = document.querySelectorAll('a[href^="tel:"]');
    for (final link in telLinks) {
      final href = link.attributes['href'];
      if (href != null) {
        final phone = href.replaceFirst('tel:', '');
        if (!phoneNumbers.contains(phone)) {
          phoneNumbers.add(phone);
        }
      }
    }

    // Extract addresses (basic implementation)
    final addressSelectors = ['.address', '.location', '[itemprop="address"]', '.contact-address'];
    for (final selector in addressSelectors) {
      final elements = document.querySelectorAll(selector);
      for (final element in elements) {
        final address = element.text.trim();
        if (address.isNotEmpty && !addresses.contains(address)) {
          addresses.add(address);
        }
      }
    }

    // Extract social media links
    final socialPlatforms = {
      'facebook': ['facebook.com', 'fb.com'],
      'twitter': ['twitter.com', 'x.com'],
      'instagram': ['instagram.com'],
      'linkedin': ['linkedin.com'],
      'youtube': ['youtube.com', 'youtu.be'],
      'tiktok': ['tiktok.com'],
      'github': ['github.com'],
      'telegram': ['t.me', 'telegram.me'],
      'whatsapp': ['wa.me', 'whatsapp.com'],
    };

    final socialLinkElements = document.querySelectorAll(
      'a[href*="facebook.com"], a[href*="twitter.com"], a[href*="instagram.com"], a[href*="linkedin.com"], a[href*="youtube.com"], a[href*="tiktok.com"], a[href*="github.com"], a[href*="t.me"], a[href*="wa.me"], a[href*="x.com"]',
    );

    for (final link in socialLinkElements) {
      final href = link.attributes['href'];
      if (href != null) {
        for (final platform in socialPlatforms.entries) {
          if (platform.value.any((domain) => href.contains(domain))) {
            socialLinks[platform.key] = href;
            break;
          }
        }
      }
    }

    // Check for contact forms
    final hasContactForm = document.querySelectorAll('form').any((form) {
      final formText = form.text.toLowerCase();
      return formText.contains('contact') ||
          formText.contains('message') ||
          formText.contains('inquiry') ||
          form.querySelector('input[type="email"]') != null;
    });

    return ContactInfo(
      emails: emails,
      phoneNumbers: phoneNumbers,
      addresses: addresses,
      socialLinks: socialLinks,
      hasContactForm: hasContactForm,
    );
  }

  /// Extracts navigation data from the page
  NavigationData _extractNavigationData(dom.Document document, String baseUrl) {
    final mainNavigation = <NavigationLink>[];
    final breadcrumbs = <String>[];
    final footerLinks = <NavigationLink>[];

    // Extract main navigation
    final navSelectors = ['nav', '.navigation', '.navbar', '.menu', 'header nav', '.main-nav'];
    for (final selector in navSelectors) {
      final navElements = document.querySelectorAll(selector);
      for (final nav in navElements) {
        final links = nav.querySelectorAll('a[href]');
        for (final link in links) {
          final href = link.attributes['href'];
          final text = link.text.trim();
          if (href != null && text.isNotEmpty) {
            final absoluteUrl = _makeAbsoluteUrl(href, baseUrl);
            if (absoluteUrl != null) {
              mainNavigation.add(NavigationLink(text: text, url: absoluteUrl));
            }
          }
        }
        if (mainNavigation.isNotEmpty) break; // Use first found navigation
      }
    }

    // Extract breadcrumbs
    final breadcrumbSelectors = [
      '.breadcrumb',
      '.breadcrumbs',
      '[aria-label="Breadcrumb"]',
      '.crumbs',
    ];
    for (final selector in breadcrumbSelectors) {
      final breadcrumbElement = document.querySelector(selector);
      if (breadcrumbElement != null) {
        final links = breadcrumbElement.querySelectorAll('a, span');
        for (final link in links) {
          final text = link.text.trim();
          if (text.isNotEmpty) {
            breadcrumbs.add(text);
          }
        }
        if (breadcrumbs.isNotEmpty) break;
      }
    }

    // Extract footer links
    final footerElement = document.querySelector('footer');
    if (footerElement != null) {
      final links = footerElement.querySelectorAll('a[href]');
      for (final link in links) {
        final href = link.attributes['href'];
        final text = link.text.trim();
        if (href != null && text.isNotEmpty) {
          final absoluteUrl = _makeAbsoluteUrl(href, baseUrl);
          if (absoluteUrl != null) {
            footerLinks.add(NavigationLink(text: text, url: absoluteUrl));
          }
        }
      }
    }

    // Extract pagination info
    PaginationInfo? pagination;
    final paginationElement = document.querySelector('.pagination, .pager, .page-numbers');
    if (paginationElement != null) {
      final nextLink = paginationElement.querySelector('a[rel="next"], .next, .page-next');
      final prevLink = paginationElement.querySelector('a[rel="prev"], .prev, .page-prev');

      pagination = PaginationInfo(
        hasNext: nextLink != null,
        hasPrevious: prevLink != null,
        nextUrl: nextLink != null
            ? _makeAbsoluteUrl(nextLink.attributes['href'] ?? '', baseUrl)
            : null,
        previousUrl: prevLink != null
            ? _makeAbsoluteUrl(prevLink.attributes['href'] ?? '', baseUrl)
            : null,
      );
    }

    return NavigationData(
      mainNavigation: mainNavigation,
      breadcrumbs: breadcrumbs,
      footerLinks: footerLinks,
      pagination: pagination,
    );
  }

  /// Extracts media content from the page
  MediaContent _extractMediaContent(dom.Document document, String baseUrl) {
    final videos = <MediaElement>[];
    final audio = <MediaElement>[];
    final embeddedMedia = <EmbeddedMedia>[];

    // Extract video elements
    final videoElements = document.querySelectorAll('video[src], video source[src]');
    for (final video in videoElements) {
      final src = video.attributes['src'];
      final poster = video.attributes['poster'];
      final title = video.attributes['title'] ?? video.attributes['alt'];

      if (src != null) {
        final absoluteUrl = _makeAbsoluteUrl(src, baseUrl);
        if (absoluteUrl != null) {
          videos.add(
            MediaElement(
              src: absoluteUrl,
              type: 'video',
              poster: poster != null ? _makeAbsoluteUrl(poster, baseUrl) : null,
              title: title,
            ),
          );
        }
      }
    }

    // Extract audio elements
    final audioElements = document.querySelectorAll('audio[src], audio source[src]');
    for (final audioEl in audioElements) {
      final src = audioEl.attributes['src'];
      final title = audioEl.attributes['title'] ?? audioEl.attributes['alt'];

      if (src != null) {
        final absoluteUrl = _makeAbsoluteUrl(src, baseUrl);
        if (absoluteUrl != null) {
          audio.add(MediaElement(src: absoluteUrl, type: 'audio', title: title));
        }
      }
    }

    // Extract embedded media (YouTube, Vimeo, etc.)
    final iframes = document.querySelectorAll('iframe[src]');
    for (final iframe in iframes) {
      final src = iframe.attributes['src'];
      final title = iframe.attributes['title'];

      if (src != null) {
        String platform = 'unknown';
        String type = 'embed';

        if (src.contains('youtube.com') || src.contains('youtu.be')) {
          platform = 'youtube';
          type = 'video';
        } else if (src.contains('vimeo.com')) {
          platform = 'vimeo';
          type = 'video';
        } else if (src.contains('soundcloud.com')) {
          platform = 'soundcloud';
          type = 'audio';
        } else if (src.contains('spotify.com')) {
          platform = 'spotify';
          type = 'audio';
        } else if (src.contains('twitter.com') || src.contains('x.com')) {
          platform = 'twitter';
          type = 'social';
        } else if (src.contains('instagram.com')) {
          platform = 'instagram';
          type = 'social';
        }

        embeddedMedia.add(EmbeddedMedia(url: src, platform: platform, type: type, title: title));
      }
    }

    return MediaContent(
      videos: videos,
      audio: audio,
      embeddedMedia: embeddedMedia,
      totalMediaCount: videos.length + audio.length + embeddedMedia.length,
    );
  }

  /// Extracts table data from the page
  List<TableData> _extractTables(dom.Document document) {
    final tables = <TableData>[];
    final tableElements = document.querySelectorAll('table');

    for (final table in tableElements) {
      final caption = table.querySelector('caption')?.text.trim();
      final headers = <String>[];
      final rows = <List<String>>[];

      // Extract headers
      final headerCells = table.querySelectorAll('thead th, tr:first-child th');
      for (final cell in headerCells) {
        headers.add(cell.text.trim());
      }

      // Extract rows
      final bodyRows = table.querySelectorAll('tbody tr, tr');
      for (final row in bodyRows) {
        final cells = row.querySelectorAll('td, th');
        if (cells.isNotEmpty) {
          final rowData = cells.map((cell) => cell.text.trim()).toList();
          rows.add(rowData);
        }
      }

      if (rows.isNotEmpty) {
        tables.add(
          TableData(
            caption: caption,
            headers: headers,
            rows: rows,
            columnCount: headers.isNotEmpty
                ? headers.length
                : (rows.isNotEmpty ? rows.first.length : 0),
            rowCount: rows.length,
          ),
        );
      }
    }

    return tables;
  }

  /// Extracts form data from the page
  List<WebFormData> _extractForms(dom.Document document, String baseUrl) {
    final forms = <WebFormData>[];
    final formElements = document.querySelectorAll('form');

    for (final form in formElements) {
      final action = form.attributes['action'];
      final method = form.attributes['method']?.toUpperCase() ?? 'GET';
      final name = form.attributes['name'] ?? form.attributes['id'];
      final fields = <FormField>[];
      bool hasFileUpload = false;

      // Extract form fields
      final inputs = form.querySelectorAll('input, textarea, select');
      for (final input in inputs) {
        final inputName = input.attributes['name'];
        final inputType = input.attributes['type'] ?? 'text';
        final label = _findLabelForInput(form, input);
        final placeholder = input.attributes['placeholder'];
        final required = input.attributes.containsKey('required');

        if (inputType == 'file') {
          hasFileUpload = true;
        }

        if (inputName != null && inputName.isNotEmpty) {
          fields.add(
            FormField(
              name: inputName,
              type: inputType,
              label: label,
              placeholder: placeholder,
              required: required,
            ),
          );
        }
      }

      final absoluteAction = action != null ? _makeAbsoluteUrl(action, baseUrl) : null;

      forms.add(
        WebFormData(
          action: absoluteAction,
          method: method,
          name: name,
          fields: fields,
          hasFileUpload: hasFileUpload,
        ),
      );
    }

    return forms;
  }

  /// Finds label text for a form input
  String? _findLabelForInput(dom.Element form, dom.Element input) {
    final inputId = input.attributes['id'];

    // Look for label with for attribute
    if (inputId != null) {
      final label = form.querySelector('label[for="$inputId"]');
      if (label != null) {
        return label.text.trim();
      }
    }

    // Look for parent label
    final parentLabel = input.parent;
    if (parentLabel?.localName == 'label') {
      return parentLabel!.text.trim();
    }

    // Look for nearby text
    final previousElement = input.previousElementSibling;
    if (previousElement?.localName == 'label') {
      return previousElement!.text.trim();
    }

    return null;
  }

  /// Extracts heading structure from the page
  List<Heading> _extractHeadings(dom.Document document) {
    final headings = <Heading>[];

    for (int level = 1; level <= 6; level++) {
      final headingElements = document.querySelectorAll('h$level');
      for (final heading in headingElements) {
        final text = heading.text.trim();
        final id = heading.attributes['id'];

        if (text.isNotEmpty) {
          headings.add(Heading(level: level, text: text, id: id));
        }
      }
    }

    return headings;
  }

  /// Classifies the content type of the page
  ContentType _classifyContentType(dom.Document document, String url) {
    final title = document.querySelector('title')?.text.toLowerCase() ?? '';
    final bodyText = document.body?.text.toLowerCase() ?? '';
    final urlLower = url.toLowerCase();

    // Check for e-commerce indicators
    if (_hasEcommerceIndicators(document, bodyText, urlLower)) {
      return ContentType.ecommerce;
    }

    // Check for news indicators
    if (_hasNewsIndicators(document, bodyText, urlLower)) {
      return ContentType.news;
    }

    // Check for blog indicators
    if (_hasBlogIndicators(document, bodyText, urlLower)) {
      return ContentType.blog;
    }

    // Check for documentation indicators
    if (_hasDocumentationIndicators(document, bodyText, urlLower)) {
      return ContentType.documentation;
    }

    // Check for portfolio indicators
    if (_hasPortfolioIndicators(document, bodyText, urlLower)) {
      return ContentType.portfolio;
    }

    // Check for forum indicators
    if (_hasForumIndicators(document, bodyText, urlLower)) {
      return ContentType.forum;
    }

    // Check for corporate indicators
    if (_hasCorporateIndicators(document, bodyText, urlLower)) {
      return ContentType.corporate;
    }

    // Default to article if has substantial content
    if (bodyText.split(' ').length > 500) {
      return ContentType.article;
    }

    return ContentType.unknown;
  }

  /// Checks for e-commerce indicators
  bool _hasEcommerceIndicators(dom.Document document, String bodyText, String url) {
    final ecommerceKeywords = [
      'price',
      'cart',
      'buy',
      'shop',
      'product',
      'order',
      'checkout',
      'payment',
    ];
    final hasKeywords = ecommerceKeywords.any((keyword) => bodyText.contains(keyword));

    final hasProductSchema = document.querySelector('[itemtype*="Product"]') != null;
    final hasPriceElements = document.querySelectorAll('.price, .cost, .amount').isNotEmpty;
    final hasCartButton = document.querySelector('[class*="cart"], [class*="buy"]') != null;

    return hasKeywords || hasProductSchema || hasPriceElements || hasCartButton;
  }

  /// Checks for news indicators
  bool _hasNewsIndicators(dom.Document document, String bodyText, String url) {
    final newsKeywords = ['news', 'breaking', 'report', 'journalist', 'editor', 'published'];
    final hasKeywords = newsKeywords.any((keyword) => bodyText.contains(keyword));

    final hasNewsSchema = document.querySelector('[itemtype*="NewsArticle"]') != null;
    final hasDateline = document.querySelector('.dateline, .publish-date, .news-date') != null;

    return hasKeywords || hasNewsSchema || hasDateline || url.contains('news');
  }

  /// Checks for blog indicators
  bool _hasBlogIndicators(dom.Document document, String bodyText, String url) {
    final blogKeywords = ['blog', 'post', 'author', 'comment', 'category', 'tag'];
    final hasKeywords = blogKeywords.any((keyword) => bodyText.contains(keyword));

    final hasBlogSchema = document.querySelector('[itemtype*="BlogPosting"]') != null;
    final hasComments = document.querySelector('.comments, .comment-section') != null;

    return hasKeywords || hasBlogSchema || hasComments || url.contains('blog');
  }

  /// Checks for documentation indicators
  bool _hasDocumentationIndicators(dom.Document document, String bodyText, String url) {
    final docKeywords = ['documentation', 'api', 'guide', 'tutorial', 'reference', 'manual'];
    final hasKeywords = docKeywords.any((keyword) => bodyText.contains(keyword));

    final hasCodeBlocks = document.querySelectorAll('pre, code').length > 3;
    final hasToc = document.querySelector('.toc, .table-of-contents') != null;

    return hasKeywords || hasCodeBlocks || hasToc || url.contains('docs');
  }

  /// Checks for portfolio indicators
  bool _hasPortfolioIndicators(dom.Document document, String bodyText, String url) {
    final portfolioKeywords = ['portfolio', 'work', 'project', 'gallery', 'showcase'];
    final hasKeywords = portfolioKeywords.any((keyword) => bodyText.contains(keyword));

    final hasGallery = document.querySelectorAll('.gallery, .portfolio-item').isNotEmpty;

    return hasKeywords || hasGallery || url.contains('portfolio');
  }

  /// Checks for forum indicators
  bool _hasForumIndicators(dom.Document document, String bodyText, String url) {
    final forumKeywords = ['forum', 'discussion', 'thread', 'reply', 'post', 'member'];
    final hasKeywords = forumKeywords.any((keyword) => bodyText.contains(keyword));

    final hasThreads = document.querySelectorAll('.thread, .topic, .discussion').isNotEmpty;

    return hasKeywords || hasThreads || url.contains('forum');
  }

  /// Checks for corporate indicators
  bool _hasCorporateIndicators(dom.Document document, String bodyText, String url) {
    final corporateKeywords = ['company', 'business', 'services', 'about us', 'contact us', 'team'];
    final hasKeywords = corporateKeywords.any((keyword) => bodyText.contains(keyword));

    final hasContactInfo = document.querySelector('.contact, .address, .phone') != null;

    return hasKeywords || hasContactInfo;
  }

  /// Performs SEO analysis on the page
  SeoAnalysis _performSeoAnalysis(
    dom.Document document,
    String? title,
    String? description,
    List<WebImage> images,
  ) {
    // Title analysis
    final hasTitle = title != null && title.isNotEmpty;
    final titleLength = title?.length ?? 0;

    // Meta description analysis
    final hasMetaDescription = description != null && description.isNotEmpty;
    final metaDescriptionLength = description?.length ?? 0;

    // H1 analysis
    final h1Elements = document.querySelectorAll('h1');
    final hasH1 = h1Elements.isNotEmpty;
    final h1Count = h1Elements.length;

    // Image alt analysis
    final imagesWithoutAlt = images.where((img) => img.alt == null || img.alt!.isEmpty).length;
    final hasImageAltTags = images.isNotEmpty && imagesWithoutAlt == 0;

    // Canonical URL
    final hasCanonical = document.querySelector('link[rel="canonical"]') != null;

    // Schema markup
    final hasSchema = document
        .querySelectorAll('[itemtype], script[type="application/ld+json"]')
        .isNotEmpty;

    return SeoAnalysis(
      hasTitle: hasTitle,
      titleLength: titleLength,
      hasMetaDescription: hasMetaDescription,
      metaDescriptionLength: metaDescriptionLength,
      hasH1: hasH1,
      h1Count: h1Count,
      hasImageAltTags: hasImageAltTags,
      imagesWithoutAlt: imagesWithoutAlt,
      hasCanonical: hasCanonical,
      hasSchema: hasSchema,
    );
  }

  /// Analyzes the page structure
  PageStructure _analyzePageStructure(dom.Document document) {
    final totalElements = document.querySelectorAll('*').length;

    // Count text blocks
    final textBlockSelectors = ['p', 'div', 'span', 'article', 'section'];
    int textBlocks = 0;
    for (final selector in textBlockSelectors) {
      textBlocks += document.querySelectorAll(selector).length;
    }

    // Count interactive elements
    final interactiveSelectors = ['a', 'button', 'input', 'select', 'textarea'];
    int interactiveElements = 0;
    for (final selector in interactiveSelectors) {
      interactiveElements += document.querySelectorAll(selector).length;
    }

    // Determine layout type based on structure
    final layoutType = _determineLayoutType(document);

    // Check for common page sections
    final hasNavigation = document.querySelector('nav, .navigation, .navbar') != null;
    final hasFooter = document.querySelector('footer') != null;
    final hasSidebar = document.querySelector('.sidebar, aside') != null;

    // Calculate content hierarchy depth
    final contentDepth = _calculateContentDepth(document);

    // Basic accessibility score
    final accessibilityScore = _calculateAccessibilityScore(document);

    return PageStructure(
      totalElements: totalElements,
      textBlocks: textBlocks,
      interactiveElements: interactiveElements,
      layoutType: layoutType,
      hasNavigation: hasNavigation,
      hasFooter: hasFooter,
      hasSidebar: hasSidebar,
      contentDepth: contentDepth,
      accessibilityScore: accessibilityScore,
    );
  }

  /// Determines the layout type of the page
  LayoutType _determineLayoutType(dom.Document document) {
    // Check for e-commerce indicators
    if (document.querySelectorAll('.product, .cart, .price').isNotEmpty) {
      return LayoutType.ecommerce;
    }

    // Check for blog indicators
    if (document.querySelectorAll('.post, .article, .blog-post').isNotEmpty) {
      return LayoutType.blog;
    }

    // Check for news indicators
    if (document.querySelectorAll('.news, .article, .story').isNotEmpty) {
      return LayoutType.news;
    }

    // Check for portfolio indicators
    if (document.querySelectorAll('.portfolio, .gallery, .project').isNotEmpty) {
      return LayoutType.portfolio;
    }

    // Check for dashboard indicators
    if (document.querySelectorAll('.dashboard, .panel, .widget').isNotEmpty) {
      return LayoutType.dashboard;
    }

    // Check for forum indicators
    if (document.querySelectorAll('.forum, .thread, .discussion').isNotEmpty) {
      return LayoutType.forum;
    }

    // Check for documentation indicators
    if (document.querySelectorAll('.docs, .documentation, pre, code').length > 3) {
      return LayoutType.documentation;
    }

    // Check for landing page indicators
    if (document.querySelectorAll('.hero, .cta, .landing').isNotEmpty) {
      return LayoutType.landing;
    }

    // Default to corporate
    return LayoutType.corporate;
  }

  /// Calculates content hierarchy depth
  int _calculateContentDepth(dom.Document document) {
    int maxDepth = 0;

    void calculateDepth(dom.Element element, int currentDepth) {
      if (currentDepth > maxDepth) {
        maxDepth = currentDepth;
      }

      for (final child in element.children) {
        calculateDepth(child, currentDepth + 1);
      }
    }

    final body = document.querySelector('body');
    if (body != null) {
      calculateDepth(body, 0);
    }

    return maxDepth;
  }

  /// Calculates basic accessibility score
  int _calculateAccessibilityScore(dom.Document document) {
    int score = 100;

    // Check for alt attributes on images
    final images = document.querySelectorAll('img');
    final imagesWithoutAlt = images.where((img) => img.attributes['alt'] == null).length;
    if (images.isNotEmpty) {
      score -= (imagesWithoutAlt / images.length * 20).round();
    }

    // Check for form labels
    final inputs = document.querySelectorAll('input[type="text"], input[type="email"], textarea');
    final inputsWithoutLabels = inputs.where((input) {
      final id = input.attributes['id'];
      return id == null || document.querySelector('label[for="$id"]') == null;
    }).length;
    if (inputs.isNotEmpty) {
      score -= (inputsWithoutLabels / inputs.length * 15).round();
    }

    // Check for heading structure
    final h1Count = document.querySelectorAll('h1').length;
    if (h1Count == 0) score -= 10;
    if (h1Count > 1) score -= 5;

    // Check for semantic elements
    if (document.querySelector('main') == null) score -= 5;
    if (document.querySelector('nav') == null) score -= 5;
    if (document.querySelector('header') == null) score -= 5;
    if (document.querySelector('footer') == null) score -= 5;

    return score.clamp(0, 100);
  }

  /// Performs basic sentiment analysis on text content
  SentimentAnalysis _analyzeSentiment(String content) {
    final positiveWords = [
      'good',
      'great',
      'excellent',
      'amazing',
      'wonderful',
      'fantastic',
      'awesome',
      'love',
      'best',
      'perfect',
      'outstanding',
      'brilliant',
      'superb',
      'magnificent',
      'happy',
      'pleased',
      'satisfied',
      'delighted',
      'thrilled',
      'excited',
      'beautiful',
      'impressive',
      'remarkable',
      'exceptional',
      'successful',
    ];

    final negativeWords = [
      'bad',
      'terrible',
      'awful',
      'horrible',
      'worst',
      'hate',
      'disgusting',
      'disappointing',
      'failed',
      'broken',
      'wrong',
      'error',
      'problem',
      'issue',
      'sad',
      'angry',
      'frustrated',
      'annoying',
      'difficult',
      'hard',
      'ugly',
      'poor',
      'weak',
      'useless',
      'worthless',
      'pathetic',
    ];

    final words = content.toLowerCase().split(RegExp(r'\W+'));

    int positiveCount = 0;
    int negativeCount = 0;
    final foundPositive = <String>[];
    final foundNegative = <String>[];

    for (final word in words) {
      if (positiveWords.contains(word)) {
        positiveCount++;
        if (!foundPositive.contains(word)) foundPositive.add(word);
      } else if (negativeWords.contains(word)) {
        negativeCount++;
        if (!foundNegative.contains(word)) foundNegative.add(word);
      }
    }

    final totalSentimentWords = positiveCount + negativeCount;
    double sentimentScore = 0.0;
    SentimentType sentimentType = SentimentType.neutral;
    double confidence = 0.0;

    if (totalSentimentWords > 0) {
      sentimentScore = (positiveCount - negativeCount) / totalSentimentWords;
      confidence = totalSentimentWords / words.length;

      if (sentimentScore > 0.1) {
        sentimentType = SentimentType.positive;
      } else if (sentimentScore < -0.1) {
        sentimentType = SentimentType.negative;
      } else if (positiveCount > 0 && negativeCount > 0) {
        sentimentType = SentimentType.mixed;
      }
    }

    return SentimentAnalysis(
      sentimentScore: sentimentScore,
      sentimentType: sentimentType,
      confidence: confidence.clamp(0.0, 1.0),
      positiveKeywords: foundPositive,
      negativeKeywords: foundNegative,
    );
  }

  /// Extracts comments and reviews from the page
  List<Comment> _extractComments(dom.Document document) {
    final comments = <Comment>[];

    // Common comment selectors
    final commentSelectors = [
      '.comment',
      '.review',
      '.feedback',
      '.testimonial',
      '.comment-item',
      '.review-item',
      '.user-comment',
      '[itemtype*="Review"]',
      '[itemtype*="Comment"]',
    ];

    for (final selector in commentSelectors) {
      final commentElements = document.querySelectorAll(selector);
      for (final element in commentElements) {
        final text = element.text.trim();
        if (text.isEmpty) continue;

        // Try to extract author
        String? author;
        final authorElement = element.querySelector('.author, .user, .name, [itemprop="author"]');
        if (authorElement != null) {
          author = authorElement.text.trim();
        }

        // Try to extract date
        DateTime? date;
        final dateElement = element.querySelector('.date, .time, [itemprop="datePublished"]');
        if (dateElement != null) {
          final dateText = dateElement.text.trim();
          date = _parseDate(dateText);
        }

        // Try to extract rating
        double? rating;
        final ratingElement = element.querySelector('.rating, .stars, [itemprop="ratingValue"]');
        if (ratingElement != null) {
          final ratingText = ratingElement.text.trim();
          rating = double.tryParse(ratingText.replaceAll(RegExp(r'[^\d.]'), ''));
        }

        comments.add(
          Comment(
            author: author,
            text: text,
            date: date,
            rating: rating,
            replyCount: element.querySelectorAll('.reply, .response').length,
          ),
        );
      }
    }

    return comments;
  }

  /// Extracts product information from e-commerce pages
  ProductInfo? _extractProductInfo(dom.Document document) {
    // Check if this looks like a product page
    final hasProductIndicators = document
        .querySelectorAll('.product, .item, [itemtype*="Product"], .price, .add-to-cart')
        .isNotEmpty;

    if (!hasProductIndicators) return null;

    // Extract product name
    String? name;
    final nameSelectors = ['h1', '.product-title', '.product-name', '[itemprop="name"]'];
    for (final selector in nameSelectors) {
      final element = document.querySelector(selector);
      if (element != null && element.text.trim().isNotEmpty) {
        name = element.text.trim();
        break;
      }
    }

    // Extract price
    double? price;
    String? currency;
    final priceSelectors = ['.price', '.cost', '.amount', '[itemprop="price"]'];
    for (final selector in priceSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final priceText = element.text.trim();
        final priceMatch = RegExp(r'[\d.,]+').firstMatch(priceText);
        if (priceMatch != null) {
          price = double.tryParse(priceMatch.group(0)!.replaceAll(',', ''));

          // Extract currency
          final currencyMatch = RegExp(r'[A-Z]{3}|[$€£¥₹]').firstMatch(priceText);
          if (currencyMatch != null) {
            currency = currencyMatch.group(0);
          }
          break;
        }
      }
    }

    // Extract description
    String? description;
    final descSelectors = ['.product-description', '.description', '[itemprop="description"]'];
    for (final selector in descSelectors) {
      final element = document.querySelector(selector);
      if (element != null && element.text.trim().isNotEmpty) {
        description = element.text.trim();
        break;
      }
    }

    // Extract brand
    String? brand;
    final brandElement = document.querySelector('[itemprop="brand"], .brand');
    if (brandElement != null) {
      brand = brandElement.text.trim();
    }

    // Extract rating
    double? rating;
    int? reviewCount;
    final ratingElement = document.querySelector('[itemprop="ratingValue"], .rating');
    if (ratingElement != null) {
      final ratingText = ratingElement.text.trim();
      rating = double.tryParse(ratingText.replaceAll(RegExp(r'[^\d.]'), ''));
    }

    final reviewElement = document.querySelector('[itemprop="reviewCount"], .review-count');
    if (reviewElement != null) {
      final reviewText = reviewElement.text.trim();
      reviewCount = int.tryParse(reviewText.replaceAll(RegExp(r'[^\d]'), ''));
    }

    // Extract availability
    String? availability;
    final availElement = document.querySelector('[itemprop="availability"], .availability, .stock');
    if (availElement != null) {
      availability = availElement.text.trim();
    }

    // Extract images
    final images = <String>[];
    final imgElements = document.querySelectorAll('.product-image img, .gallery img');
    for (final img in imgElements) {
      final src = img.attributes['src'];
      if (src != null && src.isNotEmpty) {
        images.add(src);
      }
    }

    // Extract categories
    final categories = <String>[];
    final catElements = document.querySelectorAll(
      '.category, .breadcrumb a, [itemprop="category"]',
    );
    for (final cat in catElements) {
      final text = cat.text.trim();
      if (text.isNotEmpty && !categories.contains(text)) {
        categories.add(text);
      }
    }

    // Extract SKU
    String? sku;
    final skuElement = document.querySelector('[itemprop="sku"], .sku, .product-code');
    if (skuElement != null) {
      sku = skuElement.text.trim();
    }

    return ProductInfo(
      name: name,
      price: price,
      currency: currency,
      description: description,
      brand: brand,
      rating: rating,
      reviewCount: reviewCount,
      availability: availability,
      images: images,
      categories: categories,
      sku: sku,
    );
  }

  /// Extracts article-specific information
  ArticleInfo? _extractArticleInfo(dom.Document document) {
    // Check if this looks like an article/news page
    final hasArticleIndicators = document
        .querySelectorAll('article, .article, .post, .news, [itemtype*="Article"]')
        .isNotEmpty;

    if (!hasArticleIndicators) return null;

    // Extract category
    String? category;
    final categorySelectors = ['.category', '.section', '[itemprop="articleSection"]'];
    for (final selector in categorySelectors) {
      final element = document.querySelector(selector);
      if (element != null && element.text.trim().isNotEmpty) {
        category = element.text.trim();
        break;
      }
    }

    // Extract tags
    final tags = <String>[];
    final tagElements = document.querySelectorAll('.tag, .tags a, [rel="tag"]');
    for (final tag in tagElements) {
      final text = tag.text.trim();
      if (text.isNotEmpty && !tags.contains(text)) {
        tags.add(text);
      }
    }

    // Extract summary/excerpt
    String? summary;
    final summarySelectors = ['.excerpt', '.summary', '.lead', '[itemprop="description"]'];
    for (final selector in summarySelectors) {
      final element = document.querySelector(selector);
      if (element != null && element.text.trim().isNotEmpty) {
        summary = element.text.trim();
        break;
      }
    }

    // Extract related articles
    final relatedArticles = <String>[];
    final relatedElements = document.querySelectorAll('.related a, .similar a, .more-articles a');
    for (final related in relatedElements) {
      final text = related.text.trim();
      if (text.isNotEmpty && !relatedArticles.contains(text)) {
        relatedArticles.add(text);
      }
    }

    // Extract source
    String? source;
    final sourceElement = document.querySelector('.source, .publisher, [itemprop="publisher"]');
    if (sourceElement != null) {
      source = sourceElement.text.trim();
    }

    // Extract modified date
    DateTime? modifiedDate;
    final modifiedElement = document.querySelector('[itemprop="dateModified"], .modified-date');
    if (modifiedElement != null) {
      final dateText = modifiedElement.text.trim();
      modifiedDate = _parseDate(dateText);
    }

    // Extract section
    String? section;
    final sectionElement = document.querySelector('.section, .department');
    if (sectionElement != null) {
      section = sectionElement.text.trim();
    }

    return ArticleInfo(
      category: category,
      tags: tags,
      summary: summary,
      relatedArticles: relatedArticles,
      source: source,
      modifiedDate: modifiedDate,
      section: section,
    );
  }

  /// Creates performance metrics
  PerformanceMetrics _createPerformanceMetrics(int processingTime, dom.Document document) {
    // Estimate page size based on HTML length
    final htmlSize = document.outerHtml.length;

    // Count estimated HTTP requests (images, scripts, stylesheets)
    final requestCount =
        document.querySelectorAll('img, script, link[rel="stylesheet"]').length + 1; // +1 for HTML

    // Check for compression indicators
    final compressed =
        document.querySelector('meta[name="generator"]')?.attributes['content']?.contains('gzip') ??
        false;

    // Check for cache headers (we can't really detect this from HTML, so default to false)
    const hasCacheHeaders = false;

    return PerformanceMetrics(
      loadTime: null, // Can't measure actual load time in this context
      responseTime: processingTime,
      pageSize: htmlSize,
      requestCount: requestCount,
      compressed: compressed,
      hasCacheHeaders: hasCacheHeaders,
    );
  }

  /// Helper method to parse dates from various formats
  DateTime? _parseDate(String dateText) {
    if (dateText.isEmpty) return null;

    // Try ISO format first
    try {
      return DateTime.parse(dateText);
    } catch (e) {
      // Ignore and try other formats
    }

    // Try common date formats
    final dateFormats = [
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'),
    ];

    for (final format in dateFormats) {
      final match = format.firstMatch(dateText);
      if (match != null) {
        try {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);
          return DateTime(year, month, day);
        } catch (e) {
          // Continue to next format
        }
      }
    }

    return null;
  }
}
