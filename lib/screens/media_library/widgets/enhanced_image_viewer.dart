import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/global/services/media_library_service.dart';
import 'package:freeaihub/core/models/library/media_item.dart';
import 'package:freeaihub/screens/media_library/media_library_controller.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

/// Enhanced image viewer with watermark removal, sharing, and save functionality
/// Optimized for performance with image caching and memory management
class EnhancedImageViewer extends StatefulWidget {
  final MediaItem mediaItem;

  const EnhancedImageViewer({super.key, required this.mediaItem});

  @override
  State<EnhancedImageViewer> createState() => _EnhancedImageViewerState();
}

class _EnhancedImageViewerState extends State<EnhancedImageViewer> {
  // Image cache for performance optimization
  Image? _cachedImage;
  bool _isImageLoaded = false;

  // Loading state management - start with false since we have image bytes
  final RxBool _isLoading = false.obs;

  // Reactive state for forcing UI updates
  final RxInt _updateTrigger = 0.obs;

  @override
  void didChangeDependencies() {
    _preloadImage();
    super.didChangeDependencies();
  }

  /// Force UI refresh after MediaItem changes
  void _refreshUI() {
    if (mounted) {
      // Clear cache and reload
      _cachedImage = null;
      _isImageLoaded = false;

      // Preload with fresh data
      _preloadImage();

      // Trigger reactive rebuild
      _updateTrigger.value++;

      setState(() {
        // Force widget rebuild
      });
    }
  }

