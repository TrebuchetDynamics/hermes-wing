import '../contracts/navivox_channel.dart';

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
