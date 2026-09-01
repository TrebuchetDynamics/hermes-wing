import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_chat_turn.dart';
import '../../../core/protocol/voice/models/wing_voice_run.dart';
import '../../../shared/async/fire_and_forget.dart';
import '../../../shared/security/wing_redaction.dart';
import '../../../shared/voice/text_to_speech_service.dart';
import '../../../shared/voice/voice_capture_failures.dart';
import '../../../shared/voice/voice_capture_service.dart';
import '../../../shared/voice/voice_settings.dart';
import 'hermes_continuous_voice_reply_policy.dart';
import 'hermes_spoken_text.dart';
import 'hermes_voice_capture_flow.dart';
import 'hermes_voice_failure.dart';

typedef HermesChannelReader = HermesChannel Function();
typedef VoiceCaptureServiceReader = VoiceCaptureService? Function();
typedef TextToSpeechServiceReader = TextToSpeechService? Function();
typedef VoiceSettingsReader = WingVoiceSettings Function();
typedef HermesVoiceFailureMessage =
    String Function(HermesVoiceFailure failure, String? detail);
typedef HermesVoiceContinuousPausedMessage = String Function(String message);

String _defaultVoiceFailureMessage(HermesVoiceFailure failure, String? detail) {
  return switch (failure) {
    HermesVoiceFailure.timedOut => 'Voice capture timed out.',
    HermesVoiceFailure.microphonePermissionDenied =>
      microphonePermissionDeniedVoiceCaptureMessage,
    HermesVoiceFailure.deviceLanguageUnavailable =>
      deviceSpeechLanguageUnavailableVoiceCaptureMessage,
    HermesVoiceFailure.deviceSpeechUnavailable =>
      deviceSpeechUnavailableVoiceCaptureMessage,
    HermesVoiceFailure.noSpeech => noSpeechDetectedVoiceCaptureMessage,
    HermesVoiceFailure.generic =>
      detail == null || detail.isEmpty
          ? 'Voice capture failed.'
          : 'Voice capture failed: $detail',
    HermesVoiceFailure.captureSessionChanged =>
      'Voice capture was discarded because the Hermes session changed.',
    HermesVoiceFailure.inputUnavailable => 'Voice input is not available here.',
    HermesVoiceFailure.turnSendFailed =>
      detail == null || detail.isEmpty
          ? 'Voice turn could not be sent.'
          : 'Voice turn could not be sent: $detail',
    HermesVoiceFailure.shutdownTimedOut =>
      'Voice shutdown timed out. Continuous voice paused.',
    HermesVoiceFailure.shutdownFailed =>
      'Voice shutdown failed. Continuous voice paused.',
    HermesVoiceFailure.playbackUnavailable =>
      'Voice playback is unavailable for this connection. The reply is available as text. Voice input remains available from the microphone.',
    HermesVoiceFailure.playbackUnavailableContinuous =>
      'Voice playback is unavailable for this connection. The reply is available as text. Hands-free listening stopped. Voice input remains available from the microphone.',
    HermesVoiceFailure.playbackFailed =>
      'Voice playback failed. The reply is available as text. Voice input remains available from the microphone.',
    HermesVoiceFailure.playbackFailedContinuous =>
      'Voice playback failed. The reply is available as text. Hands-free listening stopped. Voice input remains available from the microphone.',
    HermesVoiceFailure.playbackSessionChanged =>
      'Hermes session changed before the spoken reply finished.',
    HermesVoiceFailure.playbackSessionChangedContinuous =>
      'Hermes session changed before voice could re-arm. Continuous voice paused.',
    HermesVoiceFailure.pausedByLocalCommand =>
      'Continuous voice paused by local command.',
  };
}

String _defaultVoiceContinuousPausedMessage(String message) =>
    '$message Continuous voice paused.';

String _safeVoiceFailureDetail(String detail) {
  final normalized = detail.replaceFirst(
    RegExp(r'^(?:Bad state|Exception):\s*'),
    '',
  );
  return wingRedactSensitiveText(normalized);
}

