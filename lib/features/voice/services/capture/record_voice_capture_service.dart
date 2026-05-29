import 'dart:async';
import 'dart:typed_data';

import 'audio_recorder.dart';
import '../speech/speech_recognizer.dart';
import 'voice_capture_service.dart';

class VoiceCaptureFailure implements Exception {
  const VoiceCaptureFailure(this.cause);
  final Object cause;
  @override
  String toString() => 'VoiceCaptureFailure: $cause';
}

/// Push-to-talk session: hold to record, release to send. Returned by
/// [RecordVoiceCaptureService.start] so the UI can show interim transcripts
/// and stop or cancel on demand.
class VoiceCaptureSession {
  VoiceCaptureSession._({
    required AudioRecorder recorder,
    required SpeechRecognizer recognizer,
    required DateTime startedAt,
    required DateTime Function() clock,
  }) : _recorder = recorder,
       _recognizer = recognizer,
       _startedAt = startedAt,
       _clock = clock;

  final AudioRecorder _recorder;
  final SpeechRecognizer _recognizer;
  final DateTime _startedAt;
  final DateTime Function() _clock;
  bool _active = true;

  bool get isActive => _active;

  Stream<String> get interimTranscripts => _recognizer.interimTranscripts;

  Future<VoiceCapture> stop() async {
    if (!_active) {
      throw const VoiceCaptureFailure('session already finished');
    }
    _active = false;
    Object? failure;
    Uint8List audio = Uint8List(0);
    SpeechResult speech = const SpeechResult(transcript: '', confidence: 0);

    try {
      audio = await _recorder.stop();
    } catch (e) {
      failure ??= e;
    }
    try {
      speech = await _recognizer.stop();
    } catch (e) {
      failure ??= e;
    }
    if (failure != null) throw VoiceCaptureFailure(failure);

    return VoiceCapture(
      audio: audio,
      transcript: speech.transcript,
      duration: _clock().difference(_startedAt),
      confidence: speech.confidence,
    );
  }

  Future<void> cancel() async {
    if (!_active) return;
    _active = false;
    try {
      await _recorder.cancel();
    } catch (_) {
      /* swallow */
    }
    try {
      await _recognizer.cancel();
    } catch (_) {
      /* swallow */
    }
  }
}

class RecordVoiceCaptureService implements VoiceCaptureService {
  RecordVoiceCaptureService({
    required AudioRecorder recorder,
    required SpeechRecognizer recognizer,
    DateTime Function()? clock,
  }) : _recorder = recorder,
       _recognizer = recognizer,
       _clock = clock ?? DateTime.now;

  final AudioRecorder _recorder;
  final SpeechRecognizer _recognizer;
  final DateTime Function() _clock;

  /// Starts a push-to-talk session. Caller owns stop/cancel.
  VoiceCaptureSession start() {
    final startedAt = _clock();
    // Kick off both engines; we don't await here because the UI wants the
    // session handle immediately and the platform plugins resolve quickly.
    unawaited(_recorder.start());
    unawaited(_recognizer.start());
    return VoiceCaptureSession._(
      recorder: _recorder,
      recognizer: _recognizer,
      startedAt: startedAt,
      clock: _clock,
    );
  }

  /// Auto-stop variant: starts a session, then races the recognizer's
  /// `onFinal` signal against [timeout]. On timeout the session is cancelled
  /// and a [VoiceCaptureTimeout] is thrown.
  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    final session = start();
    try {
      await _recognizer.onFinal.timeout(
        timeout,
        onTimeout: () async {
          await session.cancel();
          throw const VoiceCaptureTimeout();
        },
      );
      return await session.stop();
    } on VoiceCaptureTimeout {
      rethrow;
    } catch (e) {
      // If anything went wrong mid-flight, ensure the engines are released.
      await session.cancel();
      if (e is VoiceCaptureFailure) rethrow;
      throw VoiceCaptureFailure(e);
    }
  }
}
