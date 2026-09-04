import '../models/hermes_approval_decision.dart';

/// A pending Hermes approval request emitted while a tool call is in flight.
class HermesApprovalRequest {
  const HermesApprovalRequest({
    required this.id,
    required this.toolCallId,
    required this.prompt,
    this.risk,
    this.command,
    this.description,
    this.choices,
    this.runId,
    this.sessionId,
    this.profileId,
    this.connectionGeneration,
    this.profileSelectionGeneration,
  });

  final String id;
  final String toolCallId;
  final String prompt;
  final String? risk;
  final String? command;
  final String? description;
  final Set<HermesApprovalDecision>? choices;
  final String? runId;
  final String? sessionId;
  final String? profileId;
  final int? connectionGeneration;
  final int? profileSelectionGeneration;

  bool get hasResponseIdentity =>
      id.trim().isNotEmpty || (runId?.trim().isNotEmpty ?? false);

  bool allows(HermesApprovalDecision decision) =>
      choices == null || choices!.contains(decision);

  String get identityKey {
    final approvalId = id.trim();
    final callId = toolCallId.trim();
    final currentRunId = runId?.trim() ?? '';
    final eventIdentity = approvalId.isNotEmpty
        ? 'approval:$approvalId'
        : callId.isNotEmpty
        ? 'tool:$callId'
        : currentRunId.isNotEmpty
        ? 'run:$currentRunId'
        : 'prompt:$prompt';
    return '${connectionGeneration ?? -1}|${profileId ?? ''}|'
        '${sessionId ?? ''}|${runId ?? ''}|$eventIdentity';
  }
}
