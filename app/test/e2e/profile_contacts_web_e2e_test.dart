import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/router/app_router.dart';

import '../support/test_navivox_channel.dart';

const _servers = [
  NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
  NavivoxServer(id: 'office', name: 'Office', status: 'online'),
];

final _contacts = [
  NavivoxProfileContact(
    serverId: 'local',
    profileId: 'mineru',
    displayName: 'Mineru Builder',
    serverLabel: 'local',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready to work on mineru',
    latestAt: DateTime(2026, 5, 16, 10),
    workspaceRootCount: 2,
    micAvailable: true,
  ),
  NavivoxProfileContact(
    serverId: 'office',
    profileId: 'support',
    displayName: 'Support Triage',
    serverLabel: 'office',
    health: NavivoxProfileHealth.needsAuth,
    latestPreview: 'Waiting for auth',
    latestAt: DateTime(2026, 5, 16, 9, 45),
    workspaceRootCount: 1,
    attentionBadges: ['auth'],
  ),
];

void main() {
  testWidgets(
    'web browser e2e filters by gateway and opens management details',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(_servers, activeServerId: 'local')
        ..seedProfileContacts(_contacts);
      addTearDown(channel.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const _WebE2EApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('server-filter-all')), findsOneWidget);
      expect(find.byKey(const ValueKey('server-filter-local')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('server-filter-office')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('server-filter-office')));
      await tester.pumpAndSettle();

      expect(find.text('Support Triage'), findsOneWidget);
      expect(find.text('Mineru Builder'), findsNothing);
      expect(find.text('1 profile'), findsOneWidget);

      await tester.tap(find.byTooltip('Manage gateways'));
      await tester.pumpAndSettle();

      expect(find.text('Gateways'), findsOneWidget);
      expect(find.byKey(const ValueKey('server-card-local')), findsOneWidget);
      expect(find.byKey(const ValueKey('server-card-office')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('server-manage-office')));
      await tester.pumpAndSettle();

      expect(find.text('Manage gateway'), findsOneWidget);
      expect(find.text('Office'), findsWidgets);
      expect(find.text('Support Triage'), findsOneWidget);
      expect(find.text('Profiles on this gateway'), findsOneWidget);
    },
  );

  testWidgets(
    'web browser e2e selects a profile contact and sends scoped chat text',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(_servers, activeServerId: 'local')
        ..seedProfileContacts(_contacts);
      addTearDown(channel.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const _WebE2EApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Navivox'), findsOneWidget);
      expect(find.text('Mineru Builder'), findsOneWidget);
      expect(find.text('Support Triage'), findsOneWidget);
      expect(find.text('local'), findsWidgets);
      expect(find.text('office'), findsOneWidget);
      expect(find.byTooltip('Add profile'), findsOneWidget);

      await tester.tap(find.byTooltip('Add profile'));
      await tester.pumpAndSettle();
      expect(find.text('New profile'), findsOneWidget);
      expect(find.text('Add server'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('profile-contact-office-support')),
      );
      await tester.pumpAndSettle();

      expect(channel.selectedProfileScope, (
        serverId: 'office',
        profileId: 'support',
      ));
      expect(find.text('Support Triage'), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-active-profile')), findsNothing);
      expect(find.byKey(const ValueKey('chat-context-action')), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Message Gormes'),
        'triage web path',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(channel.sentTextCalls.last, (
        text: 'triage web path',
        serverId: 'office',
        profileId: 'support',
      ));
      expect(find.text('triage web path'), findsOneWidget);
    },
  );
}

class _WebE2EApp extends ConsumerWidget {
  const _WebE2EApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}
