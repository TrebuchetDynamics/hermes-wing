import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/protocol/voice/models/wing_voice_run.dart';
import '../../../shared/voice/text_to_speech_service.dart';
import '../../../shared/voice/voice_capture_service.dart';
import '../../../shared/voice/voice_settings.dart';
import '../../voice_commands/models/voice_command.dart';
import 'hermes_continuous_voice_reply_policy.dart';
import 'hermes_voice_capture_flow.dart';

typedef HermesChannelReader = HermesChannel Function();
typedef VoiceCaptureServiceReader = VoiceCaptureService? Function();
typedef TextToSpeechServiceReader = TextToSpeechService? Function();
typedef VoiceSettingsReader = WingVoiceSettings Function();

/// Optional post-STT routing seam: tried after STT, before draft/submit.
/// Null (the default) keeps behavior identical to today.
typedef VoiceTranscriptRouter =
    Future<VoiceRouteResult?> Function(String transcript);

/// Owns Hermes voice-input state and lifecycle while the chat widget only
/// renders state and forwards operator intent.
class HermesVoiceInputController extends ChangeNotifier {
  factory HermesVoiceInputController({
    required HermesChannelReader channel,
    required VoiceCaptureServiceReader captureService,
    required TextToSpeechServiceReader textToSpeechService,
    required VoiceSettingsReader settings,
    required ValueChanged<String> onDraft,
    VoiceTranscriptRouter? routeTranscript,
    void Function(VoiceRouteResult result, {required bool autoSend})?
    onRoutedCommand,
  }) {
    assert(
      routeTranscript == null || onRoutedCommand != null,
      'onRoutedCommand is required when routeTranscript is provided',
    );
    return HermesVoiceInputController._(
      channel,
      captureService,
      textToSpeechService,
      settings,
      onDraft,
      routeTranscript,
      onRoutedCommand,
    );
  }

  HermesVoiceInputController._(
    this._channel,
    this._captureService,
    this._textToSpeechService,
    this._settings,
    this._onDraft,
    this._routeTranscript,
    this._onRoutedCommand,
  );

  final HermesChannelReader _channel;
  final VoiceCaptureServiceReader _captureService;
  final TextToSpeechServiceReader _textToSpeechService;
  final VoiceSettingsReader _settings;
  final ValueChanged<String> _onDraft;
  final VoiceTranscriptRouter? _routeTranscript;
  final void Function(VoiceRouteResult result, {required bool autoSend})?
  _onRoutedCommand;

  bool _capturing = false;
  bool _continuousEnabled = false;
  bool _disposed = false;
  bool _speaking = false;
  int _operationGeneration = 0;
  String? _error;
  String? _lastSpokenTurnId;
  VoiceCaptureService? _activeCaptureService;
  TextToSpeechService? _activeTextToSpeechService;

  bool get capturing => _capturing;
  bool get continuousEnabled => _continuousEnabled;
  String? get error => _error;
  bool get speaking => _speaking;

  Future<void> captureDraft() => _capture(autoSend: false);

  Future<void> enableContinuous() async {
    _continuousEnabled = true;
    _error = null;
    notifyListeners();
    await _capture(autoSend: true);
  }

