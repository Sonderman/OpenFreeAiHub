import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import '../home_controller.dart';

/// Tab indicator widget for switching between Library and AI Models views
class HomeTabIndicator extends StatelessWidget {
  const HomeTabIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(
      () => Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            // Library Tab Indicator
            _buildTabButton(
              context: context,
              controller: controller,
              tabIndex: 0,
              icon: Icons.library_books,
              label: 'Library',
              onTap: () => controller.navigateToLibraryView(),
            ),
            SizedBox(width: 2.w),
            // AI Models Tab Indicator
            _buildTabButton(
              context: context,
              controller: controller,
              tabIndex: 1,
              icon: Icons.grid_view,
              label: 'AI Models',
              onTap: () => controller.navigateToMainView(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds individual tab button
  Widget _buildTabButton({
    required BuildContext context,
    required HomeController controller,
    required int tabIndex,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isActive = controller.currentTabIndex.value == tabIndex;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 1.h),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
