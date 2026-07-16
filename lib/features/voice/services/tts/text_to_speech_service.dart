import 'package:flutter_tts/flutter_tts.dart';

import '../../../../shared/voice/text_to_speech_service.dart';
import '../../../../shared/voice/voice_settings.dart';
import '../platform/voice_capture_platform.dart';

export '../../../../shared/voice/text_to_speech_service.dart';
export 'pocket_speech_asset_download_service.dart';
export 'pocket_speech_text_to_speech_service.dart';

/// Reads the live voice settings at speak-time (not cached), so a rate/voice
/// change takes effect on the very next utterance.
typedef TtsSettingsReader = WingVoiceSettings Function();

abstract interface class FlutterTtsEngine {
  Future<void> awaitSpeakCompletion(bool awaitCompletion);
  Future<void> setLanguage(String language);
  Future<void> setSpeechRate(double rate);
  Future<void> setVolume(double volume);
  Future<void> setPitch(double pitch);
  Future<void> speak(String text);
  Future<void> stop();

  /// Names of the voices installed on-device (flutter_tts `getVoices`).
  Future<List<String>> voiceNames();

  /// Selects a voice by the name returned from [voiceNames]. Throws if the
  /// name is unknown — callers must treat that as non-fatal.
  Future<void> setVoiceByName(String name);
}

class PluginFlutterTtsEngine implements FlutterTtsEngine {
  PluginFlutterTtsEngine({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  final FlutterTts _flutterTts;
  List<Map<Object?, Object?>>? _cachedVoices;

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

  @override
  Future<List<String>> voiceNames() async {
    final voices = await _voices();
    return [
      for (final voice in voices)
        if (voice['name'] is String) voice['name']! as String,
    ];
  }

  @override
  Future<void> setVoiceByName(String name) async {
    final voices = await _voices();
    final match = voices.firstWhere(
      (voice) => voice['name'] == name,
      orElse: () => const {},
    );
    if (match.isEmpty) {
      throw StateError('Unknown TTS voice: $name');
    }
    final locale = match['locale'];
    await _flutterTts.setVoice({
      'name': name,
      'locale': locale is String ? locale : '',
    });
  }

  /// Fetches and caches `getVoices` so each [setVoiceByName] call can resolve
  /// the locale that goes with a voice name without re-querying the plugin.
  /// An empty result is NOT cached: some Android OEM engines report no voices
  /// until TTS finishes cold-starting, and caching that would permanently
  /// disable voice selection for the session.
  Future<List<Map<Object?, Object?>>> _voices() async {
    final cached = _cachedVoices;
    if (cached != null) return cached;
    final raw = await _flutterTts.getVoices;
    final voices = <Map<Object?, Object?>>[
      if (raw is List)
        for (final entry in raw)
          if (entry is Map) entry,
    ];
    if (voices.isNotEmpty) {
      _cachedVoices = voices;
    }
    return voices;
  }
}

class FlutterTextToSpeechService implements TextToSpeechService {
  FlutterTextToSpeechService({
    FlutterTtsEngine? engine,
    this.language = 'en-US',
    this.speechRate = 0.45,
    this.volume = 1,
    this.pitch = 1,
    TtsSettingsReader? settings,
  }) : _engine = engine ?? PluginFlutterTtsEngine(),
       // ignore: prefer_initializing_formals
       _settings = settings;

  final FlutterTtsEngine _engine;
  final String language;
  final double speechRate;
  final double volume;
  final double pitch;
  final TtsSettingsReader? _settings;
  bool _configured = false;

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _configure();
    await _applySettings();
    await _engine.speak(trimmed);
  }

  /// Applies the live voice-settings rate/voice before every utterance.
  /// A bad/unknown voice name must never prevent speech, so [setVoiceByName]
  /// failures are swallowed.
  Future<void> _applySettings() async {
    final settings = _settings?.call();
    if (settings == null) return;
    // Scale from this service's own baseline rate (the constructor default,
    // 0.45) rather than a hardcoded factor, so default settings speak at
    // the same rate as the pre-existing feature-OFF baseline.
    final rate = (speechRate * settings.speechRate).clamp(0.0, 1.0);
    await _engine.setSpeechRate(rate);
    final voiceName = settings.ttsVoiceName;
    if (voiceName != null) {
      try {
        await _engine.setVoiceByName(voiceName);
      } catch (_) {
        // Unknown/unavailable voice: keep speaking with the current voice.
      }
    }
  }

  @override
  Future<void> stop() => _engine.stop();

  @override
  Future<void> dispose() => stop();

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
  TtsSettingsReader? settings,
}) {
  final effectivePlatform = platform ?? currentVoiceCapturePlatform();
  final supported =
      effectivePlatform.isAndroid ||
      effectivePlatform.isIOS ||
      effectivePlatform.isMacOS ||
      effectivePlatform.isWindows ||
      effectivePlatform.isWeb;
  if (!supported) return null;
  return FlutterTextToSpeechService(engine: engine, settings: settings);
}
