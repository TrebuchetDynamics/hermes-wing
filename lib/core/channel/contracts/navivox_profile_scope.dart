import 'navivox_channel.dart';

/// Shared default profile/server scope for gateway-backed channel state.
///
/// Keeping these identity defaults together prevents profile decoders, memory
/// requests, voice runs, and fallback contacts from drifting when a gateway does
/// not provide explicit scope metadata.
const navivoxDefaultGatewayServerId = 'navivox-gateway';
const navivoxDefaultProfileId = 'default';
const navivoxDefaultGatewayServerLabel = 'Gormes Gateway';

/// Resolved server/profile identity used by gateway-backed channel contracts.
///
/// Memory requests may intentionally omit a server when no active profile or
/// explicit server was supplied, while voice-run records fall back to the
/// default gateway server. The optional server fallback keeps both policies on
/// the same profile-id fallback without forcing one server behavior on the
/// other.
class NavivoxProfileScope {
  const NavivoxProfileScope({this.serverId, required this.profileId});

  final String? serverId;
  final String profileId;
}

NavivoxProfileScope navivoxProfileScopeFor({
  required NavivoxProfileContact? activeProfile,
  String? serverId,
  String? profileId,
  String? fallbackServerId,
}) {
  return NavivoxProfileScope(
    serverId: serverId ?? activeProfile?.serverId ?? fallbackServerId,
    profileId: profileId ?? activeProfile?.profileId ?? navivoxDefaultProfileId,
  );
}
