import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/data/model_definisions.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:sizer/sizer.dart';

/// Individual AI model card widget
class AiModelCard extends StatelessWidget {
  final AIModel model;
  final VoidCallback onTap;

  const AiModelCard({super.key, required this.model, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final IconData? modelFeatureIcon = _getModelFeatureIcon();
    final IconData? modelCapabilitiesIcon = _getModelCapabilitiesIcon();

    return Hero(
      tag: model.id,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  model.decorations?.backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainer,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(2.sp),
            child: Stack(
              children: [
                // Main content
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Model icon
                        _buildModelIcon(context),
                        SizedBox(height: 1.h),
                        // Model name
                        _buildModelName(context),
                      ],
                    ),
                  ),
                ),
                // Feature icon (top left)
                if (modelFeatureIcon != null)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        modelFeatureIcon,
                        size: 20.sp,
                        color: model.decorations?.textColor,
                      ),
                    ),
                  ),
                // Capabilities icon (bottom left)
                if (modelCapabilitiesIcon != null)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        modelCapabilitiesIcon,
                        size: 20.sp,
                        color: model.decorations?.textColor,
                      ),
                    ),
                  ),
                // Info button (top right)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      size: 20.sp,
                      color:
                          model.decorations?.textColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => _showModelInfo(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the model icon widget
  Widget _buildModelIcon(BuildContext context) {
    if (model.urlIcon != null) {
      return CachedNetworkImage(
        imageUrl: model.urlIcon!,
        width: 15.w,
        height: 15.w,
        placeholder: (context, url) => Container(
          width: 15.w,
          height: 15.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
        ),
        errorWidget: (context, url, error) =>
            Icon(Icons.forum, size: 15.w, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    } else if (model.assetIcon != null) {
      return Image.asset(
        model.assetIcon!,
        height: appInstance.isTablet ? 40.sp : 30.sp,
        color: model.id == ModelDefinitions.pollinationsAiImage.id
            ? Theme.of(context).colorScheme.primary
            : null,
      );
    } else {
      return Icon(Icons.forum, size: 30.sp, color: Theme.of(context).colorScheme.onSurfaceVariant);
    }
  }

  /// Builds the model name widget
  Widget _buildModelName(BuildContext context) {
    return AutoSizeText(
      model.name,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: model.decorations?.textColor,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      minFontSize: appInstance.isTablet ? 20 : 16,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Gets the feature icon for the model
  IconData? _getModelFeatureIcon() {
    if (model.features.isReasoning) {
      return Icons.psychology;
    } else if (model.features.isVision) {
      return Icons.visibility;
    } else if (model.features.canGenerateImage) {
      return Icons.image;
    } else if (model.features.canGenerateVoice) {
      return Icons.voice_chat;
    } else if (model.category == CategoryTypes.chat) {
      return Icons.code;
    }
    return null;
  }

  /// Gets the capabilities icon for the model
  IconData? _getModelCapabilitiesIcon() {
    if (model.features.supportsResponseFormat) {
      return Icons.construction;
    }
    return null;
  }

  /// Shows model information dialog
  void _showModelInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(model.name),
        content: SingleChildScrollView(child: Text(model.description)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}
