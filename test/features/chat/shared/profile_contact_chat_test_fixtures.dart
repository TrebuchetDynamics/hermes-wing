import 'package:navivox/core/channel/navivox_channel.dart';

import '../../../support/test_navivox_channel.dart';
import '../../shared/fixtures/profile_contact_channel_fixtures.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';

/// Shared chat test channel with the default local Mineru Profile contact.
TestNavivoxChannel mineruReadyProfileChannel({bool micAvailable = false}) {
  return profileContactChannel(
    servers: const [
      NavivoxServer(id: 'local', name: 'local', status: 'connected'),
    ],
    contacts: [
      mineruBuilderProfile(
        displayName: 'Mineru',
        latestPreview: 'Ready',
        workspaceRootCount: 1,
        micAvailable: micAvailable,
      ),
    ],
  );
}
