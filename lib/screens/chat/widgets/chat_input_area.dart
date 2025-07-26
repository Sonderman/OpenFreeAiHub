import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/global/components/chat/custom_capability_widget.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:freeaihub/core/models/chat/image_data_model.dart';
import 'package:freeaihub/screens/chat/chat_controller.dart';
import 'package:freeaihub/screens/chat/widgets/message_builders.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:freeaihub/core/global/services/ai_character_service.dart';
import 'package:freeaihub/core/models/ai/ai_character_model.dart';
import 'package:freeaihub/core/routes/app_routes.dart';

/// Chat input area widget
/// Contains text input field, image preview, and action buttons
class ChatInputArea extends StatelessWidget {
  final ChatController controller;

  const ChatInputArea({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          _buildSelectedFilesPreview(),
          _buildTextInputField(context),
          SizedBox(height: 1.h),
          _buildBottomActionRow(context),
        ],
      ),
    );
  }

  /// Builds the selected files preview section (images and documents)
  Widget _buildSelectedFilesPreview() {
    return Obx(() {
      final hasImages = controller.selectedImages.isNotEmpty;
      final hasDocuments = controller.selectedDocuments.isNotEmpty;

      if (hasImages || hasDocuments) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: controller.selectedImages.length + controller.selectedDocuments.length,
            itemBuilder: (context, index) {
              // Show images first, then documents
              if (index < controller.selectedImages.length) {
                final imageData = controller.selectedImages[index];
                return _buildImagePreviewItem(imageData);
              } else {
                final documentIndex = index - controller.selectedImages.length;
                final documentData = controller.selectedDocuments[documentIndex];
                return _buildDocumentPreviewItem(documentData);
              }
            },
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  /// Builds individual image preview item with remove button
  Widget _buildImagePreviewItem(ImageData imageData) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(imageData.path), width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => controller.removeSelectedImage(imageData.id),
              child: Container(
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds individual document preview item with remove button
  Widget _buildDocumentPreviewItem(Map<String, dynamic> documentData) {
    const double previewWidth = 90;
    const double previewHeight = 80;

    return SizedBox(
      width: previewWidth,
      height: previewHeight,
      child: Stack(
        children: [
          Container(
            width: previewWidth,
            height: previewHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(Get.context!).colorScheme.surfaceContainerHighest,
              border: Border.all(color: Theme.of(Get.context!).colorScheme.outline, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    MessageBuilders.getDocumentIcon(documentData['extension'] ?? ''),
                    size: 26,
                    color: Theme.of(Get.context!).colorScheme.primary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    documentData['extension']?.toUpperCase() ?? 'DOC',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  AutoSizeText(
                    documentData['name'] ?? '',
                    maxLines: 2,
                    minFontSize: 6,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => controller.removeSelectedDocument(documentData['id']),
              child: Container(
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the text input field with clear button
  Widget _buildTextInputField(BuildContext context) {
    return Obx(() {
      final isInputDisabled = controller.isProcessingToolCall.value;

      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller.promptController,
        builder: (context, value, child) {
          return TextField(
            controller: controller.promptController,
            enabled: !isInputDisabled, // Disable input during tool call processing
            autofocus: false,
            focusNode: controller.promptInputFocusNode,
            onTapOutside: (event) => controller.promptInputFocusNode.unfocus(),
            decoration: InputDecoration(
              hintText: isInputDisabled ? 'Processing request...' : 'Ask anything...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isInputDisabled
                  ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              // Add clear button when text is not empty and input is enabled
              suffixIcon: value.text.isNotEmpty && !isInputDisabled
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        controller.promptController.clear();
                      },
                      tooltip: 'Clear text',
                    )
                  : null,
            ),
            minLines: 1,
            maxLines: 10,
            onSubmitted: (text) {
              if (!isInputDisabled &&
                  (text.trim().isNotEmpty ||
                      controller.selectedImages.isNotEmpty ||
                      controller.selectedDocuments.isNotEmpty)) {
                controller.handleSendPressed(text.trim());
              }
            },
          );
        },
      );
    });
  }

  /// Builds the bottom action row with tools and send button
  Widget _buildBottomActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildBottomToolsArea(context)),
        if (controller.messages.isEmpty &&
            controller.sessionManager.selectedCharacter.value == null &&
            controller.aiModel.features.supportsResponseFormat)
          SizedBox(width: 2.w),
        if (controller.messages.isEmpty &&
            controller.sessionManager.selectedCharacter.value == null &&
            controller.aiModel.features.supportsResponseFormat)
          _buildSelectCharacterButton(context),
        SizedBox(width: 2.w),
        _buildMagicEnhanceButton(context),
        SizedBox(width: 2.w),
        _buildSendButton(context),
      ],
    );
  }

  /// Builds the magic enhance button
  Widget _buildMagicEnhanceButton(BuildContext context) {
    return Obx(() {
      final isInputDisabled = controller.isProcessingToolCall.value;

      if (controller.isEnhancingPrompt.value) {
        return const CircularProgressIndicator();
      }

      return IconButton(
        onPressed: isInputDisabled
            ? null
            : () {
                if (controller.promptController.text.trim().isEmpty) return;
                controller.handlePromptEnhancing(controller.promptController);
              },
        icon: Image.asset(
          "assets/icons/magic.png",
          width: 24.sp,
          height: 24.sp,
          color: isInputDisabled
              ? context.theme.colorScheme.primary.withOpacity(0.5)
              : context.theme.colorScheme.primary,
        ),
      );
    });
  }

  /// Builds the send/stop button
  Widget _buildSendButton(BuildContext context) {
    return Obx(() {
      final isInputDisabled = controller.isProcessingToolCall.value;

      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isInputDisabled
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Theme.of(context).colorScheme.primary,
        ),
        child: IconButton(
          icon: Icon(
            controller.isTyping.value ? Icons.stop : Icons.send,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: isInputDisabled
              ? null
              : () {
                  if (controller.isTyping.value) {
                    controller.onClickStopButton();
                  } else if (controller.promptController.text.trim().isNotEmpty ||
                      controller.selectedImages.isNotEmpty ||
                      controller.selectedDocuments.isNotEmpty) {
                    controller.handleSendPressed(controller.promptController.text.trim());
                  }
                },
        ),
      );
    });
  }

  /// Builds additional tool buttons below the input area
  Widget _buildBottomToolsArea(BuildContext context) {
    double iconSize = 20.sp;
    double buttonSize = 24.sp;

    return Row(
      children: [
        _buildAddButton(context, buttonSize, iconSize),
        SizedBox(width: 2.w),
        if (controller.aiModel.features.supportsResponseFormat) _buildCapabilityWidget(buttonSize),
      ],
    );
  }

  /// Builds the add button for multimodal features
  Widget _buildAddButton(BuildContext context, double buttonSize, double iconSize) {
    return Tooltip(
      message: "Add Photo",
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
        child: InkWell(
          child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary, size: iconSize),
          onTap: () {
            if (controller.isTyping.value) return;
            pickersBottomSheet(context, controller);
          },
        ),
      ),
    );
  }

  /// Builds the character selection button
  Widget _buildSelectCharacterButton(BuildContext context) {
    return Tooltip(
      message: "Select Character",
      child: IconButton(
        onPressed: () {
          if (controller.isTyping.value) return;
          _openCharacterSelectionSheet(context);
        },
        icon: Icon(
          Icons.person_pin_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 22.sp,
        ),
      ),
    );
  }

  /// Opens a modal bottom sheet to select an AI character
  void _openCharacterSelectionSheet(BuildContext context) {
    final AiCharacterService service = Get.find<AiCharacterService>();

    Widget child = Obx(() {
      if (service.isLoading.value) {
        return const Center(
          child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
        );
      }

      final characters = service.characters;
      // Build the character list view
      Widget listView = ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: characters.length,
        shrinkWrap: true,
        separatorBuilder: (_, __) => const Divider(height: 2),
        itemBuilder: (ctx, idx) {
          final AiCharacterModel character = characters[idx];

          // Determine if this character is currently selected
          final bool isSelected =
              controller.sessionManager.selectedCharacter.value?.id == character.id;

          return ListTile(
            leading: character.imageUrl != null
                ? CircleAvatar(backgroundImage: NetworkImage(character.imageUrl!))
                : CircleAvatar(
                    child: Icon(Icons.person, color: Theme.of(ctx).colorScheme.onPrimaryContainer),
                  ),
            title: Text(character.name),
            subtitle: Text(character.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: isSelected
                ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                : null,
            selected: isSelected,
            selectedTileColor: Theme.of(ctx).colorScheme.primaryContainer.withOpacity(0.3),
            onTap: () {
              controller.selectCharacter(character);
              Navigator.pop(ctx);
            },
          );
        },
      );

      // Return a column with the list and a create button at the bottom
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expand listView when there are characters, otherwise show message
          if (characters.isNotEmpty)
            Expanded(child: listView)
          else
            Expanded(
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No AI characters found.')),
              ),
            ),

          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_add_alt_1),
            title: const Text('Edit AI Characters'),
            onTap: () {
              Get.toNamed(AppRoutes.aiCharacters);
            },
          ),
          SizedBox(height: 3.h),
        ],
      );
    });
    showCustomBottomModalSheet(context, child, title: "Select Character", maxHeight: 45.h);
  }

  /// Builds the capability widget for AI features
  Widget _buildCapabilityWidget(double buttonSize) {
    return Obx(
      () => CustomCapabilityWidget(
        iconSize: buttonSize,
        isWebSearchEnabled: controller.isWebSearchEnabled.value,
        isImageGenEnabled: controller.isImageGenEnabled.value,
        onWebSearchToggle: () => controller.isWebSearchEnabled.toggle(),
        onImageGenToggle: () => controller.isImageGenEnabled.toggle(),
        toolCapabilities: controller.aiModel.features.toolCapabilities,
      ),
    );
  }
}
