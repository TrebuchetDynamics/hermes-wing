import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/shared/async/fire_and_forget.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

void main() {
  testWidgets('active header shows agent and gateway and opens sessions', (
    tester,
  ) async {
    await _pumpGatewayChat(tester);

    expect(find.text('AGENT-A'), findsOneWidget);
    expect(find.textContaining('Alpha'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hermes-sessions-panel')), findsOneWidget);
  });

  testWidgets(
    'desktop shortcuts open sessions and create an authorized session',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final harness = await _pumpGatewayChat(tester);
      expect(find.byTooltip('Sessions (Ctrl+K)'), findsOneWidget);
      expect(find.byTooltip('New session (Ctrl+N)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('hermes-composer-field')));

      await _sendControlShortcut(tester, LogicalKeyboardKey.keyK);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-sessions-panel')),
        findsOneWidget,
      );

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await _sendControlShortcut(tester, LogicalKeyboardKey.keyN);
      await tester.pumpAndSettle();

      expect(harness.channel.createSessionCalls, [null]);
      expect(harness.channel.state.activeSessionId, 'sess_2');
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('macOS command shortcut opens sessions', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await _pumpGatewayChat(tester);
    expect(find.byTooltip('Sessions (⌘+K)'), findsOneWidget);
    expect(find.byTooltip('New session (⌘+N)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hermes-composer-field')));

    await _sendMetaShortcut(tester, LogicalKeyboardKey.keyK);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-sessions-panel')), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop new-session shortcut is absent without write access', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
      capabilities: HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {
          'type': 'bearer',
          'required': true,
          'granted_scopes': ['sessions:read'],
        },
        'endpoints': {
          'sessions': {
            'method': 'GET',
            'path': '/api/sessions',
            'required_scopes': ['sessions:read'],
          },
          'session_create': {
            'method': 'POST',
            'path': '/api/sessions',
            'required_scopes': ['sessions:write'],
          },
        },
      }),
    );
    final harness = await _pumpGatewayChat(tester, channel: channel);
    await tester.tap(find.byKey(const ValueKey('hermes-composer-field')));

    await _sendControlShortcut(tester, LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();

    expect(harness.channel.createSessionCalls, isEmpty);
    expect(find.byKey(const ValueKey('hermes-new-session')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('header selects an older session within the active gateway', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    await harness.channel.createSession(title: 'Current session');
    expect(harness.channel.state.activeSessionId, 'sess_2');

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-row-sess_1')));
    await tester.pumpAndSettle();

    expect(harness.channel.selectSessionCalls.last, 'sess_1');
    expect(harness.channel.state.activeSessionId, 'sess_1');
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('profile switch keeps the active gateway contact synchronized', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
      profiles: const [
        HermesProfile(
          id: 'agent-a',
          displayName: 'AGENT-A',
          revision: 'r-agent-a',
        ),
        HermesProfile(
          id: 'agent-b',
          displayName: 'AGENT-B',
          revision: 'r-agent-b',
        ),
      ],
    );
    final harness = await _pumpGatewayChat(
      tester,
      channel: channel,
      profileIds: const ['agent-a', 'agent-b'],
    );
    channel.replaceCapabilitiesAndProfiles(
      HermesCapabilityDocument.fromJson(const {
        'schema_version': 1,
        'auth': {'type': 'none', 'required': false},
        'endpoints': <String, Object?>{},
      }),
      const [
        HermesProfile(
          id: 'agent-a',
          displayName: 'AGENT-A',
          revision: 'r-agent-a',
        ),
        HermesProfile(
          id: 'agent-b',
          displayName: 'AGENT-B',
          revision: 'r-agent-b',
        ),
      ],
    );
    await tester.pump();
    expect(harness.directory.activeContactId, isNotNull);
    expect(channel.state.isConnected, isTrue);
    expect(find.byKey(const ValueKey('hermes-contact-header')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-profile-switcher')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-profile-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AGENT-B'));
    await tester.pumpAndSettle();

    expect(channel.selectProfileCalls, ['agent-a', 'agent-b']);
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-b'),
    );
  });

  testWidgets('profile switcher is disabled while selection is pending', (
    tester,
  ) async {
    final selectionGate = Completer<void>();
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
      selectProfileGate: (profileId) async {
        if (profileId == 'agent-b') await selectionGate.future;
      },
    );
    await _pumpGatewayChat(
      tester,
      channel: channel,
      profileIds: const ['agent-a', 'agent-b'],
    );
    channel.replaceCapabilitiesAndProfiles(
      HermesCapabilityDocument.fromJson(const {
        'schema_version': 1,
        'auth': {'type': 'none', 'required': false},
        'endpoints': <String, Object?>{},
      }),
      const [
        HermesProfile(id: 'agent-a', displayName: 'AGENT-A', revision: 'r-a'),
        HermesProfile(id: 'agent-b', displayName: 'AGENT-B', revision: 'r-b'),
      ],
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-profile-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AGENT-B'));
    await tester.pump();

    final switcher = tester.widget<TextButton>(
      find.byKey(const ValueKey('hermes-profile-switcher')),
    );
    expect(switcher.onPressed, isNull);

    selectionGate.complete();
    await tester.pumpAndSettle();
    expect(channel.state.selectedProfileId, 'agent-b');
  });

  testWidgets('session switches preserve separate unsent composer drafts', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    final composer = find.byKey(const ValueKey('hermes-composer-field'));
    await tester.enterText(composer, 'draft for the first chat');

    await harness.channel.createSession(title: 'Second chat');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(composer).controller!.text, isEmpty);
    await tester.enterText(composer, 'draft for the second chat');

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-row-sess_1')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(composer).controller!.text,
      'draft for the first chat',
    );

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-row-sess_2')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(composer).controller!.text,
      'draft for the second chat',
    );
  });

  testWidgets('prompt history stays scoped to its session', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final harness = await _pumpGatewayChat(tester);
    final composer = find.byKey(const ValueKey('hermes-composer-field'));

    await tester.enterText(composer, 'prompt only for the first chat');
    await tester.showKeyboard(composer);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(composer).controller!.text, isEmpty);

    await harness.channel.createSession(title: 'Second chat');
    await tester.pumpAndSettle();
    await tester.enterText(composer, 'prompt only for the second chat');
    await tester.showKeyboard(composer);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(composer).controller!.text, isEmpty);
    await tester.showKeyboard(composer);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(
      tester.widget<TextField>(composer).controller!.text,
      'prompt only for the second chat',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-row-sess_1')));
    await tester.pumpAndSettle();
    await tester.enterText(composer, '');
    await tester.showKeyboard(composer);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(
      tester.widget<TextField>(composer).controller!.text,
      'prompt only for the first chat',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(tester.widget<TextField>(composer).controller!.text, isEmpty);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'session branch requires confirmation and selects the child at 200% scale',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = await _pumpGatewayChat(tester, textScale: 2);

      await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-menu-sess_1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Branch'));
      await tester.pumpAndSettle();

      expect(find.text('Branch this session?'), findsOneWidget);
      expect(harness.channel.forkSessionCalls, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-branch-confirm')),
      );
      await tester.pumpAndSettle();

      expect(harness.channel.forkSessionCalls, ['sess_1']);
      expect(harness.channel.state.activeSession?.parentSessionId, 'sess_1');
      expect(tester.takeException(), isNull);
      expect(find.text('Created a new session branch.'), findsOneWidget);
    },
  );

  testWidgets('authorized session history deletes multiple selected sessions', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.replaceSessions(const [
      HermesSession(id: 'keep', source: 'test', title: 'Keep session'),
      HermesSession(id: 'delete-a', source: 'test', title: 'Delete first'),
      HermesSession(id: 'delete-b', source: 'test', title: 'Delete second'),
    ], activeSessionId: 'keep');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-search-field')),
      'Delete',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-sessions-select-all')));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.text('Delete 2'));
    await tester.pumpAndSettle();
    expect(find.text('Delete 2 sessions?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('hermes-sessions-delete-confirm')),
    );
    await tester.pumpAndSettle();

    expect(harness.channel.deleteSessionCalls, ['delete-a', 'delete-b']);
    expect(harness.channel.state.sessions.map((session) => session.id), [
      'keep',
    ]);
  });

  testWidgets('bulk session delete continues after a bounded partial failure', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected(
      deleteSessionFailureIds: const {'delete-a'},
    );
    final harness = await _pumpGatewayChat(tester, channel: channel);
    harness.channel.replaceSessions(const [
      HermesSession(id: 'keep', source: 'test', title: 'Keep session'),
      HermesSession(id: 'delete-a', source: 'test', title: 'Delete first'),
      HermesSession(id: 'delete-b', source: 'test', title: 'Delete second'),
    ], activeSessionId: 'keep');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-search-field')),
      'Delete',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-sessions-select-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete 2'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('hermes-sessions-delete-confirm')),
    );
    await tester.pumpAndSettle();

    expect(harness.channel.deleteSessionCalls, ['delete-a', 'delete-b']);
    expect(
      find.text('Deleted 1 of 2 sessions. 1 could not be deleted.'),
      findsOneWidget,
    );
    expect(find.textContaining('private transport failure'), findsNothing);
    expect(harness.channel.state.sessions.map((session) => session.id), [
      'keep',
      'delete-a',
    ]);
  });

  testWidgets('bulk selection excludes sessions with an active reply', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('background work');
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Select'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('hermes-sessions-select-all')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('1 selected'), findsOneWidget);
    final activeRow = find.byKey(const ValueKey('hermes-session-row-sess_1'));
    final activeCheckbox = find.descendant(
      of: activeRow,
      matching: find.byType(Checkbox),
    );
    expect(activeCheckbox, findsOneWidget);
    expect(tester.widget<Checkbox>(activeCheckbox).onChanged, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 100));
    final activeMenu = find.byKey(const ValueKey('hermes-session-menu-sess_1'));
    await tester.scrollUntilVisible(
      activeMenu,
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('hermes-sessions-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(activeMenu);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Branch'), findsNothing);
  });

  testWidgets('bulk selection remains usable at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pumpGatewayChat(tester, textScale: 2);
    harness.channel.replaceSessions(const [
      HermesSession(id: 'scale-a', source: 'test', title: 'Scale first'),
      HermesSession(id: 'scale-b', source: 'test', title: 'Scale second'),
    ], activeSessionId: 'scale-a');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-sessions-select')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('0 selected'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-sessions-select-all')),
      findsOneWidget,
    );
  });

  testWidgets('bulk selection is absent without session-delete authorization', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
      capabilities: HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {
          'type': 'bearer',
          'required': true,
          'granted_scopes': ['sessions:read'],
        },
        'endpoints': {
          'sessions': {
            'method': 'GET',
            'path': '/api/sessions',
            'required_scopes': ['sessions:read'],
          },
          'session_delete': {
            'method': 'DELETE',
            'path': '/api/sessions/{session_id}',
            'required_scopes': ['sessions:write'],
          },
        },
      }),
    );
    await _pumpGatewayChat(tester, channel: channel);

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-sessions-select')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('hermes-session-menu-sess_1')));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Branch'), findsNothing);
  });

  testWidgets('wide session rail deletes multiple selected sessions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pumpGatewayChat(tester);
    harness.channel.replaceSessions(const [
      HermesSession(id: 'keep', source: 'test', title: 'Keep session'),
      HermesSession(id: 'rail-a', source: 'test', title: 'Rail first'),
      HermesSession(id: 'rail-b', source: 'test', title: 'Rail second'),
    ], activeSessionId: 'keep');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-rail-search-field')),
      'Rail',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-rail-select')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('hermes-session-rail-select-all')),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.text('Delete 2'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('hermes-sessions-delete-confirm')),
    );
    await tester.pumpAndSettle();

    expect(harness.channel.deleteSessionCalls, ['rail-a', 'rail-b']);
    expect(harness.channel.state.sessions.map((session) => session.id), [
      'keep',
    ]);
  });

  testWidgets(
    'session source filter limits visible and bulk-selected sessions',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = await _pumpGatewayChat(tester);
      harness.channel.replaceSessions(const [
        HermesSession(id: 'chat-a', source: 'chat', title: 'Chat first'),
        HermesSession(
          id: 'automation-a',
          source: 'automation',
          title: 'Automation job',
        ),
        HermesSession(id: 'chat-b', source: 'chat', title: 'Chat second'),
      ], activeSessionId: 'chat-a');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('hermes-session-row-chat-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-session-row-automation-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-session-row-chat-b')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-rail-source-filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-rail-source-option-0')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('hermes-session-row-chat-a')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('hermes-session-row-automation-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-session-row-chat-b')),
        findsNothing,
      );
      expect(find.text('Showing 1 of 3 sessions'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('hermes-session-rail-select')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-rail-select-all')),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('Delete 1'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-sessions-delete-confirm')),
      );
      await tester.pumpAndSettle();

      expect(harness.channel.deleteSessionCalls, ['automation-a']);
    },
  );

  testWidgets(
    'compact session source filter limits visible and bulk-selected sessions',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = await _pumpGatewayChat(tester);
      harness.channel.replaceSessions(const [
        HermesSession(id: 'compact-chat', source: 'chat', title: 'Phone chat'),
        HermesSession(
          id: 'compact-automation',
          source: 'automation',
          title: 'Phone automation',
        ),
      ], activeSessionId: 'compact-chat');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-source-filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('automation').last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('hermes-session-row-compact-chat')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('hermes-session-row-compact-automation')),
        findsOneWidget,
      );
      expect(find.text('Showing 1 of 2 sessions'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('hermes-sessions-select')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-sessions-select-all')),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('Delete 1'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-sessions-delete-confirm')),
      );
      await tester.pumpAndSettle();

      expect(harness.channel.deleteSessionCalls, ['compact-automation']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('session search highlights title and preview matches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pumpGatewayChat(tester);
    harness.channel.replaceSessions(const [
      HermesSession(id: 'title-match', source: 'chat', title: 'Roadmap review'),
      HermesSession(
        id: 'preview-match',
        source: 'chat',
        title: 'Budget notes',
        preview: 'Investigate the unusual anomaly',
      ),
    ], activeSessionId: 'title-match');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-rail-search-field')),
      'road',
    );
    await tester.pumpAndSettle();
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('hermes-session-title-title-match')),
    );
    expect(
      (title.textSpan! as TextSpan).children!
          .whereType<TextSpan>()
          .singleWhere((span) => span.style?.backgroundColor != null)
          .text,
      'Road',
    );

    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-rail-search-field')),
      'anomaly',
    );
    await tester.pumpAndSettle();
    final subtitle = tester.widget<Text>(
      find.byKey(const ValueKey('hermes-session-subtitle-preview-match')),
    );
    expect(subtitle.textSpan!.toPlainText(), startsWith('Investigate'));
    expect(
      (subtitle.textSpan! as TextSpan).children!
          .whereType<TextSpan>()
          .singleWhere((span) => span.style?.backgroundColor != null)
          .text,
      'anomaly',
    );
  });

  testWidgets('wide session rail pins a chat above recent groups', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pumpGatewayChat(tester);
    final now = DateTime.now();
    harness.channel.replaceSessions([
      HermesSession(
        id: 'newer',
        source: 'manual',
        title: 'Newer chat',
        lastActive: now.toIso8601String(),
      ),
      HermesSession(
        id: 'older',
        source: 'manual',
        title: 'Older chat',
        lastActive: now.subtract(const Duration(days: 2)).toIso8601String(),
      ),
    ], activeSessionId: 'newer');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-session-menu-older')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();

    expect(find.text('Pinned'), findsOneWidget);
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('hermes-session-row-older')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('hermes-session-row-newer')))
            .dy,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('hermes-session-menu-older')));
    await tester.pumpAndSettle();
    expect(find.text('Unpin'), findsOneWidget);
  });

  testWidgets('compact session panel pins a chat above recent groups', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pumpGatewayChat(tester);
    final now = DateTime.now();
    harness.channel.replaceSessions([
      HermesSession(
        id: 'compact-newer',
        source: 'manual',
        title: 'Newer chat',
        lastActive: now.toIso8601String(),
      ),
      HermesSession(
        id: 'compact-older',
        source: 'manual',
        title: 'Older chat',
        lastActive: now.subtract(const Duration(days: 2)).toIso8601String(),
      ),
    ], activeSessionId: 'compact-newer');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('hermes-session-menu-compact-older')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();

    expect(find.text('Pinned'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('hermes-session-row-compact-older')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('hermes-session-row-compact-newer')),
            )
            .dy,
      ),
    );
  });

  testWidgets('wide active-session bar switches to a background reply', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('background work');
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('hermes-active-session-chip-sess_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-active-session-chip-sess_2')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-active-session-chip-sess_1')),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(harness.channel.state.activeSessionId, 'sess_1');
    expect(harness.channel.selectSessionCalls.last, 'sess_1');
    expect(find.text('background work'), findsOneWidget);
  });

  testWidgets('completed background chat stays marked until viewed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('background work');
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();

    harness.channel.completeStreamingTurn(
      text: 'background done',
      sessionId: 'sess_1',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-active-session-chip-sess_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-active-session-new-reply-sess_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-new-reply-sess_1')),
      findsOneWidget,
    );
    expect(find.textContaining('New reply'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('hermes-active-session-chip-sess_1')),
    );
    await tester.pump();

    expect(harness.channel.state.activeSessionId, 'sess_1');
    expect(
      find.byKey(const ValueKey('hermes-active-session-new-reply-sess_1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-new-reply-sess_1')),
      findsNothing,
    );
  });

  testWidgets(
    'desktop shortcuts cycle forward and backward through live chats',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = await _pumpGatewayChat(tester);
      harness.channel.beginStreamingTurn('first background work');
      await harness.channel.createSession(title: 'Second background');
      harness.channel.beginStreamingTurn('second background work');
      await harness.channel.createSession(title: 'Foreground');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('hermes-composer-field')));

      await _sendControlShortcut(tester, LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 100));
      expect(harness.channel.state.activeSessionId, 'sess_1');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 100));
      expect(harness.channel.state.activeSessionId, 'sess_2');
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('primary digit shortcuts select ordinal live chats', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('first live chat');
    await harness.channel.createSession(title: 'Second live chat');
    harness.channel.beginStreamingTurn('second live chat');
    await harness.channel.createSession(title: 'Last live chat');
    harness.channel.beginStreamingTurn('last live chat');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('hermes-composer-field')));

    await _sendControlShortcut(tester, LogicalKeyboardKey.digit1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.channel.state.activeSessionId, 'sess_1');

    await _sendMetaShortcut(tester, LogicalKeyboardKey.digit9);
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.channel.state.activeSessionId, 'sess_3');

    final selectionCount = harness.channel.selectSessionCalls.length;
    await _sendControlShortcut(tester, LogicalKeyboardKey.digit8);
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.channel.selectSessionCalls, hasLength(selectionCount));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('session list identifies a reply streaming in the background', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('background work');
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pump(const Duration(milliseconds: 300));

    final row = find.byKey(const ValueKey('hermes-session-row-sess_1'));
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining('Streaming reply'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
  });

  testWidgets('session list identifies a failed background reply', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('failed work');
    harness.channel.stopActiveTurn();
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('hermes-session-row-sess_1'));
    expect(
      find.descendant(of: row, matching: find.textContaining('Reply failed')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.error_outline)),
      findsOneWidget,
    );
  });

  testWidgets('approval stays attached to its session while switching', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.emitApprovalRequest(
      const HermesApprovalRequest(
        id: 'approval-background',
        toolCallId: 'tool-background',
        prompt: 'Approve background work?',
        runId: 'run-background',
        sessionId: 'sess_1',
      ),
    );
    await tester.pump();
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();

    expect(find.text('Approve background work?'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-row-sess_1')));
    await tester.pumpAndSettle();

    expect(find.text('Approve background work?'), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-approval-deny')), findsOneWidget);
  });

  testWidgets('sessions are grouped by recent activity', (tester) async {
    final harness = await _pumpGatewayChat(tester);
    final current = DateTime.now();
    final now = DateTime(current.year, current.month, current.day, 12);
    HermesSession session(String id, String title, DateTime lastActive) =>
        HermesSession(
          id: id,
          source: 'test',
          title: title,
          lastActive: lastActive.toIso8601String(),
        );
    harness.channel.replaceSessions([
      session('today', 'Today', now.subtract(const Duration(hours: 1))),
      session('yesterday', 'Yesterday', now.subtract(const Duration(days: 1))),
      session('week', 'This week', now.subtract(const Duration(days: 3))),
      session('earlier', 'Earlier', now.subtract(const Duration(days: 10))),
    ], activeSessionId: 'today');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-session-group-today')), findsOne);
    expect(
      find.byKey(const ValueKey('hermes-session-group-yesterday')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-group-this-week')),
      findsOne,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('hermes-session-group-earlier')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('hermes-sessions-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      find.byKey(const ValueKey('hermes-session-group-earlier')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-group-active')),
      findsNothing,
    );
  });

  testWidgets('session rows show source and model metadata', (tester) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.replaceSessions(const [
      HermesSession(
        id: 'metadata',
        source: 'api_server',
        title: 'Metadata session',
        model: 'anthropic/claude-sonnet',
        messageCount: 2,
        lastActive: '2026-07-16T10:30:00Z',
      ),
    ], activeSessionId: 'metadata');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('hermes-session-row-metadata'));
    expect(
      find.descendant(of: row, matching: find.textContaining('api server')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining('anthropic/claude-sonnet'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.textContaining('2 messages')),
      findsOneWidget,
    );
    final metadata = tester
        .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
        .map((widget) => widget.data ?? '')
        .firstWhere((text) => text.contains('api server'));
    expect(metadata, contains('Last active'));
    expect(metadata, isNot(contains('2026-07-16T10:30:00Z')));
  });

  testWidgets('session details expose bounded server-reported usage metadata', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pumpGatewayChat(tester);
    harness.channel.replaceSessions(const [
      HermesSession(
        id: 'usage-metadata',
        source: 'api_server',
        title: 'Usage metadata',
        model: 'anthropic/claude-sonnet',
        messageCount: 2,
        toolCallCount: 4,
        inputTokens: 1200,
        outputTokens: 300,
        cacheReadTokens: 800,
        cacheWriteTokens: 50,
        reasoningTokens: 25,
        apiCallCount: 3,
        estimatedCostUsd: 0.0125,
        actualCostUsd: 0.01,
        startedAt: '2026-07-16T10:25:00Z',
        endedAt: '2026-07-16T10:30:00Z',
        endReason: 'completed',
        hasSystemPrompt: true,
        hasModelConfig: false,
        preview: 'private prompt that must stay out of details',
      ),
    ], activeSessionId: 'usage-metadata');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('hermes-session-menu-usage-metadata')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-session-details-sheet')),
      findsOneWidget,
    );
    expect(find.textContaining('Tool calls: 4'), findsOneWidget);
    expect(find.textContaining('Session input tokens: 1200'), findsOneWidget);
    expect(find.textContaining('Session output tokens: 300'), findsOneWidget);
    expect(
      find.textContaining('Session cache read tokens: 800'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Session cache write tokens: 50'),
      findsOneWidget,
    );
    expect(find.textContaining('Session reasoning tokens: 25'), findsOneWidget);
    expect(find.textContaining('API calls: 3'), findsOneWidget);
    expect(find.textContaining('Actual cost (USD): 0.01'), findsOneWidget);
    expect(find.textContaining('Estimated cost (USD): 0.0125'), findsOneWidget);
    expect(find.textContaining('End reason: completed'), findsOneWidget);
    expect(find.textContaining('System prompt snapshot: yes'), findsOneWidget);
    expect(find.textContaining('Model config snapshot: no'), findsOneWidget);
    final details = tester
        .widget<SelectableText>(find.byType(SelectableText))
        .data;
    expect(details, isNot(contains('private prompt')));
    expect(details, isNot(contains('Preview:')));

    final clipboardCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        clipboardCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final copyButton = find.widgetWithText(FilledButton, 'Copy details');
    tester.widget<FilledButton>(copyButton).onPressed!();
    await tester.pumpAndSettle();

    expect(
      clipboardCalls.map((call) => call.method),
      contains('Clipboard.setData'),
    );
    expect(
      find.byKey(const ValueKey('hermes-session-details-sheet')),
      findsNothing,
    );
    expect(
      find.text('Copied redacted Hermes session details.'),
      findsOneWidget,
    );
  });

  testWidgets('phone header keeps secondary actions in overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpGatewayChat(tester);

    expect(find.byKey(const ValueKey('hermes-sessions-button')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('hermes-more-actions-button')));
    await tester.pumpAndSettle();
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
  });

  testWidgets('contact tap shows loading feedback before connect finishes', (
    tester,
  ) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
      connectGate: () => gate.future,
    );
    addTearDown(channel.dispose);
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(
          id: 'legacy',
          label: 'Legacy',
          baseUrl: 'https://legacy',
        ),
      ],
    );
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader(const {
        'legacy': GatewaySummary(
          profiles: [],
          sessionsByProfile: {},
          unscopedSessions: [],
        ),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('gateway-contact-legacy-default')),
    );
    await tester.pump();

    expect(
      directory.activeContactId,
      const GatewayContactId(gatewayId: 'legacy', profileId: 'default'),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hermes-back-to-contacts')),
      findsOneWidget,
    );
  });

  testWidgets('contact directory exposes adding another gateway', (
    tester,
  ) async {
    await _pumpGatewayChat(tester);

    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-connect-another-gateway')),
      findsOneWidget,
    );
  });

  testWidgets('back returns to contacts without deleting gateway', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);

    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pumpAndSettle();

    expect(harness.directory.activeContactId, isNull);
    expect(harness.store.deleteProfileCalls, isEmpty);
    expect(find.text('AGENT-A'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('AGENT-B'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('switching gateways does not carry a staged attachment', (
    tester,
  ) async {
    await _pumpGatewayChat(tester);
    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    composer.contentInsertionConfiguration!.onContentInserted(
      KeyboardInsertedContent(
        mimeType: 'image/png',
        uri: 'content://keyboard/gateway-owned-image',
        data: Uint8List.fromList([
          0x89,
          0x50,
          0x4e,
          0x47,
          0x0d,
          0x0a,
          0x1a,
          0x0a,
          0x00,
        ]),
      ),
    );
    await tester.pump();
    expect(find.text('pasted-image.png'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-contact-b-agent-b')));
    await tester.pumpAndSettle();

    expect(find.text('AGENT-B'), findsOneWidget);
    expect(find.text('pasted-image.png'), findsNothing);
    expect(find.text('Ready to send'), findsNothing);
  });

  testWidgets('contact opens when restoring its latest session fails', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.loader.results['a'] = const GatewaySummary(
      profileContextAvailable: true,
      profiles: [
        HermesProfile(id: 'agent-a', displayName: 'AGENT-A', revision: 'r'),
      ],
      sessionsByProfile: {
        'agent-a': [HermesSession(id: 'sess_1', source: 'test')],
      },
    );
    await harness.directory.refresh();
    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pumpAndSettle();
    harness.channel.selectSessionFails = true;

    await tester.tap(find.byKey(const ValueKey('gateway-contact-a-agent-a')));
    await tester.pumpAndSettle();

    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
    expect(
      find.byKey(const ValueKey('hermes-back-to-contacts')),
      findsOneWidget,
    );
  });

  testWidgets('system back returns to contacts without deleting gateway', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(harness.directory.activeContactId, isNull);
    expect(harness.store.deleteProfileCalls, isEmpty);
    expect(find.text('AGENT-A'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('AGENT-B'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('system back preserves the active-work switch guard', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('work');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-gateway-switch-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    await tester.pump();
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('background reply preserves the gateway switch guard', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('background work');
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-gateway-switch-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    await tester.pump();
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('disconnect removes only the active gateway', (tester) async {
    final harness = await _pumpGatewayChat(tester);

    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Other saved Hermes gateways'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-confirm')));
    await tester.pumpAndSettle();

    expect(harness.store.deleteProfileCalls, ['a']);
    expect(find.text('AGENT-A'), findsNothing);
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('AGENT-B'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('resume keeps a healthy active contact connected', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(harness.channel.connectCalls, hasLength(1));
    expect(harness.channel.disconnectCalls, 0);
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('resume reports a failed activation without an uncaught error', (
    tester,
  ) async {
    final defaultReporter = reportFireAndForgetFailure;
    final reported = <({String operation, Object error})>[];
    reportFireAndForgetFailure = (operation, error) =>
        reported.add((operation: operation, error: error));
    addTearDown(() => reportFireAndForgetFailure = defaultReporter);

    var selectionCount = 0;
    final channel = FakeHermesChannel(
      selectProfileGate: (_) async {
        selectionCount += 1;
        if (selectionCount > 1) throw StateError('profile selection failed');
      },
    );
    final harness = await _pumpGatewayChat(tester, channel: channel);
    harness.channel.addFailedExchange('resume failure');
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      reported.map((failure) => failure.operation),
      contains('Hermes reconnect after resume'),
    );
  });

  testWidgets('resume preserves an attached live stream', (tester) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('keep streaming');
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 500));

    expect(harness.channel.connectCalls, hasLength(1));
    expect(harness.channel.disconnectCalls, 0);
    expect(harness.channel.state.hasStreamingSessions, isTrue);
  });

  testWidgets('completed turn refreshes active contact summary', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);

    await harness.channel.sendText('hello');
    await tester.pumpAndSettle();

    expect(harness.channel.state.activeMessages, hasLength(2));
    expect(harness.loader.calls.where((id) => id == 'a'), hasLength(2));
    expect(harness.loader.calls.where((id) => id == 'b'), hasLength(1));
  });

  testWidgets('background completion refreshes the gateway summary', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('background summary');
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();
    final callsBeforeCompletion = harness.loader.calls
        .where((id) => id == 'a')
        .length;

    harness.channel.completeStreamingTurn(
      text: 'background done',
      sessionId: 'sess_1',
    );
    await tester.pump();

    expect(
      harness.loader.calls.where((id) => id == 'a'),
      hasLength(callsBeforeCompletion + 1),
    );
  });

  testWidgets('pending approval requires confirmation before leaving contact', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.emitApprovalRequest(
      const HermesApprovalRequest(
        id: 'approval-1',
        toolCallId: 'tool-1',
        prompt: 'Run a command?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-gateway-switch-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    await tester.pump();
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('in-flight submission requires confirmation before leaving', (
    tester,
  ) async {
    final gate = Completer<void>();
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
      sendTextGate: () => gate.future,
    );
    final harness = await _pumpGatewayChat(tester, channel: channel);

    unawaited(harness.channel.sendText('work'));
    await tester.pump();
    expect(
      harness.channel.state.activeMessages.last.status,
      HermesTurnStatus.streaming,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-gateway-switch-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    gate.complete();
    await tester.pumpAndSettle();
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('active run requires confirmation before leaving contact', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('work');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-gateway-switch-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    await tester.pump();
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });
}

Future<void> _sendControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

Future<void> _sendMetaShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
}

Future<
  ({
    HermesGatewayDirectory directory,
    FakeHermesChannel channel,
    FakeHermesEndpointStore store,
    FakeGatewaySummaryLoader loader,
  })
>
_pumpGatewayChat(
  WidgetTester tester, {
  FakeHermesChannel? channel,
  double textScale = 1,
  List<String> profileIds = const ['agent-a'],
}) async {
  channel ??= FakeHermesChannel.disconnected();
  final store = FakeHermesEndpointStore(
    profiles: const [
      HermesEndpointConfig(
        id: 'a',
        label: 'Alpha',
        baseUrl: 'https://a',
        apiKey: 'a-secret',
      ),
      HermesEndpointConfig(
        id: 'b',
        label: 'Beta',
        baseUrl: 'https://b',
        apiKey: 'b-secret',
      ),
    ],
  );
  final loader = FakeGatewaySummaryLoader({
    'a': gatewaySummary(profileIds),
    'b': gatewaySummary(['agent-b']),
  });
  final directory = HermesGatewayDirectory(
    store: store,
    cache: FakeGatewayContactCache(),
    loader: loader,
    activeChannel: channel,
  );
  await directory.refresh();
  await directory.activate(
    const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(store),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (directory: directory, channel: channel, store: store, loader: loader);
}
