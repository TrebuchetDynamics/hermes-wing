import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';

import '../../support/test_navivox_channel.dart';

void main() {
  testWidgets('chat thread shows assistant typing indicator while streaming', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local', status: 'online'),
      ], activeServerId: 'local')
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Working on it',
          activeTurnState: 'streaming',
        ),
      ], selectedKey: 'local::mineru');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          home: ChatScreen(serverId: 'local', profileId: 'mineru'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Mineru is typing…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assistant-typing-indicator')),
      findsOneWidget,
    );
  });
}
