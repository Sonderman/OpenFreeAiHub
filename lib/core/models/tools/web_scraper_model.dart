/// Represents the result of a web scraping operation
class WebScrapingResult {
  /// The URL that was scraped
  final String url;

  /// Whether the scraping operation was successful
  final bool success;

  /// The scraped content data
  final WebPageData? data;

  /// Error message if scraping failed
  final String? error;

  /// HTTP status code of the request
  final int? statusCode;

  /// Time when the scraping was performed
  final DateTime timestamp;

  const WebScrapingResult({
    required this.url,
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    required this.timestamp,
  });

  /// Create a successful scraping result
  factory WebScrapingResult.success({
    required String url,
    required WebPageData data,
    int? statusCode,
  }) {
    return WebScrapingResult(
      url: url,
      success: true,
      data: data,
      statusCode: statusCode,
      timestamp: DateTime.now(),
    );
  }

  /// Create a failed scraping result
  factory WebScrapingResult.failure({required String url, required String error, int? statusCode}) {
    return WebScrapingResult(
      url: url,
      success: false,
      error: error,
      statusCode: statusCode,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'success': success,
      'data': data?.toJson(),
      'error': error,
      'statusCode': statusCode,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WebScrapingResult.fromJson(Map<String, dynamic> json) {
    return WebScrapingResult(
      url: json['url'],
      success: json['success'],
      data: json['data'] != null ? WebPageData.fromJson(json['data']) : null,
      error: json['error'],
      statusCode: json['statusCode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Represents the scraped data from a web page
class WebPageData {
  /// Page title
  final String? title;

  /// Page description (meta description)
  final String? description;

  /// Main text content of the page
  final String? content;

  /// List of extracted links
  final List<String> links;

  /// List of extracted images
  final List<WebImage> images;

  /// Meta tags from the page
  final Map<String, String> metaTags;

  /// Page language (if detected)
  final String? language;

  /// Page author (if available)
  final String? author;

  /// Publication date (if available)
  final DateTime? publishDate;

  /// Keywords/tags from the page
  final List<String> keywords;

  /// Structured data extracted from the page
  final Map<String, dynamic> structuredData;

  /// Social media metadata (Open Graph, Twitter Card)
  final SocialMetadata? socialMetadata;

  /// Reading time estimate in minutes
  final int? readingTimeMinutes;

  /// Word count of the main content
  final int? wordCount;

  /// Page structure analysis
  final PageStructure? pageStructure;

  /// Extracted contact information
  final ContactInfo? contactInfo;

  /// Navigation elements
  final NavigationData? navigationData;

  /// Media content (videos, audio)
  final MediaContent? mediaContent;

  /// Tables data
  final List<TableData> tables;

  /// Forms data
  final List<WebFormData> forms;

  /// Content type classification
  final ContentType? contentType;

  /// SEO analysis data
  final SeoAnalysis? seoAnalysis;

  /// Performance metrics
  final PerformanceMetrics? performanceMetrics;

  /// Comments/reviews if found
  final List<Comment> comments;

  /// Product information if it's an e-commerce page
  final ProductInfo? productInfo;

  /// News/article specific information
  final ArticleInfo? articleInfo;

  /// Extracted headings hierarchy
  final List<Heading> headings;

  /// Text sentiment analysis
  final SentimentAnalysis? sentimentAnalysis;

  const WebPageData({
    this.title,
    this.description,
    this.content,
    this.links = const [],
    this.images = const [],
    this.metaTags = const {},
    this.language,
    this.author,
    this.publishDate,
    this.keywords = const [],
    this.structuredData = const {},
    this.socialMetadata,
    this.readingTimeMinutes,
    this.wordCount,
    this.pageStructure,
    this.contactInfo,
    this.navigationData,
    this.mediaContent,
    this.tables = const [],
    this.forms = const [],
    this.contentType,
    this.seoAnalysis,
    this.performanceMetrics,
    this.comments = const [],
    this.productInfo,
    this.articleInfo,
    this.headings = const [],
    this.sentimentAnalysis,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'links': links,
      'images': images.map((img) => img.toJson()).toList(),
      'metaTags': metaTags,
      'language': language,
      'author': author,
      'publishDate': publishDate?.toIso8601String(),
      'keywords': keywords,
      'structuredData': structuredData,
      'socialMetadata': socialMetadata?.toJson(),
      'readingTimeMinutes': readingTimeMinutes,
      'wordCount': wordCount,
      'pageStructure': pageStructure?.toJson(),
      'contactInfo': contactInfo?.toJson(),
      'navigationData': navigationData?.toJson(),
      'mediaContent': mediaContent?.toJson(),
      'tables': tables.map((table) => table.toJson()).toList(),
      'forms': forms.map((form) => form.toJson()).toList(),
      'contentType': contentType?.name,
      'seoAnalysis': seoAnalysis?.toJson(),
      'performanceMetrics': performanceMetrics?.toJson(),
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'productInfo': productInfo?.toJson(),
      'articleInfo': articleInfo?.toJson(),
      'headings': headings.map((heading) => heading.toJson()).toList(),
      'sentimentAnalysis': sentimentAnalysis?.toJson(),
    };
  }

  factory WebPageData.fromJson(Map<String, dynamic> json) {
    return WebPageData(
      title: json['title'],
      description: json['description'],
      content: json['content'],
      links: List<String>.from(json['links'] ?? []),
      images: (json['images'] as List?)?.map((img) => WebImage.fromJson(img)).toList() ?? [],
      metaTags: Map<String, String>.from(json['metaTags'] ?? {}),
      language: json['language'],
      author: json['author'],
      publishDate: json['publishDate'] != null ? DateTime.parse(json['publishDate']) : null,
      keywords: List<String>.from(json['keywords'] ?? []),
      structuredData: Map<String, dynamic>.from(json['structuredData'] ?? {}),
      socialMetadata: json['socialMetadata'] != null
          ? SocialMetadata.fromJson(json['socialMetadata'])
          : null,
      readingTimeMinutes: json['readingTimeMinutes'],
      wordCount: json['wordCount'],
      pageStructure: json['pageStructure'] != null
          ? PageStructure.fromJson(json['pageStructure'])
          : null,
      contactInfo: json['contactInfo'] != null ? ContactInfo.fromJson(json['contactInfo']) : null,
      navigationData: json['navigationData'] != null
          ? NavigationData.fromJson(json['navigationData'])
          : null,
      mediaContent: json['mediaContent'] != null
          ? MediaContent.fromJson(json['mediaContent'])
          : null,
      tables: (json['tables'] as List?)?.map((table) => TableData.fromJson(table)).toList() ?? [],
      forms: (json['forms'] as List?)?.map((form) => WebFormData.fromJson(form)).toList() ?? [],
      contentType: json['contentType'] != null
          ? ContentType.values.firstWhere((e) => e.name == json['contentType'])
          : null,
      seoAnalysis: json['seoAnalysis'] != null ? SeoAnalysis.fromJson(json['seoAnalysis']) : null,
      performanceMetrics: json['performanceMetrics'] != null
          ? PerformanceMetrics.fromJson(json['performanceMetrics'])
          : null,
      comments:
          (json['comments'] as List?)?.map((comment) => Comment.fromJson(comment)).toList() ?? [],
      productInfo: json['productInfo'] != null ? ProductInfo.fromJson(json['productInfo']) : null,
      articleInfo: json['articleInfo'] != null ? ArticleInfo.fromJson(json['articleInfo']) : null,
      headings:
          (json['headings'] as List?)?.map((heading) => Heading.fromJson(heading)).toList() ?? [],
      sentimentAnalysis: json['sentimentAnalysis'] != null
          ? SentimentAnalysis.fromJson(json['sentimentAnalysis'])
          : null,
    );
  }
}

/// Represents page structure analysis
class PageStructure {
  /// Total number of elements
  final int totalElements;

  /// Number of text blocks
  final int textBlocks;

  /// Number of interactive elements
  final int interactiveElements;

  /// Page layout type
  final LayoutType layoutType;

  /// Has navigation menu
  final bool hasNavigation;

  /// Has footer
  final bool hasFooter;

  /// Has sidebar
  final bool hasSidebar;

  /// Content hierarchy depth
  final int contentDepth;

  /// Accessibility score (0-100)
  final int accessibilityScore;

  const PageStructure({
    required this.totalElements,
    required this.textBlocks,
    required this.interactiveElements,
    required this.layoutType,
    required this.hasNavigation,
    required this.hasFooter,
    required this.hasSidebar,
    required this.contentDepth,
    required this.accessibilityScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalElements': totalElements,
      'textBlocks': textBlocks,
      'interactiveElements': interactiveElements,
      'layoutType': layoutType.name,
      'hasNavigation': hasNavigation,
      'hasFooter': hasFooter,
      'hasSidebar': hasSidebar,
      'contentDepth': contentDepth,
      'accessibilityScore': accessibilityScore,
    };
  }

  factory PageStructure.fromJson(Map<String, dynamic> json) {
    return PageStructure(
      totalElements: json['totalElements'],
      textBlocks: json['textBlocks'],
      interactiveElements: json['interactiveElements'],
      layoutType: LayoutType.values.firstWhere((e) => e.name == json['layoutType']),
      hasNavigation: json['hasNavigation'],
      hasFooter: json['hasFooter'],
      hasSidebar: json['hasSidebar'],
      contentDepth: json['contentDepth'],
      accessibilityScore: json['accessibilityScore'],
    );
  }
}

/// Layout types
enum LayoutType {
  blog,
  ecommerce,
  news,
  portfolio,
  corporate,
  social,
  documentation,
  landing,
  dashboard,
  forum,
  unknown,
}

/// Content types
enum ContentType {
  article,
  blog,
  news,
  product,
  service,
  documentation,
  tutorial,
  review,
  forum,
  social,
  ecommerce,
  portfolio,
  corporate,
  landing,
  unknown,
}

/// Contact information extracted from the page
class ContactInfo {
  /// Email addresses found
  final List<String> emails;

  /// Phone numbers found
  final List<String> phoneNumbers;

  /// Physical addresses found
  final List<String> addresses;

  /// Social media links
  final Map<String, String> socialLinks;

  /// Contact forms found
  final bool hasContactForm;

  const ContactInfo({
    this.emails = const [],
    this.phoneNumbers = const [],
    this.addresses = const [],
    this.socialLinks = const {},
    this.hasContactForm = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'emails': emails,
      'phoneNumbers': phoneNumbers,
      'addresses': addresses,
      'socialLinks': socialLinks,
      'hasContactForm': hasContactForm,
    };
  }

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      emails: List<String>.from(json['emails'] ?? []),
      phoneNumbers: List<String>.from(json['phoneNumbers'] ?? []),
      addresses: List<String>.from(json['addresses'] ?? []),
      socialLinks: Map<String, String>.from(json['socialLinks'] ?? {}),
      hasContactForm: json['hasContactForm'] ?? false,
    );
  }
}

/// Navigation data
class NavigationData {
  /// Main navigation links
  final List<NavigationLink> mainNavigation;

  /// Breadcrumb navigation
  final List<String> breadcrumbs;

  /// Footer links
  final List<NavigationLink> footerLinks;

  /// Pagination info
  final PaginationInfo? pagination;

  const NavigationData({
    this.mainNavigation = const [],
    this.breadcrumbs = const [],
    this.footerLinks = const [],
    this.pagination,
  });

  Map<String, dynamic> toJson() {
    return {
      'mainNavigation': mainNavigation.map((nav) => nav.toJson()).toList(),
      'breadcrumbs': breadcrumbs,
      'footerLinks': footerLinks.map((nav) => nav.toJson()).toList(),
      'pagination': pagination?.toJson(),
    };
  }

  factory NavigationData.fromJson(Map<String, dynamic> json) {
    return NavigationData(
      mainNavigation:
          (json['mainNavigation'] as List?)?.map((nav) => NavigationLink.fromJson(nav)).toList() ??
          [],
      breadcrumbs: List<String>.from(json['breadcrumbs'] ?? []),
      footerLinks:
          (json['footerLinks'] as List?)?.map((nav) => NavigationLink.fromJson(nav)).toList() ?? [],
      pagination: json['pagination'] != null ? PaginationInfo.fromJson(json['pagination']) : null,
    );
  }
}

/// Navigation link
class NavigationLink {
  /// Link text
  final String text;

  /// Link URL
  final String url;

  /// Link level/depth
  final int level;

  const NavigationLink({required this.text, required this.url, this.level = 0});

  Map<String, dynamic> toJson() {
    return {'text': text, 'url': url, 'level': level};
  }

  factory NavigationLink.fromJson(Map<String, dynamic> json) {
    return NavigationLink(text: json['text'], url: json['url'], level: json['level'] ?? 0);
  }
}

/// Pagination information
class PaginationInfo {
  /// Current page number
  final int? currentPage;

  /// Total pages
  final int? totalPages;

  /// Has next page
  final bool hasNext;

  /// Has previous page
  final bool hasPrevious;

  /// Next page URL
  final String? nextUrl;

  /// Previous page URL
  final String? previousUrl;

  const PaginationInfo({
    this.currentPage,
    this.totalPages,
    this.hasNext = false,
    this.hasPrevious = false,
    this.nextUrl,
    this.previousUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrevious': hasPrevious,
      'nextUrl': nextUrl,
      'previousUrl': previousUrl,
    };
  }

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'],
      totalPages: json['totalPages'],
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
      nextUrl: json['nextUrl'],
      previousUrl: json['previousUrl'],
    );
  }
}

/// Represents an image found on a web page
class WebImage {
  /// Image URL
  final String url;

  /// Alt text of the image
  final String? alt;

  /// Image width (if available)
  final int? width;

  /// Image height (if available)
  final int? height;

  /// Image file size in bytes (if available)
  final int? fileSize;

  /// Image format/type (jpg, png, etc.)
  final String? format;

  const WebImage({
    required this.url,
    this.alt,
    this.width,
    this.height,
    this.fileSize,
    this.format,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'alt': alt,
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'format': format,
    };
  }

  factory WebImage.fromJson(Map<String, dynamic> json) {
    return WebImage(
      url: json['url'],
      alt: json['alt'],
      width: json['width'],
      height: json['height'],
      fileSize: json['fileSize'],
      format: json['format'],
    );
  }
}

/// Represents social media metadata (Open Graph, Twitter Card)
class SocialMetadata {
  /// Open Graph title
  final String? ogTitle;

  /// Open Graph description
  final String? ogDescription;

  /// Open Graph image
  final String? ogImage;

  /// Open Graph site name
  final String? ogSiteName;

  /// Open Graph type
  final String? ogType;

  /// Twitter Card type
  final String? twitterCard;

  /// Twitter title
  final String? twitterTitle;

  /// Twitter description
  final String? twitterDescription;

  /// Twitter image
  final String? twitterImage;

  /// Twitter site handle
  final String? twitterSite;

  /// Twitter creator handle
  final String? twitterCreator;

  const SocialMetadata({
    this.ogTitle,
    this.ogDescription,
    this.ogImage,
    this.ogSiteName,
    this.ogType,
    this.twitterCard,
    this.twitterTitle,
    this.twitterDescription,
    this.twitterImage,
    this.twitterSite,
    this.twitterCreator,
  });

  Map<String, dynamic> toJson() {
    return {
      'ogTitle': ogTitle,
      'ogDescription': ogDescription,
      'ogImage': ogImage,
      'ogSiteName': ogSiteName,
      'ogType': ogType,
      'twitterCard': twitterCard,
      'twitterTitle': twitterTitle,
      'twitterDescription': twitterDescription,
      'twitterImage': twitterImage,
      'twitterSite': twitterSite,
      'twitterCreator': twitterCreator,
    };
  }

  factory SocialMetadata.fromJson(Map<String, dynamic> json) {
    return SocialMetadata(
      ogTitle: json['ogTitle'],
      ogDescription: json['ogDescription'],
      ogImage: json['ogImage'],
      ogSiteName: json['ogSiteName'],
      ogType: json['ogType'],
      twitterCard: json['twitterCard'],
      twitterTitle: json['twitterTitle'],
      twitterDescription: json['twitterDescription'],
      twitterImage: json['twitterImage'],
      twitterSite: json['twitterSite'],
      twitterCreator: json['twitterCreator'],
    );
  }
}

/// Configuration options for web scraping
class WebScrapingConfig {
  /// Maximum timeout for the request in seconds
  final int timeoutSeconds;

  /// Whether to follow redirects
  final bool followRedirects;

  /// Maximum number of redirects to follow
  final int maxRedirects;

  /// User agent string to use
  final String userAgent;

  /// Whether to extract images
  final bool extractImages;

  /// Whether to extract links
  final bool extractLinks;

  /// Whether to extract structured data (JSON-LD, microdata)
  final bool extractStructuredData;

  /// Whether to calculate reading time
  final bool calculateReadingTime;

  /// Whether to extract social metadata
  final bool extractSocialMetadata;

  /// Custom headers to include in the request
  final Map<String, String> customHeaders;

  /// Maximum content length to process (in characters)
  final int? maxContentLength;

  /// Whether to extract contact information
  final bool extractContactInfo;

  /// Whether to extract navigation data
  final bool extractNavigation;

  /// Whether to extract media content
  final bool extractMedia;

  /// Whether to extract tables
  final bool extractTables;

  /// Whether to extract forms
  final bool extractForms;

  /// Whether to perform content type classification
  final bool classifyContent;

  /// Whether to perform SEO analysis
  final bool analyzeSeo;

  /// Whether to extract comments/reviews
  final bool extractComments;

  /// Whether to extract product information
  final bool extractProductInfo;

  /// Whether to extract article information
  final bool extractArticleInfo;

  /// Whether to extract heading structure
  final bool extractHeadings;

  /// Whether to perform sentiment analysis
  final bool analyzeSentiment;

  /// Whether to analyze page structure
  final bool analyzePageStructure;

  /// Whether to collect performance metrics
  final bool collectPerformanceMetrics;

  const WebScrapingConfig({
    this.timeoutSeconds = 30,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.userAgent = 'FreeAIHub Web Scraper 1.0',
    this.extractImages = true,
    this.extractLinks = true,
    this.extractStructuredData = true,
    this.calculateReadingTime = true,
    this.extractSocialMetadata = true,
    this.customHeaders = const {},
    this.maxContentLength,
    this.extractContactInfo = true,
    this.extractNavigation = true,
    this.extractMedia = true,
    this.extractTables = true,
    this.extractForms = true,
    this.classifyContent = true,
    this.analyzeSeo = true,
    this.extractComments = true,
    this.extractProductInfo = true,
    this.extractArticleInfo = true,
    this.extractHeadings = true,
    this.analyzeSentiment = false,
    this.analyzePageStructure = true,
    this.collectPerformanceMetrics = true,
  });

  /// Create a minimal configuration for faster scraping
  factory WebScrapingConfig.minimal() {
    return const WebScrapingConfig(
      extractImages: false,
      extractLinks: false,
      extractStructuredData: false,
      calculateReadingTime: false,
      extractSocialMetadata: false,
      extractContactInfo: false,
      extractNavigation: false,
      extractMedia: false,
      extractTables: false,
      extractForms: false,
      classifyContent: false,
      analyzeSeo: false,
      extractComments: false,
      extractProductInfo: false,
      extractArticleInfo: false,
      extractHeadings: false,
      analyzeSentiment: false,
      analyzePageStructure: false,
      collectPerformanceMetrics: false,
    );
  }

  /// Create a comprehensive configuration for detailed scraping
  factory WebScrapingConfig.comprehensive() {
    return const WebScrapingConfig(
      timeoutSeconds: 60,
      extractImages: true,
      extractLinks: true,
      extractStructuredData: true,
      calculateReadingTime: true,
      extractSocialMetadata: true,
      extractContactInfo: true,
      extractNavigation: true,
      extractMedia: true,
      extractTables: true,
      extractForms: true,
      classifyContent: true,
      analyzeSeo: true,
      extractComments: true,
      extractProductInfo: true,
      extractArticleInfo: true,
      extractHeadings: true,
      analyzeSentiment: true,
      analyzePageStructure: true,
      collectPerformanceMetrics: true,
    );
  }

  /// Create a configuration for e-commerce pages
  factory WebScrapingConfig.ecommerce() {
    return const WebScrapingConfig(
      extractProductInfo: true,
      extractImages: true,
      extractComments: true,
      analyzeSeo: true,
      extractStructuredData: true,
      extractForms: true,
      classifyContent: true,
    );
  }

  /// Create a configuration for news/article pages
  factory WebScrapingConfig.news() {
    return const WebScrapingConfig(
      extractArticleInfo: true,
      extractHeadings: true,
      calculateReadingTime: true,
      extractSocialMetadata: true,
      extractComments: true,
      analyzeSentiment: true,
      classifyContent: true,
    );
  }

  /// Create a configuration for contact/business pages
  factory WebScrapingConfig.business() {
    return const WebScrapingConfig(
      extractContactInfo: true,
      extractForms: true,
      extractSocialMetadata: true,
      extractNavigation: true,
      analyzeSeo: true,
    );
  }
}

/// Media content data (videos, audio, etc.)
class MediaContent {
  /// Video elements found
  final List<MediaElement> videos;

  /// Audio elements found
  final List<MediaElement> audio;

  /// Embedded content (YouTube, Vimeo, etc.)
  final List<EmbeddedMedia> embeddedMedia;

  /// Total media count
  final int totalMediaCount;

  const MediaContent({
    this.videos = const [],
    this.audio = const [],
    this.embeddedMedia = const [],
    this.totalMediaCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'videos': videos.map((v) => v.toJson()).toList(),
      'audio': audio.map((a) => a.toJson()).toList(),
      'embeddedMedia': embeddedMedia.map((e) => e.toJson()).toList(),
      'totalMediaCount': totalMediaCount,
    };
  }

  factory MediaContent.fromJson(Map<String, dynamic> json) {
    return MediaContent(
      videos: (json['videos'] as List?)?.map((v) => MediaElement.fromJson(v)).toList() ?? [],
      audio: (json['audio'] as List?)?.map((a) => MediaElement.fromJson(a)).toList() ?? [],
      embeddedMedia:
          (json['embeddedMedia'] as List?)?.map((e) => EmbeddedMedia.fromJson(e)).toList() ?? [],
      totalMediaCount: json['totalMediaCount'] ?? 0,
    );
  }
}

/// Media element (video/audio)
class MediaElement {
  /// Media source URL
  final String src;

  /// Media type (video/audio)
  final String type;

  /// Duration if available
  final Duration? duration;

  /// Poster image for videos
  final String? poster;

  /// Media title/alt text
  final String? title;

  const MediaElement({
    required this.src,
    required this.type,
    this.duration,
    this.poster,
    this.title,
  });

  Map<String, dynamic> toJson() {
    return {
      'src': src,
      'type': type,
      'duration': duration?.inSeconds,
      'poster': poster,
      'title': title,
    };
  }

  factory MediaElement.fromJson(Map<String, dynamic> json) {
    return MediaElement(
      src: json['src'],
      type: json['type'],
      duration: json['duration'] != null ? Duration(seconds: json['duration']) : null,
      poster: json['poster'],
      title: json['title'],
    );
  }
}

/// Embedded media (iframe, etc.)
class EmbeddedMedia {
  /// Embed URL
  final String url;

  /// Platform (youtube, vimeo, etc.)
  final String platform;

  /// Embed type
  final String type;

  /// Title if available
  final String? title;

  const EmbeddedMedia({required this.url, required this.platform, required this.type, this.title});

  Map<String, dynamic> toJson() {
    return {'url': url, 'platform': platform, 'type': type, 'title': title};
  }

  factory EmbeddedMedia.fromJson(Map<String, dynamic> json) {
    return EmbeddedMedia(
      url: json['url'],
      platform: json['platform'],
      type: json['type'],
      title: json['title'],
    );
  }
}

/// Table data extracted from HTML tables
class TableData {
  /// Table caption
  final String? caption;

  /// Table headers
  final List<String> headers;

  /// Table rows
  final List<List<String>> rows;

  /// Number of columns
  final int columnCount;

  /// Number of rows
  final int rowCount;

  const TableData({
    this.caption,
    this.headers = const [],
    this.rows = const [],
    this.columnCount = 0,
    this.rowCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'caption': caption,
      'headers': headers,
      'rows': rows,
      'columnCount': columnCount,
      'rowCount': rowCount,
    };
  }

  factory TableData.fromJson(Map<String, dynamic> json) {
    return TableData(
      caption: json['caption'],
      headers: List<String>.from(json['headers'] ?? []),
      rows: (json['rows'] as List?)?.map((row) => List<String>.from(row)).toList() ?? [],
      columnCount: json['columnCount'] ?? 0,
      rowCount: json['rowCount'] ?? 0,
    );
  }
}

/// Form data extracted from HTML forms
class WebFormData {
  /// Form action URL
  final String? action;

  /// Form method (GET, POST, etc.)
  final String method;

  /// Form name/id
  final String? name;

  /// Form fields
  final List<FormField> fields;

  /// Has file upload
  final bool hasFileUpload;

  const WebFormData({
    this.action,
    this.method = 'GET',
    this.name,
    this.fields = const [],
    this.hasFileUpload = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'method': method,
      'name': name,
      'fields': fields.map((f) => f.toJson()).toList(),
      'hasFileUpload': hasFileUpload,
    };
  }

  factory WebFormData.fromJson(Map<String, dynamic> json) {
    return WebFormData(
      action: json['action'],
      method: json['method'] ?? 'GET',
      name: json['name'],
      fields: (json['fields'] as List?)?.map((f) => FormField.fromJson(f)).toList() ?? [],
      hasFileUpload: json['hasFileUpload'] ?? false,
    );
  }
}

/// Form field
class FormField {
  /// Field name
  final String name;

  /// Field type (text, email, password, etc.)
  final String type;

  /// Field label
  final String? label;

  /// Field placeholder
  final String? placeholder;

  /// Is required field
  final bool required;

  const FormField({
    required this.name,
    required this.type,
    this.label,
    this.placeholder,
    this.required = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'label': label,
      'placeholder': placeholder,
      'required': required,
    };
  }

  factory FormField.fromJson(Map<String, dynamic> json) {
    return FormField(
      name: json['name'],
      type: json['type'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
    );
  }
}

/// SEO analysis data
class SeoAnalysis {
  /// Has title tag
  final bool hasTitle;

  /// Title length
  final int titleLength;

  /// Has meta description
  final bool hasMetaDescription;

  /// Meta description length
  final int metaDescriptionLength;

  /// Has h1 tag
  final bool hasH1;

  /// Number of h1 tags
  final int h1Count;

  /// Has alt tags for images
  final bool hasImageAltTags;

  /// Images without alt tags count
  final int imagesWithoutAlt;

  /// Has canonical URL
  final bool hasCanonical;

  /// Page speed score (0-100)
  final int? pageSpeedScore;

  /// Mobile friendly
  final bool? mobileFriendly;

  /// Has schema markup
  final bool hasSchema;

  const SeoAnalysis({
    this.hasTitle = false,
    this.titleLength = 0,
    this.hasMetaDescription = false,
    this.metaDescriptionLength = 0,
    this.hasH1 = false,
    this.h1Count = 0,
    this.hasImageAltTags = false,
    this.imagesWithoutAlt = 0,
    this.hasCanonical = false,
    this.pageSpeedScore,
    this.mobileFriendly,
    this.hasSchema = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'hasTitle': hasTitle,
      'titleLength': titleLength,
      'hasMetaDescription': hasMetaDescription,
      'metaDescriptionLength': metaDescriptionLength,
      'hasH1': hasH1,
      'h1Count': h1Count,
      'hasImageAltTags': hasImageAltTags,
      'imagesWithoutAlt': imagesWithoutAlt,
      'hasCanonical': hasCanonical,
      'pageSpeedScore': pageSpeedScore,
      'mobileFriendly': mobileFriendly,
      'hasSchema': hasSchema,
    };
  }

  factory SeoAnalysis.fromJson(Map<String, dynamic> json) {
    return SeoAnalysis(
      hasTitle: json['hasTitle'] ?? false,
      titleLength: json['titleLength'] ?? 0,
      hasMetaDescription: json['hasMetaDescription'] ?? false,
      metaDescriptionLength: json['metaDescriptionLength'] ?? 0,
      hasH1: json['hasH1'] ?? false,
      h1Count: json['h1Count'] ?? 0,
      hasImageAltTags: json['hasImageAltTags'] ?? false,
      imagesWithoutAlt: json['imagesWithoutAlt'] ?? 0,
      hasCanonical: json['hasCanonical'] ?? false,
      pageSpeedScore: json['pageSpeedScore'],
      mobileFriendly: json['mobileFriendly'],
      hasSchema: json['hasSchema'] ?? false,
    );
  }
}

/// Performance metrics
class PerformanceMetrics {
  /// Load time in milliseconds
  final int? loadTime;

  /// Response time in milliseconds
  final int responseTime;

  /// Page size in bytes
  final int? pageSize;

  /// Number of HTTP requests
  final int? requestCount;

  /// Compression used
  final bool compressed;

  /// Cache headers present
  final bool hasCacheHeaders;

  const PerformanceMetrics({
    this.loadTime,
    this.responseTime = 0,
    this.pageSize,
    this.requestCount,
    this.compressed = false,
    this.hasCacheHeaders = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'loadTime': loadTime,
      'responseTime': responseTime,
      'pageSize': pageSize,
      'requestCount': requestCount,
      'compressed': compressed,
      'hasCacheHeaders': hasCacheHeaders,
    };
  }

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      loadTime: json['loadTime'],
      responseTime: json['responseTime'] ?? 0,
      pageSize: json['pageSize'],
      requestCount: json['requestCount'],
      compressed: json['compressed'] ?? false,
      hasCacheHeaders: json['hasCacheHeaders'] ?? false,
    );
  }
}

/// Comment/review data
class Comment {
  /// Comment author
  final String? author;

