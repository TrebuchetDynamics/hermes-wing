import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kokorodart/kokorodart.dart';
import 'package:navivox/features/voice/services/tts/kokoro_text_to_speech_service.dart';

void main() {
  test(
    'optional factory is disabled unless explicitly enabled with a sink',
    () {
      expect(createKokoroTextToSpeechService(), isNull);
      expect(
        createKokoroTextToSpeechService(
          enabled: true,
          useDefaultAudioSink: false,
        ),
        isNull,
      );
      expect(
        createKokoroTextToSpeechService(
          enabled: true,
          engine: _FakeKokoroSpeechEngine(),
          audioSink: _FakeKokoroAudioSink(),
        ),
        isA<KokoroTextToSpeechService>(),
      );
    },
  );

  test('speak trims text, synthesizes wav, and sends it to the sink', () async {
    final engine = _FakeKokoroSpeechEngine(wav: Uint8List.fromList([1, 2, 3]));
    final sink = _FakeKokoroAudioSink();
    final service = KokoroTextToSpeechService(
      engine: engine,
      audioSink: sink,
      options: KokoroDartSynthesisOptions.forLanguage('es'),
    );

    await service.speak('  hola  ');

    expect(engine.calls, ['es:ef_dora:hola']);
    expect(sink.played, [
      Uint8List.fromList([1, 2, 3]),
    ]);
  });

  test('blank text and empty wav are no-ops', () async {
    final engine = _FakeKokoroSpeechEngine(wav: Uint8List(0));
    final sink = _FakeKokoroAudioSink();
    final service = KokoroTextToSpeechService(engine: engine, audioSink: sink);

    await service.speak('   ');
    await service.speak('hello');

    expect(engine.calls, ['en-us:af_heart:hello']);
    expect(sink.played, isEmpty);
  });

  test('stop forwards to sink', () async {
    final sink = _FakeKokoroAudioSink();
    final service = KokoroTextToSpeechService(
      engine: _FakeKokoroSpeechEngine(),
      audioSink: sink,
    );

    await service.stop();

    expect(sink.stopCalls, 1);
  });
}

class _FakeKokoroSpeechEngine implements KokoroSpeechEngine {
  _FakeKokoroSpeechEngine({Uint8List? wav})
    : wav = wav ?? Uint8List.fromList([7]);

  final Uint8List wav;
  final calls = <String>[];

  @override
  Future<Uint8List> synthesizeWav(
    String text,
    KokoroDartSynthesisOptions options,
  ) async {
    calls.add('${options.language}:${options.voice}:$text');
    return wav;
  }
}

class _FakeKokoroAudioSink implements KokoroAudioSink {
  final played = <Uint8List>[];
  int stopCalls = 0;

  @override
  Future<void> playWav(Uint8List wav) async {
    played.add(wav);
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }
}
