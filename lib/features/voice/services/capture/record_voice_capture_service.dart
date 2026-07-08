import 'dart:async';
import 'dart:typed_data';

import 'audio_recorder.dart';
import 'record_voice_capture_policy.dart';
import '../speech/speech_recognizer.dart';
import '../../../../shared/voice/voice_capture_service.dart';

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
    required this._recorder,
    required this._recognizer,
    required this._startedAt,
    required this._clock,
    required this._recorderStarted,
    required this._recognizerStarted,
    required this._policy,
  });

  final AudioRecorder _recorder;
  final SpeechRecognizer _recognizer;
  final DateTime _startedAt;
  final DateTime Function() _clock;
  final Future<void> _recorderStarted;
  final Future<void> _recognizerStarted;
  final RecordVoiceCapturePolicy _policy;
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
      await _recorderStarted;
    } catch (e) {
      failure ??= e;
    }
    try {
      await _recognizerStarted;
    } catch (e) {
      failure ??= e;
    }
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
    if (!_policy.hasUsableTranscript(speech)) {
      throw VoiceCaptureFailure(_policy.emptyTranscriptFailure);
    }

    return VoiceCapture(
      audio: audio,
      transcript: speech.transcript.trim(),
      duration: _clock().difference(_startedAt),
      confidence: speech.confidence,
    );
  }

  Future<void> cancel() async {
    if (!_active) return;
    _active = false;
    try {
      await _recorderStarted;
    } catch (_) {
      /* swallow */
    }
    try {
      await _recognizerStarted;
    } catch (_) {
      /* swallow */
    }
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
  factory RecordVoiceCaptureService({
    required AudioRecorder recorder,
    required SpeechRecognizer recognizer,
    DateTime Function()? clock,
    RecordVoiceCapturePolicy policy = const RecordVoiceCapturePolicy(),
  }) {
    return RecordVoiceCaptureService._(
      recorder: recorder,
      recognizer: recognizer,
      clock: clock ?? DateTime.now,
      policy: policy,
    );
  }

  RecordVoiceCaptureService._({
    required this._recorder,
    required this._recognizer,
    required this._clock,
    required this._policy,
  });

  final AudioRecorder _recorder;
  final SpeechRecognizer _recognizer;
  final DateTime Function() _clock;
  final RecordVoiceCapturePolicy _policy;

  /// Starts a push-to-talk session. Caller owns stop/cancel.
  VoiceCaptureSession start() {
    final startedAt = _clock();
    // Kick off both engines; we don't await here because the UI wants the
    // session handle immediately. The session records startup futures so stop
    // and cancel observe failures instead of leaking unhandled async errors.
    final recorderStarted = _observeStartup(_recorder.start());
    final recognizerStarted = _observeStartup(_recognizer.start());
    return VoiceCaptureSession._(
      recorder: _recorder,
      recognizer: _recognizer,
      startedAt: startedAt,
      clock: _clock,
      recorderStarted: recorderStarted,
      recognizerStarted: recognizerStarted,
      policy: _policy,
    );
  }

  Future<void> _observeStartup(Future<void> startup) {
    return startup.then<void>(
      (_) {},
      onError: (Object error, StackTrace _) {
        throw error;
      },
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
