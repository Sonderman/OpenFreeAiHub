import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/global/components/chat/base_chat_widget.dart';
import 'package:freeaihub/core/data/misc.dart';
import 'package:freeaihub/core/global/components/chat/think_block_widget.dart';
import 'package:freeaihub/core/global/components/chat/typing_dots_widget.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/screens/chat/chat_controller.dart';
import 'package:freeaihub/screens/chat/components/chat_components.dart';
import 'package:freeaihub/screens/chat/widgets/chat_drawer.dart';
import 'package:freeaihub/screens/chat/widgets/chat_input_area.dart';
import 'package:freeaihub/screens/chat/widgets/message_builders.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

/// This file defines ChatView, the main chat screen.
/// It displays chat messages using flutter_chat_ui, integrates with ChatController for state management,
/// and handles user interactions like sending, editing, deleting messages, and managing chat sessions.

class ChatView extends GetView<ChatController> {
  /// ChatView widget displays the chat interface.
  /// It uses GetX to access ChatController for handling chat logic,
  /// such as sending messages, editing, deleting messages, and managing sessions.

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    /// Builds the Scaffold containing the AppBar, end drawer for chat history,
    /// and the main chat body with messages, input area, custom bottom widget,
    /// and typing indicators.
    chatScreenInfoTexts.shuffle();
    String infoText = chatScreenInfoTexts.take(1).first;

    return Scaffold(
      key: scaffoldKey,
      appBar: ChatAppBar(scaffoldKey: scaffoldKey, controller: controller),
      endDrawer: ChatDrawer(controller: controller),
      endDrawerEnableOpenDragGesture: true,
      body: SafeArea(
        child: GetBuilder<ChatController>(
          builder: (ctrl) {
            return Obx(() {
              // Create a stable copy of messages to prevent scroll calculation issues
              final messageList = List<Message>.from(controller.messages);
              return BaseChatWidget(
                key: ValueKey(messageList.length), // Add key to help Flutter track changes
                messages: messageList,
                onSendPressed: controller.handleSendPressed,
                user: MessageAuthor(name: 'You', type: AuthorType.user),
                messageBuilder: (msg) => MessageBuilders.buildMessageBubble(
                  msg,
                  context: context,
                  controller: controller,
                ),
                thinkBlockBuilder: (message) {
                  return _buildThinkBlockMessage(message, context);
                },
                bottomWidget: !controller.isTyping.value && !controller.isProcessingToolCall.value
                    ? ChatInputArea(controller: controller)
                    : null,
                typingIndicator: controller.isTyping.value ? _buildTypingIndicator(context) : null,
                imageMaxHeight: 30.h,
                emptyState: Center(
                  child: Text(
                    "AI can make mistakes. Be careful.\n\n$infoText",
                    style: const TextStyle(color: Color(0xff9e9cab)),
                    textAlign: TextAlign.center,
                  ),
                ),
                listBottomWidget:
                    (controller.isTyping.value || controller.isProcessingToolCall.value)
                    ? _buildStopButton()
                    : null,
              );
            });
          },
        ),
      ),
    );
  }

  /// Builds message widget for think blocks only (typing dots removed)
  Widget _buildThinkBlockMessage(Message message, BuildContext context) {
    // Handle think blocks - check both metadata and text field
    String thinkBlockContent = message.metadata?["ThinkBlock"] ?? message.text;
    String rawContent = thinkBlockContent
        .replaceFirst(RegExp(r'<think>', caseSensitive: false), "")
        .replaceFirst(RegExp(r'</think>', caseSensitive: false), "")
        .trim();

    // Show think block if there's any content or if it's actively thinking (even if rawContent is empty)
    if (thinkBlockContent.isNotEmpty &&
        (rawContent.isNotEmpty || thinkBlockContent.contains("<think>"))) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [ThinkBlockWidget(content: thinkBlockContent, metadata: message.metadata)],
      );
    }
    return const SizedBox.shrink();
  }

  /// Builds typing indicator widget for showing AI is responding
  Widget _buildTypingIndicator(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
      child: Container(
        padding: EdgeInsets.all(8.sp),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const TypingDotsWidget(size: 10.0, animationDuration: Duration(milliseconds: 800)),
      ),
    );
  }

  /// Builds the stop button for cancelling AI responses and tool calls
  Widget _buildStopButton() {
    // Determine button text based on current operation
    String buttonText = "Stop";
    return Card(
      color: Colors.red,
      child: TextButton(
        child: AutoSizeText(
          buttonText,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => controller.onClickStopButton(),
      ),
    );
  }
}
