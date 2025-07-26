import 'package:flutter/material.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/models/library/media_item.dart';
import 'package:freeaihub/screens/media_library/media_library_controller.dart';
import 'package:freeaihub/screens/media_library/widgets/media_item_card.dart';
import 'package:freeaihub/screens/media_library/widgets/enhanced_image_viewer.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

/// Widget displaying media items in a responsive grid
/// Optimized for performance with lazy loading and viewport-based rendering
class MediaGridWidget extends StatefulWidget {
  final List<MediaItem> mediaItems;

  const MediaGridWidget({super.key, required this.mediaItems});

  @override
  State<MediaGridWidget> createState() => _MediaGridWidgetState();
}

class _MediaGridWidgetState extends State<MediaGridWidget> with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final Set<int> _preloadedIndexes = <int>{};

  static const double _cacheExtent = 1000.0; // Cache extent for better performance

  @override
  bool get wantKeepAlive => true; // Keep state alive for better performance

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Preload initial items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadInitialItems();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Preload initial visible items for better performance
  void _preloadInitialItems() {
    final crossAxisCount = _getCrossAxisCount();
    final initialItemsToPreload = (crossAxisCount * 2).clamp(0, widget.mediaItems.length);

    for (int i = 0; i < initialItemsToPreload; i++) {
      _preloadedIndexes.add(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final isTablet = appInstance.isTablet;

    if (widget.mediaItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 15.sp : 10.sp),
      child: GridView.builder(
        controller: _scrollController,
        // Optimize physics for better performance
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        // Optimize cache extent for smoother scrolling
        cacheExtent: _cacheExtent,
        // Add padding for better UX
        padding: EdgeInsets.only(bottom: isTablet ? 20.sp : 15.sp, top: isTablet ? 10.sp : 8.sp),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(),
          crossAxisSpacing: isTablet ? 15.sp : 10.sp,
          mainAxisSpacing: isTablet ? 15.sp : 10.sp,
          mainAxisExtent: isTablet ? 50.h : 35.h,
          childAspectRatio: 0.75, // Slightly taller than square for metadata
        ),
        itemCount: widget.mediaItems.length,
        itemBuilder: (context, index) {
          // Add viewport-based optimization
          return _buildOptimizedMediaCard(context, index);
        },
      ),
    );
  }

  /// Build optimized media card with lazy loading
  Widget _buildOptimizedMediaCard(BuildContext context, int index) {
    final mediaItem = widget.mediaItems[index];

    // Return MediaItemCard directly - it already handles AutomaticKeepAliveClientMixin internally
    // Wrapping with AutomaticKeepAlive here causes ParentDataWidget conflicts
    return MediaItemCard(
      key: ValueKey(mediaItem.id),
      mediaItem: mediaItem,
      onTap: () => _showImageViewer(context, mediaItem),
      onDelete: () => _deleteItem(context, mediaItem),
    );
  }

  /// Get cross axis count based on screen size with improved logic
  int _getCrossAxisCount() {
    final screenWidth = Get.width;
    final isTablet = appInstance.isTablet;

    if (isTablet) {
      // Tablet optimizations
      if (screenWidth > 1200) return 5; // Large tablet landscape
      if (screenWidth > 900) return 4; // Tablet landscape
      return 3; // Tablet portrait
    } else {
      // Mobile optimizations
      if (screenWidth > 400) return 2; // Larger phones
      return 2; // Standard mobile
    }
  }

  /// Show image in full screen viewer with optimizations
  void _showImageViewer(BuildContext context, MediaItem mediaItem) {
    // Use optimized navigation with hero animation support
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EnhancedImageViewer(mediaItem: mediaItem),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Optimized transition animation
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  /// Delete media item with optimized confirmation dialog
  void _deleteItem(BuildContext context, MediaItem mediaItem) {
    final isTablet = appInstance.isTablet;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      // Optimize dialog performance
      barrierDismissible: true,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTablet ? 20 : 16)),
        title: Text(
          'Delete Image',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: isTablet ? 18.sp : 16.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${mediaItem.title}"?\n\nThis action cannot be undone.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: isTablet ? 14.sp : 12.sp,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 20,
                vertical: isTablet ? 12 : 10,
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: isTablet ? 14.sp : 12.sp, fontWeight: FontWeight.w500),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final controller = Get.find<MediaLibraryController>();
              await controller.deleteMediaItem(mediaItem);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 20,
                vertical: isTablet ? 12 : 10,
              ),
            ),
            child: Text(
              'Delete',
              style: TextStyle(fontSize: isTablet ? 14.sp : 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
