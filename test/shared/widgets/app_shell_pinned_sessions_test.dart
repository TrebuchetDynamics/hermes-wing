import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';

import 'app_shell_global_session_access_test.dart' as support;
import 'app_shell_global_session_modal_test.dart' as modal;
import 'package:wing/features/hermes_chat/providers/hermes_session_pin_provider.dart';
import 'package:wing/features/hermes_chat/session/hermes_session_pin_contact.dart';
import 'package:wing/features/settings/providers/shell_preferences_provider.dart';

Finder section(String name) => find.byKey(ValueKey('shell-$name-sessions'));
Finder open(String id) => find.byKey(ValueKey('shell-open-session-$id'));
Finder pin(String id) => find.byKey(ValueKey('shell-pin-session-$id'));

void noActions(support.Harness h) {
  h.noIncidentalWork();
  expect(h.channel.selectSessionCalls, isEmpty);
  expect(h.channel.createSessionCalls, isEmpty);
  expect(h.channel.renameSessionCalls, isEmpty);
  expect(h.channel.deleteSessionCalls, isEmpty);
  expect(h.channel.forkSessionCalls, isEmpty);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('saved sidebar pins are projected once for the exact contact', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wing.hermes.pinned_sessions.v1': [
        jsonEncode(['alpha', 'default', 'synthetic-other']),
        jsonEncode(['other', 'default', 'synthetic-active']),
      ],
    });
    final h = support.Harness(support.DelayedChannel());
    h.directory.contact = const GatewayContactId(
      gatewayId: 'alpha',
      profileId: 'default',
    );
    await h.pump(tester);
    expect(
      find.descendant(of: section('pinned'), matching: open('synthetic-other')),
      findsOneWidget,
    );
    expect(open('synthetic-other'), findsOneWidget);
    expect(
      find.descendant(
        of: section('recent'),
        matching: open('synthetic-active'),
      ),
      findsOneWidget,
    );
    expect(h.channel.state.activeSessionId, 'synthetic-active');
    noActions(h);
  });

  testWidgets(
    'keyboard pin and unpin preserve draft, selection and Agent state',
    (tester) async {
      final h = support.Harness(support.DelayedChannel());
      await h.pump(tester);
      final draft = find.byKey(const ValueKey('route-draft'));
      await tester.enterText(draft, 'Synthetic local draft');
      await modal.reach(tester, pin('synthetic-other'));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: section('pinned'),
          matching: open('synthetic-other'),
        ),
        findsOneWidget,
      );
      expect(open('synthetic-other'), findsOneWidget);
      expect(
        tester.widget<IconButton>(pin('synthetic-other')).tooltip,
        'Unpin',
      );
      await modal.reach(tester, pin('synthetic-other'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(section('pinned'), findsNothing);
      expect(tester.widget<TextField>(draft).controller, isNull);
      expect(find.text('Synthetic local draft'), findsOneWidget);
      expect(h.path, '/tools');
      expect(h.channel.state.activeSessionId, 'synthetic-active');
      noActions(h);
    },
  );

  testWidgets('session picker and sidebar share one reactive pin owner', (
    tester,
  ) async {
    final h = support.Harness(support.DelayedChannel());
    await modal.pump(tester, h);
    final store = h.container.read(hermesSessionPinStoreProvider);
    await modal.open(tester);
    final menu = find.byKey(
      const ValueKey('hermes-session-menu-synthetic-other'),
    );
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();
    expect(
      store.isPinned(
        hermesSessionPinContact(
          savedContact: null,
          baseUrl: h.channel.state.connectedBaseUrl,
          profileId: h.channel.state.selectedProfileId,
        ),
        'synthetic-other',
      ),
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: section('pinned'), matching: open('synthetic-other')),
      findsOneWidget,
    );
    await tester.ensureVisible(pin('synthetic-other'));
    await tester.tap(pin('synthetic-other'));
    await tester.pumpAndSettle();
    await modal.open(tester);
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(find.text('Pin'), findsOneWidget);
    expect(find.text('Unpin'), findsNothing);
    noActions(h);
  });

  testWidgets(
    'pins survive route and sidebar lifetime and stay contact scoped',
    (tester) async {
      final h = support.Harness(support.DelayedChannel());
      h.directory.contact = const GatewayContactId(
        gatewayId: 'alpha',
        profileId: 'default',
      );
      await h.pump(tester);
      await tester.ensureVisible(pin('synthetic-other'));
      await tester.tap(pin('synthetic-other'));
      await tester.pumpAndSettle();
      final store = h.container.read(hermesSessionPinStoreProvider);
      await h.container
          .read(wingSidebarExpandedProvider.notifier)
          .setSidebarExpanded(false);
      await tester.pumpAndSettle();
      expect(open('synthetic-other'), findsNothing);
      h.router.go('/settings');
      await tester.pumpAndSettle();
      await h.container
          .read(wingSidebarExpandedProvider.notifier)
          .setSidebarExpanded(true);
      await tester.pumpAndSettle();
      expect(
        identical(store, h.container.read(hermesSessionPinStoreProvider)),
        isTrue,
      );
      expect(
        find.descendant(
          of: section('pinned'),
          matching: open('synthetic-other'),
        ),
        findsOneWidget,
      );
      h.directory.contact = const GatewayContactId(
        gatewayId: 'beta',
        profileId: 'default',
      );
      h.directory.changed();
      await tester.pumpAndSettle();
      expect(section('pinned'), findsNothing);
      h.directory.contact = const GatewayContactId(
        gatewayId: 'alpha',
        profileId: 'default',
      );
      h.directory.changed();
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: section('pinned'),
          matching: open('synthetic-other'),
        ),
        findsOneWidget,
      );
      noActions(h);
    },
  );

  testWidgets('owner drift and removed rows cancel a queued pin choice', (
    tester,
  ) async {
    final h = support.Harness(support.DelayedChannel());
    h.directory.contact = const GatewayContactId(
      gatewayId: 'alpha',
      profileId: 'default',
    );
    await h.pump(tester);
    final store = h.container.read(hermesSessionPinStoreProvider);
    final stale = tester.widget<IconButton>(pin('synthetic-other')).onPressed!;
    h.directory.contact = const GatewayContactId(
      gatewayId: 'beta',
      profileId: 'default',
    );
    h.directory.changed();
    stale();
    await tester.pumpAndSettle();
    expect(section('pinned'), findsNothing);
    tester.widget<IconButton>(pin('synthetic-other')).onPressed!();
    h.channel.change(
      h.channel.state.copyWith(sessions: [support.sessions.first]),
    );
    await tester.pumpAndSettle();
    expect(
      store.isPinned(
        const GatewayContactId(gatewayId: 'alpha', profileId: 'default'),
        'synthetic-other',
      ),
      isFalse,
    );
    expect(
      store.isPinned(
        const GatewayContactId(gatewayId: 'beta', profileId: 'default'),
        'synthetic-other',
      ),
      isFalse,
    );
    expect(section('pinned'), findsNothing);
    noActions(h);
  });

  testWidgets('direct endpoint changes cannot project another endpoint pins', (
    tester,
  ) async {
    final legacy = jsonEncode(['direct', 'default', 'synthetic-active']);
    SharedPreferences.setMockInitialValues({
      'wing.hermes.pinned_sessions.v1': [legacy],
    });
    final h = support.Harness(support.DelayedChannel());
    await h.pump(tester);
    expect(section('pinned'), findsNothing);
    await tester.ensureVisible(pin('synthetic-other'));
    await tester.tap(pin('synthetic-other'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: section('pinned'), matching: open('synthetic-other')),
      findsOneWidget,
    );
    final originalEndpoint = h.channel.state.connectedBaseUrl;
    h.channel.change(
      h.channel.state.copyWith(
        connectedBaseUrl: 'https://other.example.invalid',
      ),
    );
    await tester.pumpAndSettle();
    expect(section('pinned'), findsNothing);
    h.channel.change(
      h.channel.state.copyWith(connectedBaseUrl: originalEndpoint),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: section('pinned'), matching: open('synthetic-other')),
      findsOneWidget,
    );
    final saved = (await SharedPreferences.getInstance()).getStringList(
      'wing.hermes.pinned_sessions.v1',
    )!;
    expect(saved, contains(legacy));
    expect(saved.join(), isNot(contains(originalEndpoint!)));
    expect(saved.join(), isNot(contains('other.example.invalid')));
    noActions(h);
  });

  testWidgets(
    'stale saved contact never projects pins onto another endpoint or profile',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'wing.hermes.pinned_sessions.v1': [
          jsonEncode(['alpha', 'default', 'synthetic-other']),
        ],
      });
      final h = support.Harness(support.DelayedChannel());
      h.directory.contact = const GatewayContactId(
        gatewayId: 'alpha',
        profileId: 'default',
      );
      await h.pump(tester);
      expect(section('pinned'), findsOneWidget);
      final original = h.channel.state;
      h.channel.change(
        original.copyWith(connectedBaseUrl: 'https://other.example.invalid'),
      );
      await tester.pumpAndSettle();
      expect(section('pinned'), findsNothing);
      h.channel.change(original.copyWith(selectedProfileId: 'other'));
      await tester.pumpAndSettle();
      expect(section('pinned'), findsNothing);
      h.channel.change(original);
      await tester.pumpAndSettle();
      expect(section('pinned'), findsOneWidget);
      expect(
        h.directory.contact,
        const GatewayContactId(gatewayId: 'alpha', profileId: 'default'),
      );
      noActions(h);
    },
  );
}
