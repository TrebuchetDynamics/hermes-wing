import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/agents/screens/agents_screen.dart';

import '../../../support/test_navivox_channel.dart';
import '../../shared/fixtures/profile_contact_channel_fixtures.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';
import '../../shared/fixtures/seed_fixtures.dart';
import '../../shared/app/test_material_app.dart';

final _seedServers = localOfficeServers();
final _seedProfiles = [
  mineruBuilderProfile(
    latestPreview: 'Goncho memory active',
    latestAt: DateTime(2026, 5, 16, 9, 41),
  ),
  supportTriageProfile(),
];

void main() {
  testWidgets(
    'shows empty-state and Refresh button when no agents are known yet',
    (tester) async {
      final channel = TestNavivoxChannel();

      await tester.pumpWidget(
        TestNavivoxMaterialApp(channel: channel, home: const AgentsScreen()),
      );

      expect(find.text('No profiles found on this server'), findsOneWidget);
      expect(find.text('Refresh profiles'), findsOneWidget);

      // The screen calls requestAgentList(); our test mock records that and
      // we simulate the server response by seeding agents directly.
      await tester.tap(find.text('Refresh profiles'));
      channel.seedAgents(defaultSeedAgents);
      await tester.pump();

      expect(channel.agentListRequests, greaterThanOrEqualTo(1));
      expect(channel.state.agents, hasLength(2));
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Architect'), findsOneWidget);
    },
  );

  testWidgets(
    'shows Gormes profiles from the active server when agent list is empty',
    (tester) async {
      final channel = profileContactChannel(
        servers: _seedServers,
        contacts: _seedProfiles,
      );

      await tester.pumpWidget(
        TestNavivoxMaterialApp(channel: channel, home: const AgentsScreen()),
      );

      expect(find.text('No agents loaded'), findsNothing);
      expect(find.text('Profiles on Local Gormes'), findsOneWidget);
      expect(find.text('Mineru Builder'), findsOneWidget);
      expect(find.text('mineru'), findsOneWidget);
      expect(find.text('Support Triage'), findsNothing);
      expect(find.text('Status: online'), findsOneWidget);
      expect(find.text('Channels: local/web chat, voice'), findsOneWidget);
      expect(find.text('Memory: Goncho available'), findsOneWidget);
      expect(find.text('Skills: profile skills pending API'), findsOneWidget);
      expect(find.text('Config: profile scoped'), findsOneWidget);

      await tester.tap(find.text('Mineru Builder'));
      await tester.pump();

      expect(channel.selectedProfileScope, (
        serverId: 'local',
        profileId: 'mineru',
      ));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    },
  );

  testWidgets('empty-state add-profile action opens plugged creation routes', (
    tester,
  ) async {
    final channel = TestNavivoxChannel();

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const AgentsScreen()),
    );

    await tester.tap(find.text('Add profile'));
    await tester.pumpAndSettle();

    expect(find.text('Add a profile'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('agents-create-from-seed')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('agents-add-gateway')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('agents-create-from-seed')));
    await tester.pumpAndSettle();

    expect(find.text('Create from seed'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-seed-input')), findsOneWidget);
  });

  testWidgets('tapping an agent tile selects it through the channel', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()..seedAgents(defaultSeedAgents);

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const AgentsScreen()),
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
