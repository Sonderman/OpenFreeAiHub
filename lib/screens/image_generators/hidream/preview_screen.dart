import 'package:flutter/material.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:freeaihub/screens/image_generators/hidream/hidream_controller.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

/// Screen for previewing generated images with interactive controls
///
/// This screen provides a responsive image viewer with zoom/pan capabilities
/// and action buttons for saving, sharing, and removing watermarks
class PreviewScreen extends GetView<HidreamController> {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Preview"),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive padding based on screen size
            final padding = constraints.maxWidth * 0.05;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.9,
                          maxHeight: constraints.maxHeight * 0.8,
                        ),
                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Hero(
                            tag: 'imageHero',
                            child: Obx(() {
                              return Image.memory(
                                controller.showcaseImage.value!,
                                fit: BoxFit.contain,
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(child: _buildButtons()),
    );
  }

  /// Builds a responsive group of action buttons
  Widget _buildButtons() {
    return Container(
      // Responsive padding based on screen width
      padding: EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 16.w.clamp(16, 32), // Min 16, max 32 logical pixels
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use Wrap for small screens, Row for larger screens
          if (constraints.maxWidth < 600) {
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _buildButtonList(),
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildButtonList()
                  .map(
                    (button) =>
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: button),
                  )
                  .toList(),
            );
          }
        },
      ),
    );
  }

  /// Helper method to build the individual action buttons
  List<Widget> _buildButtonList() {
    return [
      FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.teal[800],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(horizontal: 16.w.clamp(16, 24), vertical: 12),
        ),
        icon: const Icon(Icons.save_rounded, size: 20),
        label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w500)),
        onPressed: () => controller.saveImageToGallery(),
      ),
      FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(horizontal: 16.w.clamp(16, 24), vertical: 12),
        ),
        icon: const Icon(Icons.share_rounded, size: 20),
        label: const Text('Share', style: TextStyle(fontWeight: FontWeight.w500)),
        onPressed: () {
          controller.shareImage();
        },
      ),
      FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.orange[800],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(horizontal: 16.w.clamp(16, 24), vertical: 12),
        ),
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w500)),
        onPressed: () => Get.back<bool>(result: true),
      ),
    ];
  }
}
