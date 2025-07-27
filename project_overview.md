# Project Overview: FreeAI Hub

This project, FreeAI Hub, is a Flutter application designed to provide users with access to a wide variety of AI functionalities. It leverages a modular architecture with a clear separation of concerns, utilizing GetX for state management and dependency injection.

## Key Features

- **Advanced AI Chat:** An interactive and feature-rich chat interface for communicating with various AI models. It provides visual feedback for AI states like thinking (`ThinkBlockWidget`) and typing (`TypingDotsWidget`), all managed by a robust `ChatController`.
- **Versatile Image Generation:** Tools for creating images from text prompts (`Text-to-Image`) and other images (`Image-to-Image`) using different AI models like `Hidream`. It offers advanced controls over the generation process, including image size, seed, guidance scale, and inference steps.
- **High-Quality Audio Generation:** A Text-to-Speech (TTS) feature powered by `Orpheus` that allows users to generate speech from text. It includes multiple voice options, adjustable parameters like temperature and repetition penalty, and supports paralinguistic cues (e.g., `<laugh>`, `<sigh>`) for more natural-sounding audio.
- **Custom AI Characters:** A dedicated section allowing users to create, manage, and interact with their own AI characters. Users can define a character's name, description, personality (via custom instructions), and creativity level (temperature).
- **Centralized Library:** A library hub to access user-created content. It provides entry points to `My AI Characters`, `My Medias`, and a planned `My Prompts` section.
- **Media Management:** A local media library to view, manage, and share images and audio files generated within the app.
- **Dynamic Theming:** Light and dark mode support with theme customization options.

## Screens Overview

The application is composed of several main screens, each serving a specific purpose:

- **`SplashView`**: A branded splash screen that greets the user, highlights core benefits (no account / no credits required) and shows loading progress while the app initializes.
- **`HomeView`**: The central dashboard with a `TabBarView` that toggles between:
   • **`AiModelsView`** – lists available AI models and recently opened chat sessions.
   • **`LibraryView`** – quick-access hub for user-generated content (AI characters, medias, and—soon—prompts).
- **`ChatView`**: Full-featured conversational interface for interacting with any AI model.
- **`HidreamView` & `PollinationsView`**: Powerful image-generation workspaces supporting both Text-to-Image and Image-to-Image pipelines, advanced prompt enhancement, seed control, safe-mode toggles, etc.
- **`OrpheusView`**: Text-to-Speech studio offering multiple voices, paralinguistic tags, temperature / repetition controls, and in-app playback, save, and share options.
- **`AiCharactersView`** and **`CreateAiCharacterView`**: Management UI for user-defined AI personas (create, edit, delete, persist via Hive).
- **`MediaLibraryView`**: Grid-based gallery that automatically collects generated images/audio and allows viewing, sharing, and navigation back to the generator.
- **`PreferencesView`**: Comprehensive settings area where users can set their display name, chat language, theme mode (light/dark/system), and color scheme.
- **`WelcomePreferencesView`**: An onboarding version of the preferences screen shown on first launch, guiding the user through essential setup.
- **`OfflineView`**: A fallback screen displayed when no internet connection is detected, offering retry and exit options.

## Architecture & Tech Stack

- **State Management:** `get`
- **Local Storage:** `get_storage`, `hive_ce`
- **UI:** `sizer`, `flex_color_scheme`, `flutter_html`, `auto_size_text` and various custom components.
- **Networking:** `dio` for HTTP requests.
- **Media Handling:** `just_audio`, `audio_waveforms`, `image_picker`, `image_gallery_saver_plus` for handling various media types.
- **File Handling:** `universal_file_viewer`, `file_picker`, `syncfusion_flutter_pdf` for document and file management.
- **AI & Markdown:** `gpt_markdown`, `tiktoken_tokenizer_gpt4o_o1` for processing and displaying AI-generated content.

The project is structured into several key directories:
- `lib/core`: Contains the core logic, including global services, models, data handling, and utility functions.
- `lib/screens`: Houses the UI for different features of the application, such as chat, image generation, and the media library.
- `lib/main.dart`: The entry point of the application.

The application version is now **`0.1.0`**.