  /// Preload and cache the image for better performance
  void _preloadImage() async {
    try {
      // Get the current media item from service to reflect real-time changes
      final mediaService = Get.find<MediaLibraryService>();
      final currentMediaItem = mediaService.mediaItems.firstWhere(
        (item) => item.id == widget.mediaItem.id,
        orElse: () => widget.mediaItem, // Fallback to original if not found
      );

      // Create cached image widget with current display bytes
      _cachedImage = Image.memory(
        currentMediaItem.imageBytes, // Use imageBytes directly
        fit: BoxFit.contain,
        // Simplified frame builder without complex async handling
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          return child; // Always return the child immediately
        },
        errorBuilder: (context, error, stackTrace) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final isTablet = appInstance.isTablet;

          return Container(
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            ),
            child: Icon(
              Icons.broken_image,
              size: isTablet ? 64 : 48,
              color: colorScheme.onErrorContainer,
            ),
          );
        },
      );

      // Try to precache for better performance, but don't block UI
      try {
        await precacheImage(MemoryImage(currentMediaItem.imageBytes), context);
      } catch (precacheError) {
        // Ignore precache errors, image will still display
      }

      // Mark image as loaded
      if (mounted) {
        setState(() {
          _isImageLoaded = true;
        });
      }
    } catch (e) {
      // Always clear loading state on error
      if (mounted) {
        setState(() {
          _isImageLoaded = false; // Mark as failed to load
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = appInstance.isTablet;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      // Get the current media item from service to reflect real-time changes
      final mediaService = Get.find<MediaLibraryService>();
      final currentMediaItem = mediaService.mediaItems.firstWhere(
        (item) => item.id == widget.mediaItem.id,
        orElse: () => widget.mediaItem, // Fallback to original if not found
      );

      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface.withOpacity(0.95),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: colorScheme.onSurface, size: isTablet ? 28 : 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            currentMediaItem.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontSize: isTablet ? 20.sp : 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            // Info button
            IconButton(
              icon: Icon(
                Icons.info_outline,
                color: colorScheme.onSurface,
                size: isTablet ? 28 : 24,
              ),
              onPressed: () => _showItemInfo(context, currentMediaItem),
              tooltip: 'Image Information',
            ),
            // More options
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurface, size: isTablet ? 28 : 24),
              onSelected: (value) => _handleMenuAction(context, value, currentMediaItem),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: isTablet ? 24 : 20, color: colorScheme.primary),
                      SizedBox(width: isTablet ? 4.w : 3.w),
                      Text('Share', style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.sp)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: isTablet ? 24 : 20, color: colorScheme.primary),
                      SizedBox(width: isTablet ? 4.w : 3.w),
                      Text(
                        'Save to Gallery',
                        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                        size: isTablet ? 24 : 20,
                      ),
                      SizedBox(width: isTablet ? 4.w : 3.w),
                      Text(
                        'Delete',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          //color: colorScheme.primary,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Main image viewer with optimized loading
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isTablet ? 24 : 16),
                      topRight: Radius.circular(isTablet ? 24 : 16),
                    ),
                  ),
                  child: Center(
                    child: _buildOptimizedImageViewer(currentMediaItem, colorScheme, isTablet),
                  ),
                ),
              ),

              // Bottom info bar
              _buildBottomInfoBar(currentMediaItem, colorScheme, isTablet, theme),
            ],
          ),
        ),
      );
    });
  }

  /// Build optimized image viewer with caching and performance improvements
  Widget _buildOptimizedImageViewer(
    MediaItem currentMediaItem,
    ColorScheme colorScheme,
    bool isTablet,
  ) {
    return Obx(() {
      // Listen to update trigger for reactive changes
      _updateTrigger.value; // This will trigger rebuild when incremented

      // Show loading only if still loading AND image is not yet loaded
      if (_isLoading.value && !_isImageLoaded) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                SizedBox(height: 16),
                Text(
                  'Loading image...',
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }

      // If we have a cached image, show it
      if (_cachedImage != null) {
        return Hero(
          tag: 'media_${currentMediaItem.id}',
          child: Container(
            constraints: BoxConstraints(maxWidth: double.infinity, maxHeight: double.infinity),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(isTablet ? 16 : 12)),
            clipBehavior: Clip.antiAlias,
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 3.0, // Reduced max scale for better performance
              constrained: true,
              // Use clipBehavior for better performance
              clipBehavior: Clip.hardEdge,
              child: _cachedImage!,
            ),
          ),
        );
      }

      // Fallback: Show image directly from bytes if cache failed
      return Hero(
        tag: 'media_${currentMediaItem.id}',
        child: Container(
          constraints: BoxConstraints(maxWidth: double.infinity, maxHeight: double.infinity),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(isTablet ? 16 : 12)),
          clipBehavior: Clip.antiAlias,
          child: InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            minScale: 0.5,
            maxScale: 3.0,
            constrained: true,
            clipBehavior: Clip.hardEdge,
            child: Image.memory(
              currentMediaItem.imageBytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: colorScheme.errorContainer,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: isTablet ? 64 : 48,
                        color: colorScheme.onErrorContainer,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  /// Build bottom info bar with improved layout
  Widget _buildBottomInfoBar(
    MediaItem currentMediaItem,
    ColorScheme colorScheme,
    bool isTablet,
    ThemeData theme,
  ) {
    return Container(
      height: isTablet ? 40.h : 20.h,
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1)),
      ),
      padding: EdgeInsets.all(12.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scrollable description section
          Expanded(
            child: SizedBox(
              height: isTablet ? 15.h : 10.h, // Fixed height for scrollable area
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: AutoSizeText(
                  currentMediaItem.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: isTablet ? 18.sp : 16.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isTablet ? 2.h : 1.5.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildInfoChip(
                  currentMediaItem.source.displayName,
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                  colorScheme.onPrimaryContainer,
                  isTablet,
                  theme,
                ),
                SizedBox(width: isTablet ? 3.w : 2.w),
                _buildInfoChip(
                  currentMediaItem.formattedSize,
                  colorScheme.secondary,
                  colorScheme.secondaryContainer,
                  colorScheme.onSecondaryContainer,
                  isTablet,
                  theme,
                ),
                if (currentMediaItem.dimensions != null) ...[
                  SizedBox(width: isTablet ? 3.w : 2.w),
                  _buildInfoChip(
                    currentMediaItem.dimensions!.formatted,
                    colorScheme.tertiary,
                    colorScheme.tertiaryContainer,
                    colorScheme.onTertiaryContainer,
                    isTablet,
                    theme,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build info chip with dynamic theming
  Widget _buildInfoChip(
    String label,
    Color accentColor,
    Color backgroundColor,
    Color textColor,
    bool isTablet,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 4.w : 3.w,
        vertical: isTablet ? 1.5.h : 1.h,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: textColor,
          fontSize: isTablet ? 14.sp : 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Handle menu actions
  void _handleMenuAction(BuildContext context, String action, MediaItem mediaItem) {
    switch (action) {
      case 'share':
        _shareImage(mediaItem);
        break;
      case 'save':
        _saveToGallery(mediaItem);
        break;
      case 'delete':
        _showDeleteDialog(context, mediaItem);
        break;
    }
  }

  /// Share image
  Future<void> _shareImage(MediaItem mediaItem) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/shared_image_${DateTime.now().millisecondsSinceEpoch}.png';

      // Use original image (without watermark) for sharing if watermark was removed
      final imageBytes = mediaItem.imageBytes;

      final file = File(imagePath);
      await file.writeAsBytes(imageBytes);

      await SharePlus.instance.share(
        ShareParams(
          text: 'Check this out AI-generated image from $appName!',
          subject: 'AI Generated Image',
          files: [XFile(file.path)],
        ),
      );

      // Clean up temporary file
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to share image',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  /// Save image to gallery
  Future<void> _saveToGallery(MediaItem mediaItem) async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.storage,
      ].request();

      if (statuses[Permission.photos]!.isDenied && statuses[Permission.storage]!.isDenied) {
        Get.snackbar('Permission Denied', 'Storage permission is required to save images.');
        return;
      }

      // Use original image (without watermark) for saving if watermark was removed
      final imageBytes = mediaItem.imageBytes;

      final result = await ImageGallerySaverPlus.saveImage(
        imageBytes,
        quality: 100,
        name: 'FreeAIHub_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        Get.snackbar(
          'Success',
          'Image saved to gallery',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        throw Exception('Failed to save image');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save image to gallery',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  /// Show delete confirmation dialog
  void _showDeleteDialog(BuildContext context, MediaItem mediaItem) {
    final isTablet = appInstance.isTablet;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Delete Image',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${mediaItem.title}"?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: isTablet ? 16.sp : 14.sp,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 6.w : 4.w,
                vertical: isTablet ? 1.5.h : 1.h,
              ),
            ),
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(fontSize: isTablet ? 16.sp : 14.sp),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close image viewer

              final controller = Get.find<MediaLibraryController>();
              await controller.deleteMediaItem(mediaItem);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 6.w : 4.w,
                vertical: isTablet ? 1.5.h : 1.h,
              ),
            ),
            child: Text(
              'Delete',
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: isTablet ? 16.sp : 14.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show detailed item information
  void _showItemInfo(BuildContext context, MediaItem mediaItem) {
    final isTablet = appInstance.isTablet;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Custom, theme-aware dialog that scales nicely on phones & tablets
    showDialog(
      context: context,
      barrierColor: colorScheme.scrim.withOpacity(0.45), // subtle background dim
      builder: (context) {
        return Center(
          // Constrain width so it never feels stretched on large screens
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 60.w : 90.w, maxHeight: 80.h),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isTablet ? 4.h : 3.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with title & close button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mediaItem.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: isTablet ? 22.sp : 20.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                          splashRadius: isTablet ? 24 : 20,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(color: colorScheme.outline.withOpacity(0.3)),
                    SizedBox(height: isTablet ? 2.h : 1.5.h),

                    // Scrollable info
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Source', mediaItem.source.displayName, isTablet, theme),
                            _buildInfoRow('Prompt', mediaItem.description, isTablet, theme),
                            _buildInfoRow('Size', mediaItem.formattedSize, isTablet, theme),
                            if (mediaItem.dimensions != null)
                              _buildInfoRow(
                                'Dimensions',
                                mediaItem.dimensions!.formatted,
                                isTablet,
                                theme,
                              ),
                            _buildInfoRow(
                              'Created',
                              _formatDate(mediaItem.createdAt),
                              isTablet,
                              theme,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isTablet ? 3.h : 2.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 6.w : 4.w,
                            vertical: isTablet ? 1.5.h : 1.h,
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: isTablet ? 16.sp : 14.sp,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build info row for dialog with dynamic theming
  Widget _buildInfoRow(String label, String value, bool isTablet, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 1.h : 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 140 : 120,
            child: Text(
              '$label:',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 14.sp : 12.sp,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 14.sp : 12.sp,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
