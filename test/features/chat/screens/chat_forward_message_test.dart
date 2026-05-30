import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';

import '../../../support/test_navivox_channel.dart';
import '../transcript/shared/transcript_test_fixtures.dart';
import '../../shared/app/test_material_app.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';

void main() {
  testWidgets('chat message action forwards text to another profile contact', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        localReadyServer,
        officeReadyServer,
      ], activeServerId: 'local')
      ..seedProfileContacts([
        mineruBuilderProfile(latestPreview: 'building'),
        supportTriageProfile(
          health: NavivoxProfileHealth.online,
          latestPreview: 'watching tickets',
          micAvailable: true,
        ),
      ], selectedKey: 'local::mineru')
      ..seedMessages([
        transcriptTextMessage(
          id: 'assistant-1',
          createdAt: DateTime(2026, 5, 19, 12),
          text: 'send this to support',
          serverId: 'local',
          profileId: 'mineru',
        ),
      ]);

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: const ChatScreen(serverId: 'local', profileId: 'mineru'),
      ),
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
