import 'package:flutter_tts/flutter_tts.dart';

import '../../../../shared/voice/text_to_speech_service.dart';

typedef FlutterTtsEngineFactory = FlutterTts Function();

/// Device speech fallback for Agents that do not advertise audio synthesis.
/// Hermes remains the preferred provider; this service never receives keys or
/// changes Agent-owned voice configuration.
final class PlatformTextToSpeechService implements TextToSpeechService {
  PlatformTextToSpeechService({FlutterTtsEngineFactory? engineFactory})
    : _engineFactory = engineFactory ?? FlutterTts.new;

  final FlutterTtsEngineFactory _engineFactory;
  FlutterTts? _engine;
  bool _configured = false;

  FlutterTts get _tts => _engine ??= _engineFactory();

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (!_configured) {
      await _tts.awaitSpeakCompletion(true);
      _configured = true;
    }
    await _tts.speak(trimmed);
  }

  @override
  Future<void> stop() async {
    await _engine?.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
    _engine = null;
  }
}
