import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';

import 'app_shell_global_session_access_test.dart' as support;

Future<void> pump(WidgetTester tester, support.Harness h) async {
  await h.pump(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp.router(
        routerConfig: h.router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> reach(WidgetTester tester, Finder target) async {
  bool focused() {
    final element = target.evaluate().single;
    final context = FocusManager.instance.primaryFocus?.context;
    var inside = identical(context, element);
    context?.visitAncestorElements((ancestor) {
      if (identical(ancestor, element)) inside = true;
      return !inside;
    });
    return inside;
  }

  for (var i = 0; i < 60 && !focused(); i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
  expect(focused(), isTrue);
}

final opener = find.byKey(const ValueKey('global-sessions-open'));
final panel = find.byKey(const ValueKey('hermes-sessions-panel'));
final search = find.byKey(const ValueKey('hermes-session-search-field'));
final row = find.byKey(const ValueKey('hermes-session-row-synthetic-other'));

Future<void> open(WidgetTester tester) async {
  await reach(tester, opener);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
  expect(panel, findsOneWidget);
  expect(tester.widget<TextField>(search).autofocus, isTrue);

  expect(FocusManager.instance.primaryFocus?.context, isNotNull);
}

Future<void> shortcut(WidgetTester tester, {bool meta = false}) async {
  final modifier = meta
      ? LogicalKeyboardKey.metaLeft
      : LogicalKeyboardKey.controlLeft;
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(modifier);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'one global panel, search autofocus, inverse containment, Escape focus return and no reads',
    (tester) async {
      final h = support.Harness(support.DelayedChannel());
      await pump(tester, h);
      final semantics = tester.ensureSemantics();
      await open(tester);
      expect(find.byType(HermesChatScreen), findsNothing);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(of: search, matching: find.byType(EditableText)),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
      await shortcut(tester);
      expect(panel, findsOneWidget);
      for (var i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus!.context!
              .findAncestorWidgetOfExactType<Dialog>(),
          isNotNull,
        );
      }
      for (var i = 0; i < 20; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus!.context!
              .findAncestorWidgetOfExactType<Dialog>(),
          isNotNull,
        );
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      await reach(tester, opener);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      await shortcut(tester, meta: true);
      expect(panel, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('global-sessions-close')));
      await tester.pumpAndSettle();
      h.noIncidentalWork();
      expect(h.channel.selectSessionCalls, isEmpty);
      expect(h.channel.createSessionCalls, isEmpty);
      expect(h.path, '/tools');
      semantics.dispose();
    },
  );

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets('${key.keyLabel} opens acknowledged exact session once', (
      tester,
    ) async {
      final h = support.Harness(
        support.DelayedChannel()..gate = Completer<void>(),
      );
      await pump(tester, h);
      final semantics = tester.ensureSemantics();
      await open(tester);
      await tester.enterText(search, 'Synthetic other');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-session-row-synthetic-active')),
        findsNothing,
      );
      await reach(tester, row);
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(h.path, '/tools');
      expect(h.channel.selectSessionCalls, ['synthetic-other']);
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(h.channel.selectSessionCalls, ['synthetic-other']);
      h.channel.gate!.complete();
      await tester.pumpAndSettle();
      expect(h.path, '/hermes');
      expect(panel, findsNothing);
      expect(h.channel.state.activeSessionId, 'synthetic-other');
      h.noIncidentalWork();
      semantics.dispose();
    });
  }

  for (final loss in [
    'profile',
    'endpoint',
    'disconnect',
    'capability',
    'removed',
    'contact',
    'directory',
    'cancel',
    'route',
  ]) {
    testWidgets(
      'pending settlement latches $loss away and back; explicit retry uses current owner',
      (tester) async {
        final h = support.Harness(
          support.DelayedChannel()..gate = Completer<void>(),
        );
        await pump(tester, h);
        final semantics = tester.ensureSemantics();
        await open(tester);
        await reach(tester, row);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        final before = h.channel.state;
        switch (loss) {
          case 'profile':
            h.channel.change(before.copyWith(selectedProfileId: 'replacement'));
            h.channel.change(before);
          case 'endpoint':
            h.channel.change(
              before.copyWith(connectedBaseUrl: 'http://127.0.0.1:9999'),
            );
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
            h.channel.change(
              before.copyWith(sessions: [support.sessions.first]),
            );
            h.channel.change(before);
          case 'contact':
            h.directory.contact = const GatewayContactId(
              gatewayId: 'replacement',
              profileId: 'default',
            );
            h.directory.changed();
            h.directory.contact = null;
            h.directory.changed();
          case 'directory':
            h.lifetime.detach(h.directory);
            h.lifetime.attach(h.directory);
          case 'cancel':
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
          case 'route':
            h.router.go('/settings');
            h.router.go('/tools');
            await tester.pumpAndSettle();
        }
        h.channel.gate!.complete();
        await tester.pumpAndSettle();
        expect(h.path, '/tools');
        expect(h.channel.state.activeSessionId, 'synthetic-active');
        expect(h.channel.selectSessionCalls, ['synthetic-other']);
        h.channel.gate = null;
        if (panel.evaluate().isEmpty) await shortcut(tester);
        await reach(tester, row);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(h.path, '/hermes');
        expect(h.channel.selectSessionCalls, [
          'synthetic-other',
          'synthetic-other',
        ]);
        h.noIncidentalWork();
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'failed open stays over feature and Retry is one explicit current-owner read',
    (tester) async {
      final h = support.Harness(
        support.DelayedChannel()..gate = Completer<void>(),
      );
      await pump(tester, h);
      final semantics = tester.ensureSemantics();
      await open(tester);
      await reach(tester, row);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      h.channel.gate!.completeError(StateError('synthetic failure'));
      await tester.pumpAndSettle();
      expect(h.path, '/tools');
      expect(panel, findsOneWidget);
      h.channel.gate = null;
      await reach(tester, find.byKey(const ValueKey('global-sessions-retry')));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(h.path, '/hermes');
      expect(h.channel.selectSessionCalls, [
        'synthetic-other',
        'synthetic-other',
      ]);
      semantics.dispose();
    },
  );
}
