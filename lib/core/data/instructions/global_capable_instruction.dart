import 'dart:convert';
import 'package:freeaihub/core/data/model_definisions.dart';
import 'package:freeaihub/core/models/ai/ai_character_model.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';

/// Constants for instruction formatting
class InstructionConstants {
  static const String sectionSeparator = "====";
  static const String reasoningActivation = "detailed thinking on";
  static const String defaultResolution = "1024x1024";
  static const String defaultRegion = "us-en";

  // Core capabilities
  static const List<String> baseCoreCapabilities = [
    "- You can analyze and process text content with high accuracy",
    "- You can assist with coding, technical questions, and problem-solving",
    "- You can provide educational support and explanations on various topics",
  ];

  // Base rules that apply to all models
  static const List<String> baseRules = [
    "- Always provide clear, accurate and helpful responses",
    "- Be concise yet comprehensive in your explanations",
    "- Ask for clarification when user requests are ambiguous",
    "- Maintain a helpful and professional tone throughout conversations",
    "- Never show tool call arguments in the response parameter",
  ];

  // Common rules for all models
  static const List<String> commonRules = [
    "- For coding questions, provide complete, well-commented examples",
    "- Always cite sources when providing factual information",
    "- Admit when you're uncertain about something rather than guessing",
  ];
}

/// Configuration for tool definitions
class ToolDefinitions {
  /// Available resolutions for image generation
  static const List<String> imageResolutionsHidream = [
    "1360x768",
    "1248x832",
    "1168x880",
    "1024x1024",
    "880x1168",
    "832x1248",
    "768x1360",
  ];
  static const List<String> imageResolutionsPollinations = [
    "512x512",
    "768x768",
    "1024x768",
    "1024x1024",
    "768x1024",
  ];

  /// Search regions for web search (consolidated into groups for better maintainability)
  static const Map<String, List<String>> searchRegionGroups = {
    'english_primary': ['us-en', 'uk-en', 'au-en', 'ca-en', 'nz-en'],
    'european': ['de-de', 'fr-fr', 'es-es', 'it-it', 'nl-nl', 'se-sv'],
    'asian': ['jp-jp', 'kr-kr', 'cn-zh', 'tw-tzh', 'hk-tzh'],
    'multilingual': ['in-en', 'sg-en', 'za-en', 'ie-en'],
  };

  /// Get all search regions as a flat list
  static List<String> get allSearchRegions {
    return searchRegionGroups.values.expand((regions) => regions).toList()..addAll([
      "ar-es",
      "at-de",
      "be-fr",
      "be-nl",
      "br-pt",
      "bg-bg",
      "ca-fr",
      "ct-ca",
      "cl-es",
      "co-es",
      "hr-hr",
      "cz-cs",
      "dk-da",
      "ee-et",
      "fi-fi",
      "gr-el",
      "hu-hu",
      "is-is",
      "id-en",
      "il-en",
      "lv-lv",
      "lt-lt",
      "my-en",
      "mx-es",
      "no-no",
      "pk-en",
      "pe-es",
      "ph-en",
      "pl-pl",
      "pt-pt",
      "ro-ro",
      "ru-ru",
      "xa-ar",
      "sk-sk",
      "sl-sl",
      "es-ca",
      "ch-de",
      "ch-fr",
      "th-en",
      "tr-tr",
      "us-es",
      "ua-uk",
      "vn-en",
      "wt-wt",
    ]);
  }

  /// Create image generation tool definition
  static Map<String, dynamic> createImageGenerationToolHidream() {
    return {
      "type": "function",
      "function": {
        "name": "image_generation",
        "description": "Generate an image based on the prompt provided by the user",
        "strict": true,
        "parameters": {
          "type": "object",
          "properties": {
            "prompt": {
              "type": "string",
              "description":
                  "The detailed prompt for image generator ai model to generate the image with. The prompt must be in English language.",
            },
            "resolution": {
              "type": "string",
              "description":
                  "The resolution of the image to generate. Choose from the following appropriate options: ${imageResolutionsHidream.join(', ')}. The default resolution is ${InstructionConstants.defaultResolution}. 768x1360 is landscape and 1360x768 is portrait.",
              "enum": imageResolutionsHidream,
            },
          },
          "required": ["prompt", "resolution"],
        },
      },
    };
  }

