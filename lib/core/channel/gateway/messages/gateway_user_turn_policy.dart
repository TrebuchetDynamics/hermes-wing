import '../../../protocol/navivox_event.dart';
import '../../contracts/navivox_channel.dart';
import '../../contracts/navivox_message_scope.dart';
import '../turns/gateway_turn_metadata_policy.dart';

/// Builds local user transcript messages for turns sent to the gateway.
///
/// Text and voice submissions both create a user-visible transcript entry before
/// sending the shared start_turn frame. Centralizing the message construction
/// keeps profile scope and voice payload handling aligned across input modes.
NavivoxChatMessage navivoxGatewayUserTurnMessage({
  required String id,
  required String text,
  required DateTime createdAt,
  required NavivoxMessageScope scope,
  NavivoxVoiceMessage? voice,
}) {
  return NavivoxChatMessage(
    id: id,
    author: NavivoxMessageAuthor.user,
    kind: voice == null ? NavivoxMessageKind.text : NavivoxMessageKind.voice,
    createdAt: createdAt,
    text: text,
    serverId: scope.serverId,
    profileId: scope.profileId,
    voice: voice,
  );
}

/// Bundles the local user transcript entry with the gateway start-turn frame.
///
/// Text and voice turns share this submission contract: create the durable local
/// message with the active profile scope, then send the same start_turn frame to
/// the gateway. Keeping both artifacts together prevents the two input paths
/// from diverging when the turn wire contract changes.
({NavivoxChatMessage message, String frame}) navivoxGatewayUserTurnSubmission({
  required String requestId,
  required String? sessionId,
  required String text,
  required DateTime createdAt,
  required NavivoxProfileContact? profile,
  required NavivoxProfileRoutingSelection? routing,
  NavivoxVoiceMessage? voice,
}) {
  return (
    message: navivoxGatewayUserTurnMessage(
      id: requestId,
      text: text,
      createdAt: createdAt,
      scope: navivoxMessageScope(
        serverId: profile?.serverId,
        profileId: profile?.profileId,
      ),
      voice: voice,
    ),
    frame: navivoxGatewayStartTurnFrame(
      requestId: requestId,
      sessionId: sessionId,
      text: text,
      profile: profile,
      routing: routing,
    ),
  );
}
