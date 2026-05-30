import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/protocol/voice_unavailable_reason.dart';
import '../capture/voice_capture_service.dart';

const noSpeechDetectedVoiceCaptureMessage =
    'No speech was detected. Check microphone permission, device speech recognition, or try speaking closer to the mic.';
const deviceSpeechUnavailableVoiceCaptureMessage =
    'Device speech recognition is unavailable. Install or enable device speech recognition, then return to Navivox.';
const microphonePermissionDeniedVoiceCaptureMessage =
    'Microphone permission denied. Grant microphone permission in Android App info, then return to Navivox.';

typedef SpeechToTextDiagnosticLog = void Function(String message);

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

class SpeechToTextLocale {
  const SpeechToTextLocale({required this.localeId, required this.name});

  final String localeId;
  final String name;
}

class DeviceSpeechUnavailable implements Exception {
  const DeviceSpeechUnavailable([this.message = deviceSttUnavailableReason]);

  final String message;

  @override
  String toString() => message;
}

class SpeechToTextCaptureFailure implements Exception {
  const SpeechToTextCaptureFailure(this.cause);

  final Object cause;

  bool get isNoTranscript {
    final error = cause;
    if (error is SpeechRecognitionError) {
      return _isNoTranscriptReason(error.errorMsg);
    }
    return _isNoTranscriptReason(error.toString());
  }

  @override
  String toString() => 'SpeechToTextCaptureFailure: $cause';
}

abstract interface class SpeechToTextEngine {
  Future<bool?> hasPermission();

  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  });

  Future<SpeechToTextLocale?> systemLocale();

  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
  });

  Future<void> stop();

  Future<void> cancel();
}

class PluginSpeechToTextEngine implements SpeechToTextEngine {
  PluginSpeechToTextEngine({stt.SpeechToText? speechToText})
    : _speechToText = speechToText ?? stt.SpeechToText();

  final stt.SpeechToText _speechToText;

  @override
  Future<bool?> hasPermission() => _speechToText.hasPermission;

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
  Future<SpeechToTextLocale?> systemLocale() async {
    final locale = await _speechToText.systemLocale();
    if (locale == null) return null;
    return SpeechToTextLocale(localeId: locale.localeId, name: locale.name);
  }

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
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
        localeId: localeId,
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
    SpeechToTextDiagnosticLog? diagnosticLog,
    this.localeId,
    this.pauseFor = const Duration(seconds: 4),
  }) : _engine = engine ?? PluginSpeechToTextEngine(),
       _clock = clock ?? DateTime.now,
       _diagnosticLog = diagnosticLog ?? _defaultDiagnosticLog;

  final SpeechToTextEngine _engine;
  final DateTime Function() _clock;
  final SpeechToTextDiagnosticLog _diagnosticLog;
  final String? localeId;
  final Duration pauseFor;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    final startedAt = _clock();
    final completion = Completer<SpeechToTextSnapshot>();
    SpeechToTextSnapshot? latestTranscript;
    var listening = false;

    void log(String message) {
      try {
        _diagnosticLog(message);
      } catch (_) {
        // Diagnostics must never break capture.
      }
    }

    void completeWithError(Object error) {
      log(_formatErrorDiagnostic(error));
      if (!completion.isCompleted) {
        completion.completeError(_normalizeError(error));
      }
    }

    try {
      final permissionBeforeInitialize = await _readPermissionDiagnostic(log);
      log('hasPermission=$permissionBeforeInitialize before initialize');

      final available = await _engine.initialize(
        onError: completeWithError,
        onStatus: (status) {
          log('status=$status');
          final normalized = status.trim().toLowerCase();
          if ((normalized == 'done' || normalized == 'notlistening') &&
              !completion.isCompleted) {
            final snapshot = latestTranscript;
            if (snapshot != null) {
              completion.complete(snapshot);
              return;
            }
            completion.completeError(
              const SpeechToTextCaptureFailure('no transcript'),
            );
          }
        },
      );
      log('initialize=$available');
      if (!available) {
        throw DeviceSpeechUnavailable(
          permissionBeforeInitialize == false
              ? microphonePermissionDeniedReason
              : deviceSttUnavailableReason,
        );
      }

      final effectiveLocaleId = localeId ?? await _readSystemLocale(log);
      log(
        'listen locale=${effectiveLocaleId ?? 'system default'} '
        'listenFor=${timeout.inMilliseconds}ms '
        'pauseFor=${pauseFor.inMilliseconds}ms partialResults=true',
      );
      await _engine.listen(
        listenFor: timeout,
        pauseFor: pauseFor,
        localeId: effectiveLocaleId,
        onResult: (snapshot) {
          log(
            'result recognizedWords="${snapshot.words}" '
            'confidence=${snapshot.confidence} finalResult=${snapshot.finalResult}',
          );
          if (snapshot.words.trim().isNotEmpty) {
            latestTranscript = snapshot;
          }
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
      final normalized = _normalizeError(error);
      if (normalized is DeviceSpeechUnavailable) throw normalized;
      if (normalized is SpeechToTextCaptureFailure) throw normalized;
      throw SpeechToTextCaptureFailure(error);
    }
  }

  Future<bool?> _readPermissionDiagnostic(
    void Function(String message) log,
  ) async {
    try {
      return await _engine.hasPermission();
    } catch (error) {
      log('hasPermission error=$error');
      return null;
    }
  }

  Future<String?> _readSystemLocale(void Function(String message) log) async {
    try {
      final locale = await _engine.systemLocale();
      if (locale == null) {
        log('systemLocale=null');
        return null;
      }
      log('systemLocale=${locale.localeId} (${locale.name})');
      return locale.localeId;
    } catch (error) {
      log('systemLocale error=$error');
      return null;
    }
  }

  Object _normalizeError(Object error) {
    if (error is SpeechRecognitionError) {
      if (_isNoTranscriptReason(error.errorMsg)) {
        return const SpeechToTextCaptureFailure('no transcript');
      }
      if (error.permanent) {
        return DeviceSpeechUnavailable(
          _deviceSpeechUnavailableMessage(error.errorMsg),
        );
      }
    }
    if (error is stt.ListenFailedException) {
      return DeviceSpeechUnavailable(
        _deviceSpeechUnavailableMessage(
          '${error.message ?? ''} ${error.details ?? ''}',
        ),
      );
    }
    return SpeechToTextCaptureFailure(error);
  }

  String _deviceSpeechUnavailableMessage(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.contains('permission') ||
        normalized.contains('denied') ||
        normalized.contains('not_allowed') ||
        normalized.contains('not allowed')) {
      return microphonePermissionDeniedReason;
    }
    return deviceSttUnavailableReason;
  }
}

String _formatErrorDiagnostic(Object error) {
  if (error is SpeechRecognitionError) {
    return 'error errorMsg=${error.errorMsg} permanent=${error.permanent}';
  }
  return 'error=$error';
}

bool _isNoTranscriptReason(String reason) {
  final normalized = reason.trim().toLowerCase();
  return normalized == 'no transcript' ||
      normalized == 'empty transcript' ||
      normalized.contains('error_no_match') ||
      normalized.contains('error_speech_timeout');
}

void _defaultDiagnosticLog(String message) {
  developer.log(message, name: 'navivox.voice.speech_to_text');
}
