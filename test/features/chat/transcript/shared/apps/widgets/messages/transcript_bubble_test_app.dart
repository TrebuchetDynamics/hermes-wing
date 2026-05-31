import 'package:flutter/widgets.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_bubble.dart';

import '../../../contracts/transcript_forwarding_contracts.dart';
import '../shared/transcript_widget_test_host.dart';

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

  return transcriptWidgetTestHost(wrapBubble?.call(bubble) ?? bubble);
}
