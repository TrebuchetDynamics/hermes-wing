import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'app_shell_global_session_access_test.dart' as support;
import 'app_shell_global_session_modal_test.dart' as modal;

bool focused(Finder target) {
  if (target.evaluate().isEmpty) return false;
  final element = target.evaluate().single;
  var inside = identical(FocusManager.instance.primaryFocus?.context, element);
  FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
    ancestor,
  ) {
    if (identical(ancestor, element)) inside = true;
    return !inside;
  });
  return inside;
}

Future<void> reach(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 60 && !focused(target); i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
  expect(focused(target), isTrue);
}

Future<void> resize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> pump(WidgetTester tester, support.Harness h, Size size) async {
  await modal.pump(tester, h);
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp.router(
        routerConfig: h.router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2), disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final draft = find.byKey(const ValueKey('route-draft'));

Future<void> open(WidgetTester tester) async {
  await modal.reach(tester, draft);
  await modal.shortcut(tester);
  expect(modal.panel, findsOneWidget);
}

void inViewport(WidgetTester tester, Finder target) {
  final rect = tester.getRect(target);
  final size = tester.view.physicalSize;
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(size.width));
  expect(rect.bottom, lessThanOrEqualTo(size.height));
}

void main() {
  for (final initial in [
    const Size(390, 480),
    const Size(390, 700),
    const Size(1280, 900),
  ]) {
    testWidgets('200% text keyboard controls survive resize from $initial', (
      tester,
    ) async {
      final h = support.Harness(support.DelayedChannel());
      await pump(tester, h, initial);
      await open(tester);
      expect(tester.takeException(), isNull);
      final originalFocus = FocusManager.instance.primaryFocus;
      for (final size in [
        const Size(1280, 900),
        const Size(390, 700),
        const Size(390, 480),
      ]) {
        await resize(tester, size);
        expect(FocusManager.instance.primaryFocus, same(originalFocus));
        await reach(tester, modal.search);
        inViewport(tester, modal.search);
        await reach(tester, find.byKey(const ValueKey('hermes-sessions-new')));
        inViewport(tester, find.byKey(const ValueKey('hermes-sessions-new')));
        await reach(tester, modal.row);
        inViewport(tester, modal.row);
        for (var i = 0; i < 12; i++) {
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
        await reach(tester, modal.search);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(focused(draft), isTrue);
      h.noIncidentalWork();
      expect(h.channel.selectSessionCalls, isEmpty);
      expect(h.channel.createSessionCalls, isEmpty);
      await open(tester);
      await modal.reach(
        tester,
        find.byKey(const ValueKey('global-sessions-close')),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(modal.panel, findsNothing);
      expect(focused(draft), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  for (final create in [false, true]) {
    testWidgets(
      'compact scaled delayed ${create ? 'New' : 'row'} rejects owner away/back after resize',
      (tester) async {
        final h = support.Harness(
          support.DelayedChannel()..gate = Completer<void>(),
        );
        await pump(tester, h, const Size(390, 700));
        await open(tester);
        if (!create) {
          await tester.enterText(modal.search, 'Synthetic other');
          await tester.pumpAndSettle();
        }
        final action = create
            ? find.byKey(const ValueKey('hermes-sessions-new'))
            : modal.row;
        await reach(tester, action);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        final before = h.channel.state;
        h.channel.change(
          before.copyWith(selectedProfileId: 'synthetic-replacement'),
        );
        h.channel.change(before);
        await resize(tester, const Size(1280, 900));
        h.channel.gate!.complete();
        await tester.pumpAndSettle();
        expect(h.path, '/tools');
        expect(h.channel.state.activeSessionId, 'synthetic-active');
        expect(h.channel.createSessionCalls.length, create ? 1 : 0);
        expect(
          h.channel.selectSessionCalls,
          create ? isEmpty : ['synthetic-other'],
        );
        h.channel.gate = null;
        await modal.reach(tester, action);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(h.path, '/hermes');
        expect(
          h.channel.state.activeSessionId,
          create ? 'synthetic-new' : 'synthetic-other',
        );
        expect(h.channel.createSessionCalls.length, create ? 2 : 0);
        expect(
          h.channel.selectSessionCalls,
          create ? isEmpty : ['synthetic-other', 'synthetic-other'],
        );
        h.noIncidentalWork();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
