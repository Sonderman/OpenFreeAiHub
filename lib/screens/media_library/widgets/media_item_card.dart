import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/global/services/media_library_service.dart';
import 'package:freeaihub/core/models/library/media_item.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

/// Card widget for displaying individual media items
/// Optimized for performance with lazy loading and memory management
/// Now reactive to MediaLibraryService changes
class MediaItemCard extends StatefulWidget {
  final MediaItem mediaItem;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MediaItemCard({
    super.key,
    required this.mediaItem,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<MediaItemCard> createState() => _MediaItemCardState();
}

class _MediaItemCardState extends State<MediaItemCard> with AutomaticKeepAliveClientMixin {
  // Cache the image widget for better performance
  Widget? _cachedImageWidget;
  bool _isImageCached = false;

  @override
  bool get wantKeepAlive => _isImageCached && mounted; // Only keep alive when image is cached and widget is mounted

  @override
  void initState() {
    super.initState();
    // Preload image for better performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImage();
    });
  }

  @override
  void dispose() {
    _cachedImageWidget = null; // Clear cache on dispose
    super.dispose();
  }

  /// Precache the image for better performance
  void _precacheImage() async {
    await _precacheImageForMediaItem(widget.mediaItem);
  }

  /// Precache image for specific MediaItem
  Future<void> _precacheImageForMediaItem(MediaItem mediaItem) async {
    try {
      // Precache the thumbnail image
      await precacheImage(MemoryImage(mediaItem.imageBytes), context);

      if (mounted) {
        setState(() {
          _isImageCached = true;
        });
        updateKeepAlive(); // Update keep alive state
      }
    } catch (e) {
      // Handle error silently, image will load normally
      if (mounted) {
        setState(() {
          _isImageCached = true;
        });
        updateKeepAlive(); // Update keep alive state even on error
      }
    }
  }

