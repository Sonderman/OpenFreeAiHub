import 'package:flutter/material.dart';
import 'package:freeaihub/core/global/components/ui_components.dart';
import 'package:freeaihub/core/global/services/ai_character_service.dart';
import 'package:freeaihub/screens/ai_characters/ai_characters_controller.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:freeaihub/core/models/ai/ai_character_model.dart';

class CreateAiCharacterView extends StatefulWidget {
  // Optional existing character – if provided, the screen acts in edit mode
  final AiCharacterModel? character;

  const CreateAiCharacterView({super.key, this.character});

  @override
  State<CreateAiCharacterView> createState() => _CreateAiCharacterViewState();
}

class _CreateAiCharacterViewState extends State<CreateAiCharacterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  double _temperature = 0.7;

  final AiCharacterService _service = Get.find<AiCharacterService>();
  final controller = Get.find<AiCharactersController>();

  // Flag to determine create vs edit mode
  late final bool _isEditMode;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Determine if we are in edit mode from constructor or Get.arguments
    final passedCharacter = widget.character ?? (Get.arguments as AiCharacterModel?);
    _isEditMode = passedCharacter != null;

    if (_isEditMode) {
      // Prefill form fields with existing data
      _nameController.text = passedCharacter!.name;
      _descriptionController.text = passedCharacter.description;
      _instructionsController.text = passedCharacter.parameters.customInstructions;
      _temperature = passedCharacter.parameters.temperature;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _isEditMode ? 'Edit AI Character' : 'Create AI Character'),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                maxLength: 30,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 5,
                minLines: 1,
                maxLength: 255,
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(labelText: 'Instructions'),
                maxLines: 10,
                minLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Custom instructions are required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              Text('Temperature (Creativity): ${_temperature.toStringAsFixed(2)}'),
              Slider(
                value: _temperature,
                min: 0.1,
                max: 1.0,
                divisions: 18,
                onChanged: (value) {
                  setState(() {
                    _temperature = value;
                  });
                },
              ),
              SizedBox(height: 4.h),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a beautiful, modern save button with enhanced styling and animations
  Widget _buildSaveButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      height: 6.h,
      child: _isSaving
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [colorScheme.primary.withOpacity(0.8), colorScheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      _isEditMode ? 'Updating...' : 'Saving...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(24),
              shadowColor: colorScheme.primary.withOpacity(0.4),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _saveCharacter,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isEditMode ? Icons.edit_rounded : Icons.save_rounded,
                          color: colorScheme.onPrimary,
                          size: 22,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _isEditMode ? 'Update Character' : 'Save Character',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _saveCharacter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    bool success;

    if (_isEditMode) {
      // Build updated model from existing one
      final existing = widget.character ?? (Get.arguments as AiCharacterModel);
      final updated = existing.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        parameters: existing.parameters.copyWith(
          customInstructions: _instructionsController.text.trim(),
          temperature: _temperature,
        ),
      );
      success = await _service.updateAiCharacter(updated);
    } else {
      success = await _service.createAiCharacter(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        customInstructions: _instructionsController.text.trim(),
        temperature: _temperature,
        imageUrl: null,
      );
    }

    setState(() {
      _isSaving = false;
    });

    if (success) {
      controller.refreshCharacters();
      Get.back();
      Get.snackbar('Success', _isEditMode ? 'AI character updated' : 'AI character created');
    } else {
      Get.snackbar(
        'Error',
        _isEditMode ? 'Failed to update character' : 'Failed to create character',
      );
    }
  }
}
