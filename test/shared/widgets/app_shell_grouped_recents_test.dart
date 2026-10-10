import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';

import 'app_shell_global_session_access_test.dart' as support;

const rows = [
  HermesSession(id: 'a1', source: 'cli', title: 'Same title'),
  HermesSession(id: 'b1', source: 'custom', title: 'Same title'),
  HermesSession(id: 'a2', source: 'cli', title: 'Second'),
  HermesSession(id: 'blank', source: '', title: 'Blank'),
  HermesSession(id: 'spaces', source: '  ', title: 'Spaces'),
  HermesSession(id: 'p1', source: '/home/example-a', title: 'Redacted one'),
  HermesSession(id: 'p2', source: '/home/example-b', title: 'Redacted two'),
  HermesSession(id: 'exact', source: ' cli ', title: 'Exact source'),
];

Finder open(String id) => find.byKey(ValueKey('shell-open-session-$id'));
Finder get inventory => find.byKey(const ValueKey('shell-session-access'));
List<String> labels(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: inventory, matching: find.byType(Text)),
    )
    .map((text) => text.data!)
    .where(
      (label) =>
          label.startsWith('Source:') ||
          (label.startsWith('Open ') && !label.startsWith('Open or create.')),
    )
    .toList();

void noActions(support.Harness h) {
  h.noIncidentalWork();
  expect(h.channel.selectSessionCalls, isEmpty);
  expect(h.channel.createSessionCalls, isEmpty);
  expect(h.channel.renameSessionCalls, isEmpty);
  expect(h.channel.deleteSessionCalls, isEmpty);
  expect(h.channel.forkSessionCalls, isEmpty);
  expect(h.channel.refreshModelsCalls, 0);
}

Future<void> reach(
  WidgetTester tester,
  Finder target, {
  bool reverse = false,
}) async {
  bool focused() =>
      tester
          .getSemantics(target)
          .getSemanticsData()
          .flagsCollection
          .isFocused
          .toBoolOrNull() ==
      true;
  for (var i = 0; i < 60 && !focused(); i++) {
    if (reverse) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    if (reverse) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
  }
  expect(focused(), isTrue);
  final rect = tester.getRect(target);
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(tester.view.physicalSize.height));
}

