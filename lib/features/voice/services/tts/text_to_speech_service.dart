import 'package:flutter_tts/flutter_tts.dart';

import '../../../../shared/voice/text_to_speech_service.dart';
import '../platform/voice_capture_platform.dart';

export '../../../../shared/voice/text_to_speech_service.dart';
export 'kokoro_asset_download_service.dart';
export 'kokoro_text_to_speech_service.dart';

abstract interface class FlutterTtsEngine {
  Future<void> awaitSpeakCompletion(bool awaitCompletion);
  Future<void> setLanguage(String language);
  Future<void> setSpeechRate(double rate);
  Future<void> setVolume(double volume);
  Future<void> setPitch(double pitch);
  Future<void> speak(String text);
  Future<void> stop();
}

class PluginFlutterTtsEngine implements FlutterTtsEngine {
  PluginFlutterTtsEngine({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  final FlutterTts _flutterTts;

  @override
  Future<void> awaitSpeakCompletion(bool awaitCompletion) async {
    await _flutterTts.awaitSpeakCompletion(awaitCompletion);
  }

  @override
  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  @override
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

class FlutterTextToSpeechService implements TextToSpeechService {
  FlutterTextToSpeechService({
    FlutterTtsEngine? engine,
    this.language = 'en-US',
    this.speechRate = 0.45,
    this.volume = 1,
    this.pitch = 1,
  }) : _engine = engine ?? PluginFlutterTtsEngine();

  final FlutterTtsEngine _engine;
  final String language;
  final double speechRate;
  final double volume;
  final double pitch;
  bool _configured = false;

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _configure();
    await _engine.speak(trimmed);
  }

  @override
  Future<void> stop() => _engine.stop();

  Future<void> _configure() async {
    if (_configured) return;
    await _engine.awaitSpeakCompletion(true);
    await _engine.setLanguage(language);
    await _engine.setSpeechRate(speechRate);
    await _engine.setVolume(volume);
    await _engine.setPitch(pitch);
    _configured = true;
  }
}

TextToSpeechService? createDefaultTextToSpeechService({
  VoiceCapturePlatform? platform,
  FlutterTtsEngine? engine,
}) {
  final effectivePlatform = platform ?? currentVoiceCapturePlatform();
  final supported =
      effectivePlatform.isAndroid ||
      effectivePlatform.isIOS ||
      effectivePlatform.isMacOS ||
      effectivePlatform.isWindows ||
      effectivePlatform.isWeb;
  if (!supported) return null;
  return FlutterTextToSpeechService(engine: engine);
}