  static Map<String, dynamic> createImageGenerationToolPollinations() {
    return {
      "type": "function",
      "function": {
        "name": "image_generation",
        "description": "Generate an image based on the prompt provided by the user",
        "strict": true,
        "parameters": {
          "type": "object",
          "properties": {
            "prompt": {
              "type": "string",
              "description":
                  "The detailed prompt for image generator ai model to generate the image with. The prompt must be in English language.",
            },
            "resolution": {
              "type": "string",
              "description":
                  "The resolution of the image to generate. Choose from the following appropriate options: ${imageResolutionsPollinations.join(', ')}. The default resolution is ${InstructionConstants.defaultResolution}.",
              "enum": imageResolutionsPollinations,
            },
          },
          "required": ["prompt", "resolution"],
        },
      },
    };
  }

  /// Create web search tool definition
  static Map<String, dynamic> createWebSearchTool() {
    return {
      "type": "function",
      "function": {
        "name": "web_search",
        "description": "Search the web for up-to-date information on any topic",
        "strict": true,
        "parameters": {
          "type": "object",
          "properties": {
            "search_query": {
              "type": "string",
              "description":
                  "The search query to find information about. Be specific and include relevant keywords for better results.",
            },
            "region": {
              "type": "string",
              "description":
                  "The region code for search localization. Choose the most appropriate region based on the query language and user needs. Default is '${InstructionConstants.defaultRegion}' for global/English content.",
              "enum": allSearchRegions,
            },
          },
          "required": ["search_query", "region"],
        },
      },
    };
  }
}

/// Example templates for tool outputs
class ToolExamples {
  static const String imageGenerationExample = '''
EXAMPLE OUTPUT FOR IMAGE_GENERATION:
{
  "response": "I'll generate a beautiful landscape image for you. Creating a serene mountain scene with a lake and vibrant sunset colors.",
  "tool_call": {
    "name": "image_generation",
    "arguments": {
      "prompt": "A serene mountain landscape with a crystal clear lake reflecting snow-capped peaks, vibrant sunset with orange and pink hues in the sky, pine trees along the shoreline, photorealistic, highly detailed, 8K resolution",
      "resolution": "1360x768"
    }
  }
}''';

  static const String webSearchExample = '''
EXAMPLE OUTPUT FOR WEB_SEARCH:
{
  "response": "I'll search for the latest information about Flutter 3.24 features and updates for you.",
  "tool_call": {
    "name": "web_search",
    "arguments": {
      "search_query": "Flutter 3.24 new feature updates 2024",
      "region": "us-en"
    }
  }
}''';
}

/// Generates the JSON schema for tool call responses.
class ToolResponseSchema {
  /// Generates the JSON schema for the response format, including tool definitions.
  static Map<String, dynamic> generate() {
    // Get tool definitions
    final imageGenerationTool = ToolDefinitions.createImageGenerationToolPollinations();
    final webSearchTool = ToolDefinitions.createWebSearchTool();

    // Extract argument schemas from tool definitions
    final imageGenerationArgs = imageGenerationTool['function']?['parameters'];
    final webSearchArgs = webSearchTool['function']?['parameters'];

    return {
      "type": "json_object",
      "schema": {
        "type": "object",
        "properties": {
          "response": {
            "type": "string",
            "description":
                "A conversational response to the user. This can be a simple text response or an explanation of what the tool will do.",
          },
          "tool_call": {
            "description":
                "An optional tool call to be executed if necessary to fulfill the user's request.",
            "oneOf": [
              {
                "type": "object",
                "properties": {
                  "name": {"const": "image_generation"},
                  "arguments": imageGenerationArgs,
                },
                "required": ["name", "arguments"],
              },
              {
                "type": "object",
                "properties": {
                  "name": {"const": "web_search"},
                  "arguments": webSearchArgs,
                },
                "required": ["name", "arguments"],
              },
            ],
          },
        },
        "required": ["response"],
      },
    };
  }
}

