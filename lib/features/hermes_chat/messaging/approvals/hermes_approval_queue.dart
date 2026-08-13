// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../core/hermes/channel/hermes_channel.dart';

typedef HermesApprovalErrorSink = void Function(Object error);

/// Owns the pending Hermes approval queue and the in-flight answer, while the
/// chat widget only renders them and forwards operator intent.
///
/// Requests are de-duplicated by [_requestKey] so a resumed or replayed stream
/// cannot stack the same approval twice, and the request currently being
/// answered is never re-queued.
///
/// Rebuild contract: [add], [resolve], and [dismiss] notify listeners because
/// they run outside any caller `setState`. [watch], [reset], and [clearPending]
/// deliberately do not notify — they run inside wiring or an existing caller
/// `setState`, and notifying there would rebuild during `initState`.
class HermesApprovalQueue extends ChangeNotifier {
  HermesApprovalQueue({
    required HermesChannel Function() channel,
    required HermesApprovalErrorSink onResolveError,
  }) : _channel = channel,
       _onResolveError = onResolveError;

  final HermesChannel Function() _channel;
  final HermesApprovalErrorSink _onResolveError;
  final Queue<HermesApprovalRequest> _pending = Queue();
  StreamSubscription<HermesApprovalRequest>? _subscription;
  String? _answeringId;
  bool _disposed = false;

  /// Approvals awaiting an operator decision, oldest first.
  UnmodifiableListView<HermesApprovalRequest> get pending =>
      UnmodifiableListView(_pending);

  /// Identifier of the approval currently being answered, if any.
  String? get answeringId => _answeringId;

  /// Whether the operator would lose approval work by leaving this gateway.
  bool get hasPendingWork => _pending.isNotEmpty || _answeringId != null;

  /// Approvals that belong to [activeSessionId], plus session-less ones.
  Iterable<HermesApprovalRequest> activeFor(String? activeSessionId) =>
      _pending.where(
        (request) =>
            request.sessionId == null || request.sessionId == activeSessionId,
      );

  /// Re-points the queue at [channel], dropping anything from the previous one.
  void watch(HermesChannel channel) {
    reset();
    unawaited(_subscription?.cancel());
    _subscription = channel.approvalRequests.listen(add);
  }

  /// Queues [request] unless it duplicates a pending or in-flight approval.
  void add(HermesApprovalRequest request) {
    if (_disposed) return;
    final requestKey = _requestKey(request);
    final duplicate = _pending.any(
      (pending) => _requestKey(pending) == requestKey,
    );
    if (duplicate || _answeringId == request.id.trim()) return;
    _pending.addLast(request);
    notifyListeners();
  }

  /// Answers [request] with [decision] and drops it once Hermes accepts.
  ///
  /// Ignored when another approval is already in flight or [request] is no
  /// longer queued, so a double tap cannot send two decisions.
  Future<void> resolve(
    HermesApprovalDecision decision,
    HermesApprovalRequest request,
  ) async {
    if (_answeringId != null ||
        !_pending.any(
          (pending) => _requestKey(pending) == _requestKey(request),
        )) {
      return;
    }
    final approvalId = request.id.trim();
    if (approvalId.isEmpty) return;
    _answeringId = approvalId;
    notifyListeners();
    try {
      await _channel().respondToApproval(
        approvalId: approvalId,
        decision: decision,
      );
      if (_disposed) return;
      _pending.removeWhere(
        (pending) => _requestKey(pending) == _requestKey(request),
      );
      if (_answeringId == approvalId) _answeringId = null;
      notifyListeners();
    } catch (error) {
      if (_disposed) return;
      if (_answeringId == approvalId) _answeringId = null;
      notifyListeners();
      _onResolveError(error);
    }
  }

  /// Drops [request] locally without answering Hermes.
  void dismiss(HermesApprovalRequest request) {
    if (_disposed) return;
    _pending.removeWhere(
      (pending) => _requestKey(pending) == _requestKey(request),
    );
    _answeringId = null;
    notifyListeners();
  }

  /// Drops every queued approval and any in-flight answer.
  void reset() {
    _pending.clear();
    _answeringId = null;
  }

  /// Drops queued approvals but keeps an in-flight answer tracked.
  void clearPending() => _pending.clear();

  static String _requestKey(HermesApprovalRequest request) {
    final id = request.id.trim();
    if (id.isNotEmpty) return 'id:$id';
    final toolCallId = request.toolCallId.trim();
    if (toolCallId.isNotEmpty) return 'tool:$toolCallId';
    return 'prompt:${request.prompt}';
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
