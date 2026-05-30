import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/channel/navivox_channel.dart';
import '../../../../core/protocol/navivox_event.dart';
import '../../../voice/services/tts/text_to_speech_service.dart';
import '../../../voice/services/capture/voice_capture_service.dart';
import 'transcript_surface_frame.dart';

class TranscriptSurface extends StatelessWidget {
  const TranscriptSurface({
    required this.messages,
    required this.onSend,
    this.voiceCaptureService,
    this.onVoice,
    this.onVoiceCaptureStarted,
    this.onVoiceCaptureFailed,
    this.voiceCaptureTimeout = const Duration(seconds: 30),
    this.voiceUnavailableReason,
    this.voiceRecoveryAction,
    this.onOpenVoiceSettings,
    this.onUploadFile,
    this.onPickPhotoOrVideo,
    this.onOpenWorkspace,
    this.textToSpeechService,
    this.assistantTypingLabel,
    this.onCancelActiveTurn,
    this.forwardTargets = const [],
    this.onForward,
    this.onInspectRunRecord,
    super.key,
  });

  final List<NavivoxChatMessage> messages;
  final ValueChanged<String> onSend;
  final VoiceCaptureService? voiceCaptureService;
  final ValueChanged<VoiceCapture>? onVoice;
  final VoidCallback? onVoiceCaptureStarted;
  final ValueChanged<Object>? onVoiceCaptureFailed;
  final Duration voiceCaptureTimeout;
  final String? voiceUnavailableReason;
  final String? voiceRecoveryAction;
  final VoidCallback? onOpenVoiceSettings;
  final VoidCallback? onUploadFile;
  final VoidCallback? onPickPhotoOrVideo;
  final VoidCallback? onOpenWorkspace;
  final TextToSpeechService? textToSpeechService;
  final String? assistantTypingLabel;
  final VoidCallback? onCancelActiveTurn;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;
  final FutureOr<void> Function(NavivoxChatMessage message)? onInspectRunRecord;

  @override
  Widget build(BuildContext context) {
    return TranscriptSurfaceFrame(
      messages: messages,
      onSend: onSend,
      voiceCaptureService: voiceCaptureService,
      onVoice: onVoice,
      onVoiceCaptureStarted: onVoiceCaptureStarted,
      onVoiceCaptureFailed: onVoiceCaptureFailed,
      voiceCaptureTimeout: voiceCaptureTimeout,
      voiceUnavailableReason: voiceUnavailableReason,
      voiceRecoveryAction: voiceRecoveryAction,
      onOpenVoiceSettings: onOpenVoiceSettings,
      onUploadFile: onUploadFile,
      onPickPhotoOrVideo: onPickPhotoOrVideo,
      onOpenWorkspace: onOpenWorkspace,
      textToSpeechService: textToSpeechService,
      assistantTypingLabel: assistantTypingLabel,
      onCancelActiveTurn: onCancelActiveTurn,
      forwardTargets: forwardTargets,
      onForward: onForward,
      onInspectRunRecord: onInspectRunRecord,
    );
  }
}
