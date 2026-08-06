import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../shared/async/fire_and_forget.dart';
import '../../../../shared/voice/voice_capture_failures.dart';
import '../../../../shared/voice/voice_capture_service.dart';
import 'speech_to_text_capture_coordinator.dart';
import 'speech_to_text_capture_policy.dart';

export '../../../../shared/voice/voice_capture_failures.dart';
export 'speech_to_text_capture_policy.dart' show SpeechToTextSnapshot;

typedef SpeechToTextDiagnosticLog = void Function(String message);
typedef SpeechToTextReadinessCheck = Future<String?> Function();

class SpeechToTextLocale {
  const SpeechToTextLocale({required this.localeId, required this.name});

  final String localeId;
  final String name;
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
    required bool onDevice,
  });

  Future<void> stop();

  Future<void> cancel();
}

abstract interface class SpeechToTextSoundLevelEngine {
  Stream<double> get soundLevels;
}

class PluginSpeechToTextEngine
    implements SpeechToTextEngine, SpeechToTextSoundLevelEngine {
  PluginSpeechToTextEngine({
    stt.SpeechToText? speechToText,
    this.androidIntentLookup = false,
    this.androidNoBluetooth = false,
  }) : _speechToText = speechToText ?? stt.SpeechToText();

  final stt.SpeechToText _speechToText;
  final _soundLevels = StreamController<double>.broadcast();
  final bool androidIntentLookup;
  final bool androidNoBluetooth;

  @override
  Stream<double> get soundLevels => _soundLevels.stream;

  @override
  Future<bool?> hasPermission() => _speechToText.hasPermission;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) {
    final options = [
      if (androidIntentLookup) stt.SpeechToText.androidIntentLookup,
      if (androidNoBluetooth) stt.SpeechToText.androidNoBluetooth,
    ];
    return _speechToText.initialize(
      onError: (SpeechRecognitionError error) => onError(error),
      onStatus: onStatus,
      options: options.isEmpty ? null : options,
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
    required bool onDevice,
  }) async {
    await _speechToText.listen(
      onSoundLevelChange: _soundLevels.add,
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
        onDevice: onDevice,
      ),
    );
  }

  @override
  Future<void> stop() => _speechToText.stop();

  @override
  Future<void> cancel() => _speechToText.cancel();
}

