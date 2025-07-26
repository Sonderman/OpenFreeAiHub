import 'package:flutter/material.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:freeaihub/core/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Library content with action buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Column(
              children: [
                // Header section with gradient background
                _buildHeaderSection(context),
                SizedBox(height: 2.h),

                // Action buttons
                _buildActionButton(
                  context: context,
                  icon: Icons.person_pin_outlined,
                  label: 'My AI Characters',
                  onPressed: () => Get.toNamed(AppRoutes.aiCharacters),
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.perm_media,
                  label: 'My Medias',
                  onPressed: () => Get.toNamed(AppRoutes.mediaLibrary),
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.article_outlined,
                  label: 'My Prompts',
                  onPressed: () => _showComingSoonSnackbar(
                    context,
                    'Prompts',
                    'Prompt management feature will be available soon!',
                  ),
                ),

                // Coming soon placeholder
                _buildComingSoonPlaceholder(context),
                SizedBox(height: 3.h),
                // Navigation hint
                _buildNavigationHint(context),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          // Footer with social media links
          SizedBox(
            height: appInstance.isTablet ? 20.sp : 25.sp,
            width: 100.w,
            child: const SocialMediaFooter(),
          ),
        ],
      ),
    );
  }

  /// Builds the header section with gradient background
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.sp),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header title with icon
            Row(
              children: [
                Icon(
                  Icons.library_books,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 24.sp,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Library',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Access your saved AI Characters, medias, and prompts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an action button with icon and label
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 2.h),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        ),
      ),
    );
  }

  /// Builds the coming soon placeholder container
  Widget _buildComingSoonPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: appInstance.isTablet ? 14.h : 10.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24.sp,
            ),
            SizedBox(height: 1.h),
            Text(
              'More library features coming soon...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the navigation hint container
  Widget _buildNavigationHint(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15.sp),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe_right, color: Theme.of(context).colorScheme.primary, size: 20.sp),
          SizedBox(width: 2.w),
          Text(
            'Swipe right to return to AI Models',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a coming soon snackbar message
  void _showComingSoonSnackbar(BuildContext context, String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.primary,
      colorText: Theme.of(context).colorScheme.onPrimary,
      duration: Duration(seconds: 2),
    );
  }
}
