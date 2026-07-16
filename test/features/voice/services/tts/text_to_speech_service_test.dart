import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/platform/voice_capture_platform.dart';
import 'package:wing/features/voice/services/tts/text_to_speech_service.dart';

void main() {
  test('speak configures flutter_tts once and trims text', () async {
    final engine = _FakeFlutterTtsEngine();
    final service = FlutterTextToSpeechService(engine: engine);

    await service.speak('  hello Hermes  ');
    await service.speak('again');

    expect(engine.calls, [
      'awaitSpeakCompletion:true',
      'setLanguage:en-US',
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

  test('configuration failures are retried on the next speak', () async {
    final engine = _FakeFlutterTtsEngine(failNextSetLanguage: true);
    final service = FlutterTextToSpeechService(engine: engine);

    await expectLater(service.speak('first'), throwsStateError);
    await service.speak('second');

    expect(
      engine.calls.where((call) => call == 'setLanguage:en-US'),
      hasLength(2),
    );
    expect(engine.calls.last, 'speak:second');
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

class _FakeFlutterTtsEngine implements FlutterTtsEngine {
  _FakeFlutterTtsEngine({this.failNextSetLanguage = false});

  final calls = <String>[];
  bool failNextSetLanguage;

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
  }

  @override
  Future<void> setPitch(double pitch) async {
    calls.add('setPitch:$pitch');
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
}