/// Owns Hermes voice-input state and lifecycle while the chat widget only
/// renders state and forwards operator intent.
class HermesVoiceInputController extends ChangeNotifier {
  factory HermesVoiceInputController({
    required HermesChannelReader channel,
    required VoiceCaptureServiceReader captureService,
    required TextToSpeechServiceReader textToSpeechService,
    required VoiceSettingsReader settings,
    required ValueChanged<String> onDraft,
    HermesVoiceFailureMessage failureMessage = _defaultVoiceFailureMessage,
    HermesVoiceContinuousPausedMessage continuousPausedMessage =
        _defaultVoiceContinuousPausedMessage,
    Duration rearmDelay = const Duration(milliseconds: 750),
    Duration speechTimeout = const Duration(minutes: 3),
    Duration teardownTimeout = const Duration(seconds: 10),
  }) => HermesVoiceInputController._(
    channel,
    captureService,
    textToSpeechService,
    settings,
    onDraft,
    failureMessage,
    continuousPausedMessage,
    rearmDelay,
    speechTimeout,
    teardownTimeout,
  );

  HermesVoiceInputController._(
    this._channel,
    this._captureService,
    this._textToSpeechService,
    this._settings,
    this._onDraft,
    this._failureMessage,
    this._continuousPausedMessage,
    this._rearmDelay,
    this._speechTimeout,
    this._teardownTimeout,
  );

  final HermesChannelReader _channel;
  final VoiceCaptureServiceReader _captureService;
  final TextToSpeechServiceReader _textToSpeechService;
  final VoiceSettingsReader _settings;
  final ValueChanged<String> _onDraft;
  final HermesVoiceFailureMessage _failureMessage;
  final HermesVoiceContinuousPausedMessage _continuousPausedMessage;
  final Duration _rearmDelay;
  final Duration _speechTimeout;
  final Duration _teardownTimeout;

  bool _capturing = false;
  bool _continuousEnabled = false;
  bool _disposed = false;
  bool _speaking = false;
  bool _speakNextReply = false;
  bool _playbackUnavailable = false;
  int _operationGeneration = 0;
  int _speechGeneration = 0;
  String? _error;
  String? _lastSpokenTurnId;
  String? _spokenReplyPrefix;
  String? _activeSpokenChunk;
  String? _readAloudTurnId;
  int _spokenReplyCharacterCount = 0;
  String? _liveTranscript;
  double? _soundLevel;
  VoiceCaptureService? _activeCaptureService;
  Future<void> _captureTeardown = Future<void>.value();
  Future<void> _speechTeardown = Future<void>.value();
  TextToSpeechService? _activeTextToSpeechService;
  StreamSubscription<String>? _partialTranscriptSubscription;
  StreamSubscription<double>? _soundLevelSubscription;

  bool get capturing => _capturing;
  String? get liveTranscript => _liveTranscript;
  double? get soundLevel => _soundLevel;
  bool get continuousEnabled => _continuousEnabled;
  String? get error => _error;
  bool get speaking => _speaking;
  String? get readAloudTurnId => _readAloudTurnId;
  bool get playbackUnavailable => _playbackUnavailable;

  Future<void> captureDraft() => _capture(autoSend: false);

  void dismissNotice() {
    if (_error == null && !_playbackUnavailable) return;
    _error = null;
    _playbackUnavailable = false;
    notifyListeners();
  }

  void speakNextReply() {
    _baselineAssistantReplies();
    _speakNextReply = true;
  }

