import 'package:freeaihub/core/models/chat/message.dart';
import 'package:hive_ce/hive.dart';

class ChatSession extends HiveObject {
  final String id;

  final String title;

  final DateTime createdAt;

  final DateTime updatedAt;

  final List<Message> messages;

  final String aiModelID;
  // Stores enabled capabilities/tools for this session

  final Map<String, bool>? capabilities;
  // Stores context manager state for this session

  final Map<String, dynamic>? contextState;

  // (NEW) ID of the selected AI character for this session (if any)
  final String? selectedCharacterID;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    required this.aiModelID,
    this.capabilities,
    this.contextState,
    this.selectedCharacterID,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messages: (json['messages'] as List).map((e) => Message.fromJson(e)).toList(),
      aiModelID: json['aiModelID'] ?? "",
      capabilities: json['capabilities'] != null
          ? Map<String, bool>.from(json['capabilities'])
          : null,
      contextState: json['contextState'] != null
          ? Map<String, dynamic>.from(json['contextState'])
          : null,
      selectedCharacterID: json['selectedCharacterID'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((e) => e.toJson()).toList(),
      'aiModelID': aiModelID,
      if (capabilities != null) 'capabilities': capabilities,
      if (contextState != null) 'contextState': contextState,
      if (selectedCharacterID != null) 'selectedCharacterID': selectedCharacterID,
    };
  }

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
    String? aiModelID,
    Map<String, bool>? capabilities,
    Map<String, dynamic>? contextState,
    String? selectedCharacterID,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      aiModelID: aiModelID ?? this.aiModelID,
      capabilities: capabilities ?? this.capabilities,
      contextState: contextState ?? this.contextState,
      selectedCharacterID: selectedCharacterID ?? this.selectedCharacterID,
    );
  }
}
