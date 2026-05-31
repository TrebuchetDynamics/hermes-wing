import 'package:flutter/widgets.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_thread.dart';

import '../../../contracts/transcript_forwarding_contracts.dart';
import '../shared/transcript_widget_test_host.dart';

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
  return transcriptWidgetTestHost(
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