  Future<void> readAloud(String text, {String? turnId}) async {
    final phrases = hermesSpokenTextChunks(text);
    if (phrases.isEmpty || _disposed || _capturing || _continuousEnabled) {
      return;
    }
    if (_speaking) await _interruptActiveSpeech();
    if (!await _awaitSpeechTeardown() ||
        _disposed ||
        _capturing ||
        _continuousEnabled) {
      return;
    }
    final tts = _textToSpeechService();
    if (tts == null) {
      _playbackUnavailable = true;
      _error = _failureMessage(HermesVoiceFailure.playbackUnavailable, null);
      notifyListeners();
      return;
    }
    _speakNextReply = false;
    _activeTextToSpeechService = tts;
    _readAloudTurnId = turnId;
    _playbackUnavailable = false;
    _error = null;
    final speechGeneration = ++_speechGeneration;
    _speaking = true;
    notifyListeners();
    try {
      for (final phrase in phrases) {
        if (_disposed || speechGeneration != _speechGeneration) return;
        _activeSpokenChunk = phrase;
        await tts.speak(phrase).timeout(_speechTimeout);
      }
    } catch (_) {
      if (_disposed || speechGeneration != _speechGeneration) return;
      _activeTextToSpeechService = null;
      _activeSpokenChunk = null;
      _readAloudTurnId = null;
      _speaking = false;
      _playbackUnavailable = true;
      _error = _failureMessage(HermesVoiceFailure.playbackFailed, null);
      notifyListeners();
      return;
    }
    if (_disposed || speechGeneration != _speechGeneration) return;
    _activeTextToSpeechService = null;
    _activeSpokenChunk = null;
    _readAloudTurnId = null;
    _speaking = false;
    notifyListeners();
  }

  Future<void> stopSpeaking() => _interruptActiveSpeech();

  Future<void> captureAndSend() async {
    _baselineAssistantReplies();
    _speakNextReply = true;
    await _capture(autoSend: true);
  }

  Future<void> enableContinuous() async {
    _baselineAssistantReplies();
    _speakNextReply = false;
    _continuousEnabled = true;
    _playbackUnavailable = false;
    _error = null;
    notifyListeners();
    await _capture(autoSend: true, continuous: true);
  }

  void _baselineAssistantReplies() {
    _spokenReplyPrefix = null;
    _activeSpokenChunk = null;
    _lastSpokenTurnId = null;
    _spokenReplyCharacterCount = 0;
    for (final turn in _channel().state.activeMessages) {
      if (turn.author == HermesTurnAuthor.assistant) {
        _lastSpokenTurnId = turn.id;
        _spokenReplyCharacterCount = turn.text.length;
      }
    }
  }

