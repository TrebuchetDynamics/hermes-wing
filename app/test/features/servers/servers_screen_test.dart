import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/servers/screens/servers_screen.dart';

import '../../support/test_navivox_channel.dart';

void main() {
  testWidgets(
    'servers screen groups profiles by gateway and opens management sheet',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(const [
          NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
          NavivoxServer(
            id: 'office',
            name: 'Office Gateway',
            status: 'offline',
          ),
        ], activeServerId: 'local')
        ..seedProfileContacts([
          const NavivoxProfileContact(
            serverId: 'local',
            profileId: 'mineru',
            displayName: 'Mineru Builder',
            serverLabel: 'local',
            health: NavivoxProfileHealth.online,
            latestPreview: 'Ready',
            workspaceRootCount: 2,
            micAvailable: true,
          ),
          const NavivoxProfileContact(
            serverId: 'local',
            profileId: 'personal',
            displayName: 'Personal',
            serverLabel: 'local',
            health: NavivoxProfileHealth.warning,
            latestPreview: 'Workspace warning',
            workspaceRootCount: 1,
            workspaceRootsOk: false,
          ),
          const NavivoxProfileContact(
            serverId: 'office',
            profileId: 'support',
            displayName: 'Support Triage',
            serverLabel: 'office',
            health: NavivoxProfileHealth.needsAuth,
            latestPreview: 'Waiting for token',
            attentionBadges: ['auth'],
          ),
        ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const MaterialApp(home: ServersScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gateways'), findsOneWidget);
      expect(find.byKey(const ValueKey('server-card-local')), findsOneWidget);
      expect(find.byKey(const ValueKey('server-card-office')), findsOneWidget);
      expect(find.text('2 profiles'), findsOneWidget);
      expect(find.text('1 profile'), findsOneWidget);
      expect(find.text('1 warning'), findsOneWidget);
      expect(find.text('1 auth'), findsOneWidget);
      expect(find.byTooltip('Register gateway'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('server-manage-office')));
      await tester.pumpAndSettle();

      expect(find.text('Manage gateway'), findsOneWidget);
      expect(find.text('Office Gateway'), findsWidgets);
      expect(find.text('Server ID'), findsOneWidget);
      expect(find.text('office'), findsWidgets);
      expect(find.text('Profiles on this gateway'), findsOneWidget);
      expect(find.text('Support Triage'), findsOneWidget);
    },
  );

  testWidgets('register gateway action explains connect-info import boundary', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: ServersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Register gateway'));
    await tester.pumpAndSettle();

    expect(find.text('Register gateway'), findsOneWidget);
    expect(find.textContaining('gormes navivox connect-info'), findsOneWidget);
    expect(find.textContaining('persistent multi-gateway'), findsOneWidget);
  });
}
