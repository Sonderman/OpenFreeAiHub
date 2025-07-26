import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

class ChatImagePreviewController extends GetxController {
  late Uint8List image; // Single image

  final Rx<Uint8List?> showcaseImage = Rx<Uint8List?>(null);
  final RxBool isAdLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    image = args['rawImage'] as Uint8List; // Assume single image key

    showcaseImage.value = image;
  }

  Future<void> saveImageToGallery() async {
    if (showcaseImage.value == null) return;
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.storage,
      ].request();
      if (statuses[Permission.photos]!.isDenied && statuses[Permission.storage]!.isDenied) {
        Get.snackbar('Permission Denied', 'Storage permission is required to save images.');
        return;
      }

      final result = await ImageGallerySaverPlus.saveImage(
        showcaseImage.value!,
        name: "${appName}_chatImage_${DateTime.now().millisecondsSinceEpoch}",
      );
      if (result['isSuccess'] == true) {
        Get.snackbar('Success', 'Image saved to gallery');
      } else {
        Get.snackbar('Error', 'Failed to save image: ${result['errorMessage'] ?? 'Unknown error'}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save image: ${e.toString()}');
    }
  }

  Future<void> shareImage() async {
    if (showcaseImage.value == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/chat_shared_image_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(showcaseImage.value!);

      final result = await SharePlus.instance.share(
        ShareParams(
          text: 'Check out this AI-generated image from $appName!',
          subject: 'AI Generated Image',
          files: [XFile(file.path)],
        ),
      );

      if (result.status == ShareResultStatus.success) {
        Get.snackbar('Success', 'Image shared successfully');
      }

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to share image: ${e.toString()}');
    }
  }
}

class ChatImagePreviewScreen extends GetView<ChatImagePreviewController> {
  const ChatImagePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ChatImagePreviewController()); // Initialize controller

    return Scaffold(
      appBar: CustomAppBar(title: "Preview"),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
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
                        child: Obx(() {
                          if (controller.showcaseImage.value == null) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Hero(
                              tag: 'chatImageHero_${Get.arguments['messageId']}', // Unique tag
                              child: Image.memory(
                                controller.showcaseImage.value!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(child: _buildButtons(context)),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 16.w.clamp(16.0, 32.0), // Use double for clamp
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttons = _buildButtonList(context);
          if (constraints.maxWidth < 600) {
            // Adjusted breakpoint for button wrapping
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: buttons,
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: buttons
                  .map(
                    (button) => Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4), // Reduced padding
                        child: button,
                      ),
                    ),
                  )
                  .toList(),
            );
          }
        },
      ),
    );
  }

  List<Widget> _buildButtonList(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(
        horizontal: 3.w.clamp(12.0, 18.0),
        vertical: 12,
      ), // Adjusted padding
    );

    return [
      FilledButton.tonalIcon(
        style: buttonStyle.copyWith(backgroundColor: WidgetStateProperty.all(Colors.teal[700])),
        icon: const Icon(Icons.save_rounded, size: 20),
        label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w500)),
        onPressed: () => controller.saveImageToGallery(),
      ),
      FilledButton.tonalIcon(
        style: buttonStyle.copyWith(backgroundColor: WidgetStateProperty.all(Colors.blue[700])),
        icon: const Icon(Icons.share_rounded, size: 20),
        label: const Text('Share', style: TextStyle(fontWeight: FontWeight.w500)),
        onPressed: () => controller.shareImage(),
      ),
      /* FilledButton.tonalIcon(
        style: buttonStyle.copyWith(backgroundColor: WidgetStateProperty.all(Colors.orange[700])),
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w500)),
        onPressed: () => Get.back(), // Takes user back to chat
      ),*/
    ];
  }
}
