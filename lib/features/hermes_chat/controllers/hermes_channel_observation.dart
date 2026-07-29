import 'package:flutter/foundation.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_chat_turn.dart';

/// What changed between two looks at the Hermes channel.
@immutable
class HermesChannelChange {
  const HermesChannelChange({
    required this.completedReplyArrived,
    required this.activeSessionChanged,
  });

  /// A new assistant reply finished since the previous look.
  final bool completedReplyArrived;

  /// The operator moved to a different session since the previous look.
  ///
  /// False on the first look: arriving at a session is not leaving one.
  final bool activeSessionChanged;
}

/// Remembers enough of the last channel state to detect transitions.
///
/// The chat screen reacts to edges, not levels: it refreshes the gateway
/// contact when a reply *finishes* and pauses voice when the session *changes*.
/// Both need the previous value, so this holds the two that matter and answers
/// what moved.
class HermesChannelObservation {
  String? _activeSessionId;
  String? _completedReplySignature;

  /// Records [state] as the new baseline without reporting any change.
  ///
  /// Used when adopting a channel, where nothing has transitioned yet.
  void adopt(HermesChannelState state) {
    _activeSessionId = state.activeSessionId;
    _completedReplySignature = completedReplySignature(state);
  }

  /// Records [state] and reports what moved since the previous look.
  HermesChannelChange observe(HermesChannelState state) {
    final signature = completedReplySignature(state);
    final completedReplyArrived =
        signature != _completedReplySignature && signature != null;
    _completedReplySignature = signature;

    final activeSessionId = state.activeSessionId;
    final activeSessionChanged =
        _activeSessionId != null && _activeSessionId != activeSessionId;
    _activeSessionId = activeSessionId;

    return HermesChannelChange(
      completedReplyArrived: completedReplyArrived,
      activeSessionChanged: activeSessionChanged,
    );
  }

  /// Forgets the baseline, so the next look starts fresh.
  void reset() {
    _activeSessionId = null;
    _completedReplySignature = null;
  }

  /// Stable identity of every completed assistant reply on the channel.
  ///
  /// Sorted so reply ordering cannot fake a change, and null when no reply has
  /// completed yet.
  @visibleForTesting
  static String? completedReplySignature(HermesChannelState state) {
    final ids = <String>[
      for (final turns in state.messages.values)
        for (final turn in turns)
          if (turn.author == HermesTurnAuthor.assistant &&
              turn.status == HermesTurnStatus.completed)
            '${turn.sessionId}:${turn.id}',
    ]..sort();
    return ids.isEmpty ? null : ids.join('\u001f');
  }
}
