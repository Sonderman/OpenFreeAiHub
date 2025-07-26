import 'package:flutter/material.dart';
import 'package:freeaihub/core/data/language_definisitons.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:freeaihub/screens/preferences/welcome_preferences_controller.dart';
import 'package:freeaihub/core/app_instance.dart';

class WelcomePreferencesView extends StatelessWidget {
  const WelcomePreferencesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WelcomePreferencesController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              _buildHeader(context),
              SizedBox(height: 4.h),

              // Form section
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameSection(context, controller),
                      SizedBox(height: 3.h),
                      _buildLanguageSection(context, controller),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),

              // Bottom buttons
              _buildBottomButtons(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  // Header with welcome message and subtitle
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.waving_hand, size: 8.w, color: Theme.of(context).primaryColor),
            SizedBox(width: 3.w),
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Let\'s set up some preferences to serve you better.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // Name input section
  Widget _buildNameSection(BuildContext context, WelcomePreferencesController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, size: 6.w, color: Theme.of(context).primaryColor),
            SizedBox(width: 3.w),
            Text(
              'Your Name',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        Text(
          'How should we address you in chats?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 2.h),
        Obx(
          () => TextFormField(
            controller: controller.nameController,
            maxLength: 16,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              errorText: !controller.isNameValid.value && controller.nameController.text.isNotEmpty
                  ? 'Minimum 2 characters required'
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // Language selection section
  Widget _buildLanguageSection(BuildContext context, WelcomePreferencesController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.language, size: 6.w, color: Theme.of(context).primaryColor),
            SizedBox(width: 3.w),
            Text(
              'Chat Language',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        Text(
          'Which language would you like to use with AI assistant?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 2.h),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
              color: Theme.of(context).cardColor,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedLanguage.value,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                borderRadius: BorderRadius.circular(12),
                items: languages.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        // Responsive flag emoji size for better tablet display
                        Text(
                          _getLanguageFlag(entry.key),
                          style: TextStyle(
                            fontSize: appInstance.isTablet
                                ? 30.0 // Fixed size for tablets
                                : 6.w, // Responsive size for phones
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            _getLanguageDisplayName(entry.key),
                            style: Theme.of(context).textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.updateLanguage(newValue);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Bottom action buttons
  Widget _buildBottomButtons(BuildContext context, WelcomePreferencesController controller) {
    return Column(
      children: [
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: controller.isFormValid && !controller.isLoading.value
                  ? controller.savePreferencesAndContinue
                  : null,
              style: ElevatedButton.styleFrom(
                // Set a vibrant background color that's always visible
                backgroundColor: controller.isFormValid && !controller.isLoading.value
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor,
                // Add elevation for better visual depth
                elevation: controller.isFormValid && !controller.isLoading.value ? 4 : 0,
                // Smooth rounded corners
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                // Add some shadow for better visibility
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
              child: controller.isLoading.value
                  ? SizedBox(
                      height: 4.w,
                      width: 4.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Continue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),

        SizedBox(height: 2.h),

        TextButton(
          onPressed: controller.isLoading.value ? null : controller.skipPreferences,
          child: Text(
            'Not Now',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // Get appropriate flag emoji for each language
  String _getLanguageFlag(String language) {
    switch (language) {
      case 'Turkish':
        return '🇹🇷';
      case 'English':
        return '🇺🇸';
      case 'Spanish':
        return '🇪🇸';
      case 'French':
        return '🇫🇷';
      case 'German':
        return '🇩🇪';
      case 'Italian':
        return '🇮🇹';
      case 'Portuguese':
        return '🇵🇹';
      case 'Russian':
        return '🇷🇺';
      case 'Chinese':
        return '🇨🇳';
      case 'Japanese':
        return '🇯🇵';
      case 'Korean':
        return '🇰🇷';
      case 'Arabic':
        return '🇸🇦';
      case 'Hindi':
        return '🇮🇳';
      default:
        return '🌐';
    }
  }

  // Get display name for each language (with native name)
  String _getLanguageDisplayName(String language) {
    switch (language) {
      case 'Turkish':
        return 'Türkçe';
      case 'English':
        return 'English';
      case 'Spanish':
        return 'Español';
      case 'French':
        return 'Français';
      case 'German':
        return 'Deutsch';
      case 'Italian':
        return 'Italiano';
      case 'Portuguese':
        return 'Português';
      case 'Russian':
        return 'Русский';
      case 'Chinese':
        return '中文';
      case 'Japanese':
        return '日本語';
      case 'Korean':
        return '한국어';
      case 'Arabic':
        return 'العربية';
      case 'Hindi':
        return 'हिन्दी';
      default:
        return language;
    }
  }
}
