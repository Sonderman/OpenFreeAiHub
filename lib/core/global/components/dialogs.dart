import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freeaihub/core/app_configs.dart';

/// Welcome dialog shown to new users with improved design and UX
Widget welcomeDialog({VoidCallback? onContinue}) {
  return Dialog(
    backgroundColor: Theme.of(Get.context!).colorScheme.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header section with welcome icon and title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              decoration: BoxDecoration(
                color: Theme.of(Get.context!).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(Get.context!).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.celebration_outlined,
                      size: 48,
                      color: Theme.of(Get.context!).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to FreeAI Hub!',
                    style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(Get.context!).colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alpha version info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(Get.context!).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(Get.context!).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          color: Theme.of(Get.context!).colorScheme.onSecondaryContainer,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alpha Version',
                                style: Theme.of(Get.context!).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(Get.context!).colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'We\'re working hard to bring you the best AI experience possible.',
                                style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(Get.context!).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Feature highlights
                  Text(
                    'Your feedback matters:',
                    style: Theme.of(
                      Get.context!,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _buildFeatureItem(
                    Icons.feedback_outlined,
                    'Share feedback',
                    'Help us improve by reporting issues',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem(
                    Icons.group_outlined,
                    'Join our community',
                    'Get support and latest updates',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem(
                    Icons.favorite_outline,
                    'Your patience',
                    'Thank you for understanding',
                  ),

                  const SizedBox(height: 24),

                  // Emoji and thank you message
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('😊💖', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thank you for trying our app!',
                          style: Theme.of(
                            Get.context!,
                          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Primary action button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          Theme.of(Get.context!).colorScheme.primary,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          Theme.of(Get.context!).colorScheme.onPrimary,
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        elevation: const WidgetStatePropertyAll(2),
                      ),
                      onPressed: onContinue,
                      icon: const Icon(Icons.rocket_launch_outlined),
                      label: const Text(
                        'Start Exploring',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary action buttons row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: ButtonStyle(
                            foregroundColor: WidgetStatePropertyAll(
                              Theme.of(Get.context!).colorScheme.onSurface,
                            ),
                            side: WidgetStatePropertyAll(
                              BorderSide(color: Theme.of(Get.context!).colorScheme.outline),
                            ),
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse(telegramChannelUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.telegram, size: 24),
                          label: const Text(
                            'Join Group',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Helper widget to build feature list items
Widget _buildFeatureItem(IconData icon, String title, String description) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Theme.of(Get.context!).colorScheme.primary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                Get.context!,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              description,
              style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
