import '../../../core/channel/navivox_channel.dart';

/// Profile-contact aliases accepted by local command resolution.
///
/// Keeping this as a pure helper makes duplicate-contact disambiguation
/// replayable: a bare profile name may still be ambiguous, but a server-scoped
/// name can identify one contact from the flat server + profile contact list.
Set<String> localCommandContactNames(
  NavivoxProfileContact contact, {
  required String Function(String value) normalize,
}) {
  final profileId = normalize(contact.profileId);
  final displayName = normalize(contact.displayName);
  final serverId = normalize(contact.serverId);
  final serverLabel = normalize(contact.serverLabel);

  return {
    profileId,
    displayName,
    _joinLocalCommandParts([serverId, profileId]),
    _joinLocalCommandParts([serverId, displayName]),
    _joinLocalCommandParts([serverLabel, profileId]),
    _joinLocalCommandParts([serverLabel, displayName]),
  }.where((name) => name.isNotEmpty).toSet();
}

List<NavivoxProfileContact> matchingLocalCommandContacts({
  required String normalized,
  required Iterable<NavivoxProfileContact> contacts,
  required String Function(String value) normalize,
}) {
  if (normalized.isEmpty) return const [];
  return contacts
      .where(
        (contact) => localCommandContactNames(
          contact,
          normalize: normalize,
        ).contains(normalized),
      )
      .toList(growable: false);
}

String _joinLocalCommandParts(Iterable<String> parts) {
  return parts.where((part) => part.isNotEmpty).join(' ').trim();
}
