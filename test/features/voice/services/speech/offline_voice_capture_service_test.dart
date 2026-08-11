import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/engine/android_voice_audio_engine.dart';
import 'package:wing/features/voice/services/speech/offline_voice_capture_service.dart';
import 'package:wing/features/voice/services/speech/offline_whisper_engine.dart';

import 'package:wing/shared/voice/voice_settings.dart';

void main() {
  test('post-VAD endpoint returns an app-owned offline transcript', () async {
    final audio = _FakePcmCaptureEngine();
    final transcriber = _FakeOfflineTranscriber(<OfflineWhisperResult>[
      const OfflineWhisperResult(text: 'hola Hermes', language: 'es'),
    ]);
    final service = OfflineVoiceCaptureService(
      audioEngine: audio,
      vad: _SequenceVad(<VoiceActivity>[
        VoiceActivity.speech,
        VoiceActivity.end,
      ]),
      transcriber: transcriber,
      languageMode: () => VoiceLanguageMode.autoEnglishSpanish,
      partialDecodeInterval: const Duration(seconds: 10),
    );

    final capture = service.capture(timeout: const Duration(seconds: 2));
    await audio.started;
    audio.emit(Uint8List(640));
    audio.emit(Uint8List(640));

    final result = await capture;
    expect(result.transcript, 'hola Hermes');
    expect(result.audio, hasLength(1280));
    expect(audio.startedGenerations, [1]);
    expect(audio.stoppedGenerations, [1]);
    expect(transcriber.generations, [1]);
    expect(service.provenance.appOwnedModel, isTrue);
    expect(service.provenance.offlineRequested, isTrue);
  });

  test(
    'serializes rolling partial and endpoint decode on one runtime',
    () async {
      final audio = _FakePcmCaptureEngine();
      final transcriber = _SerializingTranscriber();
      final service = OfflineVoiceCaptureService(
        audioEngine: audio,
        vad: _SequenceVad(<VoiceActivity>[
          VoiceActivity.speech,
          VoiceActivity.end,
        ]),
        transcriber: transcriber,
        languageMode: () => VoiceLanguageMode.autoEnglishSpanish,
        partialDecodeInterval: const Duration(milliseconds: 20),
      );

      final capture = service.capture(timeout: const Duration(seconds: 2));
      await audio.started;
      audio.emit(Uint8List(640));
      await transcriber.firstCalled;
      audio.emit(Uint8List(640));
      await Future<void>.delayed(Duration.zero);
      expect(
        transcriber.calls,
        1,
        reason: 'native recognizer is not re-entrant',
      );

      transcriber.completeNext(
        const OfflineWhisperResult(text: 'hola', language: 'es'),
      );
      await transcriber.secondCalled;
      expect(transcriber.maxConcurrent, 1);
      transcriber.completeNext(
        const OfflineWhisperResult(text: 'hola Hermes', language: 'es'),
      );

      expect((await capture).transcript, 'hola Hermes');
    },
  );

  test('dispose releases transcriber and VAD exactly once', () async {
    final transcriber = _DisposableTranscriber();
    final vad = _DisposableVad();
    final service = OfflineVoiceCaptureService(
      audioEngine: _FakePcmCaptureEngine(),
      vad: vad,
      transcriber: transcriber,
      languageMode: () => VoiceLanguageMode.autoEnglishSpanish,
    );

    await service.dispose();
    await service.dispose();

    expect(transcriber.disposeCalls, 1);
    expect(vad.disposeCalls, 1);
    await expectLater(
      service.capture(timeout: const Duration(seconds: 1)),
      throwsStateError,
    );
  });

  test(
    'cancel invalidates transcript delivery before platform stop settles',
    () async {
      final audio = _FakePcmCaptureEngine(blockStop: true);
      final transcriber = _CompletingTranscriber();
      final service = OfflineVoiceCaptureService(
        audioEngine: audio,
        vad: _SequenceVad(<VoiceActivity>[
          VoiceActivity.speech,
          VoiceActivity.end,
        ]),
        transcriber: transcriber,
        languageMode: () => VoiceLanguageMode.autoEnglishSpanish,
        partialDecodeInterval: const Duration(seconds: 10),
      );

      final capture = service.capture(timeout: const Duration(seconds: 2));
      await audio.started;
      audio.emit(Uint8List(640));
      audio.emit(Uint8List(640));
      await transcriber.called;

      final cancellation = service.cancel();
      transcriber.complete(
        const OfflineWhisperResult(text: 'stale transcript', language: 'en'),
      );
      await expectLater(capture, throwsA(isA<OfflineVoiceCaptureCancelled>()));
      expect(audio.stopPending, isTrue);
      audio.completeStop();
      await cancellation;
    },
  );
}

