import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freeaihub/core/global/components/chat/bottom_sheets.dart';
import 'package:freeaihub/screens/chat/ai_tools/widgets/image_generation_widgets.dart';
import 'package:intl/intl.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/global/components/chat/chat_dialogs.dart';
import 'package:freeaihub/core/global/components/chat/full_screen_image_viewer.dart';
import 'package:freeaihub/core/models/chat/image_data_model.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/screens/chat/widgets/full_screen_document_viewer.dart';
import 'package:freeaihub/core/global/components/chat/html_code_preview.dart';
import 'package:freeaihub/core/global/services/tts_service.dart';
import 'package:freeaihub/screens/chat/ai_tools/web_search_tool.dart';
import 'package:freeaihub/screens/chat/ai_tools/widgets/web_search_widgets.dart';
import 'package:freeaihub/screens/chat/chat_controller.dart';
import 'package:get/get.dart';
import 'package:gpt_markdown/custom_widgets/code_field.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:markdown/markdown.dart' as mrk;
import 'package:sizer/sizer.dart';

import 'package:url_launcher/url_launcher.dart';

/// Message builders for different types of chat messages
/// Handles text messages, image messages, and their associated tools
class MessageBuilders {
  static const double _borderRadius = 14.0;

  /// Formats timestamp for display in chat messages
  /// Returns formatted time string based on when the message was sent
  static String _formatMessageTime(int? timestamp) {
    if (timestamp == null) return '';

    final messageDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(messageDate);

    // Same day - show only time
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(messageDate);
    }

