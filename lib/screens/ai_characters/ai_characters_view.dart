import 'package:flutter/material.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:freeaihub/core/routes/app_routes.dart';
import 'package:freeaihub/screens/ai_characters/ai_characters_controller.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:freeaihub/core/models/ai/ai_character_model.dart';

/// Screen that lists user created AI characters
class AiCharactersView extends StatelessWidget {
  const AiCharactersView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AiCharactersController>(
      init: AiCharactersController(),
      builder: (controller) {
        return Scaffold(
          appBar: CustomAppBar(title: "My AI Characters"),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Get.toNamed(AppRoutes.createAiCharacter);
            },
            child: const Icon(Icons.add),
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : controller.characters.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Text(
                      'You have not created any AI characters yet. Tap the + button to create your first one!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: controller.characters.length,
                  itemBuilder: (context, index) {
                    final character = controller.characters[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 3.h),
                      elevation: 4,
                      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        leading: character.imageUrl != null
                            ? CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(character.imageUrl!),
                              )
                            : CircleAvatar(
                                radius: 25,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  size: 30,
                                ),
                              ),
                        title: Text(
                          character.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 0.5.h),
                          child: Text(
                            character.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onTap: () {
                          Get.toNamed(AppRoutes.createAiCharacter, arguments: character);
                        },
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => _confirmDelete(context, controller, character),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    AiCharactersController controller,
    final AiCharacterModel character,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Character'),
        content: Text('Are you sure you want to delete "${character.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () {
              controller.deleteCharacter(character);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
