import 'dart:convert';
import 'package:freeaihub/core/models/tools/web_scraper_model.dart';
import 'package:html/dom.dart' as dom;

/// Helper class containing utility methods for web scraping operations
class WebScraperHelpers {
  /// Common CSS selectors for extracting specific content types
  static const Map<String, List<String>> contentSelectors = {
    'article': [
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
      '.article-text',
      '.text-content',
    ],
    'navigation': ['nav', '.nav', '.navigation', '.menu', '.navbar', '#navigation', '#menu'],
    'sidebar': ['aside', '.sidebar', '.side-bar', '#sidebar', '.widget'],
    'footer': ['footer', '.footer', '#footer'],
    'header': ['header', '.header', '#header'],
    'ads': [
      '.ad',
      '.ads',
      '.advertisement',
      '.sponsor',
      '.adsbygoogle',
      '[id*="ad"]',
      '[class*="ad"]',
    ],
    'social': ['.social-share', '.social-media', '.share-buttons', '.social-links'],
    'comments': ['.comments', '.comment-section', '#comments', '.disqus'],
  };

  /// Common noise selectors to remove from content
  static const List<String> noiseSelectors = [
    'script',
    'style',
    'noscript',
    'iframe',
    'object',
    'embed',
    '.hidden',
    '.invisible',
    '[style*="display:none"]',
    '[style*="visibility:hidden"]',
  ];

  /// Cleans HTML content by removing unwanted elements and normalizing text
  static String cleanHtmlContent(dom.Document document) {
    final body = document.querySelector('body');
    if (body == null) return '';

    // Remove noise elements
    for (final selector in noiseSelectors) {
      body.querySelectorAll(selector).forEach((element) => element.remove());
    }

    // Remove navigation, ads, and other non-content elements
    for (final selectors in [
      contentSelectors['navigation']!,
      contentSelectors['sidebar']!,
      contentSelectors['footer']!,
      contentSelectors['header']!,
      contentSelectors['ads']!,
      contentSelectors['social']!,
      contentSelectors['comments']!,
    ]) {
      for (final selector in selectors) {
        body.querySelectorAll(selector).forEach((element) => element.remove());
      }
    }

    return normalizeText(body.text);
  }