  Future<void> _capture({
    required bool autoSend,
    bool continuous = false,
  }) async {
    if (_capturing) return;
    final operationGeneration = ++_operationGeneration;
    _capturing = true;
    _playbackUnavailable = false;
    _error = null;
    _liveTranscript = null;
    _soundLevel = null;
    notifyListeners();

    try {
      await Future.wait<void>([
        _captureTeardown,
        _speechTeardown,
      ]).timeout(_teardownTimeout);
    } on TimeoutException {
      if (!_disposed && operationGeneration == _operationGeneration) {
        _capturing = false;
        _continuousEnabled = false;
        _speakNextReply = false;
        _error = _failureMessage(HermesVoiceFailure.shutdownTimedOut, null);
        notifyListeners();
      }
      return;
    } catch (_) {
      if (!_disposed && operationGeneration == _operationGeneration) {
        _capturing = false;
        _continuousEnabled = false;
        _speakNextReply = false;
        _error = _failureMessage(HermesVoiceFailure.shutdownFailed, null);
        notifyListeners();
      }
      return;
    }
    if (_disposed || operationGeneration != _operationGeneration) return;

    final channel = _channel();
    final captureSessionId = channel.state.activeSessionId;
    final service = _captureService();
    _activeCaptureService = service;
    unawaited(_partialTranscriptSubscription?.cancel());
    unawaited(_soundLevelSubscription?.cancel());
    final VoiceCaptureProgressService? progressService =
        service is VoiceCaptureProgressService
        ? service as VoiceCaptureProgressService
        : null;
    _partialTranscriptSubscription = progressService?.partialTranscripts.listen(
      (transcript) {
        if (_disposed || operationGeneration != _operationGeneration) {
          return;
        }
        final trimmed = transcript.trim();
        if (trimmed.isEmpty) return;
        _liveTranscript = trimmed;
        if ((continuous || _continuousEnabled) &&
            _speaking &&
            !_isPossibleSpokenReplyEcho(trimmed)) {
          unawaited(_interruptActiveSpeech());
        }
        notifyListeners();
      },
    );
    final VoiceCaptureSoundLevelService? soundLevelService =
        service is VoiceCaptureSoundLevelService
        ? service as VoiceCaptureSoundLevelService
        : null;
    _soundLevelSubscription = soundLevelService?.soundLevels.listen((level) {
      if (_disposed || operationGeneration != _operationGeneration) return;
      _soundLevel = level;
      notifyListeners();
    });
    notifyListeners();

    final outcome = await const HermesVoiceCaptureFlow().capture(
      service: service,
      timeout: continuous
          ? const Duration(minutes: 5)
          : const Duration(seconds: 12),
    );
    if (_disposed || operationGeneration != _operationGeneration) return;
    final effectiveContinuous = continuous || _continuousEnabled;

    _activeCaptureService = null;
    unawaited(_partialTranscriptSubscription?.cancel());
    _partialTranscriptSubscription = null;
    unawaited(_soundLevelSubscription?.cancel());
    _soundLevelSubscription = null;
    _soundLevel = null;
    if (!channel.state.isConnected ||
        channel.state.activeSessionId != captureSessionId) {
      _capturing = false;
      _recordCaptureFailure(
        _failureMessage(HermesVoiceFailure.captureSessionChanged, null),
        continuous: effectiveContinuous,
      );
      notifyListeners();
      return;
    }

    switch (outcome.status) {
      case HermesVoiceCaptureStatus.unavailable:
        _capturing = false;
        _recordCaptureFailure(
          _failureMessage(HermesVoiceFailure.inputUnavailable, null),
          continuous: effectiveContinuous,
        );
      case HermesVoiceCaptureStatus.failed:
        _capturing = false;
        if (effectiveContinuous &&
            (outcome.error is VoiceCaptureTimeout ||
                outcome.error is SpeechToTextCaptureFailure &&
                    (outcome.error! as SpeechToTextCaptureFailure)
                        .isNoTranscript)) {
          notifyListeners();
          unawaited(_rearmContinuousCapture());
          return;
        }
        _recordCaptureFailure(
          _failureMessage(outcome.failure!, outcome.errorDetail),
          continuous: effectiveContinuous,
        );
      case HermesVoiceCaptureStatus.captured:
        final capture = outcome.capture!;
        var transcript = capture.transcript.trim();
        if (capture.audio.isNotEmpty && channel is HermesAudioChannel) {
          try {
            transcript = (await (channel as HermesAudioChannel).transcribePcm16(
              capture.audio,
            )).trim();
          } catch (_) {
            // Device transcription remains the compatibility fallback for
            // older Hermes endpoints and interrupted uploads.
          }
          if (_disposed || operationGeneration != _operationGeneration) return;
          if (!channel.state.isConnected ||
              channel.state.activeSessionId != captureSessionId) {
            _capturing = false;
            _recordCaptureFailure(
              _failureMessage(HermesVoiceFailure.captureSessionChanged, null),
              continuous: effectiveContinuous,
            );
            notifyListeners();
            return;
          }
        }
        if (effectiveContinuous && _isSpokenReplyEcho(transcript)) {
          // Keep the reply fingerprint for the next capture too. Android can
          // return the same speaker playback in more than one recognition
          // result while its acoustic echo canceller settles.
          _capturing = false;
          notifyListeners();
          unawaited(_rearmContinuousCapture());
          return;
        }
        if (effectiveContinuous && _speaking) {
          await _interruptActiveSpeech();
          if (_disposed || operationGeneration != _operationGeneration) return;
        }
        _activeSpokenChunk = null;
        if (effectiveContinuous && _handleLocalCommand(transcript)) {
          // pause() inside _handleLocalCommand already reset _capturing.
          break;
        }
        _capturing = false;
        if (!autoSend) {
          _onDraft(transcript);
          if (_continuousEnabled && !continuous) {
            unawaited(_rearmContinuousCapture());
          }
          break;
        }
        if (effectiveContinuous &&
            captureSessionId != null &&
            channel.state.isSessionStreaming(captureSessionId)) {
          channel.stopActiveTurn();
        }
        final voiceRunId = channel.startVoiceRun();
        channel.stageVoiceRunTranscript(
          voiceRunId: voiceRunId,
          transcript: transcript,
          duration: capture.duration,
          confidence: capture.confidence,
        );
        channel.submitVoiceRun(voiceRunId);
        final run = channel.state.voiceRuns[voiceRunId];
        if (run?.status == WingVoiceRunStatus.failed) {
          final reason = run?.reason?.trim();
          final safeReason = reason == null || reason.isEmpty
              ? null
              : _safeVoiceFailureDetail(reason);
          _recordCaptureFailure(
            _failureMessage(HermesVoiceFailure.turnSendFailed, safeReason),
            continuous: _continuousEnabled,
          );
        } else if (_continuousEnabled) {
          unawaited(_rearmContinuousCapture());
        }
    }
    if (_disposed) return;
    notifyListeners();
  }

