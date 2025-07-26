import 'package:flutter/material.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:freeaihub/core/global/services/media_library_service.dart';
import 'package:freeaihub/screens/media_library/media_library_controller.dart';
import 'package:freeaihub/screens/media_library/widgets/media_grid_widget.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

/// View for displaying and managing media library
/// A simple gallery view to display all media items chronologically.
class MediaLibraryView extends StatefulWidget {
  const MediaLibraryView({super.key});

  @override
  State<MediaLibraryView> createState() => _MediaLibraryViewState();
}

class _MediaLibraryViewState extends State<MediaLibraryView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep state alive for better performance

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return GetBuilder<MediaLibraryController>(
      init: MediaLibraryController(),
      builder: (controller) {
        return Scaffold(
          appBar: CustomAppBar(title: 'My Medias', automaticallyImplyLeading: true),
          body: _buildBody(context, controller),
        );
      },
    );
  }

  /// Builds the main body content
  Widget _buildBody(BuildContext context, MediaLibraryController controller) {
    return Obx(() {
      final mediaService = Get.find<MediaLibraryService>();

      // Show loading state
      if (mediaService.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Loading media library...',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        );
      }

      // Observe media items changes from the controller
      final mediaItems = controller.mediaItems;
      mediaService.mediaItems.length;

      if (mediaItems.isEmpty) {
        return _buildEmptyState(context);
      }

      return MediaGridWidget(mediaItems: mediaItems);
    });
  }

  /// Builds empty state widget
  Widget _buildEmptyState(BuildContext context) {
    final isTablet = appInstance.isTablet;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 15.sp : 6.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: isTablet ? 48.sp : 50.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: isTablet ? 3.h : 2.h),
            Text(
              'No images saved yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 20.sp : 20.sp,
              ),
            ),
            SizedBox(height: isTablet ? 2.h : 1.h),
            Text(
              'Images from chat and generators will appear here automatically',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 18.sp : 16.sp,
              ),
            ),
            SizedBox(height: isTablet ? 20.sp : 20.sp),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.arrow_back,
                size: isTablet ? 20.sp : 18.sp,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              label: Text(
                'Go Back',
                style: TextStyle(
                  fontSize: isTablet ? 16.sp : 16.sp,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 8.w : 6.w,
                  vertical: isTablet ? 2.h : 1.5.h,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
