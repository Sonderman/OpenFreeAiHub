import 'package:freeaihub/core/models/chat/image_data_model.dart';
import 'package:hive_ce/hive.dart';

enum MessageType { text, image, video, document, multiple, thinkBlock }

enum AuthorType { user, ai }

class MessageAuthor extends HiveObject {
  final AuthorType type;

  final String? name;

  MessageAuthor({required this.type, this.name});

  Map<String, dynamic> toJson() => {'type': type.name, 'name': name};

  factory MessageAuthor.fromJson(Map<String, dynamic> json) => MessageAuthor(
    type: AuthorType.values.firstWhere((e) {
      if (json['type'] != null) {
        return e.name == json['type'];
      } else {
        return e.name == json["id"];
      }
    }, orElse: () => AuthorType.user),
    name: json['name'],
  );

  MessageAuthor copyWith({AuthorType? type, String? name}) =>
      MessageAuthor(type: type ?? this.type, name: name ?? this.name);
}

class Message extends HiveObject {
  final MessageAuthor author;

  final int? createdAt;

  final String id;

  final Map<String, dynamic>? metadata;

  final MessageType type;

  final List<ImageData>? attachedImages;

  final String text;

  final int tokenCount;

  Message({
    required this.author,
    this.createdAt,
    required this.id,
    required this.type,
    this.metadata,
    this.attachedImages,
    required this.text,
    required this.tokenCount,
  });

  Map<String, dynamic> toJson() => {
    'author': author.toJson(),
    'createdAt': createdAt,
    'id': id,
    'metadata': metadata,
    'type': type.name,
    'attachedImages': attachedImages?.map((e) => e.toJson()).toList(),
    'text': text,
    'tokenCount': tokenCount,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    author: MessageAuthor.fromJson(json['author']),
    createdAt: json['createdAt'],
    id: json['id'],
    type: MessageType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => MessageType.text,
    ),
    attachedImages: json['attachedImages'] != null
        ? (json['attachedImages'] as List).map((e) => ImageData.fromJson(e)).toList()
        : null,
    metadata: json['metadata'],
    text: json['text'] ?? "",
    tokenCount: json['tokenCount'] ?? 0,
  );

  Message copyWith({
    MessageAuthor? author,
    int? createdAt,
    String? id,
    Map<String, dynamic>? metadata,
    MessageType? type,
    List<ImageData>? attachedImages,
    String? text,
    int? tokenCount,
  }) => Message(
    author: author ?? this.author,
    createdAt: createdAt ?? this.createdAt,
    id: id ?? this.id,
    type: type ?? this.type,
    metadata: metadata ?? this.metadata,
    attachedImages: attachedImages ?? this.attachedImages,
    text: text ?? this.text,
    tokenCount: tokenCount ?? this.tokenCount,
  );
}
