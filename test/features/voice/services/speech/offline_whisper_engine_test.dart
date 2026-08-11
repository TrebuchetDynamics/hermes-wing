import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/speech/offline_whisper_engine.dart';
import 'package:wing/shared/voice/voice_settings.dart';

void main() {
  test(
    'PCM16 is normalized and bilingual auto does not force one language',
    () async {
      final runtime = _FakeWhisperRuntime(
        result: const OfflineWhisperResult(text: 'Hola Hermes', language: 'es'),
      );
      final engine = OfflineWhisperEngine(runtime);

      final result = await engine.transcribe(
        generation: 4,
        pcm16: Uint8List.fromList(<int>[0x00, 0x80, 0x00, 0x00, 0xff, 0x7f]),
        languageMode: VoiceLanguageMode.autoEnglishSpanish,
      );

      expect(result.text, 'Hola Hermes');
      expect(result.language, 'es');
      expect(runtime.language, isNull);
      expect(runtime.samples, hasLength(3));
      expect(runtime.samples[0], closeTo(-1, 0.0001));
      expect(runtime.samples[1], 0);
      expect(runtime.samples[2], closeTo(0.99997, 0.0001));
    },
  );

  test('explicit profile language is passed to Whisper', () async {
    final runtime = _FakeWhisperRuntime(
      result: const OfflineWhisperResult(text: 'hello', language: 'en'),
    );
    final engine = OfflineWhisperEngine(runtime);

    await engine.transcribe(
      generation: 1,
      pcm16: Uint8List(2),
      languageMode: VoiceLanguageMode.english,
    );

    expect(runtime.language, 'en');
  });

  test('a result from an invalidated generation is rejected', () async {
    final completer = _CompletingWhisperRuntime();
    final engine = OfflineWhisperEngine(completer);
    final pending = engine.transcribe(
      generation: 8,
      pcm16: Uint8List(2),
      languageMode: VoiceLanguageMode.autoEnglishSpanish,
    );

    engine.invalidate(8);
    completer.complete(
      const OfflineWhisperResult(text: 'stale transcript', language: 'en'),
    );

    await expectLater(pending, throwsA(isA<StaleOfflineWhisperResult>()));
  });

  test('odd-length PCM is rejected before native inference', () async {
    final runtime = _FakeWhisperRuntime(
      result: const OfflineWhisperResult(text: '', language: ''),
    );
    final engine = OfflineWhisperEngine(runtime);

    await expectLater(
      engine.transcribe(
        generation: 1,
        pcm16: Uint8List(3),
        languageMode: VoiceLanguageMode.autoEnglishSpanish,
      ),
      throwsFormatException,
    );
    expect(runtime.calls, 0);
  });
}

class _FakeWhisperRuntime implements OfflineWhisperRuntime {
  _FakeWhisperRuntime({required this.result});

  final OfflineWhisperResult result;
  Float32List samples = Float32List(0);
  String? language;
  int calls = 0;

  @override
  Future<OfflineWhisperResult> transcribe({
    required Float32List samples,
    required int sampleRate,
    required String? language,
  }) async {
    calls += 1;
    this.samples = samples;
    this.language = language;
    expect(sampleRate, 16000);
    return result;
  }

  @override
  Future<void> dispose() async {}
}

class _CompletingWhisperRuntime implements OfflineWhisperRuntime {
  final _completer = Completer<OfflineWhisperResult>();

  void complete(OfflineWhisperResult result) => _completer.complete(result);

  @override
  Future<OfflineWhisperResult> transcribe({
    required Float32List samples,
    required int sampleRate,
    required String? language,
  }) => _completer.future;

  @override
  Future<void> dispose() async {}
}
