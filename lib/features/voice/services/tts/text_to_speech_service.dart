import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../../../../shared/voice/text_to_speech_service.dart';
import '../../../../shared/voice/voice_settings.dart';
import '../../../../shared/voice/voice_text_language_detector.dart';
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
  Future<void> resetToDefaultVoice();
  Future<void> speak(String text);
  Future<void> stop();

  /// Names of the voices installed on-device (flutter_tts `getVoices`).
  Future<List<String>> voiceNames();

  /// Selects a voice by the name returned from [voiceNames]. Throws if the
  /// name is unknown — callers must treat that as non-fatal.
  Future<void> setVoiceByName(String name);

  /// Locale paired with a voice returned by [voiceNames], if known.
  Future<String?> voiceLocale(String name);

  /// The platform's selected TTS locale, if exposed by the engine.
  Future<String?> defaultLanguage();
}

class PluginFlutterTtsEngine implements FlutterTtsEngine {
  PluginFlutterTtsEngine({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts() {
    _flutterTts.setErrorHandler((message) {
      final failure = _speechFailure;
      if (failure != null && !failure.isCompleted) {
        failure.completeError(StateError(message));
      }
    });
  }

  final FlutterTts _flutterTts;
  Completer<void>? _speechFailure;
  List<Map<Object?, Object?>>? _cachedVoices;

  @override
  Future<void> awaitSpeakCompletion(bool awaitCompletion) async {
    await _flutterTts.awaitSpeakCompletion(awaitCompletion);
  }

  @override
  Future<void> setLanguage(String language) async {
    final result = await _flutterTts.setLanguage(language);
    if (result == 0 || result == false) {
      throw StateError('TTS language unavailable: $language');
    }
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
  Future<void> resetToDefaultVoice() async {
    await _flutterTts.clearVoice();
  }

  @override
  Future<void> speak(String text) async {
    final failure = Completer<void>();
    _speechFailure = failure;
    try {
      await Future.any<void>([
        _flutterTts.speak(text).then<void>((_) {}),
        failure.future,
      ]);
    } finally {
      if (identical(_speechFailure, failure)) _speechFailure = null;
    }
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
    final locale = await voiceLocale(name);
    if (locale == null) throw StateError('Unknown TTS voice: $name');
    await _flutterTts.setVoice({'name': name, 'locale': locale});
  }

  @override
  Future<String?> voiceLocale(String name) async {
    final voices = await _voices();
    final match = voices.firstWhere(
      (voice) => voice['name'] == name,
      orElse: () => const {},
    );
    final locale = match['locale'];
    return locale is String && locale.isNotEmpty ? locale : null;
  }

  @override
  Future<String?> defaultLanguage() async {
    final voice = await _flutterTts.getDefaultVoice;
    if (voice is! Map) return null;
    final locale = voice['locale'];
    return locale is String && locale.isNotEmpty ? locale : null;
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

class FallbackTextToSpeechService implements TextToSpeechService {
  FallbackTextToSpeechService(this._primary, this._fallback);

  final TextToSpeechService _primary;
  final TextToSpeechService _fallback;

  @override
  Future<void> speak(String text) async {
    try {
      await _primary.speak(text);
    } catch (_) {
      try {
        await _primary.stop();
      } catch (_) {}
      await _fallback.speak(text);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _primary.stop();
    } finally {
      await _fallback.stop();
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _primary.dispose();
    } finally {
      await _fallback.dispose();
    }
  }
}

class FlutterTextToSpeechService implements TextToSpeechService {
  FlutterTextToSpeechService({
    FlutterTtsEngine? engine,
    this.language,
    this.speechRate = 0.45,
    this.volume = 1,
    this.pitch = 1,
    TtsSettingsReader? settings,
    VoiceTextLanguageDetector? languageDetector,
  }) : _engine = engine ?? PluginFlutterTtsEngine(),
       _languageDetector =
           languageDetector ?? DefaultVoiceTextLanguageDetector(),
       // ignore: prefer_initializing_formals
       _settings = settings;

  final FlutterTtsEngine _engine;
  final VoiceTextLanguageDetector _languageDetector;

  /// Null preserves the platform's selected default TTS language.
  final String? language;
  final double speechRate;
  final double volume;
  final double pitch;
  final TtsSettingsReader? _settings;
  bool _configured = false;
  int _operationGeneration = 0;
  String? _lastAppliedLanguage;

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final operationGeneration = ++_operationGeneration;
    await _configure();
    if (operationGeneration != _operationGeneration) return;
    await _applySettings(_languageDetector.detect(trimmed));
    if (operationGeneration != _operationGeneration) return;
    await _engine.speak(trimmed);
  }

  /// Applies the reply language before the selected voice so speech follows
  /// incoming text while a compatible user-selected voice stays in use.
  Future<void> _applySettings(String? detectedLanguage) async {
    final settings = _settings?.call();
    if (settings != null) {
      // Scale from this service's own baseline rate (the constructor default,
      // 0.45) rather than a hardcoded factor, so default settings speak at
      // the same rate as the pre-existing feature-OFF baseline.
      final rate = (speechRate * settings.speechRate).clamp(0.0, 1.0);
      await _engine.setSpeechRate(rate);
    }

    // Reset to the system language first. An unavailable detected language
    // then leaves the engine at its known-good default rather than the locale
    // used for the previous reply.
    String? defaultLanguage;
    if (_lastAppliedLanguage != null &&
        _languageCode(detectedLanguage ?? '') !=
            _languageCode(_lastAppliedLanguage!)) {
      try {
        await _engine.resetToDefaultVoice();
        _lastAppliedLanguage = null;
      } catch (_) {
        // Keep the prior locale recorded so the next reply retries the reset.
      }
    }
    try {
      defaultLanguage = await _engine.defaultLanguage();
      if (defaultLanguage != null) {
        await _engine.setLanguage(defaultLanguage);
      }
    } catch (_) {
      // Some platforms do not expose a system TTS voice.
    }
    final language = detectedLanguage ?? defaultLanguage;
    if (detectedLanguage != null &&
        _languageCode(detectedLanguage) !=
            _languageCode(defaultLanguage ?? '')) {
      try {
        await _engine.setLanguage(detectedLanguage);
        _lastAppliedLanguage = detectedLanguage;
      } catch (_) {
        // A missing language pack must not silence the reply. Keep the prior
        // locale recorded so a later ambiguous reply can still reset it.
      }
    }

    final voiceName = settings?.ttsVoiceName;
    if (voiceName != null &&
        (language == null ||
            await _voiceMatchesLanguage(voiceName, language))) {
      try {
        await _engine.setVoiceByName(voiceName);
      } catch (_) {
        // Unknown/unavailable voice: keep speaking with the current voice.
      }
    }
  }

  Future<bool> _voiceMatchesLanguage(String voiceName, String language) async {
    try {
      final voiceLocale = await _engine.voiceLocale(voiceName);
      return voiceLocale != null &&
          _languageCode(voiceLocale) == _languageCode(language);
    } catch (_) {
      return false;
    }
  }

  String _languageCode(String locale) =>
      locale.split(RegExp('[-_]')).first.toLowerCase();

  @override
  Future<void> stop() {
    _operationGeneration += 1;
    return _engine.stop();
  }

  @override
  Future<void> dispose() => stop();

  Future<void> _configure() async {
    if (_configured) return;
    await _engine.awaitSpeakCompletion(true);
    final language = this.language;
    if (language != null) await _engine.setLanguage(language);
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
