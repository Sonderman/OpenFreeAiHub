import 'package:freeaihub/core/models/ai/ai_character_model.dart';
import 'package:freeaihub/core/models/chat/chat_session_model.dart';
import 'package:freeaihub/core/models/chat/image_data_model.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:freeaihub/core/models/library/media_item.dart';
import 'package:hive_ce/hive.dart';

@GenerateAdapters([
  // Chat
  AdapterSpec<ChatSession>(),
  AdapterSpec<ImageData>(),
  AdapterSpec<Message>(),
  AdapterSpec<MessageAuthor>(),
  AdapterSpec<MessageType>(),
  AdapterSpec<AuthorType>(),
  // Media
  AdapterSpec<MediaItem>(),
  AdapterSpec<MediaSource>(),
  AdapterSpec<MediaType>(),
  AdapterSpec<ImageDimensions>(),
  // AiCharacter
  AdapterSpec<AiCharacterModel>(),
  AdapterSpec<AiCharacterParametersModel>(),
])
part 'hive_adapters.g.dart';
