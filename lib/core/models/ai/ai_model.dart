import 'package:flutter/material.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/models/api/api_model.dart';

class AIModel {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final String? assetIcon;
  final String? urlIcon;
  final int maxTokens;
  final int maxOutputTokens;
  final ApiModel apiModel;
  final CategoryTypes category;
  final FeaturesModel features;
  final ModelDecorations? decorations;

  AIModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.features,
    required this.apiModel,
    required this.category,
    required this.maxTokens,
    required this.maxOutputTokens,
    this.assetIcon,
    this.urlIcon,
    this.decorations,
  });
}

class FeaturesModel {
  final bool canGenerateImage;
  final bool isReasoning;
  final bool isVision;
  final bool isMultimodal;
  final bool canGenerateVoice;
  final bool supportsToolCalling;
  final bool supportsResponseFormat;
  final ToolCapabilities toolCapabilities;

  FeaturesModel({
    this.isReasoning = false,
    this.isVision = false,
    this.isMultimodal = false,
    this.canGenerateImage = false,
    this.canGenerateVoice = false,
    this.supportsToolCalling = false,
    this.supportsResponseFormat = false,
    this.toolCapabilities = const ToolCapabilities(),
  });

  factory FeaturesModel.fromJson(Map<String, dynamic> json) {
    return FeaturesModel(
      isReasoning: json['isReasoning'],
      isVision: json['isVision'],
      isMultimodal: json['isMultimodal'],
      canGenerateImage: json['canGenerateImage'],
      canGenerateVoice: json['canGenerateVoice'],
      supportsToolCalling: json['supportsToolCalling'],
      supportsResponseFormat: json['supportsResponseFormat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isReasoning': isReasoning,
      'isVision': isVision,
      'isMultimodal': isMultimodal,
      'canGenerateImage': canGenerateImage,
      'canGenerateVoice': canGenerateVoice,
      'supportsToolCalling': supportsToolCalling,
      'supportsResponseFormat': supportsResponseFormat,
    };
  }
}

class ModelDecorations {
  final Color? backgroundColor;
  final Color? textColor;
  ModelDecorations({this.backgroundColor, this.textColor});
}

class ToolCapabilities {
  final bool webSearch;
  final bool imageGeneration;
  const ToolCapabilities({this.webSearch = false, this.imageGeneration = false});
}
