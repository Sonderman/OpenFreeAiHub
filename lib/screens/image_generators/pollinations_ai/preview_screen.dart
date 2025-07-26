import 'package:auto_size_text/auto_size_text.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:freeaihub/screens/image_generators/pollinations_ai/pollinations_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PollinationsController>();

    return Scaffold(
      appBar: CustomAppBar(title: 'Generated Image', automaticallyImplyLeading: true),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: 'pollinationsImageHero',
                child: InteractiveViewer(
                  child: Obx(() {
                    if (controller.showcaseImage.value != null) {
                      return Image.memory(controller.showcaseImage.value!, fit: BoxFit.contain);
                    } else {
                      return const Icon(Icons.image, size: 100, color: Colors.grey);
                    }
                  }),
                ),
              ),
            ),
          ),
          // Action buttons at the bottom
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Primary actions row
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: controller.showcaseImage.value != null
                            ? () => controller.saveImageToGallery()
                            : null,
                        icon: Icon(Icons.download, size: 18.sp),
                        label: AutoSizeText('Save'),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.showcaseImage.value != null
                            ? () => controller.shareImage()
                            : null,
                        icon: Icon(Icons.share, size: 18.sp),
                        label: AutoSizeText('Share'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
