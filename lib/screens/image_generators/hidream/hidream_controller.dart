// Import statements for core functionality
import 'dart:async'; // Asynchronous programming
import 'dart:convert';
import 'dart:io'; // For temporary file creation
import 'dart:math'; // Random number generation
// Byte array handling
import 'package:dio/dio.dart'; // HTTP client for API calls
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Material design widgets
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/data/model_definisions.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart'; // AI model definition
import 'package:freeaihub/core/global/services/ai_client_service.dart'; // AI service client
import 'package:freeaihub/core/global/services/media_library_service.dart'; // Media library service
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'; // Image saving
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // Temporary directory
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart'; // Image sharing

// Controller for HiDream image generation screen
class HidreamController extends GetxController {
  final ImagePicker _imagePicker = ImagePicker(); // Image picker instance
  // Text controller for user's prompt input
  TextEditingController promptController = TextEditingController();
  TextEditingController negativePromptController = TextEditingController(
    text: "ugly, blurry, low quality, low resolution",
  );
  TextEditingController seedController = TextEditingController();

  ScrollController scrollController = ScrollController();

  // Current AI model being used
  AIModel aiModel;

  HidreamController({required this.aiModel});

  // Service for making API calls to AI backend
  late AiClientService _clientService;
  late MediaLibraryService _mediaLibraryService;

  final mode = ImageGenerationMods.text2Image.obs;

  // Observable properties for image generation parameters
  final imageSize = '1024x1024'.obs; // Default image resolution
  final seed = Rx<int?>(-1); // Random seed (-1 means random)
  final shift = 3.obs; // Style shift parameter
  final guidanceScale = 50.obs; // How closely to follow prompt (0-100)
  final imageGuidanceScale = 40.obs;
  final numInferenceSteps = 50.obs; // Number of diffusion steps

  // Generation state flags
  final isGenerating = false.obs; // Whether generation is in progress
  final Rx<Uint8List?> generatedImage = Rx<Uint8List?>(null); // Generated image bytes
  final Rx<Uint8List?> showcaseImage = Rx<Uint8List?>(null);
  final Rx<Uint8List?> sourceImage = Rx<Uint8List?>(null); // Source image for image-to-image
  final RxBool isAdLoading = false.obs;
  final RxBool isEnhancingPrompt = false.obs;

  // Last generation info properties for persistent display
  final lastGeneratedMode = ''.obs; // Mode used for last generation (T2I or I2I)
  final lastGeneratedSize = ''.obs; // Size used for last generation
  final lastGeneratedSeed = ''.obs; // Seed used for last generation

  // Token for cancelling ongoing API requests
  CancelToken? _cancelToken;

  // Helper methods to update generation parameters
  void clearPrompt() => promptController.clear(); // Clear prompt text
  void clearNegativePrompt() => negativePromptController.clear(); // Clear negative prompt text
  void updateImageSize(String value) => imageSize.value = value; // Update resolution
  void updateSeed(int? value) => seed.value = value; // Update random seed
  void updateShift(int value) => shift.value = value; // Update style shift
  void updateGuidanceScale(int value) => guidanceScale.value = value; // Update guidance
  void updateImageGuidanceScale(int value) => imageGuidanceScale.value = value; // Update guidance
  void updateNumInferenceSteps(int value) => numInferenceSteps.value = value; // Update steps

  @override
  void onInit() async {
    _clientService = AiClientService(aiModel: aiModel); // Initialize service
    _mediaLibraryService = Get.find<MediaLibraryService>(); // Initialize media library service
    super.onInit(); // Call parent initialization
  }

  @override
  void onClose() async {
    // Clean up resources when controller is closed
    _cancelToken?.cancel(); // Cancel any ongoing requests
    sourceImage.value = null; // Clear source image
    scrollController.dispose();
    super.onClose(); // Call parent cleanup
  }

  void switchToEditMode() {
    sourceImage.value = showcaseImage.value;
    mode.value = ImageGenerationMods.image2Image;
    promptController.clear();
    update();
  }

