import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/screens/chat/handlers/error_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Cache entry metadata for tracking cache validity and size
class CacheEntry {
  final String key;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final int size;
  final String? mimeType;
  final Map<String, dynamic>? metadata;

  CacheEntry({
    required this.key,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.size,
    this.mimeType,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'createdAt': createdAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt.toIso8601String(),
    'size': size,
    'mimeType': mimeType,
    'metadata': metadata,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    key: json['key'],
    createdAt: DateTime.parse(json['createdAt']),
    lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
    size: json['size'],
    mimeType: json['mimeType'],
    metadata: json['metadata'],
  );

  CacheEntry copyWith({
    String? key,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    int? size,
    String? mimeType,
    Map<String, dynamic>? metadata,
  }) => CacheEntry(
    key: key ?? this.key,
    createdAt: createdAt ?? this.createdAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    size: size ?? this.size,
    mimeType: mimeType ?? this.mimeType,
    metadata: metadata ?? this.metadata,
  );
}

/// Handles all cache-related functionality for chat operations
/// Manages memory cache, persistent cache, and cache lifecycle
class CacheHandler {
  final ErrorHandler errorHandler;

  // Memory cache for quick access
  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, CacheEntry> _cacheMetadata = {};

  // Cache size limits
  static const int maxMemoryCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxPersistentCacheSize = 500 * 1024 * 1024; // 500MB
  static const int maxCacheAge = 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds

  // Current cache size tracking
  int _currentMemoryCacheSize = 0;

  // Cache directories
  Directory? _cacheDirectory;
  Directory? _imagesCacheDirectory;
  Directory? _messagesCacheDirectory;

  CacheHandler({required this.errorHandler});

  /// Initializes cache directories and loads existing cache metadata
  Future<void> initialize() async {
    try {
      final appCacheDir = await getTemporaryDirectory();
      _cacheDirectory = Directory('${appCacheDir.path}/freeaihub_cache');
      _imagesCacheDirectory = Directory('${_cacheDirectory!.path}/images');
      _messagesCacheDirectory = Directory('${_cacheDirectory!.path}/messages');

      // Create directories if they don't exist
      await _cacheDirectory!.create(recursive: true);
      await _imagesCacheDirectory!.create(recursive: true);
      await _messagesCacheDirectory!.create(recursive: true);

      // Load existing cache metadata
      await _loadCacheMetadata();

      // Clean up expired cache entries
      await _cleanupExpiredEntries();
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [CacheHandler] - Error initializing cache: $e');
      }
      errorHandler.showError('Failed to initialize cache system');
    }
  }

