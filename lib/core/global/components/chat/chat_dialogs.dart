import 'package:flutter/material.dart';
import 'package:get/get.dart';

void deleteMessageDialog({
  VoidCallback? onDelete,
  VoidCallback? onBack,
  VoidCallback? onDeleteAllFollowing,
  bool isProcessingOperation = false, // New parameter to indicate if AI is processing
}) => Get.dialog(
  AlertDialog(
    title: const Text('Delete Message'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('You can delete just this message or all the following messages'),
        if (isProcessingOperation) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note: This will stop the ongoing AI operation',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
    actionsOverflowButtonSpacing: 10,
    actions: [
      if (onDeleteAllFollowing != null)
        FilledButton(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Theme.of(Get.context!).colorScheme.primary),
            foregroundColor: WidgetStatePropertyAll(Theme.of(Get.context!).colorScheme.onPrimary),
            //minimumSize: const WidgetStatePropertyAll(Size(120, 48)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          onPressed: onDeleteAllFollowing,
          child: const Text(
            'Delete all the following messages',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      FilledButton(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Theme.of(Get.context!).colorScheme.primary),
          foregroundColor: WidgetStatePropertyAll(Theme.of(Get.context!).colorScheme.onPrimary),
          //minimumSize: const WidgetStatePropertyAll(Size(120, 48)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        onPressed: onDelete,
        child: const Text(
          'Delete just this message',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      FilledButton(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Theme.of(Get.context!).colorScheme.primary),
          foregroundColor: WidgetStatePropertyAll(Theme.of(Get.context!).colorScheme.onPrimary),
          //minimumSize: const WidgetStatePropertyAll(Size(120, 48)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        onPressed: onBack,
        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  ),
);
