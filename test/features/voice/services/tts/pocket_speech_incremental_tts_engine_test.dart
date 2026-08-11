import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/tts/incremental_tts_engine.dart';
import 'package:wing/features/voice/services/tts/pocket_speech_incremental_tts_engine.dart';
import 'package:wing/features/voice/services/tts/pocket_speech_text_to_speech_service.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';
import 'package:wing/shared/voice/voice_settings.dart';

void main() {
  test('decodes Kokoro WAV into generation-tagged PCM chunks', () async {
    final pocket = _FakePocketSpeechEngine(_monoPcm16Wav([1, 2, 3, 4]));
    final engine = PocketSpeechIncrementalTtsEngine(
      pocket,
      selectedVoice: () => 'af_heart',
    );

    final chunks = await engine
        .synthesize(
          const TtsSynthesisRequest(
            generation: 7,
            languageHint: 'en',
            text: 'Hello.',
          ),
        )
        .toList();

    expect(chunks, hasLength(1));
    expect(chunks.single.generation, 7);
    expect(chunks.single.sampleRate, 24000);
    expect(chunks.single.channelCount, 1);
    expect(chunks.single.bytes, [1, 2, 3, 4]);
    expect(pocket.calls.single.voice, 'af_heart');
  });

  test('uses a Spanish Kokoro voice for Spanish segments', () async {
    final pocket = _FakePocketSpeechEngine(_monoPcm16Wav([1, 2]));
    final engine = PocketSpeechIncrementalTtsEngine(
      pocket,
      selectedVoice: () => 'af_heart',
    );

    await engine
        .synthesize(
          const TtsSynthesisRequest(
            generation: 8,
            languageHint: 'es',
            text: 'Hola.',
          ),
        )
        .drain<void>();

    expect(pocket.calls.single.voice, 'ef_dora');
  });

  test('stop suppresses synthesis that completes after cancellation', () async {
    final gate = _BlockingPocketSpeechEngine();
    final engine = PocketSpeechIncrementalTtsEngine(gate);
    final chunks = engine
        .synthesize(
          const TtsSynthesisRequest(
            generation: 9,
            languageHint: 'en',
            text: 'Cancelled.',
          ),
        )
        .toList();

    await gate.started.future;
    var stopped = false;
    final stopping = engine.stop().then((_) => stopped = true);
    await Future<void>.delayed(Duration.zero);
    expect(stopped, isFalse);

    gate.result.complete(_monoPcm16Wav([1, 2]));
    await stopping;

    expect(await chunks, isEmpty);
  });

  test(
    'dispose awaits in-flight native synthesis before engine release',
    () async {
      final gate = _BlockingPocketSpeechEngine();
      final engine = PocketSpeechIncrementalTtsEngine(gate);
      final chunks = engine
          .synthesize(
            const TtsSynthesisRequest(
              generation: 10,
              languageHint: 'en',
              text: 'Dispose safely.',
            ),
          )
          .toList();
      await gate.started.future;

      final disposal = engine.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(gate.disposed, isFalse);

      gate.result.complete(_monoPcm16Wav([1, 2]));
      await disposal;
      expect(gate.disposed, isTrue);
      expect(await chunks, isEmpty);
    },
  );

  test('rejects non-PCM and stereo WAV output', () async {
    final stereo = _monoPcm16Wav([1, 2], channelCount: 2);
    final engine = PocketSpeechIncrementalTtsEngine(
      _FakePocketSpeechEngine(stereo),
    );

    await expectLater(
      engine
          .synthesize(
            const TtsSynthesisRequest(
              generation: 10,
              languageHint: 'en',
              text: 'Invalid.',
            ),
          )
          .drain<void>(),
      throwsA(isA<FormatException>()),
    );
  });

  test('factory builds the Android Kokoro bilingual playback path', () async {
    final pocket = _FakePocketSpeechEngine(_monoPcm16Wav([1, 2]));
    final playback = _RecordingPlayback();
    final fallback = _FallbackTts();
    final service = createIncrementalPocketSpeechTextToSpeechService(
      enabled: true,
      isAndroid: true,
      voicePack: const PocketSpeechVoicePack(
        model: PocketSpeechModel.kokoro,
        modelPath: '/model.onnx',
        voicesPath: '/voices.bin',
      ),
      engine: pocket,
      playback: playback,
      fallback: fallback,
      settings: () =>
          const WingVoiceSettings(ttsVoiceName: 'af_heart', speechRate: 1.25),
    );

    expect(service, isNotNull);
    await service!.speak('Hello. ¿Hola, cómo estás?');

    expect(pocket.calls.map((call) => call.voice), ['af_heart', 'ef_dora']);
    expect(pocket.calls.map((call) => call.speed), everyElement(1.25));
    expect(playback.chunks, hasLength(2));
    expect(fallback.spoken, isEmpty);
  });
}

final class _SynthesisCall {
  const _SynthesisCall(this.text, this.voice, this.speed);

  final String text;
  final String? voice;
  final double speed;
}

class _FakePocketSpeechEngine implements PocketSpeechEngine {
  _FakePocketSpeechEngine(this.wav);

  final Uint8List wav;
  final calls = <_SynthesisCall>[];

  @override
  Future<Uint8List> synthesizeWav(
    String text, {
    String? voice,
    double speed = 1.0,
  }) async {
    calls.add(_SynthesisCall(text, voice, speed));
    return wav;
  }

  @override
  Future<void> dispose() async {}
}

final class _BlockingPocketSpeechEngine implements PocketSpeechEngine {
  final started = Completer<void>();
  final result = Completer<Uint8List>();
  bool disposed = false;

  @override
  Future<Uint8List> synthesizeWav(
    String text, {
    String? voice,
    double speed = 1.0,
  }) {
    started.complete();
    return result.future;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

final class _RecordingPlayback implements IncrementalPcmPlayback {
  final chunks = <PcmAudioChunk>[];

  @override
  Future<void> write(PcmAudioChunk chunk) async => chunks.add(chunk);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

final class _FallbackTts implements TextToSpeechService {
  final spoken = <String>[];

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

Uint8List _monoPcm16Wav(
  List<int> pcm, {
  int sampleRate = 24000,
  int channelCount = 1,
}) {
  final result = Uint8List(44 + pcm.length);
  final data = ByteData.sublistView(result);
  void ascii(int offset, String value) {
    for (var index = 0; index < value.length; index += 1) {
      result[offset + index] = value.codeUnitAt(index);
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, result.length - 8, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, channelCount, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * channelCount * 2, Endian.little);
  data.setUint16(32, channelCount * 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, pcm.length, Endian.little);
  result.setRange(44, result.length, pcm);
  return result;
}