  /// Normalizes text by cleaning up whitespace and formatting
  static String normalizeText(String text) {
    if (text.isEmpty) return '';

    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Clean up multiple newlines
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '') // Trim each line
        .trim();
  }

  /// Extracts the best available title from various sources
  static String? extractBestTitle(dom.Document document) {
    // Priority order for title extraction
    final titleSources = [
      () => document.querySelector('meta[property="og:title"]')?.attributes['content'],
      () => document.querySelector('meta[name="twitter:title"]')?.attributes['content'],
      () => document.querySelector('[itemProp="headline"]')?.text,
      () => document.querySelector('h1')?.text,
      () => document.querySelector('title')?.text,
    ];

    for (final source in titleSources) {
      final title = source()?.trim();
      if (title != null && title.isNotEmpty && title.length > 3) {
        return title;
      }
    }

    return null;
  }

  /// Extracts the best available description from various sources
  static String? extractBestDescription(dom.Document document) {
    // Priority order for description extraction
    final descriptionSources = [
      () => document.querySelector('meta[property="og:description"]')?.attributes['content'],
      () => document.querySelector('meta[name="twitter:description"]')?.attributes['content'],
      () => document.querySelector('meta[name="description"]')?.attributes['content'],
      () => document.querySelector('[itemProp="description"]')?.text,
    ];

    for (final source in descriptionSources) {
      final description = source()?.trim();
      if (description != null && description.isNotEmpty && description.length > 10) {
        return description;
      }
    }

    return null;
  }

  /// Extracts structured data from JSON-LD scripts
  static List<Map<String, dynamic>> extractJsonLdData(dom.Document document) {
    final jsonLdData = <Map<String, dynamic>>[];
    final scripts = document.querySelectorAll('script[type="application/ld+json"]');

    for (final script in scripts) {
      try {
        final data = json.decode(script.text);
        if (data is Map<String, dynamic>) {
          jsonLdData.add(data);
        } else if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              jsonLdData.add(item);
            }
          }
        }
      } catch (e) {
        // Ignore invalid JSON
        continue;
      }
    }

    return jsonLdData;
  }

  /// Extracts microdata from the document
  static List<Map<String, dynamic>> extractMicrodata(dom.Document document) {
    final microdataItems = <Map<String, dynamic>>[];
    final elements = document.querySelectorAll('[itemscope]');

    for (final element in elements) {
      final itemType = element.attributes['itemtype'];
      if (itemType == null) continue;

      final item = <String, dynamic>{'@type': itemType};
      final properties = element.querySelectorAll('[itemprop]');

      for (final prop in properties) {
        final name = prop.attributes['itemprop'];
        if (name == null) continue;

        String? value;
        if (prop.attributes.containsKey('content')) {
          value = prop.attributes['content'];
        } else if (prop.attributes.containsKey('datetime')) {
          value = prop.attributes['datetime'];
        } else if (prop.attributes.containsKey('href')) {
          value = prop.attributes['href'];
        } else if (prop.attributes.containsKey('src')) {
          value = prop.attributes['src'];
        } else {
          value = prop.text.trim();
        }

        if (value != null && value.isNotEmpty) {
          item[name] = value;
        }
      }

      if (item.length > 1) {
        microdataItems.add(item);
      }
    }

    return microdataItems;
  }

  /// Validates and normalizes URLs
  static String? normalizeUrl(String url) {
    try {
      final uri = Uri.parse(url.trim());
      if (!uri.hasScheme) {
        return null;
      }

      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return null;
      }

      return uri.toString();
    } catch (e) {
      return null;
    }
  }

  /// Converts relative URLs to absolute URLs
  static String? resolveUrl(String url, String baseUrl) {
    try {
      final base = Uri.parse(baseUrl);
      final resolved = base.resolve(url);
      return resolved.toString();
    } catch (e) {
      return null;
    }
  }

  /// Extracts all unique links from the document
  static Set<String> extractAllLinks(dom.Document document, String baseUrl) {
    final links = <String>{};
    final linkElements = document.querySelectorAll('a[href]');

    for (final element in linkElements) {
      final href = element.attributes['href'];
      if (href == null || href.isEmpty) continue;

      final absoluteUrl = resolveUrl(href, baseUrl);
      if (absoluteUrl != null && normalizeUrl(absoluteUrl) != null) {
        links.add(absoluteUrl);
      }
    }

    return links;
  }

  /// Extracts images with detailed metadata
  static List<WebImage> extractDetailedImages(dom.Document document, String baseUrl) {
    final images = <WebImage>[];
    final imgElements = document.querySelectorAll('img');

    for (final img in imgElements) {
      final src = img.attributes['src'];
      if (src == null || src.isEmpty) continue;

      final absoluteUrl = resolveUrl(src, baseUrl);
      if (absoluteUrl == null || normalizeUrl(absoluteUrl) == null) continue;

      final alt = img.attributes['alt'];
      final width = int.tryParse(img.attributes['width'] ?? '');
      final height = int.tryParse(img.attributes['height'] ?? '');

      // Try to determine format from URL
      String? format;
      final uri = Uri.tryParse(absoluteUrl);
      if (uri != null) {
        final path = uri.path.toLowerCase();
        if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
          format = 'jpeg';
        } else if (path.endsWith('.png')) {
          format = 'png';
        } else if (path.endsWith('.gif')) {
          format = 'gif';
        } else if (path.endsWith('.webp')) {
          format = 'webp';
        } else if (path.endsWith('.svg')) {
          format = 'svg';
        }
      }

      images.add(
        WebImage(
          url: absoluteUrl,
          alt: alt?.isNotEmpty == true ? alt : null,
          width: width,
          height: height,
          format: format,
        ),
      );
    }

    return images;
  }

  /// Calculates reading time based on word count
  static int calculateReadingTime(int wordCount, {int wordsPerMinute = 200}) {
    if (wordCount <= 0) return 0;
    final minutes = (wordCount / wordsPerMinute).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  /// Extracts keywords from meta tags and content
  static List<String> extractKeywords(dom.Document document) {
    final keywords = <String>{};

    // Extract from meta keywords
    final metaKeywords = document.querySelector('meta[name="keywords"]')?.attributes['content'];
    if (metaKeywords != null && metaKeywords.isNotEmpty) {
      keywords.addAll(metaKeywords.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty));
    }

    // Extract from article tags
    final articleTags = document.querySelectorAll('meta[property="article:tag"]');
    for (final tag in articleTags) {
      final content = tag.attributes['content'];
      if (content != null && content.isNotEmpty) {
        keywords.add(content.trim());
      }
    }

    // Extract from hashtags in content
    final hashtagPattern = RegExp(r'#\w+');
    final bodyText = document.body?.text ?? '';
    final hashtags = hashtagPattern.allMatches(bodyText).map((m) => m.group(0)!.substring(1));
    keywords.addAll(hashtags);

    return keywords.toList();
  }

  /// Extracts author information from various sources
  static String? extractAuthor(dom.Document document) {
    // Priority order for author extraction
    final authorSources = [
      () => document.querySelector('meta[name="author"]')?.attributes['content'],
      () => document.querySelector('meta[property="article:author"]')?.attributes['content'],
      () => document.querySelector('[rel="author"]')?.text,
      () => document.querySelector('[itemprop="author"]')?.text,
      () => document.querySelector('.author')?.text,
      () => document.querySelector('.byline')?.text,
      () => document.querySelector('.writer')?.text,
      () => document.querySelector('.post-author')?.text,
    ];

    for (final source in authorSources) {
      final author = source()?.trim();
      if (author != null && author.isNotEmpty && author.length < 100) {
        return author;
      }
    }

    return null;
  }

  /// Extracts publication date from various sources
  static DateTime? extractPublishDate(dom.Document document) {
    // Priority order for date extraction
    final dateSources = [
      () => document.querySelector('[itemprop="datePublished"]')?.attributes['datetime'],
      () => document.querySelector('[itemprop="datePublished"]')?.attributes['content'],
      () =>
          document.querySelector('meta[property="article:published_time"]')?.attributes['content'],
      () => document.querySelector('meta[name="date"]')?.attributes['content'],
      () => document.querySelector('time[datetime]')?.attributes['datetime'],
      () => document.querySelector('.date')?.attributes['datetime'],
      () => document.querySelector('.published')?.attributes['datetime'],
    ];

    for (final source in dateSources) {
      final dateStr = source()?.trim();
      if (dateStr != null && dateStr.isNotEmpty) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          return date;
        }
      }
    }

    return null;
  }

  /// Extracts language from document
  static String? extractLanguage(dom.Document document) {
    // Try HTML lang attribute first
    final htmlLang = document.querySelector('html')?.attributes['lang'];
    if (htmlLang != null && htmlLang.isNotEmpty) {
      return htmlLang.split('-')[0]; // Get primary language code
    }

    // Try meta content-language
    final metaLang = document
        .querySelector('meta[http-equiv="content-language"]')
        ?.attributes['content'];
    if (metaLang != null && metaLang.isNotEmpty) {
      return metaLang.split('-')[0]; // Get primary language code
    }

    return null;
  }

  /// Detects if the content is likely to be meaningful article content
  static bool isContentMeaningful(String? content) {
    if (content == null || content.isEmpty) return false;

    // Basic checks for meaningful content
    final wordCount = content.split(RegExp(r'\s+')).length;
    final sentenceCount = content.split(RegExp(r'[.!?]')).length;

    return wordCount >= 50 && // At least 50 words
        sentenceCount >= 3 && // At least 3 sentences
        content.length >= 200 && // At least 200 characters
        !content.contains('404') && // Not an error page
        !content.toLowerCase().contains('page not found');
  }

  /// Extracts breadcrumb navigation if available
  static List<String> extractBreadcrumbs(dom.Document document) {
    final breadcrumbs = <String>[];

    // Try structured data breadcrumbs
    final jsonLd = extractJsonLdData(document);
    for (final data in jsonLd) {
      if (data['@type'] == 'BreadcrumbList' && data['itemListElement'] is List) {
        final items = data['itemListElement'] as List;
        for (final item in items) {
          if (item is Map && item['name'] != null) {
            breadcrumbs.add(item['name'].toString());
          }
        }
      }
    }

    if (breadcrumbs.isNotEmpty) return breadcrumbs;

    // Try microdata breadcrumbs
    final breadcrumbElements = document.querySelectorAll(
      '[itemtype*="BreadcrumbList"] [itemprop="name"]',
    );
    for (final element in breadcrumbElements) {
      final name = element.text.trim();
      if (name.isNotEmpty) {
        breadcrumbs.add(name);
      }
    }

    if (breadcrumbs.isNotEmpty) return breadcrumbs;

    // Try common breadcrumb selectors
    final breadcrumbSelectors = [
      '.breadcrumb',
      '.breadcrumbs',
      '.crumb',
      '.crumbs',
      '[aria-label="Breadcrumb"]',
    ];
    for (final selector in breadcrumbSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final links = element.querySelectorAll('a');
        for (final link in links) {
          final text = link.text.trim();
          if (text.isNotEmpty) {
            breadcrumbs.add(text);
          }
        }
        if (breadcrumbs.isNotEmpty) break;
      }
    }

    return breadcrumbs;
  }

  /// Generates a summary of the scraping result
  static String generateScrapingSummary(WebScrapingResult result) {
    if (!result.success) {
      return 'Scraping failed for ${result.url}: ${result.error}';
    }

    final data = result.data!;
    final summary = StringBuffer();

    summary.writeln('=== Web Scraping Summary ===');
    summary.writeln('URL: ${result.url}');
    summary.writeln('Status: ${result.success ? 'Success' : 'Failed'}');
    summary.writeln('Timestamp: ${result.timestamp}');

    if (data.title != null) {
      summary.writeln('Title: ${data.title}');
    }

    if (data.description != null) {
      summary.writeln(
        'Description: ${data.description?.substring(0, data.description!.length > 100 ? 100 : data.description!.length)}${data.description!.length > 100 ? '...' : ''}',
      );
    }

    if (data.author != null) {
      summary.writeln('Author: ${data.author}');
    }

    if (data.publishDate != null) {
      summary.writeln('Published: ${data.publishDate}');
    }

    if (data.language != null) {
      summary.writeln('Language: ${data.language}');
    }

    if (data.wordCount != null) {
      summary.writeln('Words: ${data.wordCount}');
    }

    if (data.readingTimeMinutes != null) {
      summary.writeln('Reading Time: ${data.readingTimeMinutes} min');
    }

    summary.writeln('Images: ${data.images.length}');
    summary.writeln('Links: ${data.links.length}');
    summary.writeln('Keywords: ${data.keywords.length}');

    if (data.socialMetadata != null) {
      summary.writeln('Social Media Metadata: Available');
    }

    if (data.structuredData.isNotEmpty) {
      summary.writeln('Structured Data: ${data.structuredData.keys.length} types');
    }

    return summary.toString();
  }
}
