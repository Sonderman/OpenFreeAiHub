// Import necessary packages and files
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/screens/audio_generators/orpheus/orpheus_view.dart';
import 'package:freeaihub/screens/chat/chat_view.dart';
import 'package:freeaihub/screens/chat/chat_controller.dart';
import 'package:freeaihub/screens/home/home_view.dart';
import 'package:freeaihub/screens/image_generators/hidream/hidream_controller.dart';
import 'package:freeaihub/screens/image_generators/hidream/hidream_view.dart';
import 'package:freeaihub/screens/image_generators/pollinations_ai/pollinations_controller.dart';
import 'package:freeaihub/screens/image_generators/pollinations_ai/pollinations_view.dart';
import 'package:freeaihub/screens/media_library/media_library_view.dart';
import 'package:freeaihub/screens/splash/splash_view.dart';
import 'package:freeaihub/screens/splash/splash_controller.dart';
import 'package:freeaihub/screens/preferences/welcome_preferences_view.dart';
import 'package:freeaihub/screens/preferences/preferences_view.dart';
import 'package:freeaihub/screens/ai_characters/ai_characters_view.dart';
import 'package:freeaihub/screens/ai_characters/create_ai_character_view.dart';
import 'package:get/get.dart';
import 'package:freeaihub/screens/preferences/preferences_controller.dart';

/// Abstract class that defines all application routes and their configurations
abstract class AppRoutes {
  // Route constants for navigation
  static const splash = '/'; // Initial splash screen route
  static const home = '/home'; // Main home screen route
  static const chat = '/chat'; // Chat screen route
  static const orpheus = '/orpheus'; // Chat screen route
  static const hidream = "/image-generator/hidream";
  static const pollinations = "/image-generator/pollinations";
  static const mediaLibrary = '/media-library'; // Media library route
  static const aiCharacters = '/ai-characters'; // AI characters list route
  static const createAiCharacter = '/ai-characters/create'; // Create AI character route
  static const welcomePreferences = '/welcome-preferences'; // Welcome preferences route
  static const preferences = '/preferences'; // Main preferences route

  /// List of GetPage routes used for navigation throughout the app
  /// Each route defines:
  /// - name: The route path
  /// - page: The widget to display for this route
  /// - binding (optional): Controller binding for the route
  /// - transition: iOS-style transitions for better UX
  static List<GetPage> routes = [
    // Splash screen route - first screen shown when app launches
    GetPage(
      name: splash,
      page: () => const SplashView(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 250),
      binding: BindingsBuilder(() {
        // Provide SplashController once when splash route is first used.
        Get.put(SplashController());
      }),
    ),

    // Home screen route - main screen after splash
    GetPage(
      name: home,
      page: () => const HomeView(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    ),

    // Welcome preferences route - shown after splash for first time users
    GetPage(
      name: welcomePreferences,
      page: () => const WelcomePreferencesView(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    ),

    // Main preferences route - accessible from home screen (modal style)
    GetPage(
      name: preferences,
      page: () => const PreferencesView(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      binding: BindingsBuilder(() {
        // Provide PreferencesController once when navigating to preferences.
        Get.put(PreferencesController());
      }),
    ),

    // Chat screen route with controller binding and iOS transition
    GetPage(
      name: chat,
      page: () => ChatView(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      binding: BindingsBuilder(() {
        final aiModel = Get.arguments as AIModel?;
        if (aiModel == null) {
          throw ArgumentError('AIModel argument is required');
        }
        // Use the refactored ChatController without tag so ChatView can find it
        Get.put(ChatController(aiModel: aiModel));
      }),
    ),

    // Image generation screen with iOS transition
    GetPage(
      name: hidream,
      page: () => const HidreamView(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      binding: BindingsBuilder(() {
        final aiModel = Get.arguments as AIModel?;
        if (aiModel == null) {
          throw ArgumentError('AIModel argument is required');
        }
        Get.put(HidreamController(aiModel: aiModel));
      }),
    ),

    // Pollinations AI image generation screen with iOS transition
    GetPage(
      name: pollinations,
      page: () => const PollinationsView(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      binding: BindingsBuilder(() {
        final aiModel = Get.arguments as AIModel?;
        if (aiModel == null) {
          throw ArgumentError('AIModel argument is required');
        }
        Get.put(PollinationsController(aiModel: aiModel));
      }),
    ),

    // Audio generation screen with iOS transition
    GetPage(
      name: orpheus,
      page: () => const OrpheusView(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    ),

    // Media library screen with iOS transition
    GetPage(
      name: mediaLibrary,
      page: () => const MediaLibraryView(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    ),

    // AI Characters list screen
    GetPage(
      name: aiCharacters,
      page: () => const AiCharactersView(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    ),

    // Create AI Character screen (modal style)
    GetPage(
      name: createAiCharacter,
      page: () => const CreateAiCharacterView(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    ),
  ];
}
