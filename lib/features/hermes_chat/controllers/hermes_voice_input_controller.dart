import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_chat_turn.dart';
import '../../../core/protocol/voice/models/wing_voice_run.dart';
import '../../../shared/async/fire_and_forget.dart';
import '../../../shared/voice/text_to_speech_service.dart';
import '../../../shared/voice/voice_capture_failures.dart';
import '../../../shared/voice/voice_capture_service.dart';
import '../../../shared/voice/voice_settings.dart';
import 'hermes_continuous_voice_reply_policy.dart';
import 'hermes_voice_capture_flow.dart';

typedef HermesChannelReader = HermesChannel Function();
typedef VoiceCaptureServiceReader = VoiceCaptureService? Function();
typedef TextToSpeechServiceReader = TextToSpeechService? Function();
typedef VoiceSettingsReader = WingVoiceSettings Function();

/// Owns Hermes voice-input state and lifecycle while the chat widget only
/// renders state and forwards operator intent.
class HermesVoiceInputController extends ChangeNotifier {
  factory HermesVoiceInputController({
    required HermesChannelReader channel,
    required VoiceCaptureServiceReader captureService,
    required TextToSpeechServiceReader textToSpeechService,
    required VoiceSettingsReader settings,
    required ValueChanged<String> onDraft,
    Duration rearmDelay = const Duration(milliseconds: 750),
  }) => HermesVoiceInputController._(
    channel,
    captureService,
    textToSpeechService,
    settings,
    onDraft,
    rearmDelay,
  );

  HermesVoiceInputController._(
    this._channel,
    this._captureService,
    this._textToSpeechService,
    this._settings,
    this._onDraft,
    this._rearmDelay,
  );

  final HermesChannelReader _channel;
  final VoiceCaptureServiceReader _captureService;
  final TextToSpeechServiceReader _textToSpeechService;
  final VoiceSettingsReader _settings;
  final ValueChanged<String> _onDraft;
  final Duration _rearmDelay;

  bool _capturing = false;
  bool _continuousEnabled = false;
  bool _disposed = false;
  bool _speaking = false;
  bool _speakNextReply = false;
  int _operationGeneration = 0;
  String? _error;
  String? _lastSpokenTurnId;
  String? _lastSpokenReply;
  String? _liveTranscript;
  VoiceCaptureService? _activeCaptureService;
  TextToSpeechService? _activeTextToSpeechService;
  StreamSubscription<String>? _partialTranscriptSubscription;

  bool get capturing => _capturing;
  String? get liveTranscript => _liveTranscript;
  bool get continuousEnabled => _continuousEnabled;
  String? get error => _error;
  bool get speaking => _speaking;

  Future<void> captureDraft() => _capture(autoSend: false);

  void speakNextReply() {
    _baselineAssistantReplies();
    _speakNextReply = true;
  }

  Future<void> captureAndSend() async {
    _baselineAssistantReplies();
    _speakNextReply = true;
    await _capture(autoSend: true);
  }

  Future<void> enableContinuous() async {
    _baselineAssistantReplies();
    _speakNextReply = false;
    _continuousEnabled = true;
    _error = null;
    notifyListeners();
    await _capture(autoSend: true, continuous: true);
  }

  void _baselineAssistantReplies() {
    _lastSpokenReply = null;
    _lastSpokenTurnId = null;
    for (final turn in _channel().state.activeMessages) {
      if (turn.author == HermesTurnAuthor.assistant) {
        _lastSpokenTurnId = turn.id;
      }
    }
  }

