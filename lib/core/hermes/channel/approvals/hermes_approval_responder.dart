import '../../client/hermes_api_client.dart';
import '../../models/hermes_approval_decision.dart';
import '../../policy/hermes_transport_policy.dart';
import '../hermes_channel_state.dart';

/// Resolves and executes approval responses for an active run. Owns the
/// approvalId -> runId mapping so the channel no longer carries it.
class HermesApprovalResponder {
  HermesApprovalResponder();

  final Map<String, String> _approvalRunIds = <String, String>{};

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
  bool forgetApproval(String approvalId) =>
      _approvalRunIds.remove(approvalId) != null;

  /// Forgets every approval raised by [runId], mirroring the terminal-run
  /// cleanup the channel previously expressed as `removeWhere(... == runId)`.
  void forgetApprovalsForRun(String runId) {
    _approvalRunIds.removeWhere((_, approvalRunId) => approvalRunId == runId);
  }

  /// Clears every mapping (connect/disconnect/dispose teardown).
  void clear() {
    _approvalRunIds.clear();
  }

  /// Executes the response. [client] must be a client of the connected
  /// channel; [state] is the channel state at call time (used only for the
  /// capability gate); [activeRunIds] is a live view of the channel's active
  /// run ids, consulted again on failure so a run that ended while the
  /// response was in flight swallows the error; [reportError] is called with
  /// the user-facing message before rethrowing.
  Future<void> respond({
    required HermesApiClient client,
    required HermesChannelState state,
    required String approvalId,
    required HermesApprovalDecision decision,
    required Iterable<String> activeRunIds,
    String? selectedProfileId,
    String Function(Object error)? safeError,
    void Function(String message)? reportError,
  }) async {
    final trimmedApprovalId = approvalId.trim();
    if (trimmedApprovalId.isEmpty) {
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
    final runId = resolveRunId(trimmedApprovalId, activeRunIds);
    if (runId == null) {
      const message =
          'Could not answer approval: active run is no longer available.';
      reportError?.call(message);
      throw StateError(message);
    }
    try {
      await client.respondApproval(
        runId: runId,
        approvalId: trimmedApprovalId,
        decision: decision.name,
        profile: selectedProfileId,
      );
      _approvalRunIds.remove(trimmedApprovalId);
    } catch (error) {
      final runStillActive = activeRunIds.contains(runId);
      final approvalStillMapped = _approvalRunIds[trimmedApprovalId] == runId;
      if (!runStillActive && !approvalStillMapped) {
        return;
      }
      reportError?.call(
        'Could not answer approval: '
        '${safeError?.call(error) ?? error}',
      );
      rethrow;
    }
  }
}