    // Yesterday
    if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(messageDate)}';
    }

    // This week (last 7 days)
    if (difference.inDays < 7) {
      return DateFormat('EEEE HH:mm').format(messageDate);
    }

    // Older messages
    return DateFormat('dd MMM HH:mm').format(messageDate);
  }

  /// Builds a styled text message bubble with dynamic width
  /// Differentiates between user and AI messages for appropriate styling and alignment
  /// Also displays attached images and documents if present in message metadata
  static Widget buildMessageBubble(
    Message message, {
    required BuildContext context,
    required ChatController controller,
  }) {
    bool isAuthorUser = message.author.type == AuthorType.user;
    bool hasToolCall = false;
    ToolCallType? toolCallType;

    // Check for attached images in metadata
    bool hasAttachedImages = message.attachedImages != null && message.attachedImages!.isNotEmpty;

    // Check for attached documents in metadata
    bool hasAttachedDocuments =
        message.metadata != null && message.metadata!['attachedDocuments'] != null;
    List<dynamic> attachedDocuments = hasAttachedDocuments
        ? (message.metadata!['attachedDocuments'] as List)
        : [];

    if (message.metadata != null &&
        message.metadata!['tool_call'] != null &&
        message.metadata!['tool_call']["name"] != null) {
      hasToolCall = true;
      switch (message.metadata!['tool_call']["name"]) {
        case "web_search":
          toolCallType = ToolCallType.webSearch;
          break;
        case "image_generation":
          toolCallType = ToolCallType.imageGeneration;
          break;
      }
    }

    return Column(
      crossAxisAlignment: isAuthorUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isAuthorUser)
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    controller.aiModel.decorations?.backgroundColor ?? Colors.transparent,
                backgroundImage: AssetImage(controller.aiModel.assetIcon!),
                radius: 17.sp,
              ),
              SizedBox(width: 2.w),
              Text(controller.formattedTitle),
            ],
          ),
        Container(
          padding: EdgeInsets.all(12.sp),
          decoration: isAuthorUser
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_borderRadius),
                    topRight: Radius.circular(_borderRadius),
                    bottomLeft: Radius.circular(_borderRadius),
                    bottomRight: Radius.zero,
                  ),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display attached images
              if (hasAttachedImages) ...[
                _buildAttachedImages(message.attachedImages!, isAuthorUser, context),
              ],

              // Display attached documents
              if (hasAttachedDocuments) ...[
                _buildAttachedDocuments(attachedDocuments, isAuthorUser, context),
              ],

              // Display text content if not empty
              if (message.text.trim().isNotEmpty) _buildMessageText(message, isAuthorUser, context),

              if (hasToolCall) _buildToolCallWidget(message, toolCallType!, controller),
            ],
          ),
        ),
        // Show timestamp for the message
        if (message.createdAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8, left: 8),
            child: Row(
              mainAxisAlignment: isAuthorUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  _formatMessageTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        if (!controller.isTyping.value)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: _buildTextMessageTools(message, context, controller),
          ),
      ],
    );
  }

  /// Builds attached images section for text messages with compact grid layout
  static Widget _buildAttachedImages(
    List<ImageData> attachedImages,

    bool isAuthorUser,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show image count if multiple images
        if (attachedImages.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library,
                  size: 14,
                  color: isAuthorUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${attachedImages.length} images',
                  style: TextStyle(
                    fontSize: 12,
                    color: isAuthorUser
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

        // Display images in a compact grid layout
        _buildImageGrid(attachedImages, isAuthorUser, context),
      ],
    );
  }

  /// Builds a compact grid layout for multiple images
  static Widget _buildImageGrid(
    List<ImageData> attachedImages,
    bool isAuthorUser,
    BuildContext context,
  ) {
    // For single image, show it in full width
    if (attachedImages.length == 1) {
      return _buildSingleImage(attachedImages[0], 0, attachedImages, context);
    }

    // For multiple images, use grid layout
    const int crossAxisCount = 2;
    const double spacing = 8.0;
    const double aspectRatio = 1.0; // Square aspect ratio for grid items

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: attachedImages.length,
      itemBuilder: (context, index) {
        return _buildGridImageItem(attachedImages[index], index, attachedImages, context);
      },
    );
  }

  /// Builds a single image widget (for single image or full-width display)
  static Widget _buildSingleImage(
    ImageData imageData,
    int imageIndex,
    List<ImageData> allImages,
    BuildContext context,
  ) {
    final imagePath = imageData.path;
    final file = File(imagePath);

    if (!file.existsSync()) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.sp),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              const Text(
                'Image not found',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              Text(
                imageData.name,
                style: TextStyle(color: Colors.red.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Extract all image paths from attached images
        final imagePaths = allImages.map<String>((imageData) => imageData.path).toList();

        Navigator.push(
          Get.context!,
          MaterialPageRoute(
            builder: (context) =>
                FullScreenImageViewer(imagePaths: imagePaths, initialIndex: imageIndex),
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.sp),
          child: Image.file(file, fit: BoxFit.cover),
        ),
      ),
    );
  }

  /// Builds a grid item for multiple images layout
  static Widget _buildGridImageItem(
    ImageData imageData,
    int imageIndex,
    List<ImageData> allImages,
    BuildContext context,
  ) {
    final imagePath = imageData.path;
    final file = File(imagePath);

    if (!file.existsSync()) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.sp),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 24),
              SizedBox(height: 4),
              Text(
                'Not found',
                style: TextStyle(color: Colors.red, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Extract all image paths from attached images
        final imagePaths = allImages.map<String>((imageData) => imageData.path).toList();

        Navigator.push(
          Get.context!,
          MaterialPageRoute(
            builder: (context) =>
                FullScreenImageViewer(imagePaths: imagePaths, initialIndex: imageIndex),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.sp),
        child: Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      ),
    );
  }

  /// Builds attached documents section for text messages
  static Widget _buildAttachedDocuments(
    List<dynamic> attachedDocuments,

    bool isAuthorUser,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show document count if multiple documents
        if (attachedDocuments.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description,
                  size: 14,
                  color: isAuthorUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${attachedDocuments.length} documents',
                  style: TextStyle(
                    fontSize: 12,
                    color: isAuthorUser
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

        // Display each attached document
        for (int documentIndex = 0; documentIndex < attachedDocuments.length; documentIndex++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildDocumentPreviewCard(
              attachedDocuments[documentIndex],

              isAuthorUser,
              context,
            ),
          ),
      ],
    );
  }

  /// Builds individual document preview card with metadata and preview functionality
  static Widget _buildDocumentPreviewCard(
    dynamic documentData,

    bool isAuthorUser,
    BuildContext context,
  ) {
    final String fileName = documentData['name'] ?? 'Unknown Document';
    final String extension = (documentData['extension'] ?? '').toUpperCase();
    final int fileSize = documentData['size'] ?? 0;
    final bool hasExtractedText = documentData['hasExtractedText'] == true;

    return GestureDetector(
      onTap: () {
        _showDocumentPreview(documentData, context);
      },
      child: Container(
        padding: EdgeInsets.all(12.sp),
        decoration: BoxDecoration(
          color: isAuthorUser
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12.sp),
          border: Border.all(
            color: isAuthorUser
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Document icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getDocumentColor(extension, context),
                borderRadius: BorderRadius.circular(8.sp),
              ),
              child: Icon(getDocumentIcon(extension), color: Colors.white, size: 20),
            ),
            SizedBox(width: 12.sp),
            // Document information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isAuthorUser
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.sp),
                  Row(
                    children: [
                      Text(
                        extension,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: _getDocumentColor(extension, context),
                        ),
                      ),
                      Text(
                        ' • ${_formatFileSize(fileSize)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isAuthorUser
                              ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (hasExtractedText) ...[
                        Text(
                          ' • Text extracted',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Preview indicator
            Icon(
              Icons.visibility,
              size: 16,
              color: isAuthorUser
                  ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5)
                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows full screen document preview
  static void _showDocumentPreview(Map<String, dynamic> documentData, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FullScreenDocumentViewer(documentData: documentData)),
    );
  }

  /// Get appropriate icon for document type
  static IconData getDocumentIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.description;
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      case 'csv':
        return Icons.table_view;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Get appropriate color for document type
  static Color _getDocumentColor(String extension, BuildContext context) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'docx':
        return Colors.blue;
      case 'xlsx':
        return Colors.green;
      case 'txt':
        return Colors.orange;
      case 'csv':
        return Colors.teal;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Format file size to human readable format
  static String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[i]}';
  }

  /// Builds the text content of a message with markdown support
  static Widget _buildMessageText(Message message, bool isAuthorUser, BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GptMarkdown(
        message.text,
        followLinkColor: true,
        codeBuilder: (context, name, code, closed) {
          if (name.contains('html')) {
            // Use the new HtmlCodeBlock widget
            return HtmlCodePreview(htmlCode: code, controller: Get.find<ChatController>());
          } else {
            // For non-HTML code blocks, always use CodeField.
            return CodeField(name: name, codes: code);
          }
        },
        onLinkTap: (url, title) {
          if (url.startsWith('http')) {
            launchUrl(Uri.parse(url));
          } else {
            Get.snackbar('Invalid URL', 'The URL is invalid: $url');
          }
        },
        textDirection: appInstance.userPreferences.chatLanguage == "Arabic"
            ? ui.TextDirection.rtl
            : ui.TextDirection.ltr,
        style: TextStyle(
          color: isAuthorUser
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Builds tool call widget for AI responses
  static Widget _buildToolCallWidget(
    Message message,
    ToolCallType toolCallType,
    ChatController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: ToolCallWidgets.buildToolCallWidget(
        messageId: message.id,
        metadata: message.metadata!,
        toolCallType: toolCallType,
        toolCallStatus: ToolCallStatus.values.firstWhere(
          (element) => element.index == message.metadata!['tool_call_status'],
        ),
        arguments: message.metadata!['tool_call']!["arguments"],
        controller: controller,
      ),
    );
  }

  /// Provides action buttons for text messages
  static Widget _buildTextMessageTools(
    Message message,
    BuildContext context,
    ChatController controller,
  ) {
    switch (message.author.type) {
      case AuthorType.user:
        return _buildUserMessageTools(message, context, controller);
      case AuthorType.ai:
        return _buildAiMessageTools(message, context, controller);
    }
  }

  /// Builds tools for user messages (copy, edit, delete, refresh)
  static Widget _buildUserMessageTools(
    Message message,
    BuildContext context,
    ChatController controller,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: message.text));
            Get.snackbar('Copied', 'Message copied to clipboard');
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 16),
          onPressed: () {
            showEditMessageBottomSheet(
              context: context,
              message: message,
              controller: controller,
              onSave: (newText, newImages) {
                controller.editMessage(message.id, newText, newImages: newImages);
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 16),
          onPressed: () {
            deleteMessageDialog(
              onDelete: () {
                Get.back();
                controller.deleteMessage(message.id);
              },
              onBack: () => Get.back(),
              onDeleteAllFollowing: controller.messages[0].id == message.id
                  ? null
                  : () {
                      Get.back();
                      controller.deleteAllFollowingMessages(message.id);
                    },
              isProcessingOperation:
                  controller.isTyping.value || controller.isProcessingToolCall.value,
            );
          },
        ),
        if (message.id == controller.messages[0].id)
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            onPressed: () {
              controller.runAiOperations("systemRerun");
            },
          ),
      ],
    );
  }

  /// Builds tools for AI messages (TTS, copy, delete, refresh)
  static Widget _buildAiMessageTools(
    Message message,
    BuildContext context,
    ChatController controller,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Obx(() {
          return IconButton(
            icon: Icon(
              controller.ttsService.ttsState.value == TtsState.playing
                  ? Icons.stop
                  : Icons.volume_up,
              size: 16,
            ),
            onPressed: () {
              if (controller.ttsService.ttsState.value == TtsState.playing) {
                controller.ttsService.stop();
              } else {
                final txt = mrk
                    .markdownToHtml(message.text)
                    .replaceAll(RegExp(r'<[^>]*>'), '')
                    .replaceAll(
                      RegExp(
                        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{2B50}\u{2B55}]',
                        unicode: true,
                      ),
                      '',
                    );
                controller.ttsService.speak(txt);
              }
            },
          );
        }),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: message.text));
            Get.snackbar('Copied', 'Message copied to clipboard');
          },
        ),
        // Only show delete button when not streaming or processing tool calls
        Obx(() {
          // Hide delete button during streaming or tool call processing
          if (controller.isTyping.value || controller.isProcessingToolCall.value) {
            return const SizedBox.shrink();
          }

          return IconButton(
            icon: const Icon(Icons.delete, size: 16),
            onPressed: () {
              deleteMessageDialog(
                onDelete: () {
                  Get.back();
                  controller.deleteMessage(
                    message.id,
                    thereIsThinkBlock: controller.aiModel.features.isReasoning,
                  );
                },
                onDeleteAllFollowing: controller.messages[0].id == message.id
                    ? null
                    : () {
                        Get.back();
                        controller.deleteAllFollowingMessages(message.id);
                      },
                onBack: () => Get.back(),
                isProcessingOperation:
                    controller.isTyping.value || controller.isProcessingToolCall.value,
              );
            },
          );
        }),
        if (message.metadata?["canTryAgain"] != null)
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            onPressed: () {
              controller.messages.removeAt(0);
              controller.runAiOperations(null);
            },
          ),
      ],
    );
  }
}

