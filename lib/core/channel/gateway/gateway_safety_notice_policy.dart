import '../../gateway/navivox_gateway_protocol.dart';
import '../../protocol/navivox_event.dart';
import '../contracts/navivox_channel.dart';

/// Gateway approval payload shared by stream notifications, tool-call cards,
/// and durable approval-request messages.
class NavivoxGatewayApprovalNotice {
  const NavivoxGatewayApprovalNotice({
    required this.id,
    required this.toolCallId,
    required this.prompt,
    required this.risk,
  });

  final String id;
  final String toolCallId;
  final String prompt;
  final String? risk;

  NavivoxApprovalRequest toChannelRequest() {
    return NavivoxApprovalRequest(
      id: id,
      toolCallId: toolCallId,
      prompt: prompt,
      risk: risk,
    );
  }
}

NavivoxGatewayApprovalNotice navivoxGatewayApprovalNotice({
  required NavivoxGatewayEvent event,
  required String Function() fallbackApprovalId,
}) {
  return NavivoxGatewayApprovalNotice(
    id: event.approvalId ?? fallbackApprovalId(),
    toolCallId: event.toolCallId ?? '',
    prompt: event.message ?? 'Approval required',
    risk: event.risk,
  );
}

/// Builds safety and approval messages from gateway events.
///
/// Warning events and approval events share the same scoped safety-notice
/// payload contract. Keeping that mapping together prevents those event types
/// from drifting into plain text messages or losing run/profile scope.
NavivoxChatMessage navivoxGatewaySafetyWarningMessage({
  required NavivoxGatewayEvent event,
  required String id,
  required DateTime createdAt,
  required ({String? serverId, String? profileId}) scope,
}) {
  return NavivoxChatMessage(
    id: id,
    author: NavivoxMessageAuthor.system,
    kind: NavivoxMessageKind.safetyWarning,
    createdAt: createdAt,
    safetyNotice: NavivoxSafetyNotice(
      id: id,
      severity: event.severity ?? 'warning',
      message: event.message ?? 'Safety warning',
      risk: event.risk,
    ),
    runRecordReference: event.runRecordReference,
    serverId: scope.serverId,
    profileId: scope.profileId,
  );
}

NavivoxToolApproval navivoxGatewayToolApproval({
  required NavivoxGatewayApprovalNotice notice,
}) {
  return NavivoxToolApproval(
    id: notice.id,
    status: 'approval_required',
    prompt: notice.prompt,
    risk: notice.risk,
  );
}

NavivoxChatMessage navivoxGatewayApprovalRequestMessage({
  required NavivoxGatewayEvent event,
  required NavivoxGatewayApprovalNotice notice,
  required DateTime createdAt,
  required ({String? serverId, String? profileId}) scope,
}) {
  return NavivoxChatMessage(
    id: notice.id,
    author: NavivoxMessageAuthor.system,
    kind: NavivoxMessageKind.approvalRequest,
    createdAt: createdAt,
    safetyNotice: NavivoxSafetyNotice(
      id: notice.id,
      approvalId: notice.id,
      toolCallId: notice.toolCallId,
      message: notice.prompt,
      risk: notice.risk,
    ),
    runRecordReference: event.runRecordReference,
    serverId: scope.serverId,
    profileId: scope.profileId,
  );
}
