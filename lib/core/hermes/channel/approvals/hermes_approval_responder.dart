import '../../client/hermes_api_client.dart';
import '../../models/hermes_approval_decision.dart';
import '../../policy/hermes_transport_policy.dart';
import '../hermes_channel_state.dart';

/// Resolves and executes approval responses for an active run. Owns the
/// approvalId -> runId mapping so the channel no longer carries it.
class HermesApprovalResponder {
  HermesApprovalResponder();

  final Map<String, String> _approvalRunIds = <String, String>{};
  final _responseOwners = <String, Object>{};
  int _generation = 0;

  bool isPendingApproval(String approvalId, String? runId) =>
      runId != null &&
      _approvalRunIds[approvalId] == runId &&
      !_responseOwners.containsKey(approvalId);

  /// Registers an approval raised by [runId]. Returns whether this approval
  /// is new (false when already registered; the mapping is still refreshed).
  bool registerApproval(String approvalId, String runId) {
    final isNew = !_approvalRunIds.containsKey(approvalId);
    _approvalRunIds[approvalId] = runId;
    return isNew;
  }

  /// The run that raised [approvalId], or when exactly one run is active,
  /// that run; otherwise null. Mirrors the channel previous resolution:
  /// `_approvalRunIds[id] ?? (single active run fallback)`.
  String? resolveRunId(String approvalId, Iterable<String> activeRunIds) {
    final mapped = _approvalRunIds[approvalId];
    if (mapped != null) return mapped;
    if (activeRunIds.length == 1) return activeRunIds.single;
    return null;
  }

  /// Forgets the mapping for [approvalId]. Returns whether a mapping existed.
  bool forgetApproval(String approvalId) {
    _responseOwners.remove(approvalId);
    return _approvalRunIds.remove(approvalId) != null;
  }

  /// Forgets every approval raised by [runId], mirroring the terminal-run
  /// cleanup the channel previously expressed as `removeWhere(... == runId)`.
  void forgetApprovalsForRun(String runId) {
    final ids = _approvalRunIds.keys
        .where((id) => _approvalRunIds[id] == runId)
        .toList();
    for (final id in ids) {
      forgetApproval(id);
    }
  }

  /// Clears every mapping (connect/disconnect/dispose teardown).
  void clear() {
    _generation += 1;
    _approvalRunIds.clear();
    _responseOwners.clear();
  }

  /// Executes the response. [client] must be a client of the connected
  /// channel; [state] is the channel state at call time (used only for the
  /// capability gate); [activeRunIds] is a live view of the channel's active
  /// run ids, consulted again on failure so a run that ended while the
  /// response was in flight swallows the error; [reportError] is called with
  /// the user-facing message before rethrowing.
  ///
  /// [approvalId] carries Agent's exact request_id. Genuinely idless legacy
  /// events may use the explicit [runId] without an exact request identity.
  Future<void> respond({
    required HermesApiClient client,
    required HermesChannelState state,
    required String approvalId,
    required HermesApprovalDecision decision,
    required Iterable<String> activeRunIds,
    String? runId,
    String? selectedProfileId,
    String Function(Object error)? safeError,
    void Function(String message)? reportError,
  }) async {
    final trimmedApprovalId = approvalId.trim();
    final trimmedRunId = runId?.trim();
    if (trimmedApprovalId.isEmpty &&
        (trimmedRunId == null || trimmedRunId.isEmpty)) {
      const message = 'Could not answer approval: approval id is missing.';
      reportError?.call(message);
      throw StateError(message);
    }
    final capabilities = state.capabilities;
    if (capabilities != null &&
        !HermesTransportPolicy(capabilities).supportsRunApprovalResponse) {
      const message =
          'Could not answer approval: Hermes did not advertise approval '
          'responses for this run.';
      reportError?.call(message);
      throw StateError(message);
    }
    final resolvedRunId = trimmedRunId?.isNotEmpty == true
        ? trimmedRunId
        : resolveRunId(trimmedApprovalId, activeRunIds);
    if (resolvedRunId == null) {
      const message =
          'Could not answer approval: active run is no longer available.';
      reportError?.call(message);
      throw StateError(message);
    }
    // Teardown retires settlement ownership, not the already-started POST.
    final generation = _generation;
    final responseOwner = Object();
    if (trimmedApprovalId.isNotEmpty) {
      _responseOwners[trimmedApprovalId] = responseOwner;
    }
    try {
      await client.respondApproval(
        runId: resolvedRunId,
        approvalId: trimmedApprovalId,
        decision: decision.name,
        profile: selectedProfileId,
      );
      if (generation == _generation &&
          trimmedApprovalId.isNotEmpty &&
          identical(_responseOwners[trimmedApprovalId], responseOwner)) {
        _approvalRunIds.remove(trimmedApprovalId);
      }
    } catch (error) {
      if (generation != _generation ||
          (trimmedApprovalId.isNotEmpty &&
              !identical(_responseOwners[trimmedApprovalId], responseOwner))) {
        return;
      }
      final runStillActive = activeRunIds.contains(resolvedRunId);
      final approvalStillMapped =
          trimmedApprovalId.isNotEmpty &&
          _approvalRunIds[trimmedApprovalId] == resolvedRunId;
      if (!runStillActive && !approvalStillMapped) {
        return;
      }
      reportError?.call(
        'Could not answer approval: '
        '${safeError?.call(error) ?? error}',
      );
      rethrow;
    } finally {
      if (generation == _generation &&
          identical(_responseOwners[trimmedApprovalId], responseOwner)) {
        _responseOwners.remove(trimmedApprovalId);
      }
    }
  }
}
