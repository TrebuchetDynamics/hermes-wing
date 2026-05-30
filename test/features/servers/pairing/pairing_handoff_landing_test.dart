import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/servers/pairing/pairing_handoff_landing.dart';
import 'package:navivox/router/navigation_intent.dart';

import '../shared/test_constants.dart';

void main() {

  test('opens requested Profile contact only when gateway reports it', () {
    const landing = PairingHandoffLanding(
      serverId: 'local',
      profileId: 'mineru',
    );
    const state = NavivoxChannelState(profileContacts: [mineru]);

    expect(landing.reportedProfileContact(state), mineru);
    expect(
      landing.navigationIntentAfterConnect(state),
      isA<OpenChatThread>()
          .having((intent) => intent.serverId, 'serverId', 'local')
          .having((intent) => intent.profileId, 'profileId', 'mineru'),
    );
  });

  test(
    'falls back to Profile contact list for missing or unreported targets',
    () {
      const missing = PairingHandoffLanding();
      const unreported = PairingHandoffLanding(
        serverId: 'local',
        profileId: 'support',
      );
      const state = NavivoxChannelState(profileContacts: [mineru]);

      expect(missing.navigationIntentAfterConnect(state), isA<OpenChatsList>());
      expect(unreported.reportedProfileContact(state), isNull);
      expect(
        unreported.navigationIntentAfterConnect(state),
        isA<OpenChatsList>(),
      );
    },
  );
}
