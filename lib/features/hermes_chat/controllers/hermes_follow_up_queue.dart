import 'dart:collection';

import 'package:flutter/foundation.dart';

/// A turn the operator composed while Hermes was still replying.
@immutable
class QueuedFollowUp {
  const QueuedFollowUp(this.text, this.sessionId);

  final String text;

  /// Session this was composed against; it is only sent back to that session.
  final String? sessionId;
}

/// Holds follow-up turns typed while a reply is streaming, and decides when one
/// may be sent.
///
/// A queued turn is bound to the session it was composed in, so switching
/// sessions parks it rather than misdelivering it, and deleting that session
/// drops it. Capacity is bounded so a long stream cannot accumulate unbounded
/// pending work.
///
/// This is a plain object rather than a [ChangeNotifier]: every caller already
/// mutates it inside a `setState` or immediately before one, so notifying would
/// only add redundant rebuilds.
class HermesFollowUpQueue {
  HermesFollowUpQueue({this.capacity = 5}) : assert(capacity > 0);

  /// Most turns that may wait at once.
  final int capacity;

  final Queue<QueuedFollowUp> _queued = Queue<QueuedFollowUp>();

  /// Operator-facing problem with the queue, or null.
  String? error;

  UnmodifiableListView<QueuedFollowUp> get pending =>
      UnmodifiableListView(_queued);

  int get length => _queued.length;
  bool get isEmpty => _queued.isEmpty;
  bool get isNotEmpty => _queued.isNotEmpty;
  bool get isFull => _queued.length >= capacity;

  /// The turn that would be sent next, or null when nothing is queued.
  QueuedFollowUp? get next => _queued.isEmpty ? null : _queued.first;

  /// Queues [text] against [sessionId]. Returns false when already at capacity.
  bool enqueue(String text, String? sessionId) {
    if (isFull) return false;
    error = null;
    _queued.addLast(QueuedFollowUp(text, sessionId));
    return true;
  }

  /// Whether the next turn can be sent into the session now on screen.
  bool canSendNext({
    required String? activeSessionId,
    required bool turnActive,
    required bool canSendTurns,
  }) {
    if (_queued.isEmpty || turnActive || !canSendTurns) return false;
    return _queued.first.sessionId == activeSessionId;
  }

  /// Removes and returns the next turn when [canSendNext] allows it.
  QueuedFollowUp? takeNextIfEligible({
    required String? activeSessionId,
    required bool turnActive,
    required bool canSendTurns,
  }) {
    if (!canSendNext(
      activeSessionId: activeSessionId,
      turnActive: turnActive,
      canSendTurns: canSendTurns,
    )) {
      return null;
    }
    error = null;
    return _queued.removeFirst();
  }

  /// Whether the operator could reopen the session the next turn belongs to.
  bool canOpenNextSession({
    required String? activeSessionId,
    required Set<String> knownSessionIds,
  }) {
    final sessionId = next?.sessionId;
    if (sessionId == null || sessionId == activeSessionId) return false;
    return knownSessionIds.contains(sessionId);
  }

  /// Puts a failed send back at the head so ordering survives the retry.
  ///
  /// Dropped when the queue filled while the send was in flight; [message] is
  /// still recorded so the operator learns the send failed either way.
  void requeueFailed(
    String text,
    String? sessionId, {
    required String message,
  }) {
    error = message;
    if (isFull) return;
    _queued.addFirst(QueuedFollowUp(text, sessionId));
  }

  /// Drops turns bound to sessions Hermes no longer lists.
  void dropForMissingSessions(Set<String> knownSessionIds) {
    _queued.removeWhere(
      (queued) =>
          queued.sessionId != null &&
          !knownSessionIds.contains(queued.sessionId),
    );
  }

  /// Drops every queued turn, keeping any recorded error.
  void clear() => _queued.clear();

  /// Drops every queued turn and any recorded error.
  void reset() {
    _queued.clear();
    error = null;
  }
}
