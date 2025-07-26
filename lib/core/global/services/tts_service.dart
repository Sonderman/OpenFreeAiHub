import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:freeaihub/core/app_instance.dart';
import 'package:freeaihub/core/data/language_definisitons.dart';
import 'package:get/get.dart';

enum TtsState { playing, stopped, paused, continued }

class TextToSpeechService extends GetxService {
  final FlutterTts _flutterTts = FlutterTts();
  final Rx<TtsState> _ttsState = TtsState.stopped.obs;

  Rx<TtsState> get ttsState => _ttsState;

  /// Metni seslendirir.
  Future<void> speak(String text) async {
    String language = languages[appInstance.userPreferences.chatLanguage]!;
    if (await _flutterTts.isLanguageAvailable(language)) {
      await _flutterTts.setLanguage(language);
    } else {
      if (kDebugMode) {
        print("Language not available: $language");
      }
      await _flutterTts.setLanguage("en-US");
    }
    await _flutterTts.speak(text, focus: true);
  }

  /// Konuşmayı durdurur.
  Future<void> stop() async {
    await _flutterTts.stop();
    _ttsState.value = TtsState.stopped;
  }

  /// Konuşma hızını ayarlar (0.5 ile 1.5 arasında değerler önerilir).
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// Konuşma dilini ayarlar (örneğin, "tr-TR" veya "en-US").
  Future<void> setLanguage(String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
  }

  /// Servisi başlatırken varsayılan ayarları yapar.
  Future<TextToSpeechService> initialize() async {
    String language = languages[appInstance.userPreferences.chatLanguage]!;
    if (await _flutterTts.isLanguageAvailable(language)) {
      await _flutterTts.setLanguage(language);
    } else {
      if (kDebugMode) {
        print("Language not available: $language");
      }
      await _flutterTts.setLanguage("en-US");
    }

    await _flutterTts.setSpeechRate(0.5); // Varsayılan hız
    _flutterTts.setStartHandler(() {
      _ttsState.value = TtsState.playing;
    });
    _flutterTts.setCompletionHandler(() {
      _ttsState.value = TtsState.stopped;
    });
    _flutterTts.setPauseHandler(() {
      _ttsState.value = TtsState.paused;
    });
    return this;
  }
}