/// Generates comprehensive system instructions for AI models with various capabilities
///
/// This function creates context-aware instructions that adapt based on:
/// - Model features (reasoning, vision, multimodal capabilities)
/// - User preferences (language, custom instructions)
/// - Available tools and capabilities
String globalCapableSystemInstruction({
  required AIModel model,
  required String datetime,
  AiCharacterModel? character,
  String? preferredLanguage,
  required String userName,
  List<String>? tools,
}) {
  final instructionBuilder = InstructionBuilder(
    model: model,
    datetime: datetime,
    character: character,
    preferredLanguage: preferredLanguage,
    userName: userName,
    tools: tools,
  );

  return instructionBuilder.build();
}

/// Builder class for creating system instructions
class InstructionBuilder {
  final AIModel model;
  final String datetime;
  final AiCharacterModel? character;
  final String? preferredLanguage;
  final String userName;
  final List<String>? tools;
  final StringBuffer _buffer = StringBuffer();

  InstructionBuilder({
    required this.model,
    required this.datetime,
    this.character,
    this.preferredLanguage,
    required this.userName,
    this.tools,
  });

  /// Build the complete instruction string
  String build() {
    _addReasoningModeActivation();
    _addCoreIdentity();
    _addCapabilities();
    _addRulesAndGuidelines();
    _addToolInstructions();
    _addResponseFormatting();
    _addCustomInstructions();
    _addLanguagePreferences();
    _addContextInformation();

    return _buffer.toString();
  }

  /// Add section separator
  void _addSectionSeparator() {
    _buffer.writeln(InstructionConstants.sectionSeparator);
    _buffer.writeln();
  }

  /// Add reasoning mode activation for supported models
  void _addReasoningModeActivation() {
    if (_shouldActivateReasoning()) {
      _buffer.writeln(InstructionConstants.reasoningActivation);
      _buffer.writeln();
    }
  }

  /// Check if reasoning mode should be activated
  bool _shouldActivateReasoning() {
    return model.features.isReasoning &&
        model.id == ModelDefinitions.llama3_1NemotronUltraV1_253b.id;
  }

  /// Add core identity and role definition
  void _addCoreIdentity() {
    _buffer.writeln(
      "You are ${character?.name ?? model.shortName}, a highly capable AI assistant with expertise in multiple domains.",
    );
    _buffer.writeln("You will have conversations with the user named $userName.");
    _buffer.writeln();
  }

  /// Add dynamic capabilities based on model features
  void _addCapabilities() {
    _addSectionSeparator();
    _buffer.writeln("CAPABILITIES");

    final capabilities = _buildCapabilitiesList();
    capabilities.forEach(_buffer.writeln);
    _buffer.writeln();
  }

  /// Build capabilities list based on model features
  List<String> _buildCapabilitiesList() {
    final capabilities = List<String>.from(InstructionConstants.baseCoreCapabilities);

    // Add feature-specific capabilities
    final featureCapabilities = _getFeatureSpecificCapabilities();
    capabilities.addAll(featureCapabilities);

    return capabilities;
  }

  /// Get capabilities based on model features
  List<String> _getFeatureSpecificCapabilities() {
    final capabilities = <String>[];

    if (_hasImageGeneration()) {
      capabilities.add("- You can generate high-quality images based on text prompts");
    }

    if (model.features.isVision) {
      capabilities.addAll([
        "- You can analyze and understand images provided by users",
        //"- You can edit and enhance existing images while maintaining original intent",
        "- You can extract text from images and describe visual content in detail",
      ]);
    }

    if (model.features.isMultimodal) {
      capabilities.add(
        "- You can process and understand multiple types of input simultaneously (text, images,video, audio, etc.)",
      );
    }

    if (_hasWebSearch()) {
      capabilities.add("- You can perform web searches to find up-to-date information");
    }

    if (model.features.canGenerateVoice) {
      capabilities.add("- You can generate natural-sounding speech from text input");
    }

    if (model.features.isReasoning) {
      capabilities.addAll([
        "- You can engage in complex reasoning and step-by-step problem solving",
        "- You can show your thinking process when working through difficult problems",
      ]);
    }

    return capabilities;
  }

  /// Add comprehensive rules and guidelines
  void _addRulesAndGuidelines() {
    _addSectionSeparator();
    _buffer.writeln("RULES");

    final rules = _buildRulesList();
    rules.forEach(_buffer.writeln);
    _buffer.writeln();

    _addSafetyGuidelines();
  }