  void _recordCaptureFailure(String message, {required bool continuous}) {
    _speakNextReply = false;
    if (continuous) {
      _continuousEnabled = false;
      _error = _continuousPausedMessage(message);
      return;
    }
    _error = message;
  }

  Future<void> maybeContinue() async {
    if ((!_continuousEnabled && !_speakNextReply) || _speaking || _disposed) {
      return;
    }
    if (!await _awaitSpeechTeardown()) return;
    if ((!_continuousEnabled && !_speakNextReply) || _speaking || _disposed) {
      return;
    }
    final settings = _settings();
    if (_continuousEnabled && !settings.speakRepliesEnabled) {
      pause();
      return;
    }
    if (_continuousEnabled && !settings.continuousVoiceEnabled) {
      pause();
      return;
    }
    final channel = _channel();
    if (channel.state.activeVoiceRun != null) return;
    final reply = hermesContinuousVoiceReplyChunkToSpeak(
      turns: channel.state.activeMessages,
      enabled: true,
      spokenTurnId: _lastSpokenTurnId,
      spokenCharacterCount: _spokenReplyCharacterCount,
      spokenText: _spokenReplyPrefix,
    );
    if (reply == null) return;
    _lastSpokenTurnId = reply.turn.id;
    _spokenReplyCharacterCount = reply.spokenCharacterCount;
    _speakNextReply = reply.turn.status == HermesTurnStatus.streaming;
    final spokenText = hermesSpokenText(reply.text);
    if (spokenText.isEmpty) {
      if (_continuousEnabled && !_capturing) {
        unawaited(_rearmContinuousCapture());
      }
      return;
    }

    final tts = _textToSpeechService();
    if (tts == null) {
      final continuous = _continuousEnabled;
      _continuousEnabled = false;
      _playbackUnavailable = true;
      _error = _failureMessage(
        continuous
            ? HermesVoiceFailure.playbackUnavailableContinuous
            : HermesVoiceFailure.playbackUnavailable,
        null,
      );
      notifyListeners();
      return;
    }
    _activeTextToSpeechService = tts;
    _playbackUnavailable = false;
    _error = null;
    final speechGeneration = ++_speechGeneration;
    _speaking = true;
    _spokenReplyPrefix = reply.turn.text.substring(
      0,
      reply.spokenCharacterCount,
    );
    _activeSpokenChunk = spokenText;
    _readAloudTurnId = null;
    notifyListeners();
    if (_continuousEnabled && !_capturing) {
      unawaited(_capture(autoSend: true, continuous: true));
    }
    try {
      await tts.speak(spokenText).timeout(_speechTimeout);
      await Future<void>.delayed(_rearmDelay);
    } catch (_) {
      if (_disposed || speechGeneration != _speechGeneration) return;
      final continuous = _continuousEnabled;
      pause(
        _failureMessage(
          continuous
              ? HermesVoiceFailure.playbackFailedContinuous
              : HermesVoiceFailure.playbackFailed,
          null,
        ),
        true,
      );
      return;
    }
    if (_disposed || speechGeneration != _speechGeneration) return;

    _speaking = false;
    _activeTextToSpeechService = null;
    if (!channel.state.isConnected ||
        channel.state.activeSessionId != reply.turn.sessionId) {
      final continuous = _continuousEnabled;
      _continuousEnabled = false;
      _error = _failureMessage(
        continuous
            ? HermesVoiceFailure.playbackSessionChangedContinuous
            : HermesVoiceFailure.playbackSessionChanged,
        null,
      );
      notifyListeners();
      return;
    }
    if (!_continuousEnabled) {
      notifyListeners();
      unawaited(maybeContinue());
      return;
    }
    notifyListeners();
    if (!_capturing) {
      unawaited(_capture(autoSend: true, continuous: true));
    }
  }

