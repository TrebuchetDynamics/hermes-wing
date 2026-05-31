import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import '../transcript/shared/transcript_test_fixtures.dart';
import '../shared/chat_screen_test_fixtures.dart';
import '../../shared/fixtures/profile_contact_channel_fixtures.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';

void main() {
  testWidgets('chat message action forwards text to another profile contact', (
    tester,
  ) async {
    final channel =
        profileContactChannel(
          servers: const [localReadyServer, officeReadyServer],
          contacts: [
            mineruBuilderProfile(latestPreview: 'building'),
            transcriptSupportContact,
          ],
        )..seedMessages([
          transcriptTextMessage(
            id: 'assistant-1',
            createdAt: DateTime(2026, 5, 19, 12),
            text: 'send this to support',
            serverId: 'local',
            profileId: 'mineru',
          ),
        ]);

    await pumpChatScreen(
      tester,
      channel: channel,
      serverId: 'local',
      profileId: 'mineru',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('send this to support'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Support Triage'));
    await tester.pumpAndSettle();

    expect(channel.selectedProfileScope, (
      serverId: 'office',
      profileId: 'support',
    ));
    expect(channel.sentTextCalls.last, (
      text: 'send this to support',
      serverId: 'office',
      profileId: 'support',
    ));
    expect(find.text('Forwarded to Support Triage'), findsOneWidget);
  });
}
