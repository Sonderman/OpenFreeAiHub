import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';

const String appName = 'FreeAI Hub';
//Check before release
const String appVersion = '0.1.1';
const bool isDebugMod = kDebugMode ? true : false;
const bool showDebugLogs = true;
const bool enableExperimentalFeatures = kDebugMode;
////////////////////////
const int welcomeDialogLimit = 2; // Maximum number of times the welcome dialog can be shown
const int singleSessionImageLimit = 4; // Maximum number of images allowed per sessionLimit
const int limitToScrapeDataForWebSearch =
    10; // Maximum number of websites to scrape for AI analysis
const int maxDocumentSize = 2; // 2MB
const int maxImagesPerMessage = 4;

const FlexScheme defaultColorScheme = FlexScheme.shadStone;

const String telegramChannelUrl = "https://t.me/g_sondermium_apps/1";
