// Import statements for core functionality
import 'dart:async'; // Asynchronous programming
import 'dart:io'; // For temporary file creation
import 'dart:math'; // Random number generation
import 'package:dio/dio.dart'; // HTTP client for API calls
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Material design widgets
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/data/model_definisions.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart'; // AI model definition
import 'package:freeaihub/core/global/services/ai_client_service.dart'; // AI service client
import 'package:freeaihub/core/global/services/media_library_service.dart'; // Media library service

import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'; // Image saving
import 'package:path_provider/path_provider.dart'; // Temporary directory
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart'; // Image sharing

// Controller for Pollinations AI image generation screen
class PollinationsController extends GetxController {
  // Text controller for user's prompt input
  TextEditingController promptController = TextEditingController();
  TextEditingController negativePromptController = TextEditingController();
  TextEditingController seedController = TextEditingController();

  ScrollController scrollController = ScrollController();

  // Current AI model being used
  AIModel aiModel;

  PollinationsController({required this.aiModel});

  // Service for making API calls to AI backend
  late AiClientService _clientService;
  late MediaLibraryService _mediaLibraryService;

  // Pollinations-specific models available
  final availableModels = [
    'flux', 'turbo',
    //'gptimage'
  ].obs;

  // Observable properties for image generation parameters
  final selectedModel = 'flux'.obs; // Current selected model
  final imageSize = '1024x1024'.obs; // Default image resolution
  final seed = Rx<int?>(-1); // Random seed (-1 means random)
  final enhance = false.obs; // Auto-enhance prompt
  final safe = true.obs; // Safe mode for content filtering

  // Generation state flags
  final isGenerating = false.obs; // Whether generation is in progress
  final Rx<Uint8List?> generatedImage = Rx<Uint8List?>(null); // Generated image bytes
  final Rx<Uint8List?> showcaseImage = Rx<Uint8List?>(null);
  final RxBool isAdLoading = false.obs;
  final RxBool isEnhancingPrompt = false.obs;

  // New properties for enhanced feedback
  final generationProgress = 0.0.obs; // Progress percentage (0.0 to 1.0)
  final generationStatus = ''.obs; // Current status message

  // Last generation info properties for persistent display
  final lastGeneratedModel = ''.obs; // Model used for last generation
  final lastGeneratedSize = ''.obs; // Size used for last generation
  final lastGeneratedSeed = ''.obs; // Seed used for last generation

  Timer? _progressTimer; // Timer for progress updates
  DateTime? _generationStartTime; // When generation started

  // Token for cancelling ongoing API requests
  CancelToken? _cancelToken;

  // Helper methods to update generation parameters
  void clearPrompt() => promptController.clear(); // Clear prompt text
  void clearNegativePrompt() => negativePromptController.clear(); // Clear negative prompt text
  void updateSelectedModel(String value) => selectedModel.value = value; // Update model
  void updateImageSize(String value) => imageSize.value = value; // Update resolution
  void updateSeed(int? value) => seed.value = value; // Update random seed
  void toggleEnhance() => enhance.value = !enhance.value; // Toggle enhancement
  void toggleSafe() => safe.value = !safe.value; // Toggle safe mode

  // New method to update generation progress
  void _updateGenerationProgress() {
    if (!isGenerating.value) return;

    final elapsed = DateTime.now().difference(_generationStartTime!).inSeconds;

    // Simulate progress based on elapsed time
    double progress = 0.0;
    int estimatedTotal = 20; // Fixed 20 seconds for progress simulation

    if (elapsed < estimatedTotal) {
      progress = elapsed / estimatedTotal;
    } else {
      progress = 0.95; // Cap at 95% until actual completion
    }

    generationProgress.value = progress;

    // Update status message based on progress
    if (progress < 0.2) {
      generationStatus.value = 'Preparing your request...';
    } else if (progress < 0.4) {
      generationStatus.value = 'Processing prompt...';
    } else if (progress < 0.7) {
      generationStatus.value = 'Generating image...';
    } else if (progress < 0.9) {
      generationStatus.value = 'Applying final touches...';
    } else {
      generationStatus.value = 'Almost ready...';
    }
  }

