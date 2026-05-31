import 'package:flutter/widgets.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_input_panel.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

import '../../../contracts/transcript_interaction_contracts.dart';
import '../shared/transcript_widget_test_host.dart';

/// Mounts [TranscriptInputPanel] under the shared Material feature-test shell.
Widget transcriptInputPanelTestApp({
  required TextEditingController controller,
  required TranscriptSendCallback onSend,
  VoiceCaptureService? voiceCaptureService,
  TranscriptVoiceCaptureCallback? onVoice,
  VoidCallback? onVoiceCaptureStarted,
  ValueChanged<Object>? onVoiceCaptureFailed,
}) {
  return transcriptWidgetTestHost(
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