  Future<void> _rearmContinuousCapture() async {
    await Future<void>.delayed(_rearmDelay);
    if (_disposed || !_continuousEnabled || _capturing || _speaking) return;
    if (_settings().speakRepliesEnabled) await maybeContinue();
    if (_disposed || !_continuousEnabled || _capturing || _speaking) return;
    await _capture(autoSend: true, continuous: true);
  }

  bool _isSpokenReplyEcho(String transcript) {
    final spokenReply = _activeSpokenChunk;
    if (spokenReply == null) return false;
    final candidate = _voiceEchoKey(transcript);
    final reply = _voiceEchoKey(spokenReply);
    if (candidate.isEmpty) return false;
    if (candidate == reply) return true;
    return candidate.length >= 12 &&
        (reply.contains(candidate) || candidate.contains(reply));
  }

  bool _isPossibleSpokenReplyEcho(String transcript) {
    final spokenReply = _activeSpokenChunk;
    if (spokenReply == null) return false;
    final candidate = _voiceEchoKey(transcript);
    if (candidate.isEmpty) return true;
    final reply = _voiceEchoKey(spokenReply);
    if (candidate == reply) return true;
    return candidate.length >= 12 &&
        (reply.startsWith(candidate) || candidate.startsWith(reply));
  }

  Future<void> _interruptActiveSpeech() async {
    if (!_speaking) return;
    _speechGeneration += 1;
    final tts = _activeTextToSpeechService;
    _activeTextToSpeechService = null;
    _readAloudTurnId = null;
    _speaking = false;
    if (!_disposed) notifyListeners();
    final stop = _stopSpeechForTeardown(tts, 'speech stop on interruption');
    _speechTeardown = Future.wait<void>([_speechTeardown, stop]);
    await _awaitSpeechTeardown();
  }

  Future<bool> _awaitSpeechTeardown() async {
    try {
      await _speechTeardown.timeout(_teardownTimeout);
      return true;
    } on TimeoutException {
      _failClosedVoiceShutdown(HermesVoiceFailure.shutdownTimedOut);
      return false;
    } catch (_) {
      _failClosedVoiceShutdown(HermesVoiceFailure.shutdownFailed);
      return false;
    }
  }

