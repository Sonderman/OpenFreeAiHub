// Function to show the edit message dialog
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/screens/chat/chat_controller.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

void showEditMessageBottomSheet({
  required BuildContext context,
  required Message message,
  required ChatController controller,
  required Function(String newText, List<Map<String, dynamic>>? newImages) onSave,
}) {
  final textController = TextEditingController(text: message.text);

  // Initialize editing images with existing attached images (new structure)
  List<Map<String, dynamic>> editingImages = [];
  if (message.attachedImages != null && message.attachedImages!.isNotEmpty) {
    editingImages = message.attachedImages!
        .map((img) => img.toJson())
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Determine if the current message is a document-type message (has attachedDocuments)
  final bool isDocumentMessage =
      message.metadata != null && message.metadata!['attachedDocuments'] != null;

  // Image editing is only allowed when the AI model supports multimodal AND the message is not a document message
  final bool allowImageEditing =
      !isDocumentMessage && (controller.aiModel.features.isMultimodal == true);

  showCustomBottomModalSheet(
    context,
    StatefulBuilder(
      builder: (dialogContext, sheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview section (only show if allowed)
            if (allowImageEditing) ...[
              if (editingImages.isNotEmpty) ...[
                const Text(
                  'Attached Images:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: editingImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final imageData = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(imageData['path']),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    sheetState(() {
                                      editingImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Add image button
              if (editingImages.length < maxImagesPerMessage)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      showModalBottomSheet<void>(
                        context: dialogContext,
                        backgroundColor: Theme.of(dialogContext).cardColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (BuildContext bottomSheetContext) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Text(
                                  'Add Photo',
                                  style: Theme.of(
                                    bottomSheetContext,
                                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Take Photo'),
                                onTap: () async {
                                  Navigator.pop(bottomSheetContext);
                                  final result = await ImagePicker().pickImage(
                                    imageQuality: 70,
                                    maxWidth: 1440,
                                    source: ImageSource.camera,
                                  );
                                  if (result != null) {
                                    // Update the editingImages list with the newly picked image
                                    // and refresh the parent dialog UI.
                                    sheetState(() {
                                      if (editingImages.length < 4) {
                                        final file = File(result.path);
                                        final fileName = result.name;
                                        final fileSize = file.lengthSync();
                                        final fileExtension = fileName.contains('.')
                                            ? fileName.split('.').last
                                            : '';
                                        editingImages.add({
                                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                          'name': fileName,
                                          'path': result.path,
                                          'size': fileSize,
                                          'extension': fileExtension,
                                          // Additional keys required by editMessage (left null if not available)
                                          'format': null,
                                          'base64URL': null,
                                        });
                                      }
                                    });
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Choose from Gallery'),
                                onTap: () async {
                                  Navigator.pop(bottomSheetContext);
                                  final result = await ImagePicker().pickImage(
                                    imageQuality: 70,
                                    maxWidth: 1440,
                                    source: ImageSource.gallery,
                                  );
                                  if (result != null) {
                                    // Update the editingImages list with the newly picked image
                                    // and refresh the parent dialog UI.
                                    sheetState(() {
                                      if (editingImages.length < 4) {
                                        final file = File(result.path);
                                        final fileName = result.name;
                                        final fileSize = file.lengthSync();
                                        final fileExtension = fileName.contains('.')
                                            ? fileName.split('.').last
                                            : '';
                                        editingImages.add({
                                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                          'name': fileName,
                                          'path': result.path,
                                          'size': fileSize,
                                          'extension': fileExtension,
                                          // Additional keys required by editMessage (left null if not available)
                                          'format': null,
                                          'base64URL': null,
                                        });
                                      }
                                    });
                                  }
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.close),
                                title: const Text('Cancel'),
                                onTap: () => Navigator.pop(bottomSheetContext),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_photo_alternate, size: 18),
                    label: Text('Add Image (${editingImages.length}/4)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Text input section
            const Text(
              'Message Text:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    maxLines: 4,
                    minLines: 2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your message...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  return IconButton(
                    onPressed: (controller.isEnhancingPrompt.value)
                        ? null
                        : () async {
                            if (textController.text.trim().isNotEmpty) {
                              await controller.handlePromptEnhancing(textController);
                            }
                          },
                    icon: Image.asset(
                      "assets/icons/magic.png",
                      width: 24,
                      height: 24,
                      color: Theme.of(Get.context!).colorScheme.primary,
                    ),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    tooltip: 'Enhance prompt',
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            // Spacer
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onSave(
                      textController.text.trim(),
                      allowImageEditing && editingImages.isNotEmpty ? editingImages : null,
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    ),
    title: 'Edit Message',
    maxHeight: MediaQuery.of(context).size.height * 0.5,
  );
}
