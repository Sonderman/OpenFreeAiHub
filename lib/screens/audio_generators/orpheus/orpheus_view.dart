import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:freeaihub/core/global/components/audio/audio_player_widget.dart';
import 'package:freeaihub/screens/audio_generators/orpheus/orpheus_controller.dart';
import 'package:get/get.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:sizer/sizer.dart';
import 'package:tiktoken_tokenizer_gpt4o_o1/tiktoken_tokenizer_gpt4o_o1.dart';

class OrpheusView extends GetView<OrpheusController> {
  const OrpheusView({super.key});

  DropdownMenuItem<String> _buildVoiceItem(String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [Icon(Icons.voice_chat, size: 20), const SizedBox(width: 8), Text(value)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.put(OrpheusController());
    return Scaffold(
      appBar: CustomAppBar(title: controller.aiModel?.name ?? ""),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 2.h,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AutoSizeText('Generated Voice', minFontSize: 16),
              SizedBox(height: 1.h),
              Obx(() {
                if (controller.generatedAudio.value != null) {
                  return Column(
                    children: [
                      AudioPlayerWidget(audioData: controller.generatedAudio.value!),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w.clamp(16, 24),
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.save_rounded, size: 20),
                            label: const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            onPressed: () => controller.saveAudio(),
                          ),
                          SizedBox(width: 2.w),
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w.clamp(16, 24),
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 20),
                            label: const Text(
                              'Share',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            onPressed: () {
                              controller.shareAudio();
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 20.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(child: Icon(Icons.voice_chat, size: 50)),
                      ),
                    ],
                  );
                }
              }),
              SizedBox(height: 5.h),
              // Prompt Input Section
              GetBuilder<OrpheusController>(
                builder: (ctrl) {
                  return TextField(
                    controller: controller.promptController,
                    autofocus: false,
                    onTapOutside: (event) => FocusScope.of(context).unfocus(),
                    onChanged: (value) {
                      int tokenCount = Tiktoken(OpenAiModel.gpt_4).count(value.trim());
                      if (tokenCount >= 2000) {
                        controller.maxLength = controller.promptController.text.length;
                      } else {
                        controller.maxLength = null;
                      }
                      if (kDebugMode) {
                        print("Token count: $tokenCount");
                      }
                      controller.update();
                    },
                    maxLength: controller.maxLength,
                    decoration: InputDecoration(
                      labelText: 'Enter your prompt',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon:
                          controller.promptController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  controller.clearPrompt();
                                  controller.update();
                                },
                              )
                              : null,
                    ),
                    maxLines: 10,
                    minLines: 1,
                  );
                },
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  const AutoSizeText('Select Voice', minFontSize: 16),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Obx(() {
                        return DropdownButton<String>(
                          value: controller.selectedVoice.value,
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: Theme.of(context).textTheme.bodyMedium,

                          items: [
                            _buildVoiceItem("Tara"),
                            _buildVoiceItem("Leah"),
                            _buildVoiceItem("Jess"),
                            _buildVoiceItem("Leo"),
                            _buildVoiceItem("Dan"),
                            _buildVoiceItem("Mia"),
                            _buildVoiceItem("Zac"),
                            _buildVoiceItem("Zoe"),
                          ],
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              controller.selectedVoice.value = newValue;
                            }
                          },
                          hint: const Text('Select voice'),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              ExpansionTile(
                title: AutoSizeText("Advanced Configurations"),
                children: [
                  Obx(() {
                    return Column(
                      children: [
                        Text('Temperature: ${controller.temperature.value / 10}'),
                        Slider(
                          value: controller.temperature.value.toDouble(),
                          min: 1,
                          max: 15,
                          onChanged: (value) => controller.temperature.value = value.toInt(),
                        ),
                        Text('Repetition Penalty: ${controller.repetitionPenalty.value / 10}'),
                        Slider(
                          value: controller.repetitionPenalty.value.toDouble(),
                          min: 11,
                          max: 20,
                          onChanged: (value) => controller.repetitionPenalty.value = value.toInt(),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for better prompts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GptMarkdown(
                      '''* Add paralinguistic elements like **<laugh>**, **<chuckle>**, **<sigh>**, **<cough>**, **<sniffle>**, **<groan>**, **<yawn>**, **<gasp>** or **uhm** for more human-like speech.
* Longer text prompts generally work better than very short phrases
* Increasing repetition penalty and temperature makes the model speak faster.''',
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: Text(
                        "Example Prompts",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      children: [
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              "Hey there my name is Tara, <chuckle> and I'm a speech generation model that can sound like a person.",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              "I've also been taught to understand and produce paralinguistic things <sigh> like sighing, or <laugh> laughing, or <yawn> yawning!",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              "I live in San Francisco, and have, uhm let's see, 3 billion 7 hundred ... <gasp> well, lets just say a lot of parameters.",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              "Sometimes when I talk too much, I need to <cough> excuse myself. <sniffle> The weather has been quite cold lately.",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              "Public speaking can be challenging. <groan> But with enough practice, anyone can become better at it.",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              "The hike was exhausting but the view from the top was absolutely breathtaking! <sigh> It was totally worth it.",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              "Did you hear that joke? <laugh> I couldn't stop laughing when I first heard it. <chuckle> It's still funny.",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              "After running the marathon, I was so tired <yawn> and needed a long rest. <sigh> But I felt accomplished.",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
      bottomNavigationBar: GetBuilder<OrpheusController>(
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: SizedBox(
              height: 8.h,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed:
                          !controller.isGenerating.value &&
                                  controller.promptController.text.trim().isNotEmpty
                              ? () => controller.generateAudio()
                              : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (controller.isGenerating.value) ...[
                            CircularProgressIndicator(),
                            SizedBox(width: 1.w),
                          ],
                          if (!controller.isGenerating.value)
                            Icon(Icons.scatter_plot_sharp, size: 20.sp),
                          SizedBox(width: 2.w),
                          AutoSizeText(
                            controller.isGenerating.value ? 'Generating...' : 'Generate Voice',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (controller.isGenerating.value) ...[
                    SizedBox(width: 2.w),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.w),
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => controller.cancelGeneration(),
                      child: Icon(Icons.stop, size: 20.sp),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
