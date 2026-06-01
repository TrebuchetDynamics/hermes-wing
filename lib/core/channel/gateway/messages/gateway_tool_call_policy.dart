import '../../../gateway/navivox_gateway_protocol.dart';
import '../../../protocol/navivox_event.dart';
import '../../contracts/navivox_message_scope.dart';
import '../approvals/gateway_approval_notice.dart';
import '../codecs/gateway_tool_artifact_codec.dart';

/// Builds durable tool-call cards from gateway events.
///
/// Progress updates and approval-required events both mutate the same tool-call
/// card. Centralizing that merge contract keeps status, approval, artifacts,
/// run-record references, and profile scope aligned.
NavivoxChatMessage navivoxGatewayToolCallMessage({
  required String id,
  required NavivoxGatewayEvent event,
  required String status,
  required NavivoxChatMessage? priorMessage,
  required DateTime createdAt,
  required NavivoxMessageScope scope,
}) {
  final prior = priorMessage?.toolCall;
  final messageScope = navivoxMessageScopeWithFallback(
    serverId: priorMessage?.serverId,
    profileId: priorMessage?.profileId,
    fallback: scope,
  );
  return NavivoxChatMessage(
    id: id,
    author: NavivoxMessageAuthor.assistant,
    kind: NavivoxMessageKind.toolCall,
    createdAt: priorMessage?.createdAt ?? createdAt,
    toolCall: NavivoxToolCall(
      name: event.toolName ?? prior?.name ?? 'tool',
      status: status,
      summary: navivoxBoundedGatewayToolText(
        event.message ?? event.text ?? prior?.summary ?? '',
      ),
      approval: prior?.approval,
      artifacts: navivoxGatewayToolArtifacts(
        metadata: event.metadata,
        toolCallId: id,
        prior: prior?.artifacts ?? const [],
      ),
    ),
    runRecordReference:
        event.runRecordReference ?? priorMessage?.runRecordReference,
    serverId: messageScope.serverId,
    profileId: messageScope.profileId,
  );
}

NavivoxChatMessage? navivoxGatewayToolApprovalMessage({
  required String id,
  required NavivoxGatewayEvent event,
  required NavivoxChatMessage? priorMessage,
  required NavivoxGatewayApprovalNotice notice,
  required DateTime createdAt,
  required NavivoxMessageScope scope,
}) {
  final priorTool = priorMessage?.toolCall;
  if (priorTool == null) return null;
  final messageScope = navivoxMessageScopeWithFallback(
    serverId: priorMessage?.serverId,
    profileId: priorMessage?.profileId,
    fallback: scope,
  );
  return NavivoxChatMessage(
    id: id,
    author: NavivoxMessageAuthor.assistant,
    kind: NavivoxMessageKind.toolCall,
    createdAt: priorMessage?.createdAt ?? createdAt,
    toolCall: priorTool.copyWith(
      approval: navivoxGatewayToolApproval(notice: notice),
    ),
    runRecordReference:
        event.runRecordReference ?? priorMessage?.runRecordReference,
    serverId: messageScope.serverId,
    profileId: messageScope.profileId,
  );
}

List<NavivoxToolArtifact> navivoxGatewayToolArtifacts({
  required Map<String, Object?> metadata,
  required String toolCallId,
  required List<NavivoxToolArtifact> prior,
}) {
  final parsed = navivoxToolArtifactsFromGatewayMetadata(
    metadata,
    toolCallId: toolCallId,
  );
  if (parsed.isEmpty) return prior;
  final byId = {for (final artifact in prior) artifact.id: artifact};
  for (final artifact in parsed) {
    byId[artifact.id] = artifact;
  }
  return byId.values.toList(growable: false);
}
