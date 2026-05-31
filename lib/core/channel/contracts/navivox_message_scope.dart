/// Server/profile scope attached to channel messages and gateway events.
typedef NavivoxMessageScope = ({String? serverId, String? profileId});

const NavivoxMessageScope navivoxUnscopedMessage = (
  serverId: null,
  profileId: null,
);

NavivoxMessageScope navivoxMessageScope({
  required String? serverId,
  required String? profileId,
}) {
  return (serverId: serverId, profileId: profileId);
}

/// Uses an existing message scope when present, falling back to an event scope.
///
/// Gateway transcript updates often merge into a prior local message. Preserving
/// that prior scope keeps follow-up assistant/tool events attached to the same
/// profile even when later gateway events omit profile metadata.
NavivoxMessageScope navivoxMessageScopeWithFallback({
  required String? serverId,
  required String? profileId,
  required NavivoxMessageScope fallback,
}) {
  return navivoxMessageScope(
    serverId: serverId ?? fallback.serverId,
    profileId: profileId ?? fallback.profileId,
  );
}
