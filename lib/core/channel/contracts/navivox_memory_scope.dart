import 'navivox_channel.dart';
import 'navivox_profile_scope.dart';

/// Profile/server scope used by memory API requests.
///
/// Centralizing the fallback keeps overview/search/detail/action calls aligned
/// when a caller supplies only part of the scope.
class NavivoxMemoryScope {
  const NavivoxMemoryScope({this.serverId, required this.profileId});

  final String? serverId;
  final String profileId;
}

NavivoxMemoryScope navivoxMemoryScopeFor({
  required NavivoxProfileContact? activeProfile,
  String? serverId,
  String? profileId,
}) {
  final scope = navivoxProfileScopeFor(
    activeProfile: activeProfile,
    serverId: serverId,
    profileId: profileId,
  );
  return NavivoxMemoryScope(
    serverId: scope.serverId,
    profileId: scope.profileId,
  );
}
