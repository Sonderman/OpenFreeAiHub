import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/screens/chat/chat_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Custom app bar with built-in feedback button
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final combinedActions = [...?actions];

    return AppBar(
      centerTitle: true,
      title: AutoSizeText(
        title,
        minFontSize: appInstance.isTablet ? 28 : 12,
        maxLines: 2,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: combinedActions,
    );
  }
}

/// Fixed footer widget containing social media links
class SocialMediaFooter extends StatelessWidget {
  const SocialMediaFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AutoSizeText(
              'Contact me on',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 14.sp),
            InkWell(
              onTap: () async {
                if (await canLaunchUrl(Uri.parse(telegramChannelUrl))) {
                  await launchUrl(Uri.parse(telegramChannelUrl));
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Could not launch Instagram')));
                }
              },
              child: Image.asset("assets/icons/telegram.png", height: 24.sp),
            ),
          ],
        ),
      ),
    );
  }
}

void pickersBottomSheet(BuildContext context, ChatController controller) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Add Photos, Files & Documents',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              if (controller.aiModel.features.isMultimodal)
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    // Open image picker to select image from gallery
                    final result = await ImagePicker().pickImage(
                      imageQuality: 70, // Reduce quality to save bandwidth
                      maxWidth: 1440, // Limit width to reasonable size
                      source: ImageSource.camera,
                    );
                    controller.handleImageSelection(result);
                  },
                ),
              if (controller.aiModel.features.isMultimodal)
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    // Open image picker to select image from gallery
                    final result = await ImagePicker().pickImage(
                      imageQuality: 70, // Reduce quality to save bandwidth
                      maxWidth: 1440, // Limit width to reasonable size
                      source: ImageSource.gallery,
                    );
                    controller.handleImageSelection(result);
                  },
                ),
              if (controller.aiModel.features.isMultimodal) const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Choose Document'),
                subtitle: const Text('PDF, DOCX, XLSX, TXT, CSV'),
                onTap: () async {
                  Navigator.pop(context);
                  // Call document selection handler
                  controller.handleDocumentSelection();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );

void showCustomBottomModalSheet(
  BuildContext context,
  Widget child, {
  double? maxHeight,
  String? title,
}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  enableDrag: true,
  isDismissible: true,
  constraints: BoxConstraints(
    maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.4,
    maxWidth: MediaQuery.of(context).size.width * 0.95,
  ),
  showDragHandle: true,
  useSafeArea: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 16),
      // Title section
      if (title != null)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      Expanded(
        child: Padding(padding: const EdgeInsets.all(8.0), child: child),
      ),
    ],
  ),
);
