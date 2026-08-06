import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
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
    final harness = await _pumpGatewayChat(tester, textScale: 2);
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
    expect(find.textContaining('Input tokens: 1200'), findsOneWidget);
    expect(find.textContaining('Output tokens: 300'), findsOneWidget);
    expect(find.textContaining('Cache read tokens: 800'), findsOneWidget);
    expect(find.textContaining('Cache write tokens: 50'), findsOneWidget);
    expect(find.textContaining('Reasoning tokens: 25'), findsOneWidget);
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
    expect(find.text('Alpha · AGENT-A'), findsOneWidget);
    expect(find.text('Beta · AGENT-B'), findsOneWidget);
  });

  testWidgets('contact opens when restoring its latest session fails', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.loader.results['a'] = const GatewaySummary(
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
    expect(find.text('Alpha · AGENT-A'), findsOneWidget);
    expect(find.text('Beta · AGENT-B'), findsOneWidget);
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
    expect(find.text('Alpha · AGENT-A'), findsNothing);
    expect(find.text('Beta · AGENT-B'), findsOneWidget);
  });

  testWidgets('resume fully reconnects the active contact only', (
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

    expect(harness.channel.connectCalls, hasLength(2));
    expect(harness.channel.disconnectCalls, 1);
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
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
    'a': gatewaySummary(['agent-a']),
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
