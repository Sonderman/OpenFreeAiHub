import 'dart:math';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/enums.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/models/api/api_model.dart';
import '../../env.dart';

class ModelDefinitions {
  static final Map<String, AIModel> availableModels = {
    "pollinations_ai_chat_gpt4_1": pollinationsAiChatGpt4_1,
    //"pollinations_ai_chat_gpt4_1_mini": pollinationsAiChatGpt4_1Mini,
    "pollinations_ai_chat_gpt4o": pollinationsAiChatGpt4o,
    "pollinations_ai_openai_4o_mini": pollinationsAiOpenai4oMini,
    "pollinations_ai_deepseek_v3": pollinationsAiDeepseekV3,
    "pollinations_ai_deepseek_r1": pollinationsAiDeepseekR1,
    "pollinations_ai_mistral_small_3_1_24b_instruct": pollinationsAiMistral_3_1_24b,
    "pollinations_ai_grok3_mini": pollinationsAiGrok3Mini,
    //"deepseekv3_0324": deepseekv3_0324,
    //"deepseekr1_0528": deepseekr1_0528,
    //"deepseekr1": deepseekr1,
    //"minimax_m1_80k": minimaxM1,
    //"qwen3_235b_a22b": qwen3_235bA22b,
    //"llama_3_1_nemotron_ultra_v1_253b": llama3_1NemotronUltraV1_253b,
    //"llama_4_maverick": llama4Maverick,
    //"qwen2.5_vl_32b_instruct": qwen2_5Vl_32bInstruct,
    "gemma_3_27b": gemma_3_27b,
    //"mistral_small_3.2_24b_instruct_2506": mistralSmall_3_2_24bInstruct_2506,
    //"hidream": hidreamI1,
    "pollinations_ai_image": pollinationsAiImage,
    //"orpheus_tts": orpheusTts,
  };

  // Chat Models