  Future<void> _capture({
    required bool autoSend,
    bool continuous = false,
  }) async {
    if (_capturing) return;
    final channel = _channel();
    final captureSessionId = channel.state.activeSessionId;
    final operationGeneration = ++_operationGeneration;
    final service = _captureService();
    _activeCaptureService = service;
    _capturing = true;
    _error = null;
    _liveTranscript = null;
    unawaited(_partialTranscriptSubscription?.cancel());
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
        notifyListeners();
      },
    );
    notifyListeners();

    final outcome = await const HermesVoiceCaptureFlow().capture(
      service: service,
      timeout: Duration(seconds: continuous ? 30 : 12),
    );
    if (_disposed || operationGeneration != _operationGeneration) return;

    _activeCaptureService = null;
    unawaited(_partialTranscriptSubscription?.cancel());
    _partialTranscriptSubscription = null;
    if (!channel.state.isConnected ||
        channel.state.activeSessionId != captureSessionId) {
      _capturing = false;
      _recordCaptureFailure(
        'Voice capture was discarded because the Hermes session changed.',
        continuous: continuous,
      );
      notifyListeners();
      return;
    }

    switch (outcome.status) {
      case HermesVoiceCaptureStatus.unavailable:
        _capturing = false;
        _recordCaptureFailure(
          'Voice input is not available here.',
          continuous: continuous,
        );
      case HermesVoiceCaptureStatus.failed:
        _capturing = false;
        if (continuous &&
            outcome.error is SpeechToTextCaptureFailure &&
            (outcome.error! as SpeechToTextCaptureFailure).isNoTranscript) {
          notifyListeners();
          unawaited(_rearmContinuousCapture());
          return;
        }
        _recordCaptureFailure(
          outcome.errorMessage ?? 'Voice capture failed.',
          continuous: continuous,
        );
      case HermesVoiceCaptureStatus.captured:
        final capture = outcome.capture!;
        final transcript = capture.transcript.trim();
        if (continuous && _isSpokenReplyEcho(transcript)) {
          _capturing = false;
          _lastSpokenReply = null;
          notifyListeners();
          unawaited(_rearmContinuousCapture());
          return;
        }
        _lastSpokenReply = null;
        if (continuous && _handleLocalCommand(transcript)) {
          // pause() inside _handleLocalCommand already reset _capturing.
          break;
        }
        _capturing = false;
        if (!autoSend) {
          _onDraft(transcript);
          break;
        }
        final voiceRunId = channel.startVoiceRun();
        channel.stageVoiceRunTranscript(
          voiceRunId: voiceRunId,
          transcript: capture.transcript,
          duration: capture.duration,
          confidence: capture.confidence,
        );
        channel.submitVoiceRun(voiceRunId);
        final run = channel.state.voiceRuns[voiceRunId];
        if (run?.status == WingVoiceRunStatus.failed) {
          _recordCaptureFailure(
            run?.reason ?? 'Voice turn could not be sent.',
            continuous: continuous,
          );
        }
    }
    if (_disposed) return;
    notifyListeners();
  }

  void _recordCaptureFailure(String message, {required bool continuous}) {
    _speakNextReply = false;
    if (continuous) {
      _continuousEnabled = false;
      _error = '$message Continuous voice paused.';
      return;
    }
    _error = message;
  }

  Future<void> maybeContinue() async {
    if ((!_continuousEnabled && !_speakNextReply) ||
        _capturing ||
        _speaking ||
        _disposed) {
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
    final reply = hermesContinuousVoiceReplyToSpeak(
      turns: channel.state.activeMessages,
      enabled: true,
      lastSpokenTurnId: _lastSpokenTurnId,
    );
    if (reply == null) return;
    _lastSpokenTurnId = reply.id;
    _speakNextReply = false;

    final tts = _textToSpeechService();
    if (tts == null) {
      final continuous = _continuousEnabled;
      _continuousEnabled = false;
      _error = continuous
          ? 'Text-to-speech is not available here. Continuous voice paused.'
          : 'Text-to-speech is not available here.';
      notifyListeners();
      return;
    }
    _activeTextToSpeechService = tts;
    final operationGeneration = ++_operationGeneration;
    _speaking = true;
    notifyListeners();
    try {
      await tts.speak(reply.text);
      _lastSpokenReply = reply.text;
      await Future<void>.delayed(_rearmDelay);
    } catch (_) {
      if (_disposed || operationGeneration != _operationGeneration) return;
      final continuous = _continuousEnabled;
      _speaking = false;
      _continuousEnabled = false;
      _activeTextToSpeechService = null;
      _error = continuous
          ? 'Could not speak Hermes reply. Continuous voice paused.'
          : 'Could not speak Hermes reply.';
      notifyListeners();
      return;
    }
    if (_disposed || operationGeneration != _operationGeneration) return;

    _speaking = false;
    _activeTextToSpeechService = null;
    if (!channel.state.isConnected ||
        channel.state.activeSessionId != reply.sessionId) {
      final continuous = _continuousEnabled;
      _continuousEnabled = false;
      _error = continuous
          ? 'Hermes session changed before voice could re-arm. Continuous voice paused.'
          : 'Hermes session changed before the spoken reply finished.';
      notifyListeners();
      return;
    }
    if (!_continuousEnabled) {
      notifyListeners();
      unawaited(maybeContinue());
      return;
    }
    notifyListeners();
    unawaited(_capture(autoSend: true, continuous: true));
  }

  Future<void> _rearmContinuousCapture() async {
    await Future<void>.delayed(_rearmDelay);
    if (_disposed || !_continuousEnabled || _capturing || _speaking) return;
    await _capture(autoSend: true, continuous: true);
  }

  bool _isSpokenReplyEcho(String transcript) {
    final spokenReply = _lastSpokenReply;
    if (spokenReply == null) return false;
    final candidate = _voiceEchoKey(transcript);
    final reply = _voiceEchoKey(spokenReply);
    return candidate.length >= 12 &&
        (candidate == reply || reply.contains(candidate));
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
      pause('Continuous voice paused by local command.');
      return true;
    }
    return false;
  }

  void pause([String? notice]) {
    _operationGeneration += 1;
    final service = _activeCaptureService;
    _activeCaptureService = null;
    unawaited(_partialTranscriptSubscription?.cancel());
    _partialTranscriptSubscription = null;
    _liveTranscript = null;
    fireAndForget(service?.cancel(), 'voice capture cancel on pause');
    final tts = _activeTextToSpeechService;
    _activeTextToSpeechService = null;
    fireAndForget(tts?.stop(), 'speech stop on pause');
    _continuousEnabled = false;
    _speakNextReply = false;
    _lastSpokenReply = null;
    _capturing = false;
    _speaking = false;
    _error = notice;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _operationGeneration += 1;
    fireAndForget(
      _activeCaptureService?.cancel(),
      'voice capture cancel on dispose',
    );
    _activeCaptureService = null;
    unawaited(_partialTranscriptSubscription?.cancel());
    _partialTranscriptSubscription = null;
    final tts = _activeTextToSpeechService;
    _activeTextToSpeechService = null;
    fireAndForget(tts?.stop(), 'speech stop on dispose');
    super.dispose();
  }
}
