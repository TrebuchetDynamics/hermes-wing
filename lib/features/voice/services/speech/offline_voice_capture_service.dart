import 'dart:async';
import 'dart:typed_data';

import '../../../../shared/voice/voice_capture_service.dart';
import '../../../../shared/voice/voice_settings.dart';
import '../engine/android_voice_audio_engine.dart';
import 'offline_whisper_engine.dart';

enum VoiceActivity { silence, speech, end }

abstract interface class OfflineVoiceActivityDetector {
  VoiceActivity accept(Uint8List pcm16);

  void reset();
}

abstract interface class OfflineVoiceActivityDetectorLifecycle {
  Future<void> dispose();
}

class OfflineVoiceCaptureCancelled implements Exception {
  const OfflineVoiceCaptureCancelled();

  @override
  String toString() => 'OfflineVoiceCaptureCancelled';
}

class OfflineVoiceCaptureService
    implements
        VoiceCaptureService,
        VoiceCaptureProgressService,
        VoiceCaptureProvenanceService,
        VoiceCaptureLifecycleService {
  OfflineVoiceCaptureService({
    required this.audioEngine,
    required this.vad,
    required this.transcriber,
    required this.languageMode,
    this.partialDecodeInterval = const Duration(milliseconds: 600),
    this.modelId = 'whisper-multilingual-int8',
  });

  static const _bytesPerSecond = 16000 * 2;

  final VoicePcmCaptureEngine audioEngine;
  final OfflineVoiceActivityDetector vad;
  final OfflineVoiceTranscriber transcriber;
  final VoiceLanguageMode Function() languageMode;
  final Duration partialDecodeInterval;
  final String modelId;
  final _partials = StreamController<String>.broadcast(sync: true);
  int _nextGeneration = 0;
  _OfflineCaptureRun? _active;
  Future<void> _teardownBarrier = Future<void>.value();
  bool _disposed = false;

  @override
  Stream<String> get partialTranscripts => _partials.stream;

  @override
  VoiceEngineProvenance get provenance => VoiceEngineProvenance(
    engine: 'sherpa-onnx Whisper',
    adapter: 'Wing native PCM + sherpa_onnx 1.13.4',
    model: modelId,
    offlineRequested: true,
    appOwnedModel: true,
  );

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    if (_disposed) throw StateError('Offline voice capture is disposed.');
    if (_active != null) {
      throw StateError('Offline voice capture is already active.');
    }
    await _teardownBarrier;
    if (_active != null) {
      throw StateError('Offline voice capture is already active.');
    }

    final run = _OfflineCaptureRun(++_nextGeneration);
    _active = run;
    vad.reset();
    run.subscription = audioEngine.audioChunks.listen(
      (chunk) => _acceptChunk(run, chunk),
      onError: (Object error, StackTrace stackTrace) {
        if (_active == run && !run.result.isCompleted) {
          run.result.completeError(error, stackTrace);
        }
      },
    );
    try {
      await audioEngine.startCapture(generation: run.generation);
    } catch (_) {
      if (_active == run) _active = null;
      await run.subscription?.cancel();
      rethrow;
    }

    try {
      final capture = await run.result.future.timeout(
        timeout,
        onTimeout: () {
          _invalidate(run);
          _beginTeardown(run);
          throw const VoiceCaptureTimeout();
        },
      );
      await _beginTeardown(run);
      if (_active == run) _active = null;
      return capture;
    } on OfflineVoiceCaptureCancelled {
      rethrow;
    } catch (_) {
      _invalidate(run);
      await _beginTeardown(run);
      rethrow;
    }
  }

  void _acceptChunk(_OfflineCaptureRun run, VoiceAudioChunk chunk) {
    if (_active != run ||
        chunk.generation != run.generation ||
        run.invalidated) {
      return;
    }
    run.audio.add(chunk.pcm16);
    final activity = vad.accept(chunk.pcm16);
    if (activity == VoiceActivity.speech) run.speechStarted = true;
    if (activity == VoiceActivity.end && run.speechStarted && !run.finalizing) {
      run.finalizing = true;
      unawaited(_finalize(run));
      return;
    }
    final intervalBytes =
        (_bytesPerSecond * partialDecodeInterval.inMicroseconds) ~/
        Duration.microsecondsPerSecond;
    if (run.speechStarted &&
        !run.partialPending &&
        intervalBytes > 0 &&
        run.audio.length - run.lastPartialBytes >= intervalBytes) {
      run.partialPending = true;
      run.lastPartialBytes = run.audio.length;
      unawaited(_decodePartial(run));
    }
  }

  Future<void> _decodePartial(_OfflineCaptureRun run) async {
    try {
      final result = await _queueDecode(run, run.audio.toBytes());
      if (_active == run && !run.invalidated && !run.finalizing) {
        final text = result.text.trim();
        if (text.isNotEmpty && text != run.lastPartial) {
          run.lastPartial = text;
          _partials.add(text);
        }
      }
    } catch (_) {
      // A rolling partial is advisory; endpoint decoding remains authoritative.
    } finally {
      run.partialPending = false;
    }
  }

  Future<void> _finalize(_OfflineCaptureRun run) async {
    try {
      final result = await _queueDecode(run, run.audio.toBytes());
      if (_active != run || run.invalidated || run.result.isCompleted) return;
      run.result.complete(
        VoiceCapture(
          audio: run.audio.toBytes(),
          transcript: result.text.trim(),
          duration: Duration(
            microseconds:
                run.audio.length *
                Duration.microsecondsPerSecond ~/
                _bytesPerSecond,
          ),
          confidence: 0,
        ),
      );
    } catch (error, stackTrace) {
      if (_active == run && !run.invalidated && !run.result.isCompleted) {
        run.result.completeError(error, stackTrace);
      }
    }
  }

  Future<OfflineWhisperResult> _queueDecode(
    _OfflineCaptureRun run,
    Uint8List snapshot,
  ) {
    final result = Completer<OfflineWhisperResult>();
    run.decodeBarrier = run.decodeBarrier.then((_) async {
      try {
        result.complete(
          await transcriber.transcribe(
            generation: run.generation,
            pcm16: snapshot,
            languageMode: languageMode(),
          ),
        );
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  void _invalidate(_OfflineCaptureRun run) {
    if (run.invalidated) return;
    run.invalidated = true;
    transcriber.invalidate(run.generation);
    if (_active == run) _active = null;
  }

  Future<void> _beginTeardown(_OfflineCaptureRun run) {
    final existing = run.teardown;
    if (existing != null) return existing;
    _invalidate(run);
    final cancelSubscription = Future.sync(
      () => run.subscription?.cancel() ?? Future<void>.value(),
    );
    final stopCapture = Future.sync(
      () => audioEngine.stopCapture(generation: run.generation),
    );
    final teardown = Future.wait<void>([
      cancelSubscription,
      stopCapture,
    ]).then<void>((_) {});
    run.teardown = teardown;
    _teardownBarrier = teardown;
    return teardown;
  }

  @override
  Future<void> cancel() {
    final run = _active;
    if (run == null) return _teardownBarrier;
    _invalidate(run);
    if (!run.result.isCompleted) {
      run.result.completeError(const OfflineVoiceCaptureCancelled());
    }
    return _beginTeardown(run);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final transcriberLifecycle = transcriber;
    final vadLifecycle = vad;
    try {
      await Future.wait<void>([
        Future<void>.sync(cancel),
        if (transcriberLifecycle is OfflineVoiceTranscriberLifecycle)
          Future<void>.sync(
            () => (transcriberLifecycle as OfflineVoiceTranscriberLifecycle)
                .dispose(),
          ),
        if (vadLifecycle is OfflineVoiceActivityDetectorLifecycle)
          Future<void>.sync(
            () => (vadLifecycle as OfflineVoiceActivityDetectorLifecycle)
                .dispose(),
          ),
      ]);
    } finally {
      await _partials.close();
    }
  }
}

class _OfflineCaptureRun {
  _OfflineCaptureRun(this.generation);

  final int generation;
  final audio = BytesBuilder(copy: false);
  final result = Completer<VoiceCapture>();
  Future<void> decodeBarrier = Future<void>.value();
  StreamSubscription<VoiceAudioChunk>? subscription;
  Future<void>? teardown;
  bool speechStarted = false;
  bool finalizing = false;
  bool partialPending = false;
  bool invalidated = false;
  int lastPartialBytes = 0;
  String? lastPartial;
}
