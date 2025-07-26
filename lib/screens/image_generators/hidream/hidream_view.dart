import 'package:auto_size_text/auto_size_text.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/screens/image_generators/hidream/preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freeaihub/screens/image_generators/hidream/hidream_controller.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

class HidreamView extends GetView<HidreamController> {
  const HidreamView({super.key});

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
                      Get.to(() => PreviewScreen(), transition: Transition.fadeIn)?.then((value) {
                        // Remove focus from any text fields when returning from preview
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          FocusScope.of(context).unfocus();
                          FocusManager.instance.primaryFocus?.unfocus();
                        });
                        if (value != null) {
                          controller.switchToEditMode();
                        }
                      });
                    },
                    child: Hero(
                      tag: 'imageHero',
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
                          //color: Colors.grey[200],
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
                        Text(
                          'Generating ${controller.mode.value == ImageGenerationMods.text2Image ? "Text to Image" : "Image to Image"}...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 8),
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
                                'Mode',
                                controller.mode.value == ImageGenerationMods.text2Image
                                    ? 'T2I'
                                    : 'I2I',
                                Icons.auto_awesome,
                              ),
                              if (controller.mode.value == ImageGenerationMods.text2Image)
                                _buildGenerationDetail(
                                  context,
                                  'Size',
                                  controller.imageSize.value,
                                  Icons.photo_size_select_actual,
                                ),
                              _buildGenerationDetail(
                                context,
                                'Seed',
                                controller.seed.value != null && controller.seed.value! >= 0
                                    ? controller.seed.value.toString()
                                    : 'Random',
                                Icons.shuffle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (controller.showcaseImage.value != null &&
                    controller.lastGeneratedMode.value.isNotEmpty) {
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
                                'Mode',
                                controller.lastGeneratedMode.value,
                                Icons.auto_awesome,
                              ),
                              _buildGenerationDetail(
                                context,
                                controller.lastGeneratedMode.value == 'Text to Image'
                                    ? 'Size'
                                    : 'Source',
                                controller.lastGeneratedSize.value,
                                controller.lastGeneratedMode.value == 'Text to Image'
                                    ? Icons.photo_size_select_actual
                                    : Icons.image,
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

              Obx(() {
                return SegmentedButton<ImageGenerationMods>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context).colorScheme.primaryContainer;
                      }
                      return Theme.of(context).colorScheme.surface;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context).colorScheme.onPrimaryContainer;
                      }
                      return Theme.of(context).colorScheme.onSurface;
                    }),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
                      ),
                    ),
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  selected: {controller.mode.value},
                  segments: [
                    ButtonSegment(
                      value: ImageGenerationMods.text2Image,
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Text to Image'),
                      ),
                      icon: Icon(Icons.text_fields, size: 18),
                    ),
                    ButtonSegment(
                      value: ImageGenerationMods.image2Image,
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Image to Image'),
                      ),
                      icon: Icon(Icons.image, size: 18),
                    ),
                  ],
                  onSelectionChanged: (selection) {
                    controller.toggleMode();
                  },
                );
              }),

              SizedBox(height: 2.h),

              // Image Picker Section for Image-to-Image mode
              Obx(() {
                if (controller.mode.value == ImageGenerationMods.image2Image) {
                  return Column(
                    children: [
                      const AutoSizeText('Source Image', minFontSize: 16),
                      SizedBox(height: 1.h),
                      GetBuilder<HidreamController>(
                        builder: (ctrl) {
                          return Stack(
                            children: [
                              Container(
                                width: appInstance.isTablet ? 30.w : double.infinity,
                                height: appInstance.isTablet ? 30.w : 30.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: controller.sourceImage.value != null
                                    ? Image.memory(controller.sourceImage.value!)
                                    : const Center(
                                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                                      ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Row(
                                  children: [
                                    if (controller.sourceImage.value != null)
                                      IconButton(
                                        onPressed: () => controller.clearSourceImage(),
                                        icon: const Icon(Icons.clear, color: Colors.white),
                                        style: ButtonStyle(
                                          backgroundColor: WidgetStatePropertyAll(Colors.red),
                                        ),
                                      ),
                                    IconButton(
                                      onPressed: () => controller.pickSourceImage(),
                                      icon: const Icon(
                                        Icons.add_photo_alternate,
                                        color: Colors.white,
                                      ),
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 2.h),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              // Prompt Input Section
              GetBuilder<HidreamController>(
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

              Obx(() {
                return ExpansionTile(
                  key: UniqueKey(),
                  title: const AutoSizeText('Select Size'),
                  enabled: controller.mode.value == ImageGenerationMods.text2Image,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: appInstance.isTablet ? 7 : 3,
                      mainAxisSpacing: 1.h,
                      crossAxisSpacing: 1.h,
                      childAspectRatio: 0.8,
                      children: [
                        _buildSizeOption(context, '1360x768', 'Portrait', Icons.phone_android),
                        _buildSizeOption(context, '1248x832', 'Tall', Icons.crop_portrait),
                        _buildSizeOption(context, '1168x880', 'Narrow', Icons.straighten),
                        _buildSizeOption(context, '1024x1024', 'Square', Icons.crop_square),
                        _buildSizeOption(context, '880x1168', 'Wide', Icons.straighten),
                        _buildSizeOption(context, '832x1248', 'Landscape', Icons.crop_landscape),
                        _buildSizeOption(context, '768x1360', 'Widescreen', Icons.desktop_windows),
                      ],
                    ),
                  ],
                );
              }),
              SizedBox(height: 3.h),
              // Advanced Configuration Section
              ExpansionTile(
                title: const Text('Advanced Configurations'),
                children: [
                  SizedBox(height: 3.h),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() {
                      return Column(
                        spacing: 2.h,
                        children: [
                          if (controller.mode.value == ImageGenerationMods.image2Image)
                            GetBuilder<HidreamController>(
                              builder: (ctrl) {
                                return TextField(
                                  controller: controller.negativePromptController,
                                  autofocus: false,
                                  onChanged: (value) => controller.update(),
                                  decoration: InputDecoration(
                                    labelText: 'Enter your negative prompt',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
                                  maxLines: 10,
                                  minLines: 1,
                                );
                              },
                            ),
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
                          if (controller.mode.value == ImageGenerationMods.text2Image)
                            Text('Shift: ${controller.shift.value}'),

                          if (controller.mode.value == ImageGenerationMods.text2Image)
                            Slider(
                              value: controller.shift.value.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              onChanged: (value) => controller.updateShift(value.toInt()),
                            ),
                          if (controller.mode.value == ImageGenerationMods.image2Image)
                            Text(
                              'Image Guidance Scale: ${controller.imageGuidanceScale.value / 10}',
                            ),
                          if (controller.mode.value == ImageGenerationMods.image2Image)
                            Slider(
                              value: controller.imageGuidanceScale.value.toDouble(),
                              min: 0,
                              max: 100,
                              onChanged: (value) =>
                                  controller.updateImageGuidanceScale(value.toInt()),
                            ),
                          Text('Guidance Scale: ${controller.guidanceScale.value / 10}'),
                          Slider(
                            value: controller.guidanceScale.value.toDouble(),
                            min: 0,
                            max: 100,
                            onChanged: (value) => controller.updateGuidanceScale(value.toInt()),
                          ),
                          Text('Inference Steps: ${controller.numInferenceSteps.value}'),
                          Slider(
                            value: controller.numInferenceSteps.value.toDouble(),
                            min: 5,
                            max: 75,
                            onChanged: (value) => controller.updateNumInferenceSteps(value.toInt()),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GetBuilder<HidreamController>(
        builder: (ctrl) {
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
                          : controller.mode.value == ImageGenerationMods.image2Image
                          ? controller.sourceImage.value != null &&
                                    controller.promptController.text.isNotEmpty
                                ? () => controller.generateImageToImage()
                                : null
                          : controller.promptController.text.isNotEmpty
                          ? () => controller.generateTextToImage()
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (controller.isGenerating.value) ...[
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            SizedBox(width: 1.w),
                          ],
                          if (!controller.isGenerating.value)
                            Icon(Icons.scatter_plot_sharp, size: 20.sp),
                          SizedBox(width: 2.w),
                          AutoSizeText(
                            controller.isGenerating.value ? 'Generating...' : 'Generate Image',
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
}
