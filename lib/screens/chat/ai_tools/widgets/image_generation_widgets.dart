import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:freeaihub/screens/chat/chat_controller.dart';
import 'package:freeaihub/screens/chat/chat_image_preview_screen.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

class ImageGenerationWidgets {
  /// Builds loading state for image generation
  static Widget buildLoadingWidget(double maxWidth, double maxHeight) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(Get.context!).colorScheme.secondary),
            SizedBox(height: 1.h),
            Text(
              "Generating image...",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(Get.context!).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds success state for image generation
  static Widget buildSuccessWidget(
    String messageId,
    Map<String, dynamic> metadata,
    double maxWidth,
    double maxHeight,
    ChatController controller,
  ) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => const ChatImagePreviewScreen(),
          arguments: {'rawImage': base64Decode(metadata["Rawbase64"])},
        );
      },
      child: Hero(
        tag: 'chatImageHero_$messageId',
        child: ConstrainedBox(
          key: ValueKey('$messageId-image'),
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: Center(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: Image.memory(base64Decode(metadata["Rawbase64"]), fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds cancelled state for image generation
  static Widget buildCancelledWidget(String messageId, double maxWidth, double maxHeight) {
    return ConstrainedBox(
      key: ValueKey('$messageId-cancelled'),
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: Colors.orange[300], size: 30.sp),
            SizedBox(height: 1.h),
            Text(
              "Image generation cancelled.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[300]),
            ),
            SizedBox(height: 0.5.h),
            Text(
              "The operation was cancelled by user or system.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.orange[400]?.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds error state for image generation
  static Widget buildErrorWidget(String messageId, double maxWidth, double maxHeight) {
    return ConstrainedBox(
      key: ValueKey('$messageId-error'),
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 30.sp),
            SizedBox(height: 1.h),
            Text(
              "Failed to generate image.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[300]),
            ),
          ],
        ),
      ),
    );
  }
}
