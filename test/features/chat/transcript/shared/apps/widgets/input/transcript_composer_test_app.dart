import 'package:flutter/widgets.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_composer.dart';

import '../../../contracts/transcript_interaction_contracts.dart';
import '../shared/transcript_widget_test_host.dart';

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
  return transcriptWidgetTestHost(
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