class _FakePcmCaptureEngine implements VoicePcmCaptureEngine {
  _FakePcmCaptureEngine({this.blockStop = false});

  final bool blockStop;
  final _chunks = StreamController<VoiceAudioChunk>.broadcast(sync: true);
  final _started = Completer<void>();
  final _stop = Completer<void>();
  final startedGenerations = <int>[];
  final stoppedGenerations = <int>[];
  int? generation;

  Future<void> get started => _started.future;
  bool get stopPending => stoppedGenerations.isNotEmpty && !_stop.isCompleted;

  void emit(Uint8List bytes) {
    _chunks.add(VoiceAudioChunk(generation: generation!, pcm16: bytes));
  }

  void completeStop() {
    if (!_stop.isCompleted) _stop.complete();
  }

  @override
  Stream<VoiceAudioChunk> get audioChunks => _chunks.stream;

  @override
  Future<void> startCapture({required int generation}) async {
    this.generation = generation;
    startedGenerations.add(generation);
    if (!_started.isCompleted) _started.complete();
  }

  @override
  Future<void> stopCapture({required int generation}) async {
    stoppedGenerations.add(generation);
    if (blockStop) await _stop.future;
  }
}

class _DisposableVad
    implements
        OfflineVoiceActivityDetector,
        OfflineVoiceActivityDetectorLifecycle {
  int disposeCalls = 0;

  @override
  VoiceActivity accept(Uint8List pcm16) => VoiceActivity.silence;

  @override
  void reset() {}

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

class _DisposableTranscriber
    implements OfflineVoiceTranscriber, OfflineVoiceTranscriberLifecycle {
  int disposeCalls = 0;

  @override
  void invalidate(int generation) {}

  @override
  Future<OfflineWhisperResult> transcribe({
    required int generation,
    required Uint8List pcm16,
    required VoiceLanguageMode languageMode,
  }) async => const OfflineWhisperResult(text: '', language: '');

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

class _SequenceVad implements OfflineVoiceActivityDetector {
  _SequenceVad(this.values);
  final List<VoiceActivity> values;
  int index = 0;

  @override
  VoiceActivity accept(Uint8List pcm16) => values[index++];

  @override
  void reset() => index = 0;
}

class _FakeOfflineTranscriber implements OfflineVoiceTranscriber {
  _FakeOfflineTranscriber(this.results);
  final List<OfflineWhisperResult> results;
  final generations = <int>[];

  @override
  Future<OfflineWhisperResult> transcribe({
    required int generation,
    required Uint8List pcm16,
    required VoiceLanguageMode languageMode,
  }) async {
    generations.add(generation);
    return results.removeAt(0);
  }

  @override
  void invalidate(int generation) {}
}

class _SerializingTranscriber implements OfflineVoiceTranscriber {
  final _firstCalled = Completer<void>();
  final _secondCalled = Completer<void>();
  final _pending = <Completer<OfflineWhisperResult>>[];
  int calls = 0;
  int concurrent = 0;
  int maxConcurrent = 0;

  Future<void> get firstCalled => _firstCalled.future;
  Future<void> get secondCalled => _secondCalled.future;

  void completeNext(OfflineWhisperResult result) {
    _pending.first.complete(result);
    _pending.removeAt(0);
  }

  @override
  Future<OfflineWhisperResult> transcribe({
    required int generation,
    required Uint8List pcm16,
    required VoiceLanguageMode languageMode,
  }) async {
    calls += 1;
    concurrent += 1;
    if (concurrent > maxConcurrent) maxConcurrent = concurrent;
    final result = Completer<OfflineWhisperResult>();
    _pending.add(result);
    if (calls == 1) _firstCalled.complete();
    if (calls == 2) _secondCalled.complete();
    try {
      return await result.future;
    } finally {
      concurrent -= 1;
    }
  }

  @override
  void invalidate(int generation) {}
}

class _CompletingTranscriber implements OfflineVoiceTranscriber {
  final _called = Completer<void>();
  final _result = Completer<OfflineWhisperResult>();

  Future<void> get called => _called.future;
  void complete(OfflineWhisperResult result) => _result.complete(result);

  @override
  Future<OfflineWhisperResult> transcribe({
    required int generation,
    required Uint8List pcm16,
    required VoiceLanguageMode languageMode,
  }) {
    if (!_called.isCompleted) _called.complete();
    return _result.future;
  }

  @override
  void invalidate(int generation) {}
}