  void _failClosedVoiceShutdown(HermesVoiceFailure failure) {
    if (_disposed) return;
    _speechGeneration += 1;
    final capture = _activeCaptureService;
    if (capture != null) _operationGeneration += 1;
    _activeCaptureService = null;
    unawaited(_partialTranscriptSubscription?.cancel());
    _partialTranscriptSubscription = null;
    unawaited(_soundLevelSubscription?.cancel());
    _soundLevelSubscription = null;
    _liveTranscript = null;
    _soundLevel = null;
    _capturing = false;
    _speaking = false;
    _readAloudTurnId = null;
    _continuousEnabled = false;
    _speakNextReply = false;
    _error = _failureMessage(failure, null);
    if (capture != null) {
      final cancellation = _cancelCaptureForTeardown(
        capture,
        'voice capture cancel after speech shutdown failure',
      );
      _captureTeardown = Future.wait<void>([_captureTeardown, cancellation]);
      fireAndForget(
        _captureTeardown,
        'voice capture teardown after shutdown failure',
      );
    }
    notifyListeners();
  }

  String _voiceEchoKey(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[.,!?;:]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool _handleLocalCommand(String transcript) {
    final commandWord = _settings().commandWord.trim().toLowerCase();
    if (commandWord.isEmpty) return false;
    final normalized = transcript.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final command = normalized == commandWord
        ? ''
        : normalized.startsWith('$commandWord ')
        ? normalized.substring(commandWord.length + 1)
        : null;
    if (command == null) return false;
    if (const {
      'stop',
      'stop listening',
      'pause',
      'pause listening',
      'mute',
      'cancel',
    }.contains(command)) {
      pause(_failureMessage(HermesVoiceFailure.pausedByLocalCommand, null));
      return true;
    }
    return false;
  }

  Future<void> _cancelCaptureForTeardown(
    VoiceCaptureService service,
    String operation,
  ) async {
    try {
      await service.cancel();
    } catch (error, stackTrace) {
      debugPrint('Hermes Wing: $operation failed (${error.runtimeType})');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _stopSpeechForTeardown(
    TextToSpeechService? service,
    String operation,
  ) async {
    try {
      await service?.stop();
    } catch (error, stackTrace) {
      debugPrint('Hermes Wing: $operation failed (${error.runtimeType})');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void pause([String? notice, bool playbackUnavailable = false]) {
    _operationGeneration += 1;
    _speechGeneration += 1;
    final service = _activeCaptureService;
    _activeCaptureService = null;
    unawaited(_partialTranscriptSubscription?.cancel());
    _partialTranscriptSubscription = null;
    _liveTranscript = null;
    _soundLevel = null;
    unawaited(_soundLevelSubscription?.cancel());
    _soundLevelSubscription = null;
    if (service != null) {
      _captureTeardown = _cancelCaptureForTeardown(
        service,
        'voice capture cancel on pause',
      );
      fireAndForget(_captureTeardown, 'voice capture teardown on pause');
    }
    final tts = _activeTextToSpeechService;
    _activeTextToSpeechService = null;
    final speechStop = _stopSpeechForTeardown(tts, 'speech stop on pause');
    _speechTeardown = Future.wait<void>([_speechTeardown, speechStop]);
    fireAndForget(_speechTeardown, 'speech teardown on pause');
    _continuousEnabled = false;
    _speakNextReply = false;
    _spokenReplyPrefix = null;
    _activeSpokenChunk = null;
    _readAloudTurnId = null;
    _capturing = false;
    _speaking = false;
    _playbackUnavailable = playbackUnavailable;
    _error = notice;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _operationGeneration += 1;
    _speechGeneration += 1;
    final capture = _activeCaptureService;
    _activeCaptureService = null;
    fireAndForget(
      capture == null
          ? null
          : _cancelCaptureForTeardown(
              capture,
              'voice capture cancel on dispose',
            ),
      'voice capture cancel on dispose',
    );
    unawaited(_partialTranscriptSubscription?.cancel());
    _partialTranscriptSubscription = null;
    unawaited(_soundLevelSubscription?.cancel());
    _soundLevelSubscription = null;
    final tts = _activeTextToSpeechService;
    _activeTextToSpeechService = null;
    fireAndForget(
      _stopSpeechForTeardown(tts, 'speech stop on dispose'),
      'speech stop on dispose',
    );
    super.dispose();
  }
}
