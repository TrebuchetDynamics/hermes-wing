import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/agents/screens/agents_screen.dart';

import '../../support/test_navivox_channel.dart';

const _seedAgents = [
  NavivoxAgent(id: 'def', name: 'Default', status: 'ready'),
  NavivoxAgent(id: 'arch', name: 'Architect', status: 'ready'),
];

void main() {
  testWidgets(
    'shows empty-state and Refresh button when no agents are known yet',
    (tester) async {
      final channel = TestNavivoxChannel();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const MaterialApp(home: AgentsScreen()),
        ),
      );

      expect(find.text('No agents loaded'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      // The screen calls requestAgentList(); our test mock records that and
      // we simulate the server response by seeding agents directly.
      await tester.tap(find.text('Refresh'));
      channel.seedAgents(_seedAgents);
      await tester.pump();

      expect(channel.agentListRequests, greaterThanOrEqualTo(1));
      expect(channel.state.agents, hasLength(2));
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Architect'), findsOneWidget);
    },
  );

  testWidgets('tapping an agent tile selects it through the channel', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()..seedAgents(_seedAgents);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: AgentsScreen()),
      ),
    );

    expect(find.text('Default'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.text('Architect'));
    await tester.pump();

    expect(channel.lastSelectedAgentId, 'arch');
    expect(channel.state.selectedAgentId, 'arch');
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