  static AIModel get deepseekv3_0324 => AIModel(
    id: "deepseekv3_0324",
    name: "Deepseek Chat V3-0324",
    shortName: "Deepseek Chat",
    description:
        '''DeepSeek V3, a 685B-parameter, mixture-of-experts model, is the latest iteration of the flagship chat model family from the DeepSeek team.It succeeds the DeepSeek V3 model and performs really well on a variety of tasks.''',
    category: CategoryTypes.chat,
    maxTokens: 163840,
    maxOutputTokens: 163840,
    urlIcon: null,
    assetIcon: "assets/model/deepseekv3.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: false,
      isMultimodal: false,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.chutes,
      baseURL: chutesBaseURL,
      apiKey: chutesApiKey,
      headers: {"Authorization": "Bearer $chutesApiKey", "Content-Type": "application/json"},
      modelName: "deepseek-ai/DeepSeek-V3-0324",
    ),
  );
  static AIModel get deepseekr1_0528 => AIModel(
    id: "deepseekr1_0528",
    name: "Deepseek R1 0528",
    shortName: "Deepseek R1 0528",
    description:
        '''DeepSeek R1 (Updated Version) is Performance on par with OpenAI o1, but open-sourced and with fully open reasoning tokens. It's 671B parameters in size, with 37B active in an inference pass.''',
    category: CategoryTypes.chat,
    maxTokens: 163840,
    maxOutputTokens: 163840,
    urlIcon: null,
    assetIcon: "assets/model/deepseekv3.png",
    features: FeaturesModel(
      isReasoning: true,
      isVision: false,
      isMultimodal: false,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.chutes,
      baseURL: chutesBaseURL,
      apiKey: chutesApiKey,
      modelName: "deepseek-ai/DeepSeek-R1-0528",
    ),
  );
  static AIModel get deepseekr1 => AIModel(
    id: "deepseekr1",
    name: "Deepseek R1",
    shortName: "Deepseek R1",
    description:
        '''DeepSeek R1 is Performance on par with OpenAI o1, but open-sourced and with fully open reasoning tokens. It's 671B parameters in size, with 37B active in an inference pass.''',
    category: CategoryTypes.chat,
    maxTokens: 163840,
    maxOutputTokens: 163840,
    urlIcon: null,
    assetIcon: "assets/model/deepseekv3.png",
    features: FeaturesModel(
      isReasoning: true,
      isVision: false,
      isMultimodal: false,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.chutes,
      baseURL: chutesBaseURL,
      apiKey: chutesApiKey,
      modelName: "deepseek-ai/DeepSeek-R1",
    ),
  );
  static AIModel get mistralSmall_3_2_24bInstruct_2506 => AIModel(
    id: "mistral_small_3.2_24b_instruct_2506",
    name: "Mistral Small 3.2 24B Instruct 2506",
    shortName: "Mistral Small 24B",
    description:
        '''Mistral-Small-3.2-24B-Instruct-2506 is an updated 24B parameter model from Mistral optimized for instruction following, repetition reduction, and improved function calling. Compared to the 3.1 release, version 3.2 significantly improves accuracy on WildBench and Arena Hard, reduces infinite generations, and delivers gains in tool use and structured output tasks.
        It supports image and text inputs with structured outputs, function/tool calling, and strong performance across coding (HumanEval+, MBPP), STEM (MMLU, MATH, GPQA), and vision benchmarks (ChartQA, DocVQA).''',
    category: CategoryTypes.chat,
    maxTokens: 96000,
    maxOutputTokens: 96000,
    urlIcon: null,
    assetIcon: "assets/model/mistral.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: true,
      isMultimodal: true,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.chutes,
      baseURL: chutesBaseURL,
      apiKey: chutesApiKey,
      headers: {"Authorization": "Bearer $chutesApiKey", "Content-Type": "application/json"},
      modelName: "chutesai/Mistral-Small-3.2-24B-Instruct-2506",
    ),
  );
  static AIModel get llama4Maverick => AIModel(
    id: "llama_4_maverick",
    name: "Llama 4 Maverick 17B",
    shortName: "Llama 4 Maverick",
    description:
        '''Llama 4 Maverick 17B Instruct (128E) is a high-capacity multimodal language model from Meta, built on a mixture-of-experts (MoE) architecture with 128 experts and 17 billion active parameters per forward pass (400B total). It supports multilingual text and image input, and produces multilingual text and code output across 12 supported languages. Optimized for vision-language tasks, Maverick is instruction-tuned for assistant-like behavior, image reasoning, and general-purpose multimodal interaction. Maverick features early fusion for native multimodality and a 1 million token context window. It was trained on a curated mixture of public, licensed, and Meta-platform data, covering ~22 trillion tokens, with a knowledge cutoff in August 2024. Released on April 5, 2025 under the Llama 4 Community License, Maverick is suited for research and commercial applications requiring advanced multimodal understanding and high model throughput.''',
    category: CategoryTypes.chat,
    urlIcon: null,
    maxTokens: 128000,
    maxOutputTokens: 128000,
    assetIcon: "assets/model/llama_maverick.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: true,
      isMultimodal: true,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.chutes,
      baseURL: chutesBaseURL,
      apiKey: chutesApiKey,
      modelName: "chutesai/Llama-4-Maverick-17B-128E-Instruct-FP8",
    ),
  );
  static AIModel get qwen3_235bA22b => AIModel(
    id: "qwen3_235b_a22b",
    name: "Qwen3 235B A22B",
    shortName: "Qwen3 235B A22B",
    description:
        '''Qwen3-235B-A22B is a 235B parameter mixture-of-experts (MoE) model developed by Qwen, activating 22B parameters per forward pass. It supports seamless switching between a "thinking" mode for complex reasoning, math, and code tasks, and a "non-thinking" mode for general conversational efficiency. The model demonstrates strong reasoning ability, multilingual support (100+ languages and dialects), advanced instruction-following, and agent tool-calling capabilities. It natively handles a 32K token context window and extends up to 131K tokens using YaRN-based scaling.''',
    category: CategoryTypes.chat,
    urlIcon: null,
    maxTokens: 40960,
    maxOutputTokens: 40960,
    assetIcon: "assets/model/qwen.png",
    features: FeaturesModel(
      isReasoning: true,
      isVision: false,
      isMultimodal: false,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.chutes,
      baseURL: chutesBaseURL,
      headers: {"Authorization": "Bearer $chutesApiKey", "Content-Type": "application/json"},
      apiKey: chutesApiKey,
      modelName: "Qwen/Qwen3-235B-A22B",
      //shouldUseHttps: true,
    ),
  );
  static AIModel get qwen2_5Vl_32bInstruct => AIModel(
    id: "qwen2.5_vl_32b_instruct",
    name: "Qwen2.5 VL 32B Instruct",
    shortName: "Qwen2.5 VL 32B",
    description:
        '''Qwen2.5-VL-32B is a multimodal vision-language model fine-tuned through reinforcement learning for enhanced mathematical reasoning, structured outputs, and visual problem-solving capabilities. It excels at visual analysis tasks, including object recognition, textual interpretation within images, and precise event localization in extended videos. Qwen2.5-VL-32B demonstrates state-of-the-art performance across multimodal benchmarks such as MMMU, MathVista, and VideoMME, while maintaining strong reasoning and clarity in text-based tasks like MMLU, mathematical problem-solving, and code generation.''',
    category: CategoryTypes.chat,
    maxTokens: 128000,
    maxOutputTokens: 128000,
    urlIcon: null,
    assetIcon: "assets/model/qwen.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: true,
      isMultimodal: true,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.chutes,
      baseURL: chutesBaseURL,
      apiKey: chutesApiKey,
      modelName: "Qwen/Qwen2.5-VL-32B-Instruct",
    ),
  );
  static AIModel get llama3_1NemotronUltraV1_253b => AIModel(
    id: "llama_3_1_nemotron_ultra_v1_253b",
    name: "Llama 3.1 Nemotron Ultra V1 253B",
    shortName: "Nemotron Ultra V1",
    description:
        '''Llama-3.1-Nemotron-Ultra-253B-v1 is a large language model (LLM) which is a derivative of Meta Llama-3.1-405B-Instruct (AKA the reference model). It is a reasoning model that is post trained for reasoning, human chat preferences, and tasks, such as RAG and tool calling. The model supports a context length of 128K tokens. This model fits on a single 8xH100 node for inference.''',
    category: CategoryTypes.chat,
    urlIcon: null,
    maxTokens: 131072,
    maxOutputTokens: 131072,
    assetIcon: "assets/model/nvidia.png",
    features: FeaturesModel(
      isReasoning: true,
      isVision: false,
      isMultimodal: false,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.chutes,
      baseURL: chutesBaseURL,
      apiKey: chutesApiKey,
      modelName: "nvidia/Llama-3_1-Nemotron-Ultra-253B-v1",
    ),
  );
  static AIModel get gemma_3_27b => AIModel(
    id: "gemma_3_27b",
    name: "Gemma 3 27B Instruct",
    shortName: "Gemma 3 27B",
    description:
        '''Gemma 3 introduces multimodality, supporting vision-language input and text outputs. It handles context windows up to 128k tokens, understands over 140 languages, and offers improved math, reasoning, and chat capabilities, including structured outputs and function calling. Gemma 3 27B is Google's latest open source model, successor to Gemma 2''',
    category: CategoryTypes.chat,
    maxTokens: 131072,
    maxOutputTokens: 8192,
    urlIcon: null,
    assetIcon: "assets/model/gemma.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: true,
      isMultimodal: true,
      canGenerateImage: false,
      //supportsResponseFormat: true,
      //toolCapabilities: ToolCapabilities(imageGeneration: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.google,
      baseURL: googleBaseURL,
      apiKey: googleApiKeys[Random().nextInt(googleApiKeys.length)],
      headers: {
        "Authorization": "Bearer ${googleApiKeys[Random().nextInt(googleApiKeys.length)]}",
        "Content-Type": "application/json",
      },
      modelName: "gemma-3-27b-it",
    ),
  );
  static AIModel get minimaxM1 => AIModel(
    id: "minimax_m1_80k",
    name: "Minimax M1",
    shortName: "Minimax M1",
    description:
        '''MiniMax-M1 is a large-scale, open-weight reasoning model designed for extended context and high-efficiency inference. It leverages a hybrid Mixture-of-Experts (MoE) architecture paired with a custom "lightning attention" mechanism, allowing it to process long sequences—up to 1 million tokens—while maintaining competitive FLOP efficiency. With 456 billion total parameters and 45.9B active per token, this variant is optimized for complex, multi-step reasoning tasks.

        Trained via a custom reinforcement learning pipeline (CISPO), M1 excels in long-context understanding, software engineering, agentic tool use, and mathematical reasoning. Benchmarks show strong performance across FullStackBench, SWE-bench, MATH, GPQA, and TAU-Bench, often outperforming other open models like DeepSeek R1 and Qwen3-235B.''',
    category: CategoryTypes.chat,
    maxTokens: 512000,
    maxOutputTokens: 80000,
    assetIcon: "assets/model/minimax.png",
    features: FeaturesModel(
      isReasoning: true,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.chutes,
      baseURL: chutesBaseURL,
      apiKey: chutesApiKey,
      modelName: "MiniMaxAI/MiniMax-M1-80k",
    ),
  );

  //Pollinations AI Chat Models
  static AIModel get pollinationsAiChatGpt4_1 => AIModel(
    id: "pollinations_ai_chat_gpt4_1",
    name: "GPT 4.1",
    shortName: "GPT 4.1",
    description:
        '''GPT-4.1 is a flagship large language model optimized for advanced instruction following, real-world software engineering, and long-context reasoning. It supports a 1 million token context window and outperforms GPT-4o and GPT-4.5 across coding (54.6% SWE-bench Verified), instruction compliance (87.4% IFEval), and multimodal understanding benchmarks. It is tuned for precise code diffs, agent reliability, and high recall in large document contexts, making it ideal for agents, IDE tooling, and enterprise knowledge retrieval.''',
    category: CategoryTypes.chat,
    maxTokens: 9000,
    maxOutputTokens: 9000,
    urlIcon: null,
    assetIcon: "assets/model/openai.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: true,
      isMultimodal: true,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.pollinations,
      baseURL: "https://text.pollinations.ai/openai",
      headers: {
        "Authorization": "Bearer $pollinationsApiKey",
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
      },
      apiKey: pollinationsApiKey,
      modelName: "gpt-4.1",
    ),
    decorations: ModelDecorations(backgroundColor: Color(0xFF181818), textColor: Colors.white),
  );
  /*static AIModel get pollinationsAiChatGpt4_1Mini => AIModel(
    id: "pollinations_ai_chat_gpt4_1_mini",
    name: "Chat GPT 4.1 Mini",
    shortName: "Chat GPT 4.1 Mini",
    description:
        '''GPT-4.1 Mini is a mid-sized model delivering performance competitive with GPT-4o at substantially lower latency and cost. It retains a 1 million token context window and scores 45.1% on hard instruction evals, 35.8% on MultiChallenge, and 84.1% on IFEval. Mini also shows strong coding ability (e.g., 31.6% on Aider’s polyglot diff benchmark) and vision understanding, making it suitable for interactive applications with tight performance constraints.''',
    category: CategoryTypes.chat,
    maxTokens: 1000000,
    maxOutputTokens: 32000,
    urlIcon: null,
    assetIcon: "assets/model/openai.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: true,
      isMultimodal: true,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.pollinations,
      baseURL: "https://text.pollinations.ai/openai",
      headers: {
        "Authorization": "Bearer $pollinationsApiKey",
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
      },
      apiKey: pollinationsApiKey,
      modelName: "openai",
    ),
    decorations: ModelDecorations(backgroundColor: Color(0xFF181818), textColor: Colors.white),
  );*/
  static AIModel get pollinationsAiChatGpt4o => AIModel(
    id: "pollinations_ai_chat_gpt4o",
    name: "GPT 4o",
    shortName: "GPT 4o",
    description:
        '''GPT-4o is a large language model optimized for advanced instruction following, real-world software engineering, and long-context reasoning. It supports a 1 million token context window and outperforms GPT-4.5 across coding (54.6% SWE-bench Verified), instruction compliance (87.4% IFEval), and multimodal understanding benchmarks. It is tuned for precise code diffs, agent reliability, and high recall in large document contexts, making it ideal for agents, IDE tooling, and enterprise knowledge retrieval.''',
    category: CategoryTypes.chat,
    maxTokens: 1000000,
    maxOutputTokens: 32000,
    urlIcon: null,
    assetIcon: "assets/model/openai.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: true,
      isMultimodal: true,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.pollinations,
      baseURL: "https://text.pollinations.ai/openai",
      headers: {
        "Authorization": "Bearer $pollinationsApiKey",
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
      },
      apiKey: pollinationsApiKey,
      modelName: "gpt-4o-mini",
    ),
    decorations: ModelDecorations(backgroundColor: Color(0xFF181818), textColor: Colors.white),
  );
  static AIModel get pollinationsAiOpenai4oMini => AIModel(
    id: "pollinations_ai_openai_4o_mini",
    name: "4o Mini",
    shortName: "4o Mini",
    description:
        '''OpenAI o4-mini is a compact reasoning model in the o-series, optimized for fast, cost-efficient performance while retaining strong multimodal and agentic capabilities. It supports tool use and demonstrates competitive reasoning and coding performance across benchmarks like AIME (99.5% with Python) and SWE-bench, outperforming its predecessor o3-mini and even approaching o3 in some domains.''',
    category: CategoryTypes.chat,
    maxTokens: 200000,
    maxOutputTokens: 100000,
    urlIcon: null,
    assetIcon: "assets/model/openai.png",
    features: FeaturesModel(
      isReasoning: true,
      isVision: true,
      isMultimodal: true,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.pollinations,
      baseURL: "https://text.pollinations.ai/openai",
      headers: {
        "Authorization": "Bearer $pollinationsApiKey",
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
      },
      apiKey: pollinationsApiKey,
      modelName: "gpt-4o-mini",
    ),
    decorations: ModelDecorations(backgroundColor: Color(0xFF181818), textColor: Colors.white),
  );
  static AIModel get pollinationsAiDeepseekR1 => AIModel(
    id: "pollinations_ai_deepseek_r1",
    name: "Deepseek R1",
    shortName: "Deepseek R1",
    description:
        '''DeepSeek R1 (Updated Version) is Performance on par with OpenAI o1, but open-sourced and with fully open reasoning tokens. It's 671B parameters in size, with 37B active in an inference pass.''',
    category: CategoryTypes.chat,
    maxTokens: 9000,
    maxOutputTokens: 9000,
    urlIcon: null,
    assetIcon: "assets/model/deepseekv3.png",
    features: FeaturesModel(
      isReasoning: true,
      isVision: false,
      isMultimodal: false,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.pollinations,
      baseURL: "https://text.pollinations.ai/openai",
      headers: {
        "Authorization": "Bearer $pollinationsApiKey",
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
      },
      apiKey: pollinationsApiKey,
      modelName: "deepseek-reasoning",
    ),
    //decorations: ModelDecorations(backgroundColor: Color(0xFF181818), textColor: Colors.white),
  );
  static AIModel get pollinationsAiDeepseekV3 => AIModel(
    id: "pollinations_ai_deepseek_v3",
    name: "Deepseek V3",
    shortName: "Deepseek V3",
    description:
        '''DeepSeek V3, a 685B-parameter, mixture-of-experts model, is the latest iteration of the flagship chat model family from the DeepSeek team.It succeeds the DeepSeek V3 model and performs really well on a variety of tasks.''',
    category: CategoryTypes.chat,
    maxTokens: 9000,
    maxOutputTokens: 9000,
    urlIcon: null,
    assetIcon: "assets/model/deepseekv3.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: false,
      isMultimodal: false,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.pollinations,
      baseURL: "https://text.pollinations.ai/openai",
      headers: {
        "Authorization": "Bearer $pollinationsApiKey",
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
      },
      apiKey: pollinationsApiKey,
      modelName: "deepseek-v3",
    ),
    //decorations: ModelDecorations(backgroundColor: Color(0xFF181818), textColor: Colors.white),
  );
  static AIModel get pollinationsAiMistral_3_1_24b => AIModel(
    id: "pollinations_ai_mistral_small_3_1_24b_instruct",
    name: "Mistral Small 3.1 24B",
    shortName: "Mistral Small 3.1",
    description:
        '''Mistral Small 3.1 24B Instruct is an upgraded variant of Mistral Small 3 (2501), featuring 24 billion parameters with advanced multimodal capabilities. It provides state-of-the-art performance in text-based reasoning and vision tasks, including image analysis, programming, mathematical reasoning, and multilingual support across dozens of languages. Equipped with an extensive 128k token context window and optimized for efficient local inference, it supports use cases such as conversational agents, function calling, long-document comprehension, and privacy-sensitive deployments.''',
    category: CategoryTypes.chat,
    maxTokens: 90000,
    maxOutputTokens: 90000,
    urlIcon: null,
    assetIcon: "assets/model/mistral.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: true,
      isMultimodal: true,
      canGenerateImage: false,
      supportsResponseFormat: true,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.pollinations,
      baseURL: "https://text.pollinations.ai/openai",
      headers: {
        "Authorization": "Bearer $pollinationsApiKey",
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
      },
      apiKey: pollinationsApiKey,
      modelName: "mistral",
    ),
    //decorations: ModelDecorations(backgroundColor: Color(0xFF181818), textColor: Colors.white),
  );
  static AIModel get pollinationsAiGrok3Mini => AIModel(
    id: "pollinations_ai_grok3_mini",
    name: "Grok 3 Mini",
    shortName: "Grok 3 Mini",
    description:
        '''A lightweight model that thinks before responding. Fast, smart, and great for logic-based tasks that do not require deep domain knowledge.''',
    category: CategoryTypes.chat,
    maxTokens: 131072,
    maxOutputTokens: 131072,
    urlIcon: null,
    assetIcon: "assets/model/grok.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: false,
      isMultimodal: false,
      canGenerateImage: false,
      supportsResponseFormat: false,
      toolCapabilities: ToolCapabilities(imageGeneration: true, webSearch: true),
    ),
    apiModel: ApiModel(
      provider: ApiProviders.pollinations,
      baseURL: "https://text.pollinations.ai/openai",
      headers: {
        "Authorization": "Bearer $pollinationsApiKey",
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
      },
      apiKey: pollinationsApiKey,
      modelName: "grok-3-mini",
    ),
    decorations: ModelDecorations(backgroundColor: Color(0xFF161618), textColor: Colors.white),
  );

  // Image Generation Models
  static AIModel get hidreamI1 => AIModel(
    id: "hidream",
    name: "Hidream",
    shortName: "Hidream",
    description:
        '''HiDream is a new open-source image generative foundation model with 17B parameters that achieves state-of-the-art image generation quality within seconds.''',
    category: CategoryTypes.imageGeneration,
    maxTokens: 8000,
    maxOutputTokens: 8000,
    urlIcon: null,
    assetIcon: "assets/model/hidream.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: false,
      isMultimodal: false,
      canGenerateImage: true,
    ),
    apiModel: ApiModel(
      provider: ApiProviders.chutes,
      baseURL: hidreamImageBaseUrl,
      baseURL2: hidreamEditBaseUrl,
      headers: {"Authorization": "Bearer $chutesApiKey", "Content-Type": "application/json"},
      apiKey: chutesApiKey,
      modelName: "",
    ),
  );

  static AIModel get pollinationsAiImage => AIModel(
    id: "pollinations_ai_image",
    name: "Pollinations AI Image",
    shortName: "Pollinations Image",
    description:
        '''Pollinations AI is the world's most accessible open GenAI platform offering text-to-image generation with no signup required. It provides various models including Flux, DALL-E, and other state-of-the-art image generation models with full parameter control and high-quality outputs.''',
    category: CategoryTypes.imageGeneration,
    maxTokens: 8000,
    maxOutputTokens: 8000,
    urlIcon: null,
    assetIcon: "assets/model/pollinations.png",
    features: FeaturesModel(
      isReasoning: false,
      isVision: false,
      isMultimodal: false,
      canGenerateImage: true,
    ),
    apiModel: ApiModel(
      provider: ApiProviders.pollinations,
      baseURL: "https://image.pollinations.ai",
      headers: {"Authorization": "Bearer $pollinationsApiKey", "Content-Type": "application/json"},
      apiKey: pollinationsApiKey,
      modelName: "",
    ),
  );

  // Audio Generation Models
  static AIModel get orpheusTts => AIModel(
    id: "orpheus_tts",
    name: "Orpheus TTS",
    shortName: "Orpheus",
    description:
        '''Orpheus TTS is a SOTA open-source text-to-speech system built on the Llama-3b backbone. Orpheus demonstrates the emergent capabilities of using LLMs for speech synthesis. Can generate 14 seconds long voices.''',
    category: CategoryTypes.audioGeneration,
    maxTokens: 2000,
    maxOutputTokens: 2000,
    urlIcon: null,
    assetIcon: "assets/model/orpheus_tts.png",
    features: FeaturesModel(canGenerateVoice: true),
    apiModel: ApiModel(
      provider: ApiProviders.chutes,
      baseURL: orpheusTtsBaseUrl,
      headers: {"Authorization": "Bearer $chutesApiKey", "Content-Type": "application/json"},
      apiKey: chutesApiKey,
      modelName: "",
    ),
  );
}
