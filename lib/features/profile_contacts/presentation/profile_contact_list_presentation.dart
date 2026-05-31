import '../../../core/channel/navivox_channel.dart';
import 'profile_contact_presentation.dart';

class ProfileContactListPresentation {
  const ProfileContactListPresentation({
    required this.servers,
    required this.allContacts,
    required this.visibleContacts,
    required this.selectedServerId,
  });

  factory ProfileContactListPresentation.fromContacts({
    required List<NavivoxServer> servers,
    required List<NavivoxProfileContact> contacts,
    String? selectedServerId,
    String query = '',
  }) {
    final sortedContacts = [...contacts]
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final normalizedQuery = query.trim().toLowerCase();
    final visibleContacts = sortedContacts
        .where(
          (contact) =>
              selectedServerId == null || contact.serverId == selectedServerId,
        )
        .where(
          (contact) =>
              normalizedQuery.isEmpty ||
              ProfileContactPresentation(contact).searchTerms.any(
                (field) => field.toLowerCase().contains(normalizedQuery),
              ),
        )
        .toList(growable: false);

    return ProfileContactListPresentation(
      servers: List.unmodifiable(servers),
      allContacts: List.unmodifiable(sortedContacts),
      visibleContacts: visibleContacts,
      selectedServerId: selectedServerId,
    );
  }

  final List<NavivoxServer> servers;
  final List<NavivoxProfileContact> allContacts;
  final List<NavivoxProfileContact> visibleContacts;
  final String? selectedServerId;

  bool get hasContacts => allContacts.isNotEmpty;
  bool get hasVisibleContacts => visibleContacts.isNotEmpty;
  bool get showServerFilter => servers.length > 1;

  String get visibleCountLabel {
    final count = visibleContacts.length;
    return count == 1 ? '1 profile' : '$count profiles';
  }
}