class SpeechToTextVoiceCaptureService
    implements
        VoiceCaptureService,
        VoiceCaptureProgressService,
        VoiceCaptureSoundLevelService {
  factory SpeechToTextVoiceCaptureService({
    SpeechToTextEngine? engine,
    DateTime Function()? clock,
    SpeechToTextDiagnosticLog? diagnosticLog,
    SpeechToTextReadinessCheck? readinessCheck,
    SpeechToTextCaptureCoordinator coordinator =
        const SpeechToTextCaptureCoordinator(),
    String? localeId,
    Duration pauseFor = const Duration(seconds: 4),
    Duration partialResultPauseFor = const Duration(milliseconds: 2500),
    bool onDeviceOnly = true,
  }) {
    return SpeechToTextVoiceCaptureService._(
      engine: engine ?? PluginSpeechToTextEngine(),
      clock: clock ?? DateTime.now,
      diagnosticLog: diagnosticLog ?? _defaultDiagnosticLog,
      readinessCheck: readinessCheck,
      coordinator: coordinator,
      localeId: localeId,
      pauseFor: pauseFor,
      partialResultPauseFor: partialResultPauseFor,
      onDeviceOnly: onDeviceOnly,
    );
  }

  SpeechToTextVoiceCaptureService._({
    required this._engine,
    required this._clock,
    required this._diagnosticLog,
    required this._readinessCheck,
    required this._coordinator,
    this.localeId,
    required this.pauseFor,
    required this.partialResultPauseFor,
    required this.onDeviceOnly,
  });

  final SpeechToTextEngine _engine;
  final DateTime Function() _clock;
  final SpeechToTextDiagnosticLog _diagnosticLog;
  final SpeechToTextReadinessCheck? _readinessCheck;
  final SpeechToTextCaptureCoordinator _coordinator;
  final String? localeId;
  final Duration pauseFor;
  final Duration partialResultPauseFor;
  final bool onDeviceOnly;
  final _partialTranscripts = StreamController<String>.broadcast(sync: true);
  final _soundLevels = StreamController<double>.broadcast(sync: true);
  bool _initialized = false;
  Completer<void>? _activeCancellation;
  Completer<SpeechToTextSnapshot>? _activeCompletion;
  void Function(Object error)? _onError;
  void Function(String status)? _onStatus;

  @override
  Stream<String> get partialTranscripts => _partialTranscripts.stream;

  @override
  Stream<double> get soundLevels => _soundLevels.stream;

  @override
  Future<void> cancel() {
    final cancellation = _activeCancellation;
    if (cancellation != null && !cancellation.isCompleted) {
      cancellation.complete();
    }
    final completion = _activeCompletion;
    if (completion != null && !completion.isCompleted) {
      completion.completeError(
        const SpeechToTextCaptureFailure('capture cancelled'),
      );
    }
    return _engine.cancel();
  }

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    final startedAt = _clock();
    final elapsed = Stopwatch()..start();
    final cancellation = Completer<void>();
    final completion = Completer<SpeechToTextSnapshot>();
    _activeCancellation = cancellation;
    _activeCompletion = completion;
    unawaited(
      completion.future.then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {},
      ),
    );
    SpeechToTextSnapshot? latestTranscript;
    Timer? partialResultTimer;
    var recognitionStarted = false;
    final soundLevelSubscription =
        (_engine is SpeechToTextSoundLevelEngine
                ? (_engine as SpeechToTextSoundLevelEngine).soundLevels
                : null)
            ?.listen(_soundLevels.add);

    void cancelPartialResultTimer() => partialResultTimer?.cancel();

    void log(String message) {
      try {
        _diagnosticLog(message);
      } catch (_) {
        // Diagnostics must never break capture.
      }
    }

    void completeWithError(Object error) {
      cancelPartialResultTimer();
      log(_coordinator.errorDiagnostic(error));
      if (!completion.isCompleted) {
        completion.completeError(_coordinator.normalizeError(error));
      }
    }

    Future<T> bounded<T>(Future<T> operation) {
      final remaining = timeout - elapsed.elapsed;
      if (remaining <= Duration.zero) {
        if (!cancellation.isCompleted) {
          fireAndForget(_engine.cancel(), 'speech engine cancel on timeout');
        }
        throw const VoiceCaptureTimeout();
      }
      return operation.timeout(
        remaining,
        onTimeout: () {
          // Never await the cancel: Android leaves it pending forever after
          // the recognizer reports NO_SPEECH_DETECTED, which would strand the
          // capture with a spinning mic and no error.
          if (!cancellation.isCompleted) {
            fireAndForget(_engine.cancel(), 'speech engine cancel on timeout');
          }
          throw const VoiceCaptureTimeout();
        },
      );
    }

    Future<T> cancellable<T>(Future<T> operation) => Future.any([
      bounded(operation),
      cancellation.future.then<T>(
        (_) => throw const SpeechToTextCaptureFailure('capture cancelled'),
      ),
    ]);

    try {
      final unavailableReason = await cancellable(
        _readinessCheck?.call() ?? Future<String?>.value(),
      );
      if (unavailableReason != null) {
        throw DeviceSpeechUnavailable(unavailableReason);
      }
      final permissionBeforeInitialize = await cancellable(
        _readPermissionDiagnostic(log),
      );
      log('hasPermission=$permissionBeforeInitialize before initialize');

      final available = await cancellable(
        _initialize(
          onError: completeWithError,
          onStatus: (status) {
            log('status=$status');
            if (completion.isCompleted) return;
            final normalizedStatus = status.trim().toLowerCase();
            if (normalizedStatus == 'listening') recognitionStarted = true;
            if (isTerminalSpeechToTextStatus(status) &&
                !recognitionStarted &&
                latestTranscript == null) {
              return;
            }
            switch (_coordinator.terminalStatusPlan(
              status: status,
              latestTranscript: latestTranscript,
            )) {
              case IgnoreSpeechToTextTerminalStatusPlan():
                break;
              case CompleteSpeechToTextTerminalStatusPlan(:final snapshot):
                cancelPartialResultTimer();
                completion.complete(snapshot);
              case FailSpeechToTextTerminalStatusPlan(:final error):
                completion.completeError(error);
            }
          },
        ),
      );
      log('initialize=$available');
      if (!available) {
        throw DeviceSpeechUnavailable(
          _coordinator.unavailableReasonForInitialize(
            permissionBeforeInitialize: permissionBeforeInitialize,
          ),
        );
      }

      final effectiveLocaleId =
          localeId ?? await cancellable(_readSystemLocale(log));
      log(
        'listen locale=${effectiveLocaleId ?? 'system default'} '
        'listenFor=${timeout.inMilliseconds}ms '
        'pauseFor=${pauseFor.inMilliseconds}ms partialResults=true '
        'onDevice=$onDeviceOnly',
      );
      await cancellable(
        _engine.listen(
          listenFor: timeout,
          pauseFor: pauseFor,
          localeId: effectiveLocaleId,
          onDevice: onDeviceOnly,
          onResult: (snapshot) {
            recognitionStarted = true;
            log(
              'result wordsLength=${snapshot.words.length} '
              'confidence=${snapshot.confidence} finalResult=${snapshot.finalResult}',
            );
            final transcript = snapshot.words.trim();
            if (transcript.isNotEmpty) _partialTranscripts.add(transcript);
            latestTranscript = _coordinator.latestUsableTranscript(
              current: latestTranscript,
              candidate: snapshot,
            );
            if (snapshot.finalResult && !completion.isCompleted) {
              cancelPartialResultTimer();
              completion.complete(
                _coordinator.completionTranscript(
                  terminalSnapshot: snapshot,
                  latestUsableSnapshot: latestTranscript,
                ),
              );
            } else if (snapshot.words.trim().isNotEmpty) {
              cancelPartialResultTimer();
              partialResultTimer = Timer(partialResultPauseFor, () {
                if (!completion.isCompleted) {
                  fireAndForget(
                    _engine.stop(),
                    'speech engine stop after partial transcript inactivity',
                  );
                }
              });
            }
          },
        ),
      );

      final snapshot = await bounded(completion.future);
      cancelPartialResultTimer();
      await cancellable(_engine.stop());

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
      cancelPartialResultTimer();
      rethrow;
    } catch (error) {
      cancelPartialResultTimer();
      if (!cancellation.isCompleted) {
        fireAndForget(
          _engine.cancel(),
          'speech engine cancel after capture failure',
        );
      }
      if (error is DeviceSpeechUnavailable ||
          error is SpeechToTextCaptureFailure) {
        rethrow;
      }
      final normalized = _coordinator.normalizeError(error);
      if (normalized is DeviceSpeechUnavailable) throw normalized;
      if (normalized is SpeechToTextCaptureFailure) throw normalized;
      throw SpeechToTextCaptureFailure(error);
    } finally {
      if (identical(_activeCancellation, cancellation)) {
        _activeCancellation = null;
      }
      if (identical(_activeCompletion, completion)) _activeCompletion = null;
      await soundLevelSubscription?.cancel();
    }
  }

  Future<bool> _initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    _onError = onError;
    _onStatus = onStatus;
    if (_initialized) return true;
    _initialized = await _engine.initialize(
      onError: (error) => _onError?.call(error),
      onStatus: (status) => _onStatus?.call(status),
    );
    return _initialized;
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
}

void _defaultDiagnosticLog(String message) {
  developer.log(message, name: 'wing.voice.speech_to_text');
}