  Future<void> _capture({required bool autoSend}) async {
    if (_capturing) return;
    final channel = _channel();
    final captureSessionId = channel.state.activeSessionId;
    final operationGeneration = ++_operationGeneration;
    final service = _captureService();
    _activeCaptureService = service;
    _capturing = true;
    _error = null;
    notifyListeners();

    final outcome = await const HermesVoiceCaptureFlow().capture(
      service: service,
      timeout: Duration(seconds: autoSend ? 30 : 12),
    );
    if (_disposed || operationGeneration != _operationGeneration) return;

    _activeCaptureService = null;
    // _capturing intentionally stays true until each branch below resolves:
    // the routing await in the captured branch must keep the capture window
    // closed so maybeContinue() or a second mic tap cannot interleave and
    // silently drop the transcript. pause() still recovers a hung router
    // (generation bump plus _capturing reset).
    if (!channel.state.isConnected ||
        channel.state.activeSessionId != captureSessionId) {
      _capturing = false;
      _recordCaptureFailure(
        'Voice capture was discarded because the Hermes session changed.',
        autoSend: autoSend,
      );
      notifyListeners();
      return;
    }

    switch (outcome.status) {
      case HermesVoiceCaptureStatus.unavailable:
        _capturing = false;
        _recordCaptureFailure(
          'Voice input is not available here.',
          autoSend: autoSend,
        );
      case HermesVoiceCaptureStatus.failed:
        _capturing = false;
        _recordCaptureFailure(
          outcome.errorMessage ?? 'Voice capture failed.',
          autoSend: autoSend,
        );
      case HermesVoiceCaptureStatus.captured:
        final capture = outcome.capture!;
        if (autoSend && _handleLocalCommand(capture.transcript)) {
          // pause() inside _handleLocalCommand already reset _capturing.
          break;
        }
        final transcript = capture.transcript.trim();
        VoiceRouteResult? routed;
        if (_routeTranscript != null) {
          try {
            routed = await _routeTranscript(transcript);
          } catch (_) {
            // A broken router must never block the transcript: fall through.
            routed = null;
          }
          if (_disposed || operationGeneration != _operationGeneration) {
            // pause()/dispose() owns _capturing now.
            return;
          }
          final stillValidSession =
              channel.state.isConnected &&
              channel.state.activeSessionId == captureSessionId;
          if (!stillValidSession) {
            if (autoSend) {
              _capturing = false;
              _recordCaptureFailure(
                'Voice capture was discarded because the Hermes session changed.',
                autoSend: true,
              );
              notifyListeners();
              return;
            }
            // Unlike the capture-time discard above, a draft is inert text in
            // the composer, so delivering it despite the session change is
            // deliberate — only the routed shortcut is dropped.
            routed = null;
          }
        }
        _capturing = false;
        if (routed != null) {
          _onRoutedCommand!(routed, autoSend: autoSend);
          break;
        }
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
            autoSend: true,
          );
        }
    }
    // onRoutedCommand may trigger navigation; cheap insurance against
    // notifying listeners of a disposed controller after that returns.
    if (_disposed) return;
    notifyListeners();
  }

  void _recordCaptureFailure(String message, {required bool autoSend}) {
    if (autoSend) {
      _continuousEnabled = false;
      _error = '$message Continuous voice paused.';
      return;
    }
    _error = message;
  }

  Future<void> maybeContinue() async {
    if (!_continuousEnabled || _capturing || _speaking || _disposed) return;
    final settings = _settings();
    if (!settings.continuousVoiceEnabled || !settings.speakRepliesEnabled) {
      pause();
      return;
    }
    final channel = _channel();
    final reply = hermesContinuousVoiceReplyToSpeak(
      turns: channel.state.activeMessages,
      enabled: true,
      lastSpokenTurnId: _lastSpokenTurnId,
    );
    if (reply == null) return;
    _lastSpokenTurnId = reply.id;

    final tts = _textToSpeechService();
    if (tts == null) {
      _continuousEnabled = false;
      _error = 'Text-to-speech is not available here. Continuous voice paused.';
      notifyListeners();
      return;
    }
    _activeTextToSpeechService = tts;
    final operationGeneration = ++_operationGeneration;
    _speaking = true;
    notifyListeners();
    try {
      await tts.speak(reply.text);
    } catch (_) {
      if (_disposed || operationGeneration != _operationGeneration) return;
      _speaking = false;
      _continuousEnabled = false;
      _error = 'Could not speak Hermes reply. Continuous voice paused.';
      notifyListeners();
      return;
    }
    if (_disposed ||
        operationGeneration != _operationGeneration ||
        !_continuousEnabled) {
      return;
    }

    _speaking = false;
    if (!channel.state.isConnected ||
        channel.state.activeSessionId != reply.sessionId) {
      _continuousEnabled = false;
      _error =
          'Hermes session changed before voice could re-arm. Continuous voice paused.';
      notifyListeners();
      return;
    }
    notifyListeners();
    unawaited(_capture(autoSend: true));
  }

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
    unawaited(service?.cancel().catchError((_) {}));
    final tts = _activeTextToSpeechService;
    _activeTextToSpeechService = null;
    unawaited(tts?.stop().catchError((_) {}));
    _continuousEnabled = false;
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
    unawaited(_activeCaptureService?.cancel());
    _activeCaptureService = null;
    final tts = _activeTextToSpeechService;
    _activeTextToSpeechService = null;
    unawaited(tts?.stop().catchError((_) {}));
    super.dispose();
  }
}
