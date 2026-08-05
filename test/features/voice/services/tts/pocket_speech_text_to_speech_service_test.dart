import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/tts/pocket_speech_text_to_speech_service.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';
import 'package:wing/shared/voice/voice_settings.dart';
import 'package:wing/shared/voice/voice_text_language_detector.dart';
import 'package:pocket_speech/src/kokoro_engine/src/tokenizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Pocket Speech runtime assets load in the consuming app', () async {
    final tokenizer = Tokenizer();
    await tokenizer.ensureInitialized();
    expect(tokenizer.tokenize('hɛloʊ'), isNotEmpty);
  });

  test('factory accepts downloaded Kitten and Kokoro voice packs', () {
    for (final model in PocketSpeechModel.values) {
      final service = createPocketSpeechTextToSpeechService(
        enabled: true,
        voicePack: PocketSpeechVoicePack(
          model: model,
          modelPath: '/models/${model.name}/model.onnx',
          voicesPath: '/models/${model.name}/voices.json',
        ),
        audioSink: _FakePocketSpeechAudioSink(),
      );
      expect(service, isA<PocketSpeechTextToSpeechService>());
    }
  });

  test('optional factory requires explicit enablement, engine, and sink', () {
    expect(createPocketSpeechTextToSpeechService(), isNull);
    expect(
      createPocketSpeechTextToSpeechService(
        enabled: true,
        engine: _FakePocketSpeechEngine(),
        useDefaultAudioSink: false,
      ),
      isNull,
    );
    expect(
      createPocketSpeechTextToSpeechService(
        enabled: true,
        engine: _FakePocketSpeechEngine(),
        audioSink: _FakePocketSpeechAudioSink(),
      ),
      isA<PocketSpeechTextToSpeechService>(),
    );
  });

  test('factory falls back when Pocket Speech synthesis fails', () async {
    final fallback = FakeTextToSpeechService();
    final service = createPocketSpeechTextToSpeechService(
      enabled: true,
      engine: _FailingPocketSpeechEngine(),
      audioSink: _FakePocketSpeechAudioSink(),
      fallback: fallback,
    );

    await service!.speak('hello from Hermes');

    expect(fallback.spoken, ['hello from Hermes']);
  });

  test('non-English replies use the platform fallback', () async {
    final engine = _FakePocketSpeechEngine();
    final fallback = FakeTextToSpeechService();
    final service = createPocketSpeechTextToSpeechService(
      enabled: true,
      engine: engine,
      audioSink: _FakePocketSpeechAudioSink(),
      fallback: fallback,
      languageDetector: const _FixedLanguageDetector('es'),
    );

    await service!.speak('Hola, ¿cómo puedo ayudarte hoy?');

    expect(engine.calls, isEmpty);
    expect(fallback.spoken, ['Hola, ¿cómo puedo ayudarte hoy?']);
  });

  test(
    'Kitten ignores a persisted voice missing from its pinned pack',
    () async {
      final engine = _FakePocketSpeechEngine();
      final service = createPocketSpeechTextToSpeechService(
        enabled: true,
        voicePack: const PocketSpeechVoicePack(
          model: PocketSpeechModel.kitten,
          modelPath: '/models/kitten/model.onnx',
          voicesPath: '/models/kitten/voices.json',
        ),
        engine: engine,
        audioSink: _FakePocketSpeechAudioSink(),
        settings: () => const WingVoiceSettings(ttsVoiceName: 'Bella'),
      );

      await service!.speak('Hermes Wing is ready to speak.');

      expect(engine.selectedVoices, [isNull]);
    },
  );

  test('speak trims text, synthesizes wav, and sends it to the sink', () async {
    final engine = _FakePocketSpeechEngine(wav: Uint8List.fromList([1, 2, 3]));
    final sink = _FakePocketSpeechAudioSink();
    final service = PocketSpeechTextToSpeechService(
      engine: engine,
      audioSink: sink,
    );

    await service.speak('  hello  ');

    expect(engine.calls, ['hello']);
    expect(sink.played, [
      Uint8List.fromList([1, 2, 3]),
    ]);
  });

  test('blank text and empty wav are no-ops', () async {
    final engine = _FakePocketSpeechEngine(wav: Uint8List(0));
    final sink = _FakePocketSpeechAudioSink();
    final service = PocketSpeechTextToSpeechService(
      engine: engine,
      audioSink: sink,
    );

    await service.speak('   ');
    await service.speak('hello');

    expect(engine.calls, ['hello']);
    expect(sink.played, isEmpty);
  });

  test('stop forwards to sink', () async {
    final sink = _FakePocketSpeechAudioSink();
    final service = PocketSpeechTextToSpeechService(
      engine: _FakePocketSpeechEngine(),
      audioSink: sink,
    );

    await service.stop();
    expect(sink.stopCalls, 1);
  });

  test('dispose releases the Pocket Speech engine and audio sink', () async {
    final engine = _FakePocketSpeechEngine();
    final sink = _FakePocketSpeechAudioSink();
    final service = PocketSpeechTextToSpeechService(
      engine: engine,
      audioSink: sink,
    );

    await service.dispose();

    expect(engine.disposeCalls, 1);
    expect(sink.disposeCalls, 1);
  });

  test('audio sink waits for playback completion', () async {
    final player = _FakePocketSpeechAudioPlayer();
    final sink = AudioPlayersPocketSpeechAudioSink(player: player);
    var completed = false;
    final playback = sink
        .playWav(Uint8List.fromList([1, 2, 3]))
        .then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);

    expect(completed, isFalse);
    player.completePlayback();
    await playback;
    expect(completed, isTrue);
    await sink.dispose();
  });

  test('stopping audio sink releases pending playback', () async {
    final player = _FakePocketSpeechAudioPlayer();
    final sink = AudioPlayersPocketSpeechAudioSink(player: player);
    final playback = sink.playWav(Uint8List.fromList([1]));
    await Future<void>.delayed(Duration.zero);

    await sink.stop();
    await playback;
    await sink.dispose();

    expect(player.stopCalls, greaterThanOrEqualTo(1));
    expect(player.disposeCalls, 1);
  });
}

class _FixedLanguageDetector implements VoiceTextLanguageDetector {
  const _FixedLanguageDetector(this.language);

  final String? language;

  @override
  String? detect(String text) => language;
}

class _FailingPocketSpeechEngine implements PocketSpeechEngine {
  @override
  Future<Uint8List> synthesizeWav(
    String text, {
    String? voice,
    double speed = 1.0,
  }) => throw StateError('Pocket Speech synthesis failed');

  @override
  Future<void> dispose() async {}
}

class _FakePocketSpeechEngine implements PocketSpeechEngine {
  _FakePocketSpeechEngine({Uint8List? wav})
    : wav = wav ?? Uint8List.fromList([7]);

  final Uint8List wav;
  final calls = <String>[];
  final selectedVoices = <String?>[];
  int disposeCalls = 0;

  @override
  Future<Uint8List> synthesizeWav(
    String text, {
    String? voice,
    double speed = 1.0,
  }) async {
    calls.add(text);
    selectedVoices.add(voice);
    return wav;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

class _FakePocketSpeechAudioSink implements PocketSpeechAudioSink {
  final played = <Uint8List>[];
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> playWav(Uint8List wav) async => played.add(wav);

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

class _FakePocketSpeechAudioPlayer implements PocketSpeechAudioPlayer {
  final _completed = StreamController<void>.broadcast();
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Stream<void> get onPlayerComplete => _completed.stream;

  @override
  Future<void> playBytes(Uint8List wav) async {}

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
    await _completed.close();
  }

  void completePlayback() => _completed.add(null);
}
