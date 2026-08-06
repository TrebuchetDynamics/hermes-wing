import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/platform/voice_capture_platform.dart';
import 'package:wing/features/voice/services/tts/text_to_speech_service.dart';
import 'package:wing/shared/voice/voice_text_language_detector.dart';
import 'package:wing/shared/voice/voice_settings.dart';

void main() {
  test('speak configures flutter_tts once and trims text', () async {
    final engine = _FakeFlutterTtsEngine();
    final service = FlutterTextToSpeechService(engine: engine);

    await service.speak('  hello Hermes  ');
    await service.speak('again');

    expect(engine.calls, [
      'awaitSpeakCompletion:true',
      'setSpeechRate:0.45',
      'setVolume:1.0',
      'setPitch:1.0',
      'speak:hello Hermes',
      'speak:again',
    ]);
  });

  test('blank speak is a no-op', () async {
    final engine = _FakeFlutterTtsEngine();
    final service = FlutterTextToSpeechService(engine: engine);

    await service.speak('   ');

    expect(engine.calls, isEmpty);
  });

  test(
    'an explicit language configuration is retried on the next speak',
    () async {
      final engine = _FakeFlutterTtsEngine(failNextSetLanguage: true);
      final service = FlutterTextToSpeechService(
        engine: engine,
        language: 'en-US',
      );

      await expectLater(service.speak('first'), throwsStateError);
      await service.speak('second');

      expect(
        engine.calls.where((call) => call == 'setLanguage:en-US'),
        hasLength(2),
      );
      expect(engine.calls.last, 'speak:second');
    },
  );

  test('detects and applies the language of a short incoming reply', () async {
    final engine = _FakeFlutterTtsEngine();
    final service = FlutterTextToSpeechService(engine: engine);

    await service.speak('Hola, ¿cómo estás?');

    expect(engine.calls, contains('setLanguage:es'));
  });

  test('sets the detected reply language before speaking', () async {
    final engine = _FakeFlutterTtsEngine();
    final service = FlutterTextToSpeechService(
      engine: engine,
      languageDetector: const _FixedLanguageDetector('es'),
    );

    await service.speak('Hola, ¿cómo puedo ayudarte hoy?');

    expect(engine.calls, [
      'awaitSpeakCompletion:true',
      'setSpeechRate:0.45',
      'setVolume:1.0',
      'setPitch:1.0',
      'setLanguage:es',
      'speak:Hola, ¿cómo puedo ayudarte hoy?',
    ]);
  });

  test(
    'ambiguous reply does not inherit the previous foreign locale',
    () async {
      final engine = _FakeFlutterTtsEngine();
      final service = FlutterTextToSpeechService(engine: engine);

      await service.speak('Hola, ¿cómo puedo ayudarte hoy?');
      expect(engine.currentLanguage, 'es');

      await service.speak('OK');

      expect(engine.currentLanguage, isNull);
    },
  );

  test('retries a failed default-voice reset on the next reply', () async {
    final engine = _FakeFlutterTtsEngine();
    final service = FlutterTextToSpeechService(engine: engine);

    await service.speak('Hola, ¿cómo puedo ayudarte hoy?');
    engine.failNextReset = true;
    await service.speak('OK');
    expect(engine.currentLanguage, 'es');

    await service.speak('OK');

    expect(engine.currentLanguage, isNull);
    expect(
      engine.calls.where((call) => call == 'resetToDefaultVoice'),
      hasLength(2),
    );
  });

  test(
    'rejected language does not retain the previous foreign locale',
    () async {
      final engine = _FakeFlutterTtsEngine();
      final detector = _MutableLanguageDetector('es');
      final service = FlutterTextToSpeechService(
        engine: engine,
        languageDetector: detector,
      );

      await service.speak('Hola, puedo ayudarte.');
      expect(engine.currentLanguage, 'es');

      detector.language = 'fa';
      engine.failNextSetLanguage = true;
      await service.speak('سلام، می‌توانم کمک کنم.');

      expect(engine.currentLanguage, isNull);
    },
  );

  test(
    'resets to the system language before switching reply language',
    () async {
      final engine = _FakeFlutterTtsEngine(systemLanguage: 'en-US');
      final service = FlutterTextToSpeechService(
        engine: engine,
        languageDetector: const _FixedLanguageDetector('es'),
      );

      await service.speak('Hola, ¿cómo puedo ayudarte hoy?');

      expect(
        engine.calls,
        containsAllInOrder(['setLanguage:en-US', 'setLanguage:es']),
      );
    },
  );

  test(
    'does not override a detected language with an incompatible voice',
    () async {
      final engine = _FakeFlutterTtsEngine();
      final service = FlutterTextToSpeechService(
        engine: engine,
        settings: () => const WingVoiceSettings(ttsVoiceName: 'english-voice'),
        languageDetector: const _FixedLanguageDetector('es'),
      );

      await service.speak('Hola, ¿cómo puedo ayudarte hoy?');

      expect(engine.calls, contains('setLanguage:es'));
      expect(engine.calls, isNot(contains('setVoiceByName:english-voice')));
    },
  );

  test('stop prevents delayed configuration from starting speech', () async {
    final engine = _DelayedConfigureFlutterTtsEngine();
    final service = FlutterTextToSpeechService(engine: engine);
    final speaking = service.speak('hello');
    await Future<void>.delayed(Duration.zero);

    await service.stop();
    engine.completeConfiguration();
    await speaking;

    expect(engine.calls, isNot(contains('speak:hello')));
  });

  test('stop forwards to flutter_tts engine', () async {
    final engine = _FakeFlutterTtsEngine();
    final service = FlutterTextToSpeechService(engine: engine);

    await service.stop();

    expect(engine.calls, ['stop']);
  });

  test('dispose stops flutter_tts output', () async {
    final engine = _FakeFlutterTtsEngine();
    final service = FlutterTextToSpeechService(engine: engine);

    await service.dispose();

    expect(engine.calls, ['stop']);
  });

  test('default TTS is only created for flutter_tts supported platforms', () {
    expect(
      createDefaultTextToSpeechService(
        platform: const VoiceCapturePlatform(isAndroid: true),
        engine: _FakeFlutterTtsEngine(),
      ),
      isNotNull,
    );
    expect(
      createDefaultTextToSpeechService(
        platform: const VoiceCapturePlatform(isAndroid: false, isWeb: true),
        engine: _FakeFlutterTtsEngine(),
      ),
      isNotNull,
    );
    expect(
      createDefaultTextToSpeechService(
        platform: const VoiceCapturePlatform(isAndroid: false),
        engine: _FakeFlutterTtsEngine(),
      ),
      isNull,
    );
  });
}