  /// Comment text
  final String text;

  /// Comment date
  final DateTime? date;

  /// Rating if available
  final double? rating;

  /// Reply count
  final int replyCount;

  const Comment({this.author, required this.text, this.date, this.rating, this.replyCount = 0});

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'text': text,
      'date': date?.toIso8601String(),
      'rating': rating,
      'replyCount': replyCount,
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      author: json['author'],
      text: json['text'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      rating: json['rating']?.toDouble(),
      replyCount: json['replyCount'] ?? 0,
    );
  }
}

/// Product information for e-commerce pages
class ProductInfo {
  /// Product name
  final String? name;

  /// Product price
  final double? price;

  /// Currency
  final String? currency;

  /// Product description
  final String? description;

  /// Product brand
  final String? brand;

  /// Product rating
  final double? rating;

  /// Number of reviews
  final int? reviewCount;

  /// Availability status
  final String? availability;

  /// Product images
  final List<String> images;

  /// Product categories
  final List<String> categories;

  /// Product SKU
  final String? sku;

  const ProductInfo({
    this.name,
    this.price,
    this.currency,
    this.description,
    this.brand,
    this.rating,
    this.reviewCount,
    this.availability,
    this.images = const [],
    this.categories = const [],
    this.sku,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'currency': currency,
      'description': description,
      'brand': brand,
      'rating': rating,
      'reviewCount': reviewCount,
      'availability': availability,
      'images': images,
      'categories': categories,
      'sku': sku,
    };
  }

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      name: json['name'],
      price: json['price']?.toDouble(),
      currency: json['currency'],
      description: json['description'],
      brand: json['brand'],
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
      availability: json['availability'],
      images: List<String>.from(json['images'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
      sku: json['sku'],
    );
  }
}

