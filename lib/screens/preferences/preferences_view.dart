import 'package:flutter/material.dart';
import 'package:freeaihub/core/data/language_definisitons.dart';
import 'package:freeaihub/core/models/user_preferences.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:freeaihub/screens/preferences/preferences_controller.dart';
import 'package:freeaihub/core/app_instance.dart';

/// Main Preferences view accessible from home screen
/// Contains user preferences with save/reset functionality
class PreferencesView extends GetView<PreferencesController> {
  const PreferencesView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PreferencesController>(
      builder: (controller) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with back button and reset action
                _buildHeader(context, controller),
                SizedBox(height: 3.h),

                // Settings sections
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User preferences section
                        _buildUserPreferencesCard(context, controller),
                        SizedBox(height: 3.h),

                        // Future settings placeholder
                        _buildFutureSettingsCard(context, controller),
                        SizedBox(height: 4.h),
                      ],
                    ),
                  ),
                ),

                // Bottom save button
                _buildSaveButton(context, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header with settings title and subtitle
  Widget _buildHeader(BuildContext context, PreferencesController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row with back button, title and reset button
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              iconSize: appInstance.isTablet ? 32.0 : 7.w,
            ),
            SizedBox(width: 2.w),
            Icon(
              Icons.settings,
              size: appInstance.isTablet ? 32.0 : 8.w,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Preferences',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.restore),
              onPressed: controller.resetToDefaults,
              tooltip: 'Reset to defaults',
              iconSize: appInstance.isTablet ? 28.0 : 6.w,
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Padding(
          padding: EdgeInsets.only(left: appInstance.isTablet ? 60.0 : 14.w),
          child: Text(
            'Manage your preferences here.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// User preferences card containing name and language settings
  Widget _buildUserPreferencesCard(BuildContext context, PreferencesController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card title
            Row(
              children: [
                Icon(Icons.person, size: 6.w, color: Theme.of(context).primaryColor),
                SizedBox(width: 3.w),
                Text(
                  'User Preferences',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Name section
            _buildNameSection(context, controller),
            SizedBox(height: 3.h),

            // Language section
            _buildLanguageSection(context, controller),
          ],
        ),
      ),
    );
  }

  /// Name input section
  Widget _buildNameSection(BuildContext context, PreferencesController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 5.w,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 3.w),
            Text(
              'Your Name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'How should we address you in chats?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 1.5.h),
        Obx(
          () => TextFormField(
            controller: controller.nameController,
            maxLength: 16,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.badge_outlined),
              errorText: !controller.isNameValid.value && controller.nameController.text.isNotEmpty
                  ? 'Minimum 2 characters required'
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Language selection section
  Widget _buildLanguageSection(BuildContext context, PreferencesController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.language, size: 5.w, color: Theme.of(context).colorScheme.onSurfaceVariant),
            SizedBox(width: 3.w),
            Text(
              'Chat Language',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Which language would you like to use with AI assistant?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 1.5.h),
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

  /// Future settings placeholder card
  Widget _buildFutureSettingsCard(BuildContext context, PreferencesController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, size: 6.w, color: Theme.of(context).primaryColor),
                SizedBox(width: 3.w),
                Text(
                  'Theme Preferences',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Theme mode section
            _buildThemeModeSection(context, controller),
            SizedBox(height: 3.h),

            // Color scheme section
            _buildColorSchemeSection(context, controller),
          ],
        ),
      ),
    );
  }

  /// Theme mode selection section
  Widget _buildThemeModeSection(BuildContext context, PreferencesController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.brightness_6,
              size: 5.w,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 3.w),
            Text(
              'Theme Mode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Choose your preferred theme mode',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 1.5.h),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
              color: Theme.of(context).cardColor,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppThemeMode>(
                value: controller.selectedThemeMode.value,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                borderRadius: BorderRadius.circular(12),
                items: controller.availableThemeModes.map((mode) {
                  return DropdownMenuItem<AppThemeMode>(
                    value: mode,
                    child: Row(
                      children: [
                        // Responsive icon size for better tablet display
                        Icon(
                          controller.getThemeModeIcon(mode),
                          size: appInstance.isTablet
                              ? 30.0 // Fixed size for tablets
                              : 6.w, // Responsive size for phones
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            controller.getThemeModeDisplayName(mode),
                            style: Theme.of(context).textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (AppThemeMode? newValue) {
                  if (newValue != null) {
                    controller.updateThemeMode(newValue);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Color scheme selection section
  Widget _buildColorSchemeSection(BuildContext context, PreferencesController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.color_lens,
              size: 5.w,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 3.w),
            Text(
              'Color Scheme',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Choose your preferred color palette',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 1.5.h),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
              color: Theme.of(context).cardColor,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FlexScheme>(
                value: controller.selectedColorScheme.value,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                borderRadius: BorderRadius.circular(12),
                items: controller.availableColorSchemes.entries.map((entry) {
                  return DropdownMenuItem<FlexScheme>(
                    value: entry.key,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: controller.selectedColorScheme.value == entry.key
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      child: Row(
                        children: [
                          Container(
                            width: 5.w,
                            height: 5.w,
                            decoration: BoxDecoration(
                              color: _getSchemePreviewColor(entry.key),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: controller.selectedColorScheme.value == entry.key
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (FlexScheme? newValue) {
                  if (newValue != null) {
                    controller.updateColorScheme(newValue);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Get preview color for a color scheme
  Color _getSchemePreviewColor(FlexScheme scheme) {
    // Get the primary color from the scheme data
    final schemeData = scheme.data;
    return schemeData.light.primary;
  }

  /// Save button at the bottom
  Widget _buildSaveButton(BuildContext context, PreferencesController controller) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 6.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            disabledForegroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: controller.isFormValid && !controller.isLoading.value
              ? controller.savePreferences
              : null,
          child: controller.isLoading.value
              ? SizedBox(
                  height: 4.w,
                  width: 4.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(
                  'Save Changes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
        ),
      ),
    );
  }

  /// Get appropriate flag emoji for each language
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

  /// Get display name for each language (with native name)
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
