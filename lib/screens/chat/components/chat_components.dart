import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/screens/chat/chat_controller.dart';
import 'package:get/get.dart';

/// Custom app bar with built-in feedback button
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool automaticallyImplyLeading;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ChatController controller;

  const ChatAppBar({
    super.key,
    this.automaticallyImplyLeading = true,
    required this.scaffoldKey,
    required this.controller,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final combinedActions = [
      IconButton(
        icon: const Icon(Icons.history),
        onPressed: () {
          if (scaffoldKey.currentState != null) {
            scaffoldKey.currentState!.openEndDrawer();
          } else {
            Scaffold.of(context).openEndDrawer();
          }
        },
      ),

      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert),
        onSelected: (String value) {
          switch (value) {
            case 'session_info':
              _showSessionInfoModal(context);
              break;
          }
        },
        itemBuilder: (BuildContext context) => [
          if (enableExperimentalFeatures)
            PopupMenuItem<String>(
              value: 'session_info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurface),
                  SizedBox(width: 8),
                  Text('Session Info'),
                ],
              ),
            ),
          PopupMenuItem<String>(
            value: 'feedback',
            child: Row(
              children: [
                Icon(Icons.feedback_outlined, color: Theme.of(context).colorScheme.onSurface),
                SizedBox(width: 8),
                Text('Feedback'),
              ],
            ),
          ),
        ],
      ),
    ];

    return AppBar(
      titleTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).scaffoldBackgroundColor,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      title: Obx(
        () => AutoSizeText(
          controller.formattedTitle,
          minFontSize: appInstance.isTablet ? 28 : 12,
          maxLines: 2,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: combinedActions,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  /// Shows session info modal bottom sheet with context manager data
  void _showSessionInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar for dragging
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Session Info',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: _buildSessionInfoContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the session info content widget with context manager data
  Widget _buildSessionInfoContent(BuildContext context) {
    final contextManager = controller.contextManager;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Model Information Section
        _buildInfoSection(
          context: context,
          title: 'Model Information',
          icon: Icons.psychology,
          children: [
            _buildInfoRow('Model Name', controller.aiModel.name),
            _buildInfoRow('Short Name', controller.aiModel.shortName),
            //_buildInfoRow('Provider', controller.aiModel.apiModel.provider.name),
            _buildInfoRow('Max Tokens', '${controller.aiModel.maxTokens.toString()} tokens'),
          ],
        ),

        const SizedBox(height: 20),

        // Token Usage Section
        _buildInfoSection(
          context: context,
          title: 'Token Usage',
          icon: Icons.data_usage,
          children: [
            _buildInfoRow('Total Tokens', '${contextManager.totalTokens.toString()} tokens'),
            _buildInfoRow('Prompt Tokens', '${contextManager.promptTokens.toString()} tokens'),
            _buildInfoRow(
              'Completion Tokens',
              '${contextManager.completionTokens.toString()} tokens',
            ),
            _buildInfoRow(
              'Session Total',
              '${contextManager.sessionTotalTokens.toString()} tokens',
            ),
            _buildInfoRow(
              'System Instruction',
              '${contextManager.systemInstructionTokens.toString()} tokens',
            ),
            const SizedBox(height: 8),
            // Context usage progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Context Usage', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      '${(contextManager.contextUsagePercentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: contextManager.isAtLimit
                            ? Colors.red
                            : contextManager.isNearLimit
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: contextManager.contextUsagePercentage,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      contextManager.isAtLimit
                          ? Colors.red
                          : contextManager.isNearLimit
                          ? Colors.orange
                          : Colors.green,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Session Information Section
        _buildInfoSection(
          context: context,
          title: 'Session Information',
          icon: Icons.chat,
          children: [
            _buildInfoRow(
              'Current Session',
              controller.currentSession.value?.title ?? 'No session',
            ),
            _buildInfoRow('Total Messages', controller.messages.length.toString()),
            _buildInfoRow('Total Sessions', controller.sessions.length.toString()),
            _buildInfoRow('Web Search Enabled', controller.isWebSearchEnabled.value ? 'Yes' : 'No'),
            _buildInfoRow(
              'Image Generation Enabled',
              controller.isImageGenEnabled.value ? 'Yes' : 'No',
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Context Status Section
        _buildInfoSection(
          context: context,
          title: 'Context Status',
          icon: Icons.warning,
          children: [
            _buildStatusRow('Near Limit', contextManager.isNearLimit),
            _buildStatusRow('At Limit', contextManager.isAtLimit),
            _buildStatusRow('Needs Trimming', contextManager.needsContextTrimming),
          ],
        ),
      ],
    );
  }

  /// Builds an info section with title and icon
  Widget _buildInfoSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// Builds an info row with label and value
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a status row with label and boolean indicator
  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: status ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status ? 'Yes' : 'No',
              style: TextStyle(
                color: status ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
