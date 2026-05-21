import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';

import '../../support/test_navivox_channel.dart';

const _seedAgents = [
  NavivoxAgent(id: 'def', name: 'Default', status: 'ready'),
  NavivoxAgent(id: 'arch', name: 'Architect', status: 'ready'),
];

const _seedServers = [
  NavivoxServer(id: 'srv1', name: 'Local', status: 'ready'),
];

void main() {
  testWidgets(
    'chat AppBar omits the active-agent indicator when no agent is selected',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(_seedServers, activeServerId: 'srv1')
        ..seedAgents(_seedAgents);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );

      expect(find.byKey(const ValueKey('chat-active-agent')), findsNothing);
    },
  );

  testWidgets('chat AppBar keeps agent context behind a compact info action', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_seedServers, activeServerId: 'srv1')
      ..seedAgents(_seedAgents, selectedAgentId: 'arch');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );

    expect(find.byKey(const ValueKey('chat-active-agent')), findsNothing);
    expect(find.byKey(const ValueKey('chat-context-action')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chat-context-action')));
    await tester.pumpAndSettle();

    expect(find.text('Chat info'), findsOneWidget);
    expect(find.text('Agent'), findsOneWidget);
    expect(find.text('Architect'), findsOneWidget);
  });
}
