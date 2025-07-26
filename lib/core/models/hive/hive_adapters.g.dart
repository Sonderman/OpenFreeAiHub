// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class ChatSessionAdapter extends TypeAdapter<ChatSession> {
  @override
  final typeId = 0;

  @override
  ChatSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatSession(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
      messages: (fields[4] as List).cast<Message>(),
      aiModelID: fields[5] as String,
      capabilities: (fields[6] as Map?)?.cast<String, bool>(),
      contextState: (fields[7] as Map?)?.cast<String, dynamic>(),
      selectedCharacterID: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatSession obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.messages)
      ..writeByte(5)
      ..write(obj.aiModelID)
      ..writeByte(6)
      ..write(obj.capabilities)
      ..writeByte(7)
      ..write(obj.contextState)
      ..writeByte(8)
      ..write(obj.selectedCharacterID);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ImageDataAdapter extends TypeAdapter<ImageData> {
  @override
  final typeId = 1;

  @override
  ImageData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageData(
      id: fields[0] as String,
      name: fields[1] as String,
      path: fields[2] as String,
      size: (fields[3] as num).toInt(),
      extension: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ImageData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.extension);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final typeId = 2;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      author: fields[0] as MessageAuthor,
      createdAt: (fields[1] as num?)?.toInt(),
      id: fields[2] as String,
      type: fields[4] as MessageType,
      metadata: (fields[3] as Map?)?.cast<String, dynamic>(),
      attachedImages: (fields[5] as List?)?.cast<ImageData>(),
      text: fields[6] as String,
      tokenCount: (fields[7] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.author)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.metadata)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.attachedImages)
      ..writeByte(6)
      ..write(obj.text)
      ..writeByte(7)
      ..write(obj.tokenCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageAuthorAdapter extends TypeAdapter<MessageAuthor> {
  @override
  final typeId = 3;

  @override
  MessageAuthor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageAuthor(
      type: fields[0] as AuthorType,
      name: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MessageAuthor obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAuthorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageTypeAdapter extends TypeAdapter<MessageType> {
  @override
  final typeId = 4;

  @override
  MessageType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageType.text;
      case 1:
        return MessageType.image;
      case 2:
        return MessageType.video;
      case 3:
        return MessageType.document;
      case 4:
        return MessageType.multiple;
      case 5:
        return MessageType.thinkBlock;
      default:
        return MessageType.text;
    }
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    switch (obj) {
      case MessageType.text:
        writer.writeByte(0);
      case MessageType.image:
        writer.writeByte(1);
      case MessageType.video:
        writer.writeByte(2);
      case MessageType.document:
        writer.writeByte(3);
      case MessageType.multiple:
        writer.writeByte(4);
      case MessageType.thinkBlock:
        writer.writeByte(5);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AuthorTypeAdapter extends TypeAdapter<AuthorType> {
  @override
  final typeId = 5;

  @override
  AuthorType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AuthorType.user;
      case 1:
        return AuthorType.ai;
      default:
        return AuthorType.user;
    }
  }

  @override
  void write(BinaryWriter writer, AuthorType obj) {
    switch (obj) {
      case AuthorType.user:
        writer.writeByte(0);
      case AuthorType.ai:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MediaItemAdapter extends TypeAdapter<MediaItem> {
  @override
  final typeId = 6;

  @override
  MediaItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaItem(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      source: fields[3] as MediaSource,
      type: fields[4] as MediaType,
      base64Data: fields[5] as String,
      thumbnailBase64: fields[6] as String?,
      sizeBytes: (fields[7] as num).toInt(),
      dimensions: fields[8] as ImageDimensions?,
      createdAt: fields[9] as DateTime,
      lastAccessedAt: fields[10] as DateTime,
      metadata: (fields[11] as Map?)?.cast<String, dynamic>(),
      tags: fields[12] == null ? const [] : (fields[12] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MediaItem obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.source)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.base64Data)
      ..writeByte(6)
      ..write(obj.thumbnailBase64)
      ..writeByte(7)
      ..write(obj.sizeBytes)
      ..writeByte(8)
      ..write(obj.dimensions)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.lastAccessedAt)
      ..writeByte(11)
      ..write(obj.metadata)
      ..writeByte(12)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MediaSourceAdapter extends TypeAdapter<MediaSource> {
  @override
  final typeId = 7;

  @override
  MediaSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MediaSource.chat;
      case 1:
        return MediaSource.hidream;
      case 2:
        return MediaSource.pollinationsAi;
      case 3:
        return MediaSource.unknown;
      default:
        return MediaSource.chat;
    }
  }

  @override
  void write(BinaryWriter writer, MediaSource obj) {
    switch (obj) {
      case MediaSource.chat:
        writer.writeByte(0);
      case MediaSource.hidream:
        writer.writeByte(1);
      case MediaSource.pollinationsAi:
        writer.writeByte(2);
      case MediaSource.unknown:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MediaTypeAdapter extends TypeAdapter<MediaType> {
  @override
  final typeId = 8;

  @override
  MediaType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MediaType.image;
      case 1:
        return MediaType.audio;
      case 2:
        return MediaType.video;
      case 3:
        return MediaType.document;
      default:
        return MediaType.image;
    }
  }

  @override
  void write(BinaryWriter writer, MediaType obj) {
    switch (obj) {
      case MediaType.image:
        writer.writeByte(0);
      case MediaType.audio:
        writer.writeByte(1);
      case MediaType.video:
        writer.writeByte(2);
      case MediaType.document:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ImageDimensionsAdapter extends TypeAdapter<ImageDimensions> {
  @override
  final typeId = 9;

  @override
  ImageDimensions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageDimensions(
      width: (fields[0] as num).toInt(),
      height: (fields[1] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ImageDimensions obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.width)
      ..writeByte(1)
      ..write(obj.height);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageDimensionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AiCharacterModelAdapter extends TypeAdapter<AiCharacterModel> {
  @override
  final typeId = 10;

  @override
  AiCharacterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiCharacterModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      imageUrl: fields[3] as String?,
      isActive: fields[4] as bool,
      isPublic: fields[5] as bool,
      isOfficial: fields[6] as bool,
      parameters: fields[7] as AiCharacterParametersModel,
      defaultAiModelID: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AiCharacterModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.isPublic)
      ..writeByte(6)
      ..write(obj.isOfficial)
      ..writeByte(7)
      ..write(obj.parameters)
      ..writeByte(8)
      ..write(obj.defaultAiModelID);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiCharacterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AiCharacterParametersModelAdapter
    extends TypeAdapter<AiCharacterParametersModel> {
  @override
  final typeId = 11;

  @override
  AiCharacterParametersModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiCharacterParametersModel(
      customInstructions: fields[0] as String,
      temperature: (fields[1] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, AiCharacterParametersModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.customInstructions)
      ..writeByte(1)
      ..write(obj.temperature);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiCharacterParametersModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
