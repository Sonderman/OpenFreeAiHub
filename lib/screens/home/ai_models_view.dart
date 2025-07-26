import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'home_controller.dart';
import 'widgets/ai_model_card.dart';
import 'package:freeaihub/core/global/services/hive_service.dart';
import 'package:freeaihub/core/models/chat/chat_session_model.dart';
import 'package:freeaihub/core/data/model_definisions.dart';
import 'package:freeaihub/core/routes/app_routes.dart';
import 'package:intl/intl.dart' as intl;

/// AI Models view widget displaying categorized AI model cards
class AiModelsView extends StatelessWidget {
  const AiModelsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scrollable grid of AI model categories
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Latest conversations section
              _buildLatestConversationsSection(context),
              // Build all category sections
              ...AppInstance.categories.entries.map(
                (category) => _buildCategorySection(context, category),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a category section widget with title and AI model cards
  Widget _buildCategorySection(BuildContext context, MapEntry<CategoryTypes, String> category) {
    // Filter models for the current category.
    final models = appInstance.activeModels
        .where((model) => model.category == category.key)
        .toList();

    // If there are no models in this category, return an empty widget to hide the section.
    if (models.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category title with improved styling
          _buildCategoryTitle(context, category.value),
          // Grid of AI models in this category
          _buildAiModelGrid(context, models),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  /// Builds the category title section
  Widget _buildCategoryTitle(BuildContext context, String categoryName) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              categoryName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                //color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a grid of AI model cards for a specific category
  Widget _buildAiModelGrid(BuildContext context, List models) {
    final controller = Get.find<HomeController>();

    // Build grid of model cards
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: appInstance.isTablet ? 3 : 2,
        childAspectRatio: 1,
        crossAxisSpacing: 15.sp,
        mainAxisSpacing: 15.sp,
      ),
      itemCount: models.length,
      itemBuilder: (context, index) {
        return AiModelCard(
          model: models[index],
          onTap: () => controller.viewSelector(models[index]),
        );
      },
    );
  }

  /// Builds the latest conversations section showing the most recent 3 chats
  Widget _buildLatestConversationsSection(BuildContext context) {
    Future<List<ChatSession>> fetchLatestSessions() async {
      final sessions = await HiveService.to.getAllChatSessions();
      return sessions.take(6).toList();
    }

    return FutureBuilder<List<ChatSession>>(
      future: fetchLatestSessions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final sessions = snapshot.data!;
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              _buildCategoryTitle(context, 'Latest Conversations'),
              // Sessions list
              SizedBox(
                height: 26.h,
                child: ListView.separated(
                  //physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => SizedBox(height: 1.h),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final aiModel = ModelDefinitions.availableModels[session.aiModelID];
                    if (aiModel == null) {
                      return const SizedBox.shrink();
                    }
                    return SizedBox(
                      height: 8.h, // Fixed height for uniform appearance
                      child: GestureDetector(
                        onTap: () {
                          Get.toNamed(
                            '${AppRoutes.chat}?sessionId=${session.id}',
                            arguments: aiModel,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(10.sp),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Model icon
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        aiModel.decorations?.backgroundColor ?? Colors.transparent,
                                    backgroundImage: aiModel.assetIcon != null
                                        ? AssetImage(aiModel.assetIcon!)
                                        : null,
                                    radius: 14.sp,
                                    child: aiModel.assetIcon == null
                                        ? Icon(Icons.forum, size: 14.sp)
                                        : null,
                                  ),
                                  // Model short name label
                                  Expanded(
                                    child: SizedBox(
                                      width: 15.w,
                                      child: AutoSizeText(
                                        aiModel.shortName,
                                        maxLines: 2,
                                        minFontSize: 8,
                                        textAlign: TextAlign.center,
                                        //style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 3.w),
                              // Session title
                              Expanded(
                                child: Text(
                                  session.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              // Updated date
                              Text(
                                intl.DateFormat('MMM dd').format(session.updatedAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
