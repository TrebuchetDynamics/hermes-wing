import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';

import '../../support/test_navivox_channel.dart';

void main() {
  testWidgets('chat message action forwards text to another profile contact', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local', status: 'ready'),
        NavivoxServer(id: 'office', name: 'Office', status: 'ready'),
      ], activeServerId: 'local')
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'building',
        ),
        NavivoxProfileContact(
          serverId: 'office',
          profileId: 'support',
          displayName: 'Support Triage',
          serverLabel: 'office',
          health: NavivoxProfileHealth.online,
          latestPreview: 'watching tickets',
        ),
      ], selectedKey: 'local::mineru')
      ..seedMessages([
        NavivoxChatMessage(
          id: 'assistant-1',
          author: NavivoxMessageAuthor.assistant,
          kind: NavivoxMessageKind.text,
          createdAt: DateTime(2026, 5, 19, 12),
          text: 'send this to support',
        ),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          home: ChatScreen(serverId: 'local', profileId: 'mineru'),
        ),
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
