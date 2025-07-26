import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_ce/hive.dart';

/// Model representing a media item in the library
/// Stores both metadata and image data for generated and chat images
class MediaItem extends HiveObject {
  /// Unique identifier for the media item
  final String id;

  /// Title or name of the media item
  final String title;

  /// Description or prompt used to generate the image
  final String description;

  /// Source of the image (chat, hidream, pollinations_ai, etc.)
  final MediaSource source;

  /// Type of the media item
  final MediaType type;

  /// Base64 encoded image data
  final String base64Data;

  /// Thumbnail base64 data (optional, for performance)
  final String? thumbnailBase64;

  /// File size in bytes
  final int sizeBytes;

  /// Image dimensions
  final ImageDimensions? dimensions;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last accessed timestamp
  final DateTime lastAccessedAt;

  /// Additional metadata specific to the source
  final Map<String, dynamic>? metadata;

  /// Tags for categorization
  final List<String> tags;

  MediaItem({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.type,
    required this.base64Data,
    this.thumbnailBase64,
    required this.sizeBytes,
    this.dimensions,
    required this.createdAt,
    required this.lastAccessedAt,
    this.metadata,
    this.tags = const [],
  });

  /// Factory constructor for chat images
  factory MediaItem.fromChatImage({
    required String id,
    required String description,
    required String base64Data,
    required int sizeBytes,
    Map<String, dynamic>? metadata,
  }) {
    return MediaItem(
      id: id,
      title: 'Chat Image',
      description: description,
      source: MediaSource.chat,
      type: MediaType.image,
      base64Data: base64Data,
      sizeBytes: sizeBytes,
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Factory constructor for Hidream generated images
  factory MediaItem.fromHidreamImage({
    required String id,
    required String prompt,
    required String base64Data,
    required int sizeBytes,
    Map<String, dynamic>? generationParams,
  }) {
    return MediaItem(
      id: id,
      title: 'Hidream Image',
      description: prompt,
      source: MediaSource.hidream,
      type: MediaType.image,
      base64Data: base64Data,
      sizeBytes: sizeBytes,
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      metadata: generationParams,
      tags: ['generated', 'hidream'],
    );
  }

  /// Factory constructor for Pollinations AI generated images
  factory MediaItem.fromPollinationsImage({
    required String id,
    required String prompt,
    required String base64Data,
    required int sizeBytes,
    Map<String, dynamic>? generationParams,
  }) {
    return MediaItem(
      id: id,
      title: 'Pollinations AI Image',
      description: prompt,
      source: MediaSource.pollinationsAi,
      type: MediaType.image,
      base64Data: base64Data,
      sizeBytes: sizeBytes,
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      metadata: generationParams,
      tags: ['generated', 'pollinations'],
    );
  }

  /// Convert MediaItem to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'source': source.name,
      'type': type.name,
      'base64Data': base64Data,
      'thumbnailBase64': thumbnailBase64,
      'sizeBytes': sizeBytes,
      'dimensions': dimensions?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'metadata': metadata,
      'tags': tags,
    };
  }

  /// Create MediaItem from JSON
  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      source: MediaSource.values.firstWhere((e) => e.name == json['source']),
      type: MediaType.values.firstWhere((e) => e.name == json['type']),
      base64Data: json['base64Data'] as String,
      thumbnailBase64: json['thumbnailBase64'] as String?,
      sizeBytes: json['sizeBytes'] as int,
      dimensions: json['dimensions'] != null
          ? ImageDimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  /// Get image bytes from base64 data
  Uint8List get imageBytes {
    String cleanBase64 = base64Data;
    if (cleanBase64.contains(',')) {
      cleanBase64 = cleanBase64.split(',')[1];
    }
    return base64Decode(cleanBase64);
  }

  /// Get thumbnail bytes from base64 data
  Uint8List? get thumbnailBytes {
    if (thumbnailBase64 == null) return null;
    String cleanBase64 = thumbnailBase64!;
    if (cleanBase64.contains(',')) {
      cleanBase64 = cleanBase64.split(',')[1];
    }
    return base64Decode(cleanBase64);
  }

  /// Create a copy with updated fields
  MediaItem copyWith({
    String? id,
    String? title,
    String? description,
    MediaSource? source,
    MediaType? type,
    String? base64Data,
    String? thumbnailBase64,
    int? sizeBytes,
    ImageDimensions? dimensions,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      source: source ?? this.source,
      type: type ?? this.type,
      base64Data: base64Data ?? this.base64Data,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      dimensions: dimensions ?? this.dimensions,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
    );
  }

  /// Update last accessed time
  MediaItem updateLastAccessed() {
    return copyWith(lastAccessedAt: DateTime.now());
  }

  /// Get formatted file size
  String get formattedSize {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var size = sizeBytes.toDouble();
    var suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MediaItem{id: $id, title: $title, source: $source, type: $type, createdAt: $createdAt}';
  }
}

/// Represents the source where the media was generated
enum MediaSource {
  chat('Chat'),
  hidream('Hidream'),
  pollinationsAi('Pollinations AI'),
  unknown('Unknown');

  const MediaSource(this.displayName);
  final String displayName;
}

/// Represents the type of media
enum MediaType {
  image('Image'),
  audio('Audio'),
  video('Video'),
  document('Document');

  const MediaType(this.displayName);
  final String displayName;
}

/// Represents image dimensions
class ImageDimensions extends HiveObject {
  final int width;
  final int height;

  ImageDimensions({required this.width, required this.height});

  /// Create from JSON
  factory ImageDimensions.fromJson(Map<String, dynamic> json) {
    return ImageDimensions(width: json['width'] as int, height: json['height'] as int);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height};
  }

  /// Get aspect ratio
  double get aspectRatio => width / height;

  /// Get formatted dimension string
  String get formatted => '${width}x$height';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageDimensions &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => width.hashCode ^ height.hashCode;

  @override
  String toString() => 'ImageDimensions{width: $width, height: $height}';
}
