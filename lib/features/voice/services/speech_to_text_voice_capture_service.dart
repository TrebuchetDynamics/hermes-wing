import 'dart:async';
import 'dart:typed_data';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'voice_capture_service.dart';

class SpeechToTextSnapshot {
  const SpeechToTextSnapshot({
    required this.words,
    required this.confidence,
    required this.finalResult,
  });

  final String words;
  final double confidence;
  final bool finalResult;
}

class DeviceSpeechUnavailable implements Exception {
  const DeviceSpeechUnavailable([this.message = 'device STT unavailable']);

  final String message;

  @override
  String toString() => message;
}

class SpeechToTextCaptureFailure implements Exception {
  const SpeechToTextCaptureFailure(this.cause);

  final Object cause;

  @override
  String toString() => 'SpeechToTextCaptureFailure: $cause';
}

abstract interface class SpeechToTextEngine {
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  });

  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
  });

  Future<void> stop();

  Future<void> cancel();
}

class PluginSpeechToTextEngine implements SpeechToTextEngine {
  PluginSpeechToTextEngine({stt.SpeechToText? speechToText})
    : _speechToText = speechToText ?? stt.SpeechToText();

  final stt.SpeechToText _speechToText;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) {
    return _speechToText.initialize(
      onError: (SpeechRecognitionError error) => onError(error),
      onStatus: onStatus,
    );
  }

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
  }) async {
    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) => onResult(
        SpeechToTextSnapshot(
          words: result.recognizedWords,
          confidence: result.confidence,
          finalResult: result.finalResult,
        ),
      ),
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        listenFor: listenFor,
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        pauseFor: pauseFor,
      ),
    );
  }

  @override
  Future<void> stop() => _speechToText.stop();

  @override
  Future<void> cancel() => _speechToText.cancel();
}

class SpeechToTextVoiceCaptureService implements VoiceCaptureService {
  SpeechToTextVoiceCaptureService({
    SpeechToTextEngine? engine,
    DateTime Function()? clock,
    this.pauseFor = const Duration(seconds: 2),
  }) : _engine = engine ?? PluginSpeechToTextEngine(),
       _clock = clock ?? DateTime.now;

  final SpeechToTextEngine _engine;
  final DateTime Function() _clock;
  final Duration pauseFor;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    final startedAt = _clock();
    final completion = Completer<SpeechToTextSnapshot>();
    var listening = false;

    void completeWithError(Object error) {
      if (!completion.isCompleted) {
        completion.completeError(_normalizeError(error));
      }
    }

    try {
      final available = await _engine.initialize(
        onError: completeWithError,
        onStatus: (status) {
          final normalized = status.trim().toLowerCase();
          if ((normalized == 'done' || normalized == 'notlistening') &&
              !completion.isCompleted) {
            completion.completeError(
              const SpeechToTextCaptureFailure('no transcript'),
            );
          }
        },
      );
      if (!available) throw const DeviceSpeechUnavailable();

      await _engine.listen(
        listenFor: timeout,
        pauseFor: pauseFor,
        onResult: (snapshot) {
          if (snapshot.finalResult && !completion.isCompleted) {
            completion.complete(snapshot);
          }
        },
      );
      listening = true;

      final snapshot = await completion.future.timeout(
        timeout,
        onTimeout: () async {
          listening = false;
          await _engine.cancel();
          throw const VoiceCaptureTimeout();
        },
      );
      listening = false;
      await _engine.stop();

      final transcript = snapshot.words.trim();
      if (transcript.isEmpty) {
        throw const SpeechToTextCaptureFailure('empty transcript');
      }

      return VoiceCapture(
        audio: Uint8List(0),
        transcript: transcript,
        duration: _clock().difference(startedAt),
        confidence: snapshot.confidence,
      );
    } on VoiceCaptureTimeout {
      rethrow;
    } catch (error) {
      if (listening) await _engine.cancel();
      if (error is DeviceSpeechUnavailable ||
          error is SpeechToTextCaptureFailure) {
        rethrow;
      }
      throw SpeechToTextCaptureFailure(error);
    }
  }

  Object _normalizeError(Object error) {
    if (error is SpeechRecognitionError && error.permanent) {
      return DeviceSpeechUnavailable(error.errorMsg);
    }
    return SpeechToTextCaptureFailure(error);
  }
}
