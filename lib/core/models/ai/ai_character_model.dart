import 'package:hive_ce/hive.dart';

class AiCharacterModel extends HiveObject {
  final String id;

  final String name;

  final String description;

  final String? imageUrl;

  final bool isActive;

  final bool isPublic;

  final bool isOfficial;

  final AiCharacterParametersModel parameters;

  final String? defaultAiModelID;

  // Constructor
  AiCharacterModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.isActive,
    required this.isPublic,
    required this.isOfficial,
    required this.parameters,
    this.defaultAiModelID,
  });

  // Factory constructor for creating instance from JSON
  factory AiCharacterModel.fromJson(Map<String, dynamic> json) {
    return AiCharacterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool,
      isPublic: json['isPublic'] as bool,
      isOfficial: json['isOfficial'] as bool,
      parameters: AiCharacterParametersModel.fromJson(json['parameters'] as Map<String, dynamic>),
      defaultAiModelID: json['defaultAiModelID'] as String?,
    );
  }

  // Method to convert instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'isPublic': isPublic,
      'isOfficial': isOfficial,
      'parameters': parameters.toJson(),
      'defaultAiModelID': defaultAiModelID,
    };
  }

  // Copy with method for immutable updates
  AiCharacterModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
    bool? isPublic,
    bool? isOfficial,
    AiCharacterParametersModel? parameters,
    String? defaultAiModelID,
  }) {
    return AiCharacterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
      isOfficial: isOfficial ?? this.isOfficial,
      parameters: parameters ?? this.parameters,
      defaultAiModelID: defaultAiModelID ?? this.defaultAiModelID,
    );
  }

  // ToString method for debugging
  @override
  String toString() {
    return 'AiCharacterModel(id: $id, name: $name, description: $description, imageUrl: $imageUrl, isActive: $isActive, isOfficial: $isOfficial, parameters: $parameters, defaultAiModelID: $defaultAiModelID)';
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiCharacterModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.isActive == isActive &&
        other.isOfficial == isOfficial &&
        other.parameters == parameters &&
        other.defaultAiModelID == defaultAiModelID;
  }

  // HashCode
  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      imageUrl,
      isActive,
      isOfficial,
      parameters,
      defaultAiModelID,
    );
  }
}

class AiCharacterParametersModel extends HiveObject {
  final String customInstructions;

  final double temperature;

  // Constructor
  AiCharacterParametersModel({required this.customInstructions, required this.temperature});

  // Factory constructor for creating instance from JSON
  factory AiCharacterParametersModel.fromJson(Map<String, dynamic> json) {
    return AiCharacterParametersModel(
      customInstructions: json['customInstructions'] as String,
      temperature: (json['temperature'] as num).toDouble(),
    );
  }

  // Method to convert instance to JSON
  Map<String, dynamic> toJson() {
    return {'customInstructions': customInstructions, 'temperature': temperature};
  }

  // Copy with method for immutable updates
  AiCharacterParametersModel copyWith({String? customInstructions, double? temperature}) {
    return AiCharacterParametersModel(
      customInstructions: customInstructions ?? this.customInstructions,
      temperature: temperature ?? this.temperature,
    );
  }

  // ToString method for debugging
  @override
  String toString() {
    return 'AiCharacterParametersModel(customInstructions: $customInstructions, temperature: $temperature)';
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiCharacterParametersModel &&
        other.customInstructions == customInstructions &&
        other.temperature == temperature;
  }

  // HashCode
  @override
  int get hashCode {
    return Object.hash(customInstructions, temperature);
  }
}
