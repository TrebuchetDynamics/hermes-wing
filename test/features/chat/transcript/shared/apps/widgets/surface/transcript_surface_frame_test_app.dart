import 'package:flutter/widgets.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_surface_frame.dart';

import '../../../contracts/transcript_interaction_contracts.dart';
import '../shared/transcript_widget_test_host.dart';

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

  return transcriptWidgetTestHost(
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
