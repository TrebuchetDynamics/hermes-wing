import '../../core/channel/navivox_channel.dart';

/// Cross-feature scope descriptor combining active server and profile contact.
///
/// Extracted from `features/profile_contacts` because [ConfigScreenPresentation]
/// and other feature presentations depend on the same scoping model without
/// importing the full profile-contacts presentation layer.
class ProfileContactScopePresentation {
  const ProfileContactScopePresentation({
    required this.activeServer,
    required this.activeServerId,
    required this.activeProfile,
  });

  final NavivoxServer? activeServer;
  final String? activeServerId;
  final NavivoxProfileContact? activeProfile;

  String get serverLabel =>
      activeServer?.name ??
      activeProfile?.serverLabel ??
      activeServerId ??
      'No server selected';

  String get profileLabel => activeProfile?.displayName ?? 'No active profile';

  String? get profileId => activeProfile?.profileId;
}
