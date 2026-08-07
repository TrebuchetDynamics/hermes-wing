part of '../hermes_api_channel.dart';

extension _ApprovalsExtension on HermesApiChannel {
  Future<void> _respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
  }) async {
    final client = _client;
    final trimmedApprovalId = approvalId.trim();
    if (trimmedApprovalId.isEmpty) {
      const message = 'Could not answer approval: approval id is missing.';
      _setState(_state.copyWith(errorMessage: message));
      throw StateError(message);
    }
    final capabilities = _state.capabilities;
    if (capabilities != null &&
        !HermesTransportPolicy(capabilities).supportsRunApprovalResponse) {
      const message =
          'Could not answer approval: Hermes did not advertise approval responses for this run.';
      _setState(_state.copyWith(errorMessage: message));
      throw StateError(message);
    }
    final runId =
        _approvalRunIds[trimmedApprovalId] ??
        (_activeRunIds.length == 1 ? _activeRunIds.values.single : null);
    if (client == null || runId == null) {
      const message =
          'Could not answer approval: active run is no longer available.';
      _setState(_state.copyWith(errorMessage: message));
      throw StateError(message);
    }
    try {
      await client.respondApproval(
        runId: runId,
        approvalId: trimmedApprovalId,
        decision: decision.name,
        profile: _state.selectedProfileId,
      );
      _approvalRunIds.remove(trimmedApprovalId);
    } catch (error) {
      final runStillActive = _activeRunIds.values.contains(runId);
      final approvalStillMapped = _approvalRunIds[trimmedApprovalId] == runId;
      if (!identical(_client, client) ||
          !runStillActive && !approvalStillMapped) {
        return;
      }
      _setState(
        _state.copyWith(
          errorMessage: 'Could not answer approval: ${_safeHermesError(error)}',
        ),
      );
      rethrow;
    }
  }
}