/// Article/news specific information
class ArticleInfo {
  /// Article category
  final String? category;

  /// Article tags
  final List<String> tags;

  /// Article summary/excerpt
  final String? summary;

  /// Related articles
  final List<String> relatedArticles;

  /// Article source
  final String? source;

  /// Modified date
  final DateTime? modifiedDate;

  /// Article section
  final String? section;

  const ArticleInfo({
    this.category,
    this.tags = const [],
    this.summary,
    this.relatedArticles = const [],
    this.source,
    this.modifiedDate,
    this.section,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'tags': tags,
      'summary': summary,
      'relatedArticles': relatedArticles,
      'source': source,
      'modifiedDate': modifiedDate?.toIso8601String(),
      'section': section,
    };
  }

  factory ArticleInfo.fromJson(Map<String, dynamic> json) {
    return ArticleInfo(
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      summary: json['summary'],
      relatedArticles: List<String>.from(json['relatedArticles'] ?? []),
      source: json['source'],
      modifiedDate: json['modifiedDate'] != null ? DateTime.parse(json['modifiedDate']) : null,
      section: json['section'],
    );
  }
}

/// Heading structure
class Heading {
  /// Heading level (1-6)
  final int level;

  /// Heading text
  final String text;

  /// Heading ID if available
  final String? id;