  // Start progress tracking
  void _startProgressTracking() {
    _generationStartTime = DateTime.now();
    generationProgress.value = 0.0;
    generationStatus.value = 'Initializing...';

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateGenerationProgress();
    });
  }

  // Stop progress tracking
  void _stopProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = null;

    if (isGenerating.value) {
      generationProgress.value = 1.0;
      generationStatus.value = 'Completed!';
    } else {
      generationProgress.value = 0.0;
      generationStatus.value = '';
    }
  }

  @override
  void onInit() async {
    _clientService = AiClientService(aiModel: aiModel); // Initialize service
    _mediaLibraryService = Get.find<MediaLibraryService>(); // Initialize media library service
    super.onInit(); // Call parent initialization
  }

  @override
  void onClose() async {
    _progressTimer?.cancel(); // Cancel progress timer
    scrollController.dispose();
    super.onClose(); // Call parent cleanup
  }

  Future<void> saveImageToGallery() async {
    if (showcaseImage.value == null) return;
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.storage,
      ].request();
      if (statuses[Permission.photos]!.isDenied && statuses[Permission.storage]!.isDenied) return;
      final result = await ImageGallerySaverPlus.saveImage(
        showcaseImage.value!,
        name: "${appName}_pollinationsAI_${DateTime.now().toString()}",
      );
      if (result['isSuccess'] == true) {
        Get.snackbar('Success', 'Image saved to gallery');
      } else {
        Get.snackbar('Error', 'Failed to save image');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save image: ${e.toString()}');
    }
  }

  void handlePromptEnhancing(String prompt) async {
    isEnhancingPrompt.value = true;
    update();
    final enhacedText = await _clientService.enhancePrompt(
      customModel: ModelDefinitions.deepseekv3_0324,
      prompt: prompt,
    );
    isEnhancingPrompt.value = false;
    update();
    if (enhacedText == null) return;
    promptController.text = enhacedText;
  }

  Future<void> shareImage() async {
    if (showcaseImage.value == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/generated_image_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(showcaseImage.value!);

      final result = await SharePlus.instance.share(
        ShareParams(
          text: 'Check this out AI-generated image from $appName!',
          subject: 'AI Generated Image',
          files: [XFile(file.path)],
        ),
      );

      if (result.status == ShareResultStatus.success) {
        Get.snackbar('Success', 'Image shared successfully');
      }

      // Clean up temp file after sharing
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to share image: ${e.toString()}');
    }
  }

  Future<void> generateImage() async {
    if (promptController.text.isEmpty) return;

    try {
      isGenerating.value = true;
      showcaseImage.value = null;
      generatedImage.value = null;
      update();

      // Start progress tracking for user feedback
      _startProgressTracking();

      // Create cancel token for this request
      _cancelToken = CancelToken();

      // Build the Pollinations API URL with parameters
      final baseUrl = aiModel.apiModel.baseURL;
      final prompt = Uri.encodeComponent(promptController.text.trim());

      // Build query parameters
      final Map<String, String> queryParams = {};

      // Add model if not default
      if (selectedModel.value != 'flux') {
        queryParams['model'] = selectedModel.value;
      }

      // Add dimensions
      final dimensions = imageSize.value.split('x');
      if (dimensions.length == 2) {
        queryParams['width'] = dimensions[0];
        queryParams['height'] = dimensions[1];
      }

      // Add seed if specified
      String actualSeed;
      if (seed.value != null && seed.value! >= 0) {
        actualSeed = seed.value.toString();
        queryParams['seed'] = actualSeed;
      } else {
        actualSeed = '${Random().nextInt(1000000)}';
        queryParams['seed'] = actualSeed;
      }

      // Add other parameters
      if (enhance.value) queryParams['enhance'] = 'true';
      queryParams['nologo'] = 'true';
      queryParams['nofeed'] = 'true';
      queryParams['private'] = 'true';
      queryParams['safe'] = safe.value ? 'true' : 'false';
      queryParams['referrer'] = "com.sondermium.freeaihub";
      if (aiModel.apiModel.apiKey.isNotEmpty) queryParams['token'] = aiModel.apiModel.apiKey;

      // Build final URL
      final uri = Uri.parse(
        '$baseUrl/prompt/$prompt',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      if (kDebugMode) {
        print('Pollinations API URL: $uri');
      }

      // Update status for API request
      generationStatus.value = 'Connecting to AI service...';

      // Make HTTP request to generate image
      final dio = Dio();
      final response = await dio.get(
        uri.toString(),
        cancelToken: _cancelToken,
        options: Options(
          responseType: ResponseType.bytes,
          headers: aiModel.apiModel.headers,
          followRedirects: true,
          maxRedirects: 5,
        ),
        onReceiveProgress: (received, total) {
          // Update progress based on download progress if total is known
          if (total > 0) {
            final downloadProgress = received / total;
            generationProgress.value = 0.7 + (downloadProgress * 0.2); // 70-90% for download
            generationStatus.value = 'Downloading generated image...';
          }
        },
      );

      if (response.statusCode == 200) {
        generationStatus.value = 'Processing image...';
        final imageBytes = Uint8List.fromList(response.data);
        generatedImage.value = imageBytes;
        showcaseImage.value = imageBytes;

        // Complete the progress
        generationProgress.value = 1.0;
        generationStatus.value = 'Image generated successfully!';

        // Update last generation info for persistent display
        lastGeneratedModel.value = selectedModel.value;
        lastGeneratedSize.value = imageSize.value;
        lastGeneratedSeed.value = actualSeed;

        // Automatically save to media library
        _saveToMediaLibrary(
          imageBytes: imageBytes,
          prompt: promptController.text,
          generationParams: {
            'model': selectedModel.value,
            'size': imageSize.value,
            'seed': actualSeed,
            'enhance': enhance.value,
            'safe': safe.value,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        Get.snackbar(
          'Success',
          'Image generated successfully!',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Scroll to top to show the generated image
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (showcaseImage.value != null) {
            scrollController.animateTo(0, duration: Duration(seconds: 1), curve: Curves.easeInOut);
          }
        });
      } else {
        throw Exception('Failed to generate image: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        Get.snackbar(
          'Cancelled',
          'Image generation was cancelled',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to generate image',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
      if (kDebugMode) {
        print('Pollinations generation error: $e');
      }
    } finally {
      isGenerating.value = false;
      _stopProgressTracking();
      update();
    }
  }

  void cancelGeneration() {
    _cancelToken?.cancel();
    isGenerating.value = false;
    _stopProgressTracking();
    Get.snackbar(
      'Cancelled',
      'Image generation cancelled',
      backgroundColor: Colors.orange.withOpacity(0.8),
      colorText: Colors.white,
    );
    update();
  }

  /// Automatically save generated image to media library
  Future<void> _saveToMediaLibrary({
    required Uint8List imageBytes,
    required String prompt,
    required Map<String, dynamic> generationParams,
  }) async {
    try {
      final success = await _mediaLibraryService.savePollinationsImage(
        imageBytes: imageBytes,
        prompt: prompt.isNotEmpty ? prompt : 'Pollinations AI Generated Image',
        generationParams: generationParams,
      );

      if (success && kDebugMode && showDebugLogs) {
        print('[DEBUG] [PollinationsController] - Image automatically saved to media library');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [PollinationsController] - Error saving to media library: $e');
      }
    }
  }
}
