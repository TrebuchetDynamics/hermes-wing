part of '../hermes_api_channel.dart';

extension _ApprovalsExtension on HermesApiChannel {
  Future<void> _respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
  }) async {
    final client = _client;
    final runId = _activeRunId;
    if (client == null || runId == null) {
      const message =
          'Could not answer approval: active run is no longer available.';
      _setState(_state.copyWith(errorMessage: message));
      throw StateError(message);
    }
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
    try {
      await client.respondApproval(
        runId: runId,
        approvalId: trimmedApprovalId,
        decision: decision.name,
      );
    } catch (error) {
      if (!identical(_client, client) || _activeRunId != runId) return;
      _setState(
        _state.copyWith(
          errorMessage: 'Could not answer approval: ${_safeHermesError(error)}',
        ),
      );
      rethrow;
    }
  }
}
