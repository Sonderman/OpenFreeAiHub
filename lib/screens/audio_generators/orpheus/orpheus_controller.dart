import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/global/services/ai_client_service.dart';
import 'package:freeaihub/core/utils/media_store_operations.dart';
import 'package:get/get.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class OrpheusController extends GetxController {
  // Current AI model being used
  AIModel? aiModel;

  // Service for making API calls to AI backend
  late AiClientService _clientService;

  // Token for cancelling ongoing API requests
  CancelToken? _cancelToken;

  final Rx<Uint8List?> generatedAudio = Rx<Uint8List?>(null);
  TextEditingController promptController = TextEditingController();
  int? maxLength;

  final isGenerating = false.obs; // Whether generation is in progress
  final Rx<String> selectedVoice = 'Tara'.obs; // Currently selected voice
  final temperature = 6.obs; // Temperature for generation
  final repetitionPenalty = 11.obs;

  @override
  void onInit() async {
    // Initialize controller with passed AI model
    if (Get.arguments != null) {
      aiModel = Get.arguments; // Get model from navigation arguments
      _clientService = AiClientService(aiModel: aiModel!); // Initialize service
    }
    super.onInit(); // Call parent initialization
  }

  @override
  void onClose() async {
    // Clean up resources when controller is closed
    _cancelToken?.cancel(); // Cancel any ongoing requests

    super.onClose(); // Call parent cleanup
  }

  void clearPrompt() => promptController.clear(); // Clear prompt text

  void generateAudio() async {
    if (promptController.text.trim().isEmpty) return;
    isGenerating.value = true;

    update();
    _cancelToken = CancelToken(); // Create new cancellation token

    // Prepare request payload
    final data = {
      "prompt": promptController.text.trim(),
      "voice": selectedVoice.value.toLowerCase(),
      "temperature": temperature.value / 10,
      "repetition_penalty": repetitionPenalty.value / 10,
    };

    final generatedData = await _clientService.generateTextToVoice(
      data: data,
      cancelToken: _cancelToken,
    );
    if (generatedData != null) {
      generatedAudio.value = generatedData;

      if (kDebugMode) {
        print("Audio size: ${generatedAudio.value!.lengthInBytes}");
      }
    }
    isGenerating.value = false;
    update();
  }

  void cancelGeneration() {
    _cancelToken?.cancel(); // Cancel ongoing request
    isGenerating.value = false;
    update();
  }

  Future<void> saveAudio() async {
    if (generatedAudio.value == null) return;
    try {
      // Request storage permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.audio,
      ].request();

      if (!(statuses[Permission.audio]!.isGranted || statuses[Permission.storage]!.isGranted)) {
        return;
      }

      final timestamp = DateTime.now().toString();
      final fileName = '${appName}_generatedAudio_$timestamp.wav';

      bool result = await saveBytesToMediaStorage(
        fileName: fileName,
        dirType: DirType.audio,
        data: generatedAudio.value!,
      );

      // Verify file saved
      if (result) {
        Get.snackbar('Success', 'Voice saved to Audio/Music folder');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save Voice: ${e.toString()}');
    }
  }

  Future<void> shareAudio() async {
    if (generatedAudio.value == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/generated_audio_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      await file.writeAsBytes(generatedAudio.value!);

      final result = await SharePlus.instance.share(
        ShareParams(
          text: 'Check this out, an AI-generated voice from $appName!',
          subject: 'AI Generated Voice',
          files: [XFile(file.path)],
        ),
      );

      if (result.status == ShareResultStatus.success) {
        Get.snackbar('Success', 'Voice shared successfully');
      }

      // Clean up temp file after sharing
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to share voice: ${e.toString()}');
    }
  }
}
