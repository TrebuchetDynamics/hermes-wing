import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';
import 'package:navivox/router/app_routes.dart';

import '../../../support/test_navivox_channel.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';
import '../../shared/fixtures/seed_fixtures.dart';
import '../shared/chat_screen_test_fixtures.dart';

const _seedServers = [
  NavivoxServer(id: 'srv1', name: 'Local', status: 'ready'),
];

final _seedProfiles = [
  mineruBuilderProfile(
    serverId: 'srv1',
    serverLabel: 'Local',
    latestPreview: 'Ready for scoped chat',
  ),
];

void main() {
  testWidgets(
    'chat AppBar omits the active-agent indicator when no agent is selected',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(_seedServers, activeServerId: 'srv1')
        ..seedAgents(defaultSeedAgents);

      await pumpChatScreen(tester, channel: channel);

      expect(find.byKey(const ValueKey('chat-active-agent')), findsNothing);
    },
  );

  testWidgets('chat AppBar keeps agent context behind a compact info action', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_seedServers, activeServerId: 'srv1')
      ..seedAgents(defaultSeedAgents, selectedAgentId: 'arch');

    await pumpChatScreen(tester, channel: channel);

    expect(find.byKey(const ValueKey('chat-active-agent')), findsNothing);
    expect(find.byKey(const ValueKey('chat-context-action')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chat-context-action')));
    await tester.pumpAndSettle();

    expect(find.text('Chat info'), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Agent'), findsOneWidget);
    expect(find.text('Architect'), findsOneWidget);
  });

  testWidgets('chat AppBar shows active profile avatar like Telegram header', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_seedServers, activeServerId: 'srv1')
      ..seedProfileContacts(_seedProfiles, selectedKey: 'srv1::mineru');

    await pumpChatScreen(tester, channel: channel);

    expect(
      find.byKey(const ValueKey('chat-active-profile-avatar')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('chat-active-profile-avatar')),
        matching: find.text('M'),
      ),
      findsOneWidget,
    );
    expect(find.text('Mineru Builder'), findsOneWidget);
  });

  testWidgets('chat info exposes active server and profile scope', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_seedServers, activeServerId: 'srv1')
      ..seedProfileContacts(_seedProfiles, selectedKey: 'srv1::mineru');

    await pumpChatScreen(tester, channel: channel);

    await tester.tap(find.byKey(const ValueKey('chat-context-action')));
    await tester.pumpAndSettle();

    expect(find.text('Chat info'), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Profile ID'), findsOneWidget);
    expect(find.text('mineru'), findsOneWidget);
    expect(find.text('Server ID'), findsOneWidget);
    expect(find.text('srv1'), findsOneWidget);
  });

  testWidgets('chat info menu actions navigate to correct routes', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_seedServers, activeServerId: 'srv1')
      ..seedProfileContacts(_seedProfiles, selectedKey: 'srv1::mineru');

    final navigatedRoutes = <String>[];
    final goRouter = GoRouter(
      initialLocation: AppRoutes.chatLocation(
        serverId: 'srv1',
        profileId: 'mineru',
      ),
      routes: [
        GoRoute(
          path: '/chats/:serverId/:profileId',
          builder: (context, state) => const ChatScreen(),
        ),
        GoRoute(
          path: AppRoutes.agents,
          builder: (context, state) {
            navigatedRoutes.add(AppRoutes.agents);
            return const SizedBox();
          },
        ),
        GoRoute(
          path: AppRoutes.memory,
          builder: (context, state) {
            navigatedRoutes.add(AppRoutes.memory);
            return const SizedBox();
          },
        ),
        GoRoute(
          path: AppRoutes.config,
          builder: (context, state) {
            navigatedRoutes.add(AppRoutes.config);
            return const SizedBox();
          },
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) {
            navigatedRoutes.add(AppRoutes.settings);
            return const SizedBox();
          },
        ),
        GoRoute(
          path: AppRoutes.servers,
          builder: (context, state) {
            navigatedRoutes.add(AppRoutes.servers);
            return const SizedBox();
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: MaterialApp.router(routerConfig: goRouter),
      ),
    );
    await tester.pumpAndSettle();

    // Helper: open chat info sheet, scroll to reveal actions, tap a labeled
    // action, and assert the GoRouter navigated to [expectedRoute].
    // Returns the GoRouter so the caller can navigate back between actions.
    Future<void> tapInfoAction(String actionLabel, String expectedRoute) async {
      await tester.tap(find.byKey(const ValueKey('chat-context-action')));
      await tester.pumpAndSettle();

      expect(find.text('Chat info'), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      // Scroll aggressively to reveal actions below profile info rows
      await tester.drag(
        find.byType(DraggableScrollableSheet),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();

      // If scrolling wasn't enough, scroll more
      if (find.text(actionLabel).evaluate().isEmpty) {
        await tester.drag(
          find.byType(DraggableScrollableSheet),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      expect(find.text(actionLabel), findsOneWidget);
      await tester.tap(find.text(actionLabel));
      await tester.pumpAndSettle();
      expect(
        navigatedRoutes,
        contains(expectedRoute),
        reason: '$actionLabel should navigate to $expectedRoute',
      );
      navigatedRoutes.clear();

      // Navigate back to the chat screen for the next action
      goRouter.go(
        AppRoutes.chatLocation(serverId: 'srv1', profileId: 'mineru'),
      );
      await tester.pumpAndSettle();
    }

    await tapInfoAction('Open profile contacts', AppRoutes.agents);
    await tapInfoAction('Workspace and memory', AppRoutes.memory);
    await tapInfoAction('Profile config', AppRoutes.config);
    await tapInfoAction('Navivox settings', AppRoutes.settings);
    await tapInfoAction('Gateway details', AppRoutes.servers);
  });
}
