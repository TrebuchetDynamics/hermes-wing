import '../../../gateway/navivox_gateway_protocol.dart';
import '../../../protocol/navivox_event.dart';
import '../../contracts/navivox_message_scope.dart';
import '../approvals/gateway_approval_notice.dart';

/// Builds safety and approval messages from gateway events.
///
/// Warning events and approval events share the same scoped safety-notice
/// payload contract. Keeping that mapping together prevents those event types
/// from drifting into plain text messages or losing run/profile scope.
NavivoxChatMessage navivoxGatewaySafetyWarningMessage({
  required NavivoxGatewayEvent event,
  required String id,
  required DateTime createdAt,
  required NavivoxMessageScope scope,
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

NavivoxChatMessage navivoxGatewayApprovalRequestMessage({
  required NavivoxGatewayEvent event,
  required NavivoxGatewayApprovalNotice notice,
  required DateTime createdAt,
  required NavivoxMessageScope scope,
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
