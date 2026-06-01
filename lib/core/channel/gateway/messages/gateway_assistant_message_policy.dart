import '../../../gateway/navivox_gateway_protocol.dart';
import '../../../protocol/navivox_event.dart';
import '../../contracts/navivox_message_scope.dart';

/// Builds assistant transcript messages from gateway events.
///
/// Assistant delta and final-message events share the same message id, scope,
/// and run-record merge contract. Keeping this mapping here prevents the two
/// event paths from drifting as the transcript payload evolves.
String navivoxGatewayAssistantMessageId({
  required NavivoxGatewayEvent event,
  required String Function() fallbackRequestId,
}) {
  final requestId = event.requestId ?? fallbackRequestId();
  return 'assistant-$requestId';
}

NavivoxChatMessage navivoxGatewayAssistantTextMessage({
  required String id,
  required NavivoxGatewayEvent event,
  required NavivoxChatMessage? existing,
  required DateTime createdAt,
  required NavivoxMessageScope scope,
  required bool appendText,
}) {
  final incomingText = event.text ?? '';
  final text = appendText
      ? '${existing?.text ?? ''}$incomingText'
      : incomingText;
  final messageScope = navivoxMessageScopeWithFallback(
    serverId: existing?.serverId,
    profileId: existing?.profileId,
    fallback: scope,
  );
  return NavivoxChatMessage(
    id: id,
    author: existing?.author ?? NavivoxMessageAuthor.assistant,
    kind: existing?.kind ?? NavivoxMessageKind.text,
    createdAt: existing?.createdAt ?? createdAt,
    text: text,
    runRecordReference:
        event.runRecordReference ?? existing?.runRecordReference,
    serverId: messageScope.serverId,
    profileId: messageScope.profileId,
  );
}
