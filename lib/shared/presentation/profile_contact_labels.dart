import '../../core/channel/navivox_channel.dart';
import 'count_labels.dart';
import 'profile_health_labels.dart';

String profileContactDisplayLabel(
  NavivoxProfileContact? contact, {
  required String fallback,
}) {
  final displayName = contact?.displayName.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;
  return fallback;
}

String profileContactServerLabel(
  NavivoxProfileContact? contact, {
  required String fallback,
}) {
  final label = contact?.serverLabel.trim();
  if (label != null && label.isNotEmpty) return label;
  return fallback;
}

String profileContactIdentityLabel(
  NavivoxProfileContact contact, {
  required String fallback,
}) {
  final displayName = contact.displayName.trim();
  if (displayName.isNotEmpty) return displayName;
  final profileId = contact.profileId.trim();
  if (profileId.isNotEmpty) return profileId;
  final serverId = contact.serverId.trim();
  if (serverId.isNotEmpty) return serverId;
  return fallback;
}

List<String> profileContactProjectStatusSegments(
  NavivoxProfileContact profile,
) {
  final segments = <String>[];
  if (profile.workspaceRootCount > 0) {
    segments.add(countLabel(profile.workspaceRootCount, 'project'));
  }
  if (profile.workspaceRootsError > 0) {
    segments.add(countLabel(profile.workspaceRootsError, 'error'));
  }
  if (profile.workspaceRootsWarning > 0) {
    segments.add(countLabel(profile.workspaceRootsWarning, 'warning'));
  }
  if (segments.isEmpty && !profile.workspaceRootsOk) {
    segments.add('project attention needed');
  }
  return segments;
}

String profileContactProjectStatusLabel(NavivoxProfileContact profile) {
  return profileContactProjectStatusSegments(profile).join(' • ');
}

String profileContactStatusBarLabel(NavivoxProfileContact profile) {
  return [
    profile.serverLabel,
    profileHealthLabel(profile.health),
    ...profileContactProjectStatusSegments(profile),
  ].join(' • ');
}