  Future<void> pickSourceImage() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.storage,
      ].request();
      if (statuses[Permission.photos]!.isDenied && statuses[Permission.storage]!.isDenied) return;

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        sourceImage.value = bytes;
        update();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  void clearSourceImage() {
    sourceImage.value = null;
    update();
  }

  void toggleMode() {
    mode.value = mode.value == ImageGenerationMods.text2Image
        ? ImageGenerationMods.image2Image
        : ImageGenerationMods.text2Image;
    update();
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
        name: "${appName}_generatedImage_${DateTime.now().toString()}",
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

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to share image: ${e.toString()}');
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

  Future<void> generateTextToImage() async {
    if (isGenerating.value) return; // Prevent multiple generations
    generatedImage.value = null; // Clear previous image
    showcaseImage.value = null; // Clear showcase image

    try {
      isGenerating.value = true; // Set generating flag
      update();
      _cancelToken = CancelToken(); // Create new cancellation token

      // Prepare request payload
      final data = {
        "seed": seed.value == -1 ? Random().nextInt(1000000) : seed.value,
        "shift": shift.value,
        "prompt": promptController.text,
        "resolution": imageSize.value,
        "guidance_scale": (guidanceScale.value / 10).toDouble(),
        "num_inference_steps": numInferenceSteps.value,
      };

      // Store the actual seed value that will be used
      final String actualSeed = data["seed"].toString();

      // Make API call with timeout
      final image = await _clientService
          .generateTextToImage(data: data, cancelToken: _cancelToken)
          .timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              _cancelToken?.cancel(); // Cancel on timeout
              Get.snackbar('Something went wrong!', 'Image generation timed out');
              return null;
            },
          );

      // Handle successful response
      if (image != null && image.isNotEmpty) {
        Get.log('Image generated: Size - ${image.length} bytes');
        // Remove logEvent
        generatedImage.value = image;
        showcaseImage.value = image; // Set showcase image directly

        // Update last generation info for persistent display
        lastGeneratedMode.value = 'Text to Image';
        lastGeneratedSize.value = imageSize.value;
        lastGeneratedSeed.value = actualSeed;

        // Automatically save to media library
        _saveToMediaLibrary(
          imageBytes: image,
          prompt: promptController.text,
          mode: 'Text to Image',
          generationParams: data,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          update(); // Notify listeners
          // Scroll to top to show the generated image
          if (showcaseImage.value != null) {
            scrollController.animateTo(0, duration: Duration(seconds: 1), curve: Curves.easeInOut);
          }
        });
      }

      _cancelToken = null; // Reset token
    } catch (e) {
      if (kDebugMode) {
        print('Image generation error: $e');
      }
      Get.snackbar('Error', 'Failed to generate image');
    } finally {
      // Ensure generating flag is reset after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isClosed) {
          isGenerating.value = false;
        }
      });
    }
  }

  // Main image generation method
  Future<void> generateImageToImage() async {
    if (isGenerating.value) return; // Prevent multiple generations
    generatedImage.value = null; // Clear previous image
    showcaseImage.value = null; // Clear showcase image

    try {
      isGenerating.value = true; // Set generating flag
      update();
      _cancelToken = CancelToken(); // Create new cancellation token

      Map<String, dynamic>? generatedDescription = await _clientService.describeImage(
        customModel: ModelDefinitions.llama4Maverick,
        base64Image: base64Encode(sourceImage.value!),
        prompt: promptController.text.trim(),
      );
      if (generatedDescription == null || _cancelToken!.isCancelled) {
        isGenerating.value = false;
        update();
        return;
      }

      if (kDebugMode) {
        print('Generated description: $generatedDescription');
      }

      // Prepare request payload
      final data = {
        "seed": seed.value == -1 ? Random().nextInt(1000000) : seed.value,
        "image_b64": base64Encode(sourceImage.value!),
        "prompt":
            "Editing Instructions: ${generatedDescription["editing_instruction"]} \nTarget Image Description: ${generatedDescription["target_image_description"]}",
        "negative_prompt": negativePromptController.text,
        "guidance_scale": (guidanceScale.value / 10).toDouble(),
        "num_inference_steps": numInferenceSteps.value,
        "image_guidance_scale": (imageGuidanceScale / 10).toDouble(),
      };

      // Store the actual seed value that will be used
      final String actualSeed = data["seed"].toString();

      // Make API call with timeout
      final image = await _clientService
          .generateImageToImage(data: data, cancelToken: _cancelToken)
          .timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              _cancelToken?.cancel(); // Cancel on timeout
              Get.snackbar('Something went wrong!', 'Image generation timed out');
              isGenerating.value = false;
              return null;
            },
          );

      // Handle successful response
      if (image != null && image.isNotEmpty) {
        Get.log('Image generated: Size - ${image.length} bytes');
        // Remove logEvent
        generatedImage.value = image;
        showcaseImage.value = image; // Set showcase image directly

        // Update last generation info for persistent display
        lastGeneratedMode.value = 'Image to Image';
        lastGeneratedSize.value =
            '${sourceImage.value!.length ~/ 1024}KB'; // Show source image size
        lastGeneratedSeed.value = actualSeed;

        // Automatically save to media library
        _saveToMediaLibrary(
          imageBytes: image,
          prompt: promptController.text,
          mode: 'Image to Image',
          generationParams: data,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          update(); // Notify listeners
          // Scroll to top to show the generated image
          if (showcaseImage.value != null) {
            scrollController.animateTo(0, duration: Duration(seconds: 1), curve: Curves.easeInOut);
          }
        });
      }

      _cancelToken = null; // Reset token
    } catch (e) {
      if (kDebugMode) {
        print('Image generation error: $e');
      }
      Get.snackbar('Error', 'Failed to generate image');
    } finally {
      // Ensure generating flag is reset after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isClosed) {
          isGenerating.value = false;
          if (showcaseImage.value != null) {
            scrollController.animateTo(0, duration: Duration(seconds: 1), curve: Curves.easeInOut);
          }
          update();
        }
      });
    }
  }

  // Cancel ongoing image generation
  void cancelGeneration() {
    _cancelToken?.cancel(); // Cancel API request
    isGenerating.value = false; // Reset state
    update();
  }

  /// Automatically save generated image to media library
  Future<void> _saveToMediaLibrary({
    required Uint8List imageBytes,
    required String prompt,
    required String mode,
    required Map<String, dynamic> generationParams,
  }) async {
    try {
      final success = await _mediaLibraryService.saveHidreamImage(
        imageBytes: imageBytes,
        prompt: prompt.isNotEmpty ? prompt : 'Hidream Generated Image',
        generationParams: {
          ...generationParams,
          'mode': mode,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (success && kDebugMode && showDebugLogs) {
        print('[DEBUG] [HidreamController] - Image automatically saved to media library');
      }
    } catch (e) {
      if (kDebugMode && showDebugLogs) {
        print('[DEBUG] [HidreamController] - Error saving to media library: $e');
      }
    }
  }
}
