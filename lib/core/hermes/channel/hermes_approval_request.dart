/// A pending Hermes approval request emitted while a tool call is in flight.
class HermesApprovalRequest {
  const HermesApprovalRequest({
    required this.id,
    required this.toolCallId,
    required this.prompt,
    this.risk,
  });

  final String id;
  final String toolCallId;
  final String prompt;
  final String? risk;
}
