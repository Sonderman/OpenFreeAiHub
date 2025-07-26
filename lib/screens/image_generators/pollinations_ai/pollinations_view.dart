import 'package:auto_size_text/auto_size_text.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:freeaihub/screens/image_generators/pollinations_ai/pollinations_controller.dart';
import 'package:freeaihub/screens/image_generators/pollinations_ai/preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

class PollinationsView extends GetView<PollinationsController> {
  const PollinationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: controller.aiModel.name),
      body: GestureDetector(
        onTap: () {
          // Remove focus when tapping anywhere outside text fields
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: SingleChildScrollView(
          controller: controller.scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const AutoSizeText('Generated Image', minFontSize: 16),
              SizedBox(height: 1.h),
              // Image Preview Section
              Obx(() {
                if (controller.showcaseImage.value != null) {
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => PreviewScreen(), transition: Transition.fadeIn)?.then((_) {
                        // Remove focus from any text fields when returning from preview
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          FocusScope.of(context).unfocus();
                          FocusManager.instance.primaryFocus?.unfocus();
                        });
                      });
                    },
                    child: Hero(
                      tag: 'pollinationsImageHero',
                      child: Image.memory(
                        controller.showcaseImage.value!,
                        height: appInstance.isTablet ? 30.w : null,
                      ),
                    ),
                  );
                } else {
                  return Stack(
                    children: [
                      Container(
                        width: appInstance.isTablet ? 30.w : double.infinity,
                        height: appInstance.isTablet ? 30.w : 30.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                      ),
                    ],
                  );
                }
              }),
              SizedBox(height: 2.h),

              // Generation Info Section
              Obx(() {
                if (controller.isGenerating.value) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // Generation Details
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildGenerationDetail(
                                context,
                                'Model',
                                controller.selectedModel.value,
                                Icons.memory,
                              ),
                              _buildGenerationDetail(
                                context,
                                'Size',
                                controller.imageSize.value,
                                Icons.photo_size_select_actual,
                              ),
                              if (controller.seed.value != null && controller.seed.value! >= 0)
                                _buildGenerationDetail(
                                  context,
                                  'Seed',
                                  controller.seed.value.toString(),
                                  Icons.shuffle,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (controller.showcaseImage.value != null &&
                    controller.lastGeneratedModel.value.isNotEmpty) {
                  // Show last generation info when image is available
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generation Details',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildGenerationDetail(
                                context,
                                'Model',
                                controller.lastGeneratedModel.value,
                                Icons.memory,
                              ),
                              _buildGenerationDetail(
                                context,
                                'Size',
                                controller.lastGeneratedSize.value,
                                Icons.photo_size_select_actual,
                              ),
                              _buildGenerationDetail(
                                context,
                                'Seed',
                                controller.lastGeneratedSeed.value,
                                Icons.shuffle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Model Selection Section
              ExpansionTile(
                title: const AutoSizeText('Select Model'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Obx(() {
                      return Column(
                        children: controller.availableModels.map((model) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => controller.updateSelectedModel(model),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: controller.selectedModel.value == model
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer.withAlpha(100)
                                      : Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: controller.selectedModel.value == model
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                    width: controller.selectedModel.value == model ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Model Icon
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: controller.selectedModel.value == model
                                            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                            : Theme.of(
                                                context,
                                              ).colorScheme.outline.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getModelIcon(model),
                                        color: controller.selectedModel.value == model
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface.withOpacity(0.7),
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),

                                    // Model Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getModelDisplayName(model),
                                            style: Theme.of(context).textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: controller.selectedModel.value == model
                                                      ? Theme.of(context).colorScheme.primary
                                                      : null,
                                                ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            _getModelDescription(model),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Selection Indicator
                                    if (controller.selectedModel.value == model)
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Prompt Input Section
              GetBuilder<PollinationsController>(
                builder: (ctrl) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.promptController,
                          autofocus: false,
                          enableInteractiveSelection: false,
                          onChanged: (value) => controller.update(),
                          decoration: InputDecoration(
                            labelText: 'Enter your prompt',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: controller.promptController.text.isNotEmpty
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
                        ),
                      ),
                      SizedBox(width: 2.w),
                      controller.isEnhancingPrompt.value
                          ? CircularProgressIndicator()
                          : IconButton(
                              onPressed: () {
                                if (controller.promptController.text.trim().isEmpty) return;
                                controller.handlePromptEnhancing(
                                  controller.promptController.text.trim(),
                                );
                              },
                              icon: Image.asset(
                                "assets/icons/magic.png",
                                color: context.theme.colorScheme.primary,
                                height: 24.sp,
                                width: 24.sp,
                              ),
                            ),
                    ],
                  );
                },
              ),

              SizedBox(height: 1.h),

              // Size Selection Section
              ExpansionTile(
                title: const AutoSizeText('Select Size'),
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: appInstance.isTablet ? 5 : 3,
                    mainAxisSpacing: 1.h,
                    crossAxisSpacing: 1.h,
                    childAspectRatio: 0.8,
                    children: [
                      _buildSizeOption(context, '512x512', 'Small', Icons.crop_square),
                      _buildSizeOption(context, '768x768', 'Medium', Icons.crop_square),
                      _buildSizeOption(context, '1024x1024', 'Large', Icons.crop_square),
                      _buildSizeOption(context, '1024x768', 'Landscape', Icons.crop_landscape),
                      _buildSizeOption(context, '768x1024', 'Portrait', Icons.crop_portrait),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Advanced Configuration Section
              ExpansionTile(
                title: const Text('Advanced Configurations'),
                children: [
                  SizedBox(height: 2.h),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      spacing: 2.h,
                      children: [
                        /*// Negative Prompt Input (if needed)
                        GetBuilder<PollinationsController>(
                          builder: (ctrl) {
                            return TextField(
                              controller: controller.negativePromptController,
                              autofocus: false,
                              onChanged: (value) => controller.update(),
                              decoration: InputDecoration(
                                labelText: 'Negative prompt (optional)',
                                hintText: 'What you don\'t want in the image',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: controller.negativePromptController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          controller.clearNegativePrompt();
                                          controller.update();
                                        },
                                      )
                                    : null,
                              ),
                              maxLines: 5,
                              minLines: 1,
                            );
                          },
                        ),*/
                        // Seed Input
                        TextField(
                          controller: controller.seedController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          autofocus: false,
                          decoration: InputDecoration(
                            labelText: "Seed",
                            hintText: 'Leave empty for random value',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: controller.seedController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      controller.updateSeed(null);
                                      controller.seedController.clear();
                                      controller.update();
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            if (value.isEmpty) {
                              controller.updateSeed(null);
                            } else {
                              controller.updateSeed(int.tryParse(value));
                            }
                            controller.update();
                          },
                        ),

                        // Toggle Options
                        Obx(() {
                          return Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Auto-enhance prompt'),
                                subtitle: const Text('Automatically improve prompt quality'),
                                value: controller.enhance.value,
                                onChanged: (value) => controller.toggleEnhance(),
                              ),
                              SwitchListTile(
                                title: const Text('Safe mode'),
                                subtitle: const Text('Filter inappropriate content'),
                                value: controller.safe.value,
                                onChanged: (value) => controller.toggleSafe(),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GetBuilder<PollinationsController>(
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
                      onPressed: controller.isGenerating.value
                          ? null
                          : controller.promptController.text.isNotEmpty
                          ? () => controller.generateImage()
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (controller.isGenerating.value) ...[
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 1.w),
                          ],
                          if (!controller.isGenerating.value) Icon(Icons.auto_awesome, size: 20.sp),
                          SizedBox(width: 2.w),
                          Flexible(
                            child: AutoSizeText(
                              controller.isGenerating.value ? 'Generating...' : 'Generate Image',
                            ),
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

  Widget _buildSizeOption(BuildContext context, String size, String label, IconData icon) {
    return Obx(
      () => GestureDetector(
        onTap: () => controller.updateImageSize(size),
        child: Container(
          decoration: BoxDecoration(
            color: controller.imageSize.value == size
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: controller.imageSize.value == size
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24.sp),
              SizedBox(height: 1.h),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: controller.imageSize.value == size
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(size, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerationDetail(BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary.withOpacity(0.8)),
        SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  IconData _getModelIcon(String model) {
    switch (model) {
      case 'flux':
        return Icons.auto_awesome;
      case 'turbo':
        return Icons.flash_on;
      case 'gptimage':
        return Icons.psychology;
      default:
        return Icons.memory;
    }
  }

  String _getModelDisplayName(String model) {
    switch (model) {
      case 'flux':
        return 'Flux';
      case 'turbo':
        return 'Turbo';
      case 'gptimage':
        return 'GPT Image';
      default:
        return model.toUpperCase();
    }
  }

  String _getModelDescription(String model) {
    switch (model) {
      case 'flux':
        return 'High quality, balanced generation with excellent detail';
      case 'turbo':
        return 'Fast generation with good quality for quick results';
      case 'gptimage':
        return 'AI-powered generation with creative interpretation';
      default:
        return 'Advanced AI image generation model';
    }
  }
}