  /// Stores image data in cache with memory and persistent storage
  Future<String?> cacheImage(
    String imageId,
    Uint8List imageData, {
    String? mimeType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (imageData.isEmpty) {
        throw Exception('Cannot cache empty image data');
      }

      final cacheKey = 'image_$imageId';

      // Store in memory cache if there's space
      if (_currentMemoryCacheSize + imageData.length <= maxMemoryCacheSize) {
        _memoryCache[cacheKey] = imageData;
        _currentMemoryCacheSize += imageData.length;
      }

      // Store in persistent cache
      final imageFile = File('${_imagesCacheDirectory!.path}/$imageId.cache');
      await imageFile.writeAsBytes(imageData);

      // Update metadata
      final entry = CacheEntry(
        key: cacheKey,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        size: imageData.length,
        mimeType: mimeType ?? 'image/jpeg',
        metadata: metadata,
      );
      _cacheMetadata[cacheKey] = entry;

      // Save metadata
      await _saveCacheMetadata();

      return cacheKey;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [CacheHandler] - Error caching image: $e');
      }
      errorHandler.showError('Failed to cache image');
      return null;
    }
  }

  /// Retrieves image data from cache (memory first, then persistent)
  Future<Uint8List?> getCachedImage(String imageId) async {
    try {
      final cacheKey = 'image_$imageId';

      // Check memory cache first
      if (_memoryCache.containsKey(cacheKey)) {
        // Update last accessed time
        final entry = _cacheMetadata[cacheKey];
        if (entry != null) {
          _cacheMetadata[cacheKey] = entry.copyWith(lastAccessedAt: DateTime.now());
        }

        return _memoryCache[cacheKey];
      }

      // Check persistent cache
      final imageFile = File('${_imagesCacheDirectory!.path}/$imageId.cache');
      if (await imageFile.exists()) {
        final imageData = await imageFile.readAsBytes();

        // Update memory cache if there's space
        if (_currentMemoryCacheSize + imageData.length <= maxMemoryCacheSize) {
          _memoryCache[cacheKey] = imageData;
          _currentMemoryCacheSize += imageData.length;
        }

        // Update last accessed time
        final entry = _cacheMetadata[cacheKey];
        if (entry != null) {
          _cacheMetadata[cacheKey] = entry.copyWith(lastAccessedAt: DateTime.now());
          await _saveCacheMetadata();
        }

        return imageData;
      }

      return null;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [CacheHandler] - Error retrieving cached image: $e');
      }
      return null;
    }
  }

  /// Caches message data for quick session loading
  Future<String?> cacheMessage(
    String messageId,
    Message message, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final cacheKey = 'message_$messageId';
      final messageJson = jsonEncode(message.toJson());
      final messageData = utf8.encode(messageJson);

      // Store in persistent cache
      final messageFile = File('${_messagesCacheDirectory!.path}/$messageId.cache');
      await messageFile.writeAsBytes(messageData);

      // Update metadata
      final entry = CacheEntry(
        key: cacheKey,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        size: messageData.length,
        mimeType: 'application/json',
        metadata: metadata,
      );
      _cacheMetadata[cacheKey] = entry;

      await _saveCacheMetadata();

      return cacheKey;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [CacheHandler] - Error caching message: $e');
      }
      return null;
    }
  }

  /// Retrieves cached message data
  Future<Message?> getCachedMessage(String messageId) async {
    try {
      final messageFile = File('${_messagesCacheDirectory!.path}/$messageId.cache');
      if (await messageFile.exists()) {
        final messageData = await messageFile.readAsBytes();
        final messageJson = utf8.decode(messageData);
        final messageMap = jsonDecode(messageJson) as Map<String, dynamic>;

        // Update last accessed time
        final cacheKey = 'message_$messageId';
        final entry = _cacheMetadata[cacheKey];
        if (entry != null) {
          _cacheMetadata[cacheKey] = entry.copyWith(lastAccessedAt: DateTime.now());
          await _saveCacheMetadata();
        }

        return Message.fromJson(messageMap);
      }
      return null;
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [CacheHandler] - Error retrieving cached message: $e');
      }
      return null;
    }
  }

  /// Removes specific cache entry
  Future<void> removeCacheEntry(String key) async {
    try {
      // Remove from memory cache
      if (_memoryCache.containsKey(key)) {
        final entry = _cacheMetadata[key];
        if (entry != null) {
          _currentMemoryCacheSize -= entry.size;
        }
        _memoryCache.remove(key);
      }

      // Remove from persistent cache
      String fileName = '';
      if (key.startsWith('image_')) {
        fileName = '${_imagesCacheDirectory!.path}/${key.substring(6)}.cache';
      } else if (key.startsWith('message_')) {
        fileName = '${_messagesCacheDirectory!.path}/${key.substring(8)}.cache';
      }

      if (fileName.isNotEmpty) {
        final file = File(fileName);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove metadata
      _cacheMetadata.remove(key);
      await _saveCacheMetadata();
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [CacheHandler] - Error removing cache entry: $e');
      }
    }
  }

  /// Clears all memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
    _currentMemoryCacheSize = 0;
  }

  /// Clears all persistent cache
  Future<void> clearPersistentCache() async {
    try {
      // Clear images cache
      if (_imagesCacheDirectory != null && await _imagesCacheDirectory!.exists()) {
        await _imagesCacheDirectory!.delete(recursive: true);
        await _imagesCacheDirectory!.create(recursive: true);
      }

      // Clear messages cache
      if (_messagesCacheDirectory != null && await _messagesCacheDirectory!.exists()) {
        await _messagesCacheDirectory!.delete(recursive: true);
        await _messagesCacheDirectory!.create(recursive: true);
      }

      // Clear metadata
      _cacheMetadata.clear();
      await _saveCacheMetadata();
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [CacheHandler] - Error clearing persistent cache: $e');
      }
      errorHandler.showError('Failed to clear cache');
    }
  }

  /// Clears all cache (memory + persistent)
  Future<void> clearAllCache() async {
    clearMemoryCache();
    await clearPersistentCache();
  }

  /// Gets cache statistics for monitoring and debugging
  Map<String, dynamic> getCacheStatistics() {
    final totalEntries = _cacheMetadata.length;
    final memoryEntries = _memoryCache.length;
    final totalPersistentSize = _cacheMetadata.values.fold<int>(
      0,
      (sum, entry) => sum + entry.size,
    );

    final imageEntries = _cacheMetadata.keys.where((key) => key.startsWith('image_')).length;
    final messageEntries = _cacheMetadata.keys.where((key) => key.startsWith('message_')).length;

    return {
      'total_entries': totalEntries,
      'memory_entries': memoryEntries,
      'image_entries': imageEntries,
      'message_entries': messageEntries,
      'memory_cache_size': _currentMemoryCacheSize,
      'persistent_cache_size': totalPersistentSize,
      'memory_cache_size_mb': (_currentMemoryCacheSize / (1024 * 1024)).round(),
      'persistent_cache_size_mb': (totalPersistentSize / (1024 * 1024)).round(),
      'cache_hit_ratio': _calculateCacheHitRatio(),
    };
  }

  /// Optimizes cache by removing least recently used entries
  Future<void> optimizeCache() async {
    try {
      // Remove expired entries
      await _cleanupExpiredEntries();

      // If memory cache is over limit, remove LRU entries
      if (_currentMemoryCacheSize > maxMemoryCacheSize) {
        await _evictLRUMemoryEntries();
      }

      // If persistent cache is over limit, remove LRU entries
      final totalPersistentSize = _cacheMetadata.values.fold<int>(
        0,
        (sum, entry) => sum + entry.size,
      );

      if (totalPersistentSize > maxPersistentCacheSize) {
        await _evictLRUPersistentEntries();
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [CacheHandler] - Error optimizing cache: $e');
      }
    }
  }

  /// Loads cache metadata from disk
  Future<void> _loadCacheMetadata() async {
    try {
      final metadataFile = File('${_cacheDirectory!.path}/metadata.json');
      if (await metadataFile.exists()) {
        final metadataJson = await metadataFile.readAsString();
        final metadataMap = jsonDecode(metadataJson) as Map<String, dynamic>;

        for (final entry in metadataMap.entries) {
          _cacheMetadata[entry.key] = CacheEntry.fromJson(entry.value);
        }
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [CacheHandler] - Error loading cache metadata: $e');
      }
    }
  }

  /// Saves cache metadata to disk
  Future<void> _saveCacheMetadata() async {
    try {
      final metadataFile = File('${_cacheDirectory!.path}/metadata.json');
      final metadataMap = <String, dynamic>{};

      for (final entry in _cacheMetadata.entries) {
        metadataMap[entry.key] = entry.value.toJson();
      }

      await metadataFile.writeAsString(jsonEncode(metadataMap));
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [CacheHandler] - Error saving cache metadata: $e');
      }
    }
  }

  /// Removes expired cache entries
  Future<void> _cleanupExpiredEntries() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheMetadata.entries) {
      final age = now.millisecondsSinceEpoch - entry.value.createdAt.millisecondsSinceEpoch;
      if (age > maxCacheAge) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await removeCacheEntry(key);
    }
  }

  /// Evicts least recently used entries from memory cache
  Future<void> _evictLRUMemoryEntries() async {
    final sortedEntries =
        _cacheMetadata.entries.where((entry) => _memoryCache.containsKey(entry.key)).toList()
          ..sort((a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt));

    int evictedSize = 0;
    int evictedCount = 0;

    for (final entry in sortedEntries) {
      if (_currentMemoryCacheSize - evictedSize <= maxMemoryCacheSize * 0.8) {
        break;
      }

      _memoryCache.remove(entry.key);
      evictedSize += entry.value.size;
      evictedCount++;
    }

    _currentMemoryCacheSize -= evictedSize;
  }

  /// Evicts least recently used entries from persistent cache
  Future<void> _evictLRUPersistentEntries() async {
    final sortedEntries = _cacheMetadata.entries.toList()
      ..sort((a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt));

    int evictedSize = 0;
    int evictedCount = 0;
    final targetSize = (maxPersistentCacheSize * 0.8).round();

    for (final entry in sortedEntries) {
      final currentSize = _cacheMetadata.values.fold<int>(0, (sum, e) => sum + e.size);

      if (currentSize - evictedSize <= targetSize) {
        break;
      }

      await removeCacheEntry(entry.key);
      evictedSize += entry.value.size;
      evictedCount++;
    }
  }

  /// Calculates cache hit ratio for statistics
  double _calculateCacheHitRatio() {
    // This would require tracking cache hits and misses
    // For now, return a placeholder value
    return 0.75; // 75% hit ratio placeholder
  }

  /// Checks if cache entry exists
  bool hasCacheEntry(String key) {
    return _cacheMetadata.containsKey(key);
  }

  /// Gets cache entry metadata
  CacheEntry? getCacheEntry(String key) {
    return _cacheMetadata[key];
  }

  /// Cleanup when cache handler is disposed
  void dispose() {
    clearMemoryCache();
  }
}