class _DelayedConfigureFlutterTtsEngine extends _FakeFlutterTtsEngine {
  final _configuration = Completer<void>();

  @override
  Future<void> awaitSpeakCompletion(bool awaitCompletion) {
    calls.add('awaitSpeakCompletion:$awaitCompletion');
    return _configuration.future;
  }

  void completeConfiguration() => _configuration.complete();
}

class _FakeFlutterTtsEngine implements FlutterTtsEngine {
  _FakeFlutterTtsEngine({
    this.failNextSetLanguage = false,
    this.systemLanguage,
  });

  final calls = <String>[];
  bool failNextSetLanguage;
  bool failNextReset = false;
  final String? systemLanguage;
  String? currentLanguage;

  @override
  Future<void> awaitSpeakCompletion(bool awaitCompletion) async {
    calls.add('awaitSpeakCompletion:$awaitCompletion');
  }

  @override
  Future<void> setLanguage(String language) async {
    calls.add('setLanguage:$language');
    if (failNextSetLanguage) {
      failNextSetLanguage = false;
      throw StateError('language unavailable');
    }
    currentLanguage = language;
  }

  @override
  Future<void> setPitch(double pitch) async {
    calls.add('setPitch:$pitch');
  }

  @override
  Future<void> resetToDefaultVoice() async {
    calls.add('resetToDefaultVoice');
    if (failNextReset) {
      failNextReset = false;
      throw StateError('default voice unavailable');
    }
    currentLanguage = null;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    calls.add('setSpeechRate:$rate');
  }

  @override
  Future<void> setVolume(double volume) async {
    calls.add('setVolume:$volume');
  }

  @override
  Future<void> speak(String text) async {
    calls.add('speak:$text');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<List<String>> voiceNames() async {
    calls.add('voiceNames');
    return const ['nova', 'en-GB-standard'];
  }

  @override
  Future<void> setVoiceByName(String name) async {
    calls.add('setVoiceByName:$name');
  }

  @override
  Future<String?> voiceLocale(String name) async => 'en-US';

  @override
  Future<String?> defaultLanguage() async => systemLanguage;
}

class _MutableLanguageDetector implements VoiceTextLanguageDetector {
  _MutableLanguageDetector(this.language);

  String? language;

  @override
  String? detect(String text) => language;
}

class _FixedLanguageDetector implements VoiceTextLanguageDetector {
  const _FixedLanguageDetector(this.language);

  final String? language;

  @override
  String? detect(String text) => language;
}
