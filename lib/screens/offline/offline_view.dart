import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'offline_controller.dart';

class OfflineView extends GetView<OfflineController> {
  const OfflineView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(OfflineController());
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 20.w,
                  color: Theme.of(context).colorScheme.error,
                ),
                SizedBox(height: 4.h),
                Text(
                  'No Internet Connection',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Please check your internet connection and try again',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: controller.retryConnection,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      label: const AutoSizeText(
                        'Retry Connection',
                        minFontSize: 16,
                        maxFontSize: 20,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 4,
                        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    OutlinedButton.icon(
                      onPressed: controller.exitApp,
                      icon: const Icon(Icons.close_rounded),
                      label: const AutoSizeText('Exit App', minFontSize: 16, maxFontSize: 20),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