void main() {
  testWidgets(
    'source projection preserves exact identities and encounter order without work',
    (tester) async {
      final h = support.Harness(support.DelayedChannel());
      h.channel.change(
        h.channel.state.copyWith(sessions: rows, activeSessionId: 'a1'),
      );
      await h.pump(tester);
      expect(labels(tester), [
        'Source: cli',
        'Open Same title',
        'Open Second',
        'Source: custom',
        'Open Same title',
        'Source: Unknown source',
        'Open Blank',
        'Open Spaces',
        'Source: [redacted-path]',
        'Open Redacted one',
        'Source: [redacted-path]',
        'Open Redacted two',
        'Source:  cli ',
        'Open Exact source',
      ]);
      for (final row in rows) {
        expect(open(row.id), findsOneWidget);
      }
      expect(h.channel.state.sessions, rows);
      noActions(h);
      final updated = [
        rows[1],
        rows[2],
        const HermesSession(id: 'a1', source: 'cli', title: 'Updated'),
        const HermesSession(id: 'append', source: 'custom', title: 'Append'),
      ];
      h.channel.change(h.channel.state.copyWith(sessions: updated));
      await tester.pumpAndSettle();
      expect(labels(tester), [
        'Source: custom',
        'Open Same title',
        'Open Append',
        'Source: cli',
        'Open Second',
        'Open Updated',
      ]);
      expect(open('blank'), findsNothing);
      expect(h.channel.state.activeSessionId, 'a1');
      noActions(h);
    },
  );

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    for (final id in ['a1', 'b1']) {
      testWidgets(
        '${key.keyLabel} opens exact grouped $id once at short height and 2x text',
        (tester) async {
          final h = support.Harness(support.DelayedChannel());
          h.channel.change(
            h.channel.state.copyWith(sessions: rows, activeSessionId: 'a1'),
          );
          await h.pump(tester, height: 600, scale: 2);
          final semantics = tester.ensureSemantics();
          await reach(tester, open('b1'));
          await reach(tester, open('a1'), reverse: true);
          await reach(tester, open(id));
          noActions(h);
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          expect(h.path, '/hermes');
          expect(h.channel.selectSessionCalls, [id]);
          expect(h.channel.state.activeSessionId, id);
          expect(h.channel.createSessionCalls, isEmpty);
          h.noIncidentalWork();
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }

  for (final mode in [
    'collapse',
    'compact',
    'owner',
    'disconnect',
    'capability',
    'removed',
  ]) {
    testWidgets(
      'grouped captured callback stays obsolete after $mode and return',
      (tester) async {
        final h = support.Harness(support.DelayedChannel());
        h.channel.change(
          h.channel.state.copyWith(sessions: rows, activeSessionId: 'a1'),
        );
        await h.pump(tester);
        final callback = tester.widget<TextButton>(open('b1')).onPressed!;
        final before = h.channel.state;
        switch (mode) {
          case 'collapse':
            await tester.tap(
              find.byKey(const ValueKey('desktop-sidebar-toggle')),
            );
            await tester.pumpAndSettle();
            expect(open('b1'), findsNothing);
            await tester.tap(
              find.byKey(const ValueKey('desktop-sidebar-toggle')),
            );
          case 'compact':
            tester.view.physicalSize = const Size(390, 900);
            await tester.pumpAndSettle();
            expect(open('b1'), findsNothing);
            tester.view.physicalSize = const Size(1280, 1100);
          case 'owner':
            h.channel.change(before.copyWith(selectedProfileId: 'replacement'));
            h.channel.change(before);
          case 'disconnect':
            h.channel.change(
              before.copyWith(status: HermesConnectionStatus.disconnected),
            );
            h.channel.change(before);
          case 'capability':
            h.channel.change(
              before.copyWith(
                capabilities: HermesCapabilityDocument.fromJson({
                  'schema_version': 99,
                }),
              ),
            );
            h.channel.change(before);
          case 'removed':
            h.channel.change(before.copyWith(sessions: [rows.first]));
            h.channel.change(before);
        }
        await tester.pumpAndSettle();
        callback();
        await tester.pumpAndSettle();
        expect(open('b1'), findsOneWidget);
        expect(h.path, '/tools');
        noActions(h);
      },
    );
  }

  for (final mode in ['duplicate', 'failure', 'compact', 'capability']) {
    testWidgets('grouped pending open handles $mode without stale effects', (
      tester,
    ) async {
      final h = support.Harness(
        support.DelayedChannel()..gate = Completer<void>(),
      );
      h.channel.change(
        h.channel.state.copyWith(sessions: rows, activeSessionId: 'a1'),
      );
      await h.pump(tester);
      final before = h.channel.state;
      final callback = tester.widget<TextButton>(open('b1')).onPressed!;
      callback();
      callback();
      await tester.pumpAndSettle();
      expect(h.channel.selectSessionCalls, ['b1']);
      expect(h.path, '/tools');
      expect(tester.widget<TextButton>(open('b1')).onPressed, isNull);
      expect(find.text('Opening session…'), findsOneWidget);
      switch (mode) {
        case 'compact':
          tester.view.physicalSize = const Size(390, 900);
          await tester.pumpAndSettle();
          expect(open('b1'), findsNothing);
          tester.view.physicalSize = const Size(1280, 1100);
          await tester.pumpAndSettle();
        case 'capability':
          h.channel.change(
            before.copyWith(
              capabilities: HermesCapabilityDocument.fromJson({
                'schema_version': 99,
              }),
            ),
          );
          h.channel.change(before);
      }
      if (mode == 'failure') {
        h.channel.gate!.completeError(StateError('synthetic failure'));
      } else {
        h.channel.gate!.complete();
      }
      await tester.pumpAndSettle();
      if (mode == 'duplicate') {
        expect(h.path, '/hermes');
        expect(h.channel.state.activeSessionId, 'b1');
      } else {
        expect(h.path, '/tools');
        expect(h.channel.state.activeSessionId, 'a1');
        expect(
          find.text('Could not open the session. Try again in Chat.'),
          mode == 'failure' ? findsOneWidget : findsNothing,
        );
        if (mode == 'failure') {
          h.channel.gate = null;
          final semantics = tester.ensureSemantics();
          await reach(tester, open('b1'), reverse: true);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(h.path, '/hermes');
          expect(h.channel.selectSessionCalls, ['b1', 'b1']);
          semantics.dispose();
        } else {
          expect(h.channel.selectSessionCalls, ['b1']);
        }
      }
      h.noIncidentalWork();
      expect(h.channel.createSessionCalls, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