  const Heading({required this.level, required this.text, this.id});

  Map<String, dynamic> toJson() {
    return {'level': level, 'text': text, 'id': id};
  }

  factory Heading.fromJson(Map<String, dynamic> json) {
    return Heading(level: json['level'], text: json['text'], id: json['id']);
  }
}

/// Sentiment analysis data
class SentimentAnalysis {
  /// Overall sentiment score (-1 to 1)
  final double sentimentScore;

  /// Sentiment classification
  final SentimentType sentimentType;

  /// Confidence level (0 to 1)
  final double confidence;

  /// Positive keywords found
  final List<String> positiveKeywords;

  /// Negative keywords found
  final List<String> negativeKeywords;

  const SentimentAnalysis({
    required this.sentimentScore,
    required this.sentimentType,
    required this.confidence,
    this.positiveKeywords = const [],
    this.negativeKeywords = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'sentimentScore': sentimentScore,
      'sentimentType': sentimentType.name,
      'confidence': confidence,
      'positiveKeywords': positiveKeywords,
      'negativeKeywords': negativeKeywords,
    };
  }

  factory SentimentAnalysis.fromJson(Map<String, dynamic> json) {
    return SentimentAnalysis(
      sentimentScore: json['sentimentScore']?.toDouble() ?? 0.0,
      sentimentType: SentimentType.values.firstWhere(
        (e) => e.name == json['sentimentType'],
        orElse: () => SentimentType.neutral,
      ),
      confidence: json['confidence']?.toDouble() ?? 0.0,
      positiveKeywords: List<String>.from(json['positiveKeywords'] ?? []),
      negativeKeywords: List<String>.from(json['negativeKeywords'] ?? []),
    );
  }
}

/// Sentiment types
enum SentimentType { positive, negative, neutral, mixed }
