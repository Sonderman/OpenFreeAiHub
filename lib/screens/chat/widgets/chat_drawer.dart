import 'package:flutter/material.dart';
import 'package:freeaihub/core/models/chat/chat_session_model.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/screens/chat/chat_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

/// Chat history drawer widget
/// Displays list of chat sessions with options to select, delete, or create new sessions
class ChatDrawer extends StatelessWidget {
  final ChatController controller;

  const ChatDrawer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Chat History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: controller.sessions.length,
                  itemBuilder: (context, index) {
                    final session = controller.sessions[index];
                    return _buildSessionTile(context, session);
                  },
                ),
              ),
            ),
            _buildNewChatButton(context),
          ],
        ),
      ),
    );
  }

  /// Builds individual session tile with title, date, and delete option
  Widget _buildSessionTile(BuildContext context, ChatSession session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: controller.currentSession.value?.id == session.id
              ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1)
              : BorderSide.none,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(session.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(intl.DateFormat('MMM dd, HH:mm').format(session.updatedAt)),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context, session),
          ),
          selected: controller.currentSession.value?.id == session.id,
          onTap: () {
            Get.back();
            controller.loadSpecificSession(session.id);
          },
        ),
      ),
    );
  }

  /// Shows delete confirmation dialog for a session
  void _showDeleteDialog(BuildContext context, ChatSession session) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat session?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteCurrentSession(session.id);
              if (controller.currentSession.value?.id == session.id) {
                controller.startNewSession();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Builds the new chat button at the bottom of the drawer
  Widget _buildNewChatButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: FilledButton.tonal(
        onPressed: () => _handleNewChatPress(),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20),
            SizedBox(width: 8),
            Text('New Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /// Handles new chat button press with smart session management
  void _handleNewChatPress() {
    // Check if the sessions list is not empty
    if (controller.sessions.isNotEmpty) {
      final lastSession = controller.sessions.first; // sessions are ordered descending by date
      // Check if the last session is titled 'New Chat' (or similar default)
      // and if the current loaded session is this last session and has no user messages
      bool isDefaultNewChat = lastSession.title.startsWith('New Chat');
      bool isLastSessionCurrentlyLoaded = controller.currentSession.value?.id == lastSession.id;
      bool hasNoMessagesInCurrentLastSession = controller.messages
          .where((m) => m.author.type == AuthorType.user)
          .isEmpty;

      if (isDefaultNewChat && isLastSessionCurrentlyLoaded && hasNoMessagesInCurrentLastSession) {
        // If it's an empty "New Chat" session and currently loaded, just close the drawer
        Get.back();
      } else if (isDefaultNewChat &&
          controller.messages.isEmpty &&
          controller.currentSession.value?.id == lastSession.id) {
        // If the last session is a "New Chat", is the current session, and has no messages at all
        Get.back(); // Close drawer
        controller.loadSpecificSession(
          lastSession.id,
        ); // Ensure it's loaded (might be redundant but safe)
      } else {
        controller.startNewSession();
        Get.back(); // Close drawer
      }
    } else {
      // If there are no sessions, start a new one
      controller.startNewSession();
      Get.back(); // Close drawer
    }
  }
}
