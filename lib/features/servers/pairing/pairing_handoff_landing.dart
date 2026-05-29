import '../../../core/channel/navivox_channel.dart';
import '../../../router/navigation_intent.dart';

class PairingHandoffLanding {
  const PairingHandoffLanding({this.serverId, this.profileId});

  final String? serverId;
  final String? profileId;

  bool get hasProfileTarget =>
      _nonEmpty(serverId) != null && _nonEmpty(profileId) != null;

  NavivoxProfileContact? reportedProfileContact(NavivoxChannelState state) {
    final server = _nonEmpty(serverId);
    final profile = _nonEmpty(profileId);
    if (server == null || profile == null) return null;
    final key = '$server::$profile';
    for (final contact in state.profileContacts) {
      if (contact.key == key) return contact;
    }
    return null;
  }

  NavigationIntent navigationIntentAfterConnect(NavivoxChannelState state) {
    final contact = reportedProfileContact(state);
    if (contact == null) return const OpenChatsList();
    return OpenChatThread(contact.serverId, contact.profileId);
  }

  static String? _nonEmpty(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