  /// Build optimized image widget with caching
  Widget _buildOptimizedImage(ColorScheme colorScheme, bool isTablet, MediaItem mediaItem) {
    if (_cachedImageWidget != null) {
      return _cachedImageWidget!;
    }

    _cachedImageWidget = Hero(
      tag: 'media_${mediaItem.id}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTablet ? 16 : 12),
            topRight: Radius.circular(isTablet ? 16 : 12),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          mediaItem.imageBytes,
          fit: BoxFit.cover,
          // Optimize image rendering
          isAntiAlias: true,
          filterQuality: FilterQuality.medium, // Balance between quality and performance
          // Add frame builder for smoother loading
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isTablet ? 16 : 12),
                  topRight: Radius.circular(isTablet ? 16 : 12),
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isTablet ? 16 : 12),
                  topRight: Radius.circular(isTablet ? 16 : 12),
                ),
              ),
              child: Icon(Icons.broken_image, size: isTablet ? 48 : 32, color: colorScheme.outline),
            );
          },
        ),
      ),
    );

    return _cachedImageWidget!;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = appInstance.isTablet;

    return Obx(() {
      // Get the current media item from service to reflect real-time changes
      final mediaService = Get.find<MediaLibraryService>();
      final currentMediaItem = mediaService.mediaItems.firstWhere(
        (item) => item.id == widget.mediaItem.id,
        orElse: () => widget.mediaItem, // Fallback to original if not found
      );

      // Check if cache should be invalidated due to MediaItem changes
      // Remove _lastWatermarkStatus and watermark checks

      return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTablet ? 16 : 12)),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with optimized loading
              Expanded(
                flex: 2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Main image with optimized loading using current MediaItem
                    _buildOptimizedImage(colorScheme, isTablet, currentMediaItem),

                    // Source badge with optimized styling
                    Positioned(
                      top: isTablet ? 12 : 8,
                      left: isTablet ? 12 : 8,
                      child: _buildSourceBadge(colorScheme, isTablet, theme, currentMediaItem),
                    ),
                  ],
                ),
              ),

              // Content section with optimized layout using current MediaItem
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  child: _buildContentSection(colorScheme, isTablet, theme, currentMediaItem),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Build optimized source badge
  Widget _buildSourceBadge(
    ColorScheme colorScheme,
    bool isTablet,
    ThemeData theme,
    MediaItem mediaItem,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 10, vertical: isTablet ? 6 : 6),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _getSourceAbbreviation(mediaItem.source),
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontSize: isTablet ? 10.sp : 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build optimized content section
  Widget _buildContentSection(
    ColorScheme colorScheme,
    bool isTablet,
    ThemeData theme,
    MediaItem mediaItem,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description with optimized text rendering
        Expanded(
          child: AutoSizeText(
            mediaItem.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: isTablet ? 14.sp : 12.sp,
              height: 1.3,
            ),
            maxLines: isTablet ? 4 : 3,
            overflow: TextOverflow.ellipsis,
            minFontSize: isTablet ? 12 : 10,
            // Optimize text rendering
            textScaleFactor: 1.0,
          ),
        ),

        SizedBox(height: isTablet ? 12 : 8),

        // Bottom row with metadata and actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Metadata row with optimized chips
            Expanded(child: _buildMetadataChips(colorScheme, isTablet, theme, mediaItem)),

            // Actions with optimized buttons
            _buildActionButtons(colorScheme, isTablet),
          ],
        ),
      ],
    );
  }

  /// Build optimized metadata chips
  Widget _buildMetadataChips(
    ColorScheme colorScheme,
    bool isTablet,
    ThemeData theme,
    MediaItem mediaItem,
  ) {
    return Row(
      children: [
        // File size chip
        Container(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 6, vertical: isTablet ? 4 : 3),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
          ),
          child: Text(
            mediaItem.formattedSize,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontSize: isTablet ? 11.sp : 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Dimensions chip (if available)
        if (mediaItem.dimensions != null) ...[
          SizedBox(width: isTablet ? 8 : 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 6, vertical: isTablet ? 4 : 3),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
            ),
            child: Text(
              mediaItem.dimensions!.formatted,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontSize: isTablet ? 11.sp : 9.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build optimized action buttons
  Widget _buildActionButtons(ColorScheme colorScheme, bool isTablet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Copy button with optimized interaction
        _buildActionButton(
          icon: Icons.copy,
          color: Colors.black,
          backgroundColor: Colors.white,
          onTap: _handleCopyAction,
          isTablet: isTablet,
        ),

        SizedBox(width: isTablet ? 8 : 4),

        // Delete button with optimized interaction
        _buildActionButton(
          icon: Icons.delete_outline,
          color: Colors.red,
          backgroundColor: Colors.white,
          onTap: _handleDeleteAction,
          isTablet: isTablet,
        ),
      ],
    );
  }

  /// Build reusable action button
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
        child: Icon(icon, size: isTablet ? 20 : 14, color: color),
      ),
    );
  }

  /// Handle copy action with optimized feedback
  void _handleCopyAction() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.mediaItem.description));

    // Show optimized snackbar
    Get.showSnackbar(
      GetSnackBar(
        message: 'Description copied to clipboard',
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        messageText: Text(
          'Description copied to clipboard',
          style: TextStyle(color: Get.theme.colorScheme.onPrimary),
        ),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: Icon(Icons.check_circle, color: Get.theme.colorScheme.onPrimary),
        shouldIconPulse: false, // Optimize animation
      ),
    );
  }

  /// Handle delete action with haptic feedback
  void _handleDeleteAction() {
    HapticFeedback.lightImpact();
    widget.onDelete();
  }

  /// Get abbreviation for source
  String _getSourceAbbreviation(MediaSource source) {
    switch (source) {
      case MediaSource.chat:
        return 'CHAT';
      case MediaSource.hidream:
        return 'HD';
      case MediaSource.pollinationsAi:
        return 'PA';
      case MediaSource.unknown:
        return '?';
    }
  }
}
