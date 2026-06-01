import 'dart:convert';

import '../../../gateway/navivox_gateway_protocol.dart';
import '../../contracts/navivox_channel.dart';

/// Builds gateway turn metadata consistently for text and voice submissions.
///
/// Keeping the profile/routing field names in one place prevents the text and
/// voice paths from drifting when the gateway metadata contract evolves.
Map<String, Object?> navivoxGatewayTurnMetadata({
  required NavivoxProfileContact? profile,
  required NavivoxProfileRoutingSelection? routing,
}) {
  return {
    'client': 'navivox',
    'platform': 'flutter',
    if (profile != null) ...{
      'server_id': profile.serverId,
      'profile_id': profile.profileId,
    },
    if (routing?.workspace != null) 'workspace': routing!.workspace,
    if (routing?.provider != null) 'provider_id': routing!.provider,
    if (routing?.channel != null) 'channel_id': routing!.channel,
  };
}

/// Encodes the shared gateway start-turn wire contract.
///
/// Text and voice submissions differ in their local message state, but both must
/// send the same start_turn envelope and metadata shape to the gateway.
String navivoxGatewayStartTurnFrame({
  required String requestId,
  required String? sessionId,
  required String text,
  required NavivoxProfileContact? profile,
  required NavivoxProfileRoutingSelection? routing,
}) {
  return jsonEncode(
    NavivoxGatewayMessage.startTurn(
      requestId: requestId,
      sessionId: sessionId,
      text: text,
      metadata: navivoxGatewayTurnMetadata(profile: profile, routing: routing),
    ).body,
  );
}