  /// Build rules list based on model features
  List<String> _buildRulesList() {
    final rules = List<String>.from(InstructionConstants.baseRules);

    // Add feature-specific rules
    final featureRules = _getFeatureSpecificRules();
    rules.addAll(featureRules);

    // Add common rules
    rules.addAll(InstructionConstants.commonRules);

    return rules;
  }

  /// Get rules based on model features
  List<String> _getFeatureSpecificRules() {
    final rules = <String>[];

    if (_hasImageGeneration()) {
      rules.addAll([
        "- When generating images, ensure they are appropriate and high-quality",
        "- Create detailed, descriptive English prompts for image generation",
        "- Consider aspect ratios and resolution requirements carefully",
        "- When generating images, always generate tool_call arguments in English language",
      ]);
    } else if (tools != null &&
        !(tools!.contains('image_generation')) &&
        (model.features.canGenerateImage || model.features.toolCapabilities.imageGeneration)) {
      // Model supports image generation, but tool is disabled for this session
      rules.add(
        "- Image generation is DISABLED for this session. Do NOT claim you can generate images or offer image generation unless the user enables it.",
      );
    }

    if (model.features.isVision) {
      rules.addAll([
        "- When editing images, maintain the original intent while improving quality",
        "- Provide detailed descriptions of visual content when analyzing images",
        "- Be specific about what you observe in images",
      ]);
    }

    if (_hasWebSearch()) {
      rules.addAll([
        "- For web searches, verify information from multiple sources when possible",
        "- When user asks for current information requiring web search, do not make assumptions in the response parameter - instead indicate that a web search is needed to provide accurate information",
      ]);
    } else if (tools != null &&
        !(tools!.contains('web_search')) &&
        model.features.toolCapabilities.webSearch) {
      // Model supports web search, but tool is disabled for this session
      rules.add(
        "- Web search is DISABLED for this session. Do NOT claim you can perform web searches or offer web search unless the user enables it.",
      );
    }

    if (model.features.isReasoning) {
      rules.addAll([
        "- Show your reasoning process for complex problems",
        "- Break down multi-step problems into clear, logical steps",
      ]);
    }

    return rules;
  }

  /// Add comprehensive safety guidelines
  void _addSafetyGuidelines() {
    _buffer.writeln("SAFETY & ETHICAL GUIDELINES");
    _buffer.writeln(
      "You must never provide, encourage, or assist in any harmful, illegal, unethical, or unsafe behavior.",
    );
    _buffer.writeln("This includes—but is not limited to—sharing information related to:");
    _buffer.writeln();

    const prohibitedAreas = [
      "  - Weapons manufacturing or use",
      "  - Illegal drug production or usage",
      "  - Suicide, self-harm, or harm to others",
      "  - Hacking, phishing, or cybercrime",
      "  - Medical, legal, or financial advice that could endanger someone's well-being",
      "  - Hate speech, harassment, or discrimination",
      "  - Creating false or misleading information",
      "  - Violating privacy or confidentiality",
    ];

    prohibitedAreas.forEach(_buffer.writeln);
    _buffer.writeln();
    _buffer.writeln(
      "If a user requests or implies any such content, respond firmly, respectfully decline,",
    );
    _buffer.writeln("and, if appropriate, guide them toward safe and supportive alternatives.");
    _buffer.writeln();
  }

  /// Add tool usage instructions and definitions
  void _addToolInstructions() {
    _addSectionSeparator();
    _buffer.writeln("TOOL USE");
    _buffer.writeln("- You have access to various tools to enhance your assistance capabilities");
    _buffer.writeln("- Use these tools when appropriate to provide the best possible assistance");
    _buffer.writeln(
      "- Explain what you're doing when using tools to help users understand the process",
    );
    _buffer.writeln();

    if (_hasAnyTools()) {
      _addAvailableToolsSection();
    }
  }

  /// Check if model has any tools available
  bool _hasAnyTools() {
    return _hasImageGeneration() || _hasWebSearch();
  }

