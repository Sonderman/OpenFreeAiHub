import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:freeaihub/core/app_configs.dart';

/// Enum for theme mode options
enum AppThemeMode { system, light, dark }

class UserPreferences {
  final String userName;
  final String chatLanguage;
  final bool preferencesCompleted;
  final AppThemeMode themeMode; // System, Light, Dark theme mode
  final FlexScheme colorScheme; // Selected color scheme from FlexColorScheme

  const UserPreferences({
    required this.userName,
    required this.chatLanguage,
    required this.preferencesCompleted,
    this.themeMode = AppThemeMode.system,
    this.colorScheme = defaultColorScheme,
  });

  // Default values for new users
  static const UserPreferences defaultPreferences = UserPreferences(
    userName: 'User',
    chatLanguage: 'English',
    preferencesCompleted: false,
    themeMode: AppThemeMode.system,
    colorScheme: defaultColorScheme,
  );

  // Copy with method for easy updates
  UserPreferences copyWith({
    String? userName,
    String? chatLanguage,
    bool? preferencesCompleted,
    AppThemeMode? themeMode,
    FlexScheme? colorScheme,
  }) {
    return UserPreferences(
      userName: userName ?? this.userName,
      chatLanguage: chatLanguage ?? this.chatLanguage,
      preferencesCompleted: preferencesCompleted ?? this.preferencesCompleted,
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'chatLanguage': chatLanguage,
      'preferencesCompleted': preferencesCompleted,
      'themeMode': themeMode.name,
      'colorScheme': colorScheme.name,
    };
  }

  // Create from JSON from storage
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userName: json['userName'] as String? ?? 'User',
      chatLanguage: json['chatLanguage'] as String? ?? 'English',
      preferencesCompleted: json['preferencesCompleted'] as bool? ?? false,
      themeMode: _parseThemeMode(json['themeMode']),
      colorScheme: _parseColorScheme(json['colorScheme']),
    );
  }

  // Create from local storage individual values (backward compatibility)
  factory UserPreferences.fromStorage({
    String? userName,
    String? chatLanguage,
    bool? preferencesCompleted,
    String? themeMode,
    String? colorScheme,
  }) {
    return UserPreferences(
      userName: userName ?? 'User',
      chatLanguage: chatLanguage ?? 'English',
      preferencesCompleted: preferencesCompleted ?? false,
      themeMode: _parseThemeMode(themeMode),
      colorScheme: _parseColorScheme(colorScheme),
    );
  }

  // Helper method to parse theme mode from string
  static AppThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }

  // Helper method to parse color scheme from string
  static FlexScheme _parseColorScheme(String? value) {
    try {
      return FlexScheme.values.firstWhere(
        (scheme) => scheme.name == value,
        orElse: () => defaultColorScheme,
      );
    } catch (e) {
      return defaultColorScheme;
    }
  }

  // Get Flutter ThemeMode equivalent
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  @override
  String toString() {
    return 'UserPreferences(userName: $userName, chatLanguage: $chatLanguage, preferencesCompleted: $preferencesCompleted, themeMode: $themeMode, colorScheme: $colorScheme)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferences &&
        other.userName == userName &&
        other.chatLanguage == chatLanguage &&
        other.preferencesCompleted == preferencesCompleted &&
        other.themeMode == themeMode &&
        other.colorScheme == colorScheme;
  }

  @override
  int get hashCode {
    return userName.hashCode ^
        chatLanguage.hashCode ^
        preferencesCompleted.hashCode ^
        themeMode.hashCode ^
        colorScheme.hashCode;
  }
}
