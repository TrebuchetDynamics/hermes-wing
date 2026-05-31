import 'package:flutter/material.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_bubble.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_composer.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_input_panel.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_surface_frame.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_thread.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

import 'transcript_forwarding_contracts.dart';
import 'transcript_interaction_contracts.dart';
import 'transcript_test_scaffold.dart';

/// Mounts [TranscriptBubble] under the shared Material feature-test shell.
Widget transcriptBubbleTestApp({
  required NavivoxChatMessage message,
  required bool isUser,
  bool showTail = true,
  List<NavivoxProfileContact> forwardTargets = const [],
  TranscriptForwardCallback? onForward,
  VoidCallback? onCancelActiveTurn,
  Widget Function(Widget bubble)? wrapBubble,
}) {
  final bubble = TranscriptBubble(
    message: message,
    isUser: isUser,
    showTail: showTail,
    forwardTargets: forwardTargets,
    onForward: onForward,
    onCancelActiveTurn: onCancelActiveTurn,
  );

  return transcriptTestScaffold(wrapBubble?.call(bubble) ?? bubble);
}

/// Mounts [TranscriptComposer] under the shared Material feature-test shell.
Widget transcriptComposerTestApp({
  required TextEditingController controller,
  required TranscriptSendCallback onSend,
  bool voiceCaptureAvailable = false,
  String? voiceUnavailableReason,
  String? voiceRecoveryAction,
  VoidCallback? onOpenVoiceSettings,
  VoidCallback? onUploadFile,
  VoidCallback? onPickPhotoOrVideo,
  VoidCallback? onOpenWorkspace,
  bool capturing = false,
  VoidCallback? onToggleVoice,
}) {
  return transcriptTestScaffold(
    TranscriptComposer(
      controller: controller,
      onSend: onSend,
      voiceCaptureAvailable: voiceCaptureAvailable,
      voiceUnavailableReason: voiceUnavailableReason,
      voiceRecoveryAction: voiceRecoveryAction,
      onOpenVoiceSettings: onOpenVoiceSettings,
      onUploadFile: onUploadFile,
      onPickPhotoOrVideo: onPickPhotoOrVideo,
      onOpenWorkspace: onOpenWorkspace,
      capturing: capturing,
      onToggleVoice: onToggleVoice,
    ),
  );
}

/// Mounts [TranscriptInputPanel] under the shared Material feature-test shell.
Widget transcriptInputPanelTestApp({
  required TextEditingController controller,
  required TranscriptSendCallback onSend,
  VoiceCaptureService? voiceCaptureService,
  TranscriptVoiceCaptureCallback? onVoice,
  VoidCallback? onVoiceCaptureStarted,
  ValueChanged<Object>? onVoiceCaptureFailed,
}) {
  return transcriptTestScaffold(
    TranscriptInputPanel(
      controller: controller,
      onSend: onSend,
      voiceCaptureService: voiceCaptureService,
      onVoice: onVoice,
      onVoiceCaptureStarted: onVoiceCaptureStarted,
      onVoiceCaptureFailed: onVoiceCaptureFailed,
    ),
  );
}

/// Mounts [TranscriptSurfaceFrame] under the shared Material feature-test shell.
Widget transcriptSurfaceFrameTestApp({
  required List<NavivoxChatMessage> messages,
  TranscriptSendCallback? onSend,
  Widget? header,
  double height = 360,
}) {
  final frame = TranscriptSurfaceFrame(
    messages: messages,
    onSend: onSend ?? transcriptNoopSend,
  );

  return transcriptTestScaffold(
    header == null
        ? SizedBox(height: height, child: frame)
        : Column(
            children: [
              header,
              Expanded(child: frame),
            ],
          ),
  );
}

/// Mounts [TranscriptThread] under the shared Material feature-test shell.
Widget transcriptThreadTestApp({
  required ScrollController scrollController,
  required List<NavivoxChatMessage> messages,
  String? assistantTypingLabel,
  DateTime? dateLabelNow,
  List<NavivoxProfileContact> forwardTargets = const [],
  TranscriptForwardCallback? onForward,
  VoidCallback? onCancelActiveTurn,
}) {
  return transcriptTestScaffold(
    TranscriptThread(
      messages: messages,
      scrollController: scrollController,
      assistantTypingLabel: assistantTypingLabel,
      dateLabelNow: dateLabelNow,
      forwardTargets: forwardTargets,
      onForward: onForward,
      onCancelActiveTurn: onCancelActiveTurn,
    ),
  );
}