/// Tool call widgets for different types of AI tool calls
class ToolCallWidgets {
  /// Builds appropriate tool call widget based on type
  static Widget buildToolCallWidget({
    required String messageId,
    required ToolCallType toolCallType,
    required ToolCallStatus toolCallStatus,
    required Map arguments,
    required Map metadata,
    required ChatController controller,
  }) {
    switch (toolCallType) {
      case ToolCallType.imageGeneration:
        return _buildImageGenerationWidget(
          messageId: messageId,
          prompt: arguments["prompt"],
          resolution: arguments["resolution"],
          toolCallStatus: toolCallStatus,
          metadata: metadata as Map<String, dynamic>,
          controller: controller,
        );
      case ToolCallType.imageEditing:
        return const SizedBox.shrink();
      case ToolCallType.webSearch:
        return _buildWebSearchWidget(
          searchQuery: arguments["search_query"],
          messageId: messageId,
          controller: controller,
          metadata: metadata as Map<String, dynamic>,
        );
    }
  }

  static Widget _buildWebSearchWidget({
    required String searchQuery,
    required String messageId,
    required ChatController controller,
    required Map<String, dynamic> metadata,
  }) {
    // Get tool call status from metadata
    ToolCallStatus toolCallStatus = ToolCallStatus.values.firstWhere(
      (element) => element.index == metadata['tool_call_status'],
      orElse: () => ToolCallStatus.pending,
    );

    // If status is pending or processing, trigger web search operation
    if (toolCallStatus == ToolCallStatus.pending || toolCallStatus == ToolCallStatus.processing) {
      // If status is pending, update it to processing and trigger web search
      if (toolCallStatus == ToolCallStatus.pending) {
        // Use a post-frame callback to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.messages.any((element) => element.id == messageId)) {
            // Update tool call status to processing
            controller.messages
                    .firstWhere((element) => element.id == messageId)
                    .metadata!["tool_call_status"] =
                ToolCallStatus.processing.index;

            // Set tool call processing state to block new messages
            controller.streamingHandler.isProcessingToolCall.value = true;
            CancelToken cancelToken = controller.cancelToken;

            // Trigger web search operation
            controller.webSearchTool
                .handleWebSearch(
                  searchQuery,
                  messageId,
                  controller.messages,
                  controller.aiModel.features.isReasoning,
                  cancelToken,
                  resetToolCallProcessingState: () =>
                      controller.streamingHandler.isProcessingToolCall.value = false,
                  update: controller.update,
                  markSessionAsUpdated: controller.markSessionAsUpdatedCallback,
                  autoSaveSession: controller.autoSaveSessionCallback,
                )
                .whenComplete(() {
                  // Check cancellation status and update accordingly
                  final messageIndex = controller.messages.indexWhere(
                    (element) => element.id == messageId,
                  );
                  if (messageIndex != -1) {
                    if (cancelToken.isCancelled) {
                      controller.messages[messageIndex].metadata!["tool_call_status"] =
                          ToolCallStatus.cancelled.index;

                      // Update web search result status as well
                      if (controller.messages[messageIndex].metadata!.containsKey(
                        'web_search_result',
                      )) {
                        controller.messages[messageIndex].metadata!['web_search_result']['status'] =
                            WebSearchStatus.error.name;
                        controller.messages[messageIndex].metadata!['web_search_result']['error'] =
                            'Search cancelled by user';
                      }

                      // Trigger UI update
                      controller.update();
                    }
                  }

                  // Reset tool call processing state
                  controller.streamingHandler.isProcessingToolCall.value = false;
                });
          }
        });
      }
      // Handle different statuses based on results in metadata
      if (metadata.containsKey('web_search_result')) {
        final searchResult = metadata['web_search_result'];
        if (searchResult['status'] == WebSearchStatus.loading.name) {
          return WebSearchWidgets.buildSearchLoadingWidget(searchQuery);
        } else if (searchResult['status'] == WebSearchStatus.scraping.name) {
          return WebSearchWidgets.buildSearchScrapingWidget(searchQuery, searchResult);
        } else if (searchResult['status'] == WebSearchStatus.analyzing.name) {
          return WebSearchWidgets.buildSearchAnalyzingWidget(searchQuery, searchResult);
        } else if (searchResult['status'] == WebSearchStatus.completed.name) {
          return WebSearchWidgets.buildSearchCompletedWidget(searchQuery, searchResult);
        } else if (searchResult['status'] == WebSearchStatus.error.name) {
          return WebSearchWidgets.buildSearchErrorWidget(searchQuery, searchResult['error']);
        } else if (searchResult['status'] == WebSearchStatus.noResults.name) {
          return WebSearchWidgets.buildNoResultsWidget(searchQuery);
        }
      }

      // Show loading widget during processing
      return WebSearchWidgets.buildSearchLoadingWidget(searchQuery);
    }
    if (toolCallStatus == ToolCallStatus.success) {
      return WebSearchWidgets.buildSearchCompletedWidget(searchQuery, metadata);
    }

    // Handle cancelled status
    if (toolCallStatus == ToolCallStatus.cancelled) {
      return WebSearchWidgets.buildSearchCancelledWidget(searchQuery);
    }

    // Handle tool call status error
    if (toolCallStatus == ToolCallStatus.error) {
      return WebSearchWidgets.buildSearchErrorWidget(searchQuery, "Web search failed");
    }

    // Default loading state
    return WebSearchWidgets.buildSearchLoadingWidget(searchQuery);
  }

  /// Builds image generation tool call widget
  static Widget _buildImageGenerationWidget({
    required String messageId,
    required String prompt,
    required String resolution,
    required ToolCallStatus toolCallStatus,
    required Map<String, dynamic> metadata,
    required ChatController controller,
  }) {
    double maxWidth = appInstance.isTablet ? 50.w : 80.w;
    double maxHeight = appInstance.isTablet ? 40.h : 30.h;

    if (toolCallStatus == ToolCallStatus.pending || toolCallStatus == ToolCallStatus.processing) {
      // If status is pending, update it to processing and trigger generation
      if (toolCallStatus == ToolCallStatus.pending) {
        // Use a post-frame callback to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.messages.any((element) => element.id == messageId)) {
            controller.messages
                    .firstWhere((element) => element.id == messageId)
                    .metadata!["tool_call_status"] =
                ToolCallStatus.processing.index;

            // Set tool call processing state to block new messages
            controller.streamingHandler.isProcessingToolCall.value = true;

            controller.imageGenerationTool.handleImageGenerationPollinations(
              prompt: prompt,
              messageId: messageId,
              resolution: resolution,
              messages: controller.messages,
              cancelToken: controller.cancelToken,
              resetToolCallProcessingState: () =>
                  controller.streamingHandler.isProcessingToolCall.value = false,
              update: controller.update,
              markSessionAsUpdated: controller.markSessionAsUpdatedCallback,
              autoSaveSession: controller.autoSaveSessionCallback,
            );
          }
        });
      }
      return ImageGenerationWidgets.buildLoadingWidget(maxWidth, maxHeight);
    } else if (toolCallStatus == ToolCallStatus.success) {
      return ImageGenerationWidgets.buildSuccessWidget(
        messageId,
        metadata,
        maxWidth,
        maxHeight,
        controller,
      );
    } else if (toolCallStatus == ToolCallStatus.cancelled) {
      return ImageGenerationWidgets.buildCancelledWidget(messageId, maxWidth, maxHeight);
    } else if (toolCallStatus == ToolCallStatus.error) {
      return ImageGenerationWidgets.buildErrorWidget(messageId, maxWidth, maxHeight);
    } else {
      return const SizedBox.shrink();
    }
  }
}