  /// Add available tools section
  void _addAvailableToolsSection() {
    _addSectionSeparator();
    _buffer.writeln("AVAILABLE TOOLS");

    if (_hasImageGeneration()) {
      _addImageGenerationTool();
    }

    if (_hasWebSearch()) {
      if (_hasImageGeneration()) _buffer.writeln();
      _addWebSearchTool();
    }

    _buffer.writeln();
  }

  /// Add image generation tool definition and example
  void _addImageGenerationTool() {
    final tool = ToolDefinitions.createImageGenerationToolPollinations();
    _buffer.writeln(jsonEncode(tool));
    _buffer.writeln();
    _buffer.writeln(ToolExamples.imageGenerationExample);
  }

  /// Add web search tool definition and example
  void _addWebSearchTool() {
    final tool = ToolDefinitions.createWebSearchTool();
    _buffer.writeln(jsonEncode(tool));
    _buffer.writeln();
    _buffer.writeln(ToolExamples.webSearchExample);
  }

  /// Add response formatting guidelines
  void _addResponseFormatting() {
    _addSectionSeparator();
    _buffer.writeln("RESPONSE FORMATTING");

    const formattingRules = [
      "- Use clear, well-structured markdown for responses",
      "- Include relevant code blocks with syntax highlighting when appropriate",
      "- For images, provide detailed descriptions along with the generated content",
      "- For web search results, summarize key points with source attribution",
      "- Use proper headers, lists, and formatting to enhance readability",
      "- Always respond in JSON format with a \"response\" parameter",
      "- Use valid JSON syntax for all responses",
      "- Escape special characters properly in JSON strings",
    ];

    formattingRules.forEach(_buffer.writeln);
    _buffer.writeln();

    _addJsonFormatExamples();
  }

  /// Add JSON format examples
  void _addJsonFormatExamples() {
    _buffer.writeln("REQUIRED JSON FORMAT:");
    _buffer.writeln("For normal responses (no tool needed):");
    _buffer.writeln("{");
    _buffer.writeln('  "response": "Your markdown response here"');
    _buffer.writeln('}');
    _buffer.writeln();
    _buffer.writeln("For responses with tool calls:");
    _buffer.writeln("{");
    _buffer.writeln('  "response": "Your text explaining what you\'re doing",');
    _buffer.writeln('  "tool_call": {');
    _buffer.writeln('    "name": "tool_name",');
    _buffer.writeln('    "arguments": {');
    _buffer.writeln('      "arg1": "value1",');
    _buffer.writeln('      "arg2": "value2"');
    _buffer.writeln('    }');
    _buffer.writeln('  }');
    _buffer.writeln('}');
    _buffer.writeln();
  }

  /// Add custom user instructions if provided
  void _addCustomInstructions() {
    if (character?.parameters.customInstructions.trim().isNotEmpty == true) {
      _addSectionSeparator();
      _buffer.writeln("USER'S CUSTOM INSTRUCTIONS");
      _buffer.writeln(character?.parameters.customInstructions);
      _buffer.writeln();
    }
  }

  /// Add language preference instructions
  void _addLanguagePreferences() {
    _addSectionSeparator();
    _buffer.writeln("PREFERRED LANGUAGE");
    _buffer.writeln(
      "- Always response in ${preferredLanguage ?? 'the language of the user\'s input'}",
    );
    _buffer.writeln("- Maintain consistency in language choice throughout the conversation");
    _buffer.writeln("- If unsure about language preference, ask the user for clarification");
    _buffer.writeln();
  }

  /// Add current context information
  void _addContextInformation() {
    _addSectionSeparator();
    _buffer.writeln("CURRENT DATE AND TIME: $datetime");
  }

  /// Check if image generation tool is available (explicit tools list has priority over model capability flags)
  bool _hasImageGeneration() {
    // Respect explicit tools list if provided
    if (tools != null) {
      return tools!.contains('image_generation');
    }
    // Fallback to model feature flags
    return model.features.canGenerateImage || model.features.toolCapabilities.imageGeneration;
  }

  /// Check if web search tool is available (explicit tools list has priority over model capability flags)
  bool _hasWebSearch() {
    // Respect explicit tools list if provided
    if (tools != null) {
      return tools!.contains('web_search');
    }
    // Fallback to model feature flags
    return model.features.toolCapabilities.webSearch;
  }
}
