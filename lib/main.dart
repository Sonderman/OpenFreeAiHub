// Import statements for various packages and local files
import 'dart:io';

import 'package:flutter/material.dart'; // Material design widgets
import 'package:flutter/services.dart'; // Platform services
import 'package:flutter_easyloading/flutter_easyloading.dart'; // Loading indicators
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/global/services/tts_service.dart';
import 'package:freeaihub/core/global/services/connectiviy_service.dart'; // Network connectivity
import 'package:freeaihub/core/global/services/hive_service.dart';
import 'package:freeaihub/core/global/services/get_storage_service.dart'; // Local storage
import 'package:get/get.dart'; // State management
import 'package:get_storage/get_storage.dart'; // Local storage
import 'package:media_store_plus/media_store_plus.dart';
import 'package:sizer/sizer.dart'; // Responsive sizing
import 'package:sizer/sizer.dart' as sizer; // Responsive sizing
import 'package:freeaihub/core/themes/theme_controller.dart'; // Theme controller
import 'core/routes/app_routes.dart'; // App routing
import 'package:freeaihub/core/global/services/media_library_service.dart'; // Media library service
import 'package:freeaihub/core/global/services/ai_character_service.dart'; // AI character service
import 'package:freeaihub/core/themes/app_theme.dart';

// Main application entry point
void main() async {
  // Ensure Flutter framework is initialized
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = "FreeAIHub";
  }

  // Initialize AppInstance first (required by ThemeController)
  Get.put(AppInstance(), permanent: true); // Will be updated in Sizer builder

  // Initialize ThemeController after AppInstance
  Get.put(ThemeController(), permanent: true);

  /*workerManager.log = isDebugMod;
  await workerManager.init();*/

  // Run the app wrapped in BetterFeedback for user feedback functionality
  runApp(
    const MyApp(), // Main app widget
  );
}

// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Sizer for responsive design
    return Sizer(
      builder: (context, orientation, deviceScreen) {
        // Update app instance tablet status
        final appInstance = Get.find<AppInstance>();
        // Update the tablet status based on device screen
        if (deviceScreen == sizer.ScreenType.tablet) {
          appInstance.isTablet = true;
        } else {
          appInstance.isTablet = false;
        }

        // Initialize theme controller reference
        final themeController = Get.find<ThemeController>();

        SystemChrome.setPreferredOrientations(
          deviceScreen == sizer.ScreenType.tablet
              ? [
                  DeviceOrientation.landscapeLeft, // Landscape left orientation for tablets
                  DeviceOrientation.landscapeRight, // Landscape right orientation for tablets
                ]
              : [
                  DeviceOrientation.portraitUp, // Only portrait up orientation
                  DeviceOrientation.portraitDown, // Only portrait down orientation
                ],
        );

        // Use Obx so that theme changes emitted by ThemeController rebuild the MaterialApp
        return Obx(
          () => GetMaterialApp(
            title: appName, // App title
            debugShowCheckedModeBanner: false, // Hide debug banner
            builder: EasyLoading.init(), // Initialize loading indicators
            initialRoute: AppRoutes.splash, // Initial route (splash screen)
            theme: themeController.currentTheme, // Reactive light/dark theme based on controller
            // Provide an explicit dark theme as well for completeness
            darkTheme: AppTheme.getFlexDarkTheme(themeController.colorScheme),
            themeMode: themeController.themeMode, // Follow theme controller reactively
            getPages: AppRoutes.routes, // Application routes
          ),
        );
      },
    );
  }
}

// Initialize and set up all application services
Future<void> setServices() async {
  // Initialize connectivity service
  await Get.putAsync(() => ConnectivityService().init(), permanent: true);

  // Initialize local storage
  await GetStorage.init();
  Get.put(GetStorageService(), permanent: true);

  // Initialize Hive
  await Get.put(HiveService(), permanent: true).init();

  // Initialize user preferences in app instance
  await appInstance.initializeUserPreferences();

  // Initialize TTS service
  await Get.putAsync(() => TextToSpeechService().initialize(), permanent: true);

  // Initialize media library service
  Get.put(MediaLibraryService(), permanent: true);

  // Initialize AI character service
  Get.put(AiCharacterService(), permanent: true);
}
