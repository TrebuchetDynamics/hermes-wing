import 'package:flutter/foundation.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_chat_turn.dart';

/// What changed between two looks at the Hermes channel.
@immutable
class HermesChannelChange {
  const HermesChannelChange({
    required this.completedReplySessionIds,
    required this.activeReplyCompleted,
    required this.activeSessionChanged,
    required this.activeUserTurnArrived,
  });

  /// Sessions where a new assistant reply finished since the previous look.
  final Set<String> completedReplySessionIds;

  /// Whether any new assistant reply finished since the previous look.
  bool get completedReplyArrived => completedReplySessionIds.isNotEmpty;

  /// A reply finished in the session that stayed active.
  final bool activeReplyCompleted;

  /// A new user turn appeared in the session that stayed active.
  final bool activeUserTurnArrived;

  /// The operator moved to a different session since the previous look.
  ///
  /// False on the first look: arriving at a session is not leaving one.
  final bool activeSessionChanged;
}

/// Remembers enough of the last channel state to detect transitions.
///
/// The chat screen reacts to edges, not levels: it refreshes the gateway
/// contact when a reply *finishes*, pauses voice when the session *changes*,
/// and resumes transcript following when a user turn arrives. This stores the
/// small previous-state signatures needed to answer what moved.
class HermesChannelObservation {
  String? _activeSessionId;
  String? _activeUserTurnSignature;
  String? _activeCompletedReplySignature;
  Map<String, Set<String>> _completedReplyIdsBySession = const {};

  /// Records [state] as the new baseline without reporting any change.
  ///
  /// Used when adopting a channel, where nothing has transitioned yet.
  void adopt(HermesChannelState state) {
    _activeSessionId = state.activeSessionId;
    _activeUserTurnSignature = activeUserTurnSignature(state);
    _activeCompletedReplySignature = activeCompletedReplySignature(state);
    _completedReplyIdsBySession = _completedReplyIds(state);
  }

  /// Records [state] and reports what moved since the previous look.
  HermesChannelChange observe(HermesChannelState state) {
    final completedReplyIdsBySession = _completedReplyIds(state);
    final completedReplySessionIds = <String>{
      for (final entry in completedReplyIdsBySession.entries)
        if (entry.value
            .difference(
              _completedReplyIdsBySession[entry.key] ?? const <String>{},
            )
            .isNotEmpty)
          entry.key,
    };
    _completedReplyIdsBySession = completedReplyIdsBySession;

    final activeSessionId = state.activeSessionId;
    final previousActiveSessionId = _activeSessionId;
    final activeSessionChanged =
        previousActiveSessionId != null &&
        previousActiveSessionId != activeSessionId;
    final userTurnSignature = activeUserTurnSignature(state);
    final stayedInActiveSession =
        previousActiveSessionId != null &&
        previousActiveSessionId == activeSessionId;
    final activeUserTurnArrived =
        stayedInActiveSession &&
        userTurnSignature != null &&
        userTurnSignature != _activeUserTurnSignature;
    final activeReplySignature = activeCompletedReplySignature(state);
    final activeReplyCompleted =
        stayedInActiveSession &&
        activeReplySignature != null &&
        activeReplySignature != _activeCompletedReplySignature;
    _activeSessionId = activeSessionId;
    _activeUserTurnSignature = userTurnSignature;
    _activeCompletedReplySignature = activeReplySignature;

    return HermesChannelChange(
      completedReplySessionIds: Set.unmodifiable(completedReplySessionIds),
      activeReplyCompleted: activeReplyCompleted,
      activeSessionChanged: activeSessionChanged,
      activeUserTurnArrived: activeUserTurnArrived,
    );
  }

  /// Forgets the baseline, so the next look starts fresh.
  void reset() {
    _activeSessionId = null;
    _activeUserTurnSignature = null;
    _activeCompletedReplySignature = null;
    _completedReplyIdsBySession = const {};
  }

  /// Stable identity of user turns in the active session.
  @visibleForTesting
  static String? activeUserTurnSignature(HermesChannelState state) {
    final activeSessionId = state.activeSessionId;
    if (activeSessionId == null) return null;
    final ids = <String>[
      for (final turn
          in state.messages[activeSessionId] ?? const <HermesChatTurn>[])
        if (turn.author == HermesTurnAuthor.user) turn.id,
    ];
    return ids.isEmpty ? null : ids.join('\u001f');
  }

  /// Stable identity of completed assistant replies in the active session.
  @visibleForTesting
  static String? activeCompletedReplySignature(HermesChannelState state) {
    final activeSessionId = state.activeSessionId;
    if (activeSessionId == null) return null;
    final ids = <String>[
      for (final turn
          in state.messages[activeSessionId] ?? const <HermesChatTurn>[])
        if (turn.author == HermesTurnAuthor.assistant &&
            turn.status == HermesTurnStatus.completed)
          turn.id,
    ];
    return ids.isEmpty ? null : ids.join('\u001f');
  }

  static Map<String, Set<String>> _completedReplyIds(
    HermesChannelState state,
  ) => {
    for (final entry in state.messages.entries)
      if (entry.value.any(
        (turn) =>
            turn.author == HermesTurnAuthor.assistant &&
            turn.status == HermesTurnStatus.completed,
      ))
        entry.key: {
          for (final turn in entry.value)
            if (turn.author == HermesTurnAuthor.assistant &&
                turn.status == HermesTurnStatus.completed)
              turn.id,
        },
  };

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
