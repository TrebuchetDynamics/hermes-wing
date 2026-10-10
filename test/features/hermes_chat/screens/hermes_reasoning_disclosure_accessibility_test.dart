import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_rich_text.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

// The wide active-session rail has an independent repeating activity indicator.
// Bound pumping while the run is active rather than waiting for all tickers.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> resize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  await settle(tester);
  expect(tester.takeException(), isNull);
}

bool summaryFocused() =>
    FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ExpansionTile>() !=
        null &&
    FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ListTile>() !=
        null;

Future<FocusNode> reachSummary(
  WidgetTester tester, {
  bool backwards = false,
}) async {
  if (backwards) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  for (var i = 0; i < 40 && !summaryFocused(); i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  if (backwards) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  expect(summaryFocused(), isTrue);
  return FocusManager.instance.primaryFocus!;
}

void expectSummary(
  WidgetTester tester,
  String label, {
  required bool expanded,
}) {
  final title = find.text(label);
  expect(title, findsOneWidget);
  final flags = tester.getSemantics(title).flagsCollection;
  expect(flags.isExpanded, expanded ? Tristate.isTrue : Tristate.isFalse);
  expect(flags.isLiveRegion, isTrue);
  expect(MediaQuery.textScalerOf(tester.element(title)).scale(16), 32);
  final rect = tester.getRect(title);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(tester.view.physicalSize.width));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(900));
}

void expectBodyBounds(WidgetTester tester) {
  final body = find.descendant(
    of: find.byType(ExpansionTile),
    matching: find.byType(HermesRichText),
  );
  expect(body, findsOneWidget);
  final rect = tester.getRect(body);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(tester.view.physicalSize.width));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(900));
  expect(tester.takeException(), isNull);
}

void expectReadOnly(FakeHermesChannel channel) {
  expect(channel.sentImageDataUrls, isEmpty);
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.selectSessionCalls, isEmpty);
  expect(channel.lockSessionModelCalls, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
  expect(channel.stopActiveTurnCalls, 0);
  expect(channel.connectCalls, isEmpty);
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );

  for (final initialWidth in [390.0, 1280.0]) {
    testWidgets(
      'reasoning keyboard roundtrip from $initialWidth keeps expansion truthful and remounted focus reachable at 200-percent text under reduced motion',
      (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(initialWidth, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = FakeHermesChannel();
        addTearDown(channel.dispose);
        channel.beginStreamingTurn('Synthetic accessibility request');
        channel.addReasoningTurn(
          'Synthetic accessibility reasoning at /tmp/synthetic.txt',
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [hermesChannelProvider.overrideWithValue(channel)],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(platform: TargetPlatform.linux),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(2),
                ),
                child: child!,
              ),
              home: const HermesChatScreen(),
            ),
          ),
        );
        await settle(tester);
        expectSummary(tester, 'Thinking…', expanded: false);
        expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
        final original = await reachSummary(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await settle(tester);
        expectSummary(tester, 'Thinking…', expanded: true);
        expectBodyBounds(tester);
        expect(
          find.text('Synthetic accessibility reasoning at [redacted-path]'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<HermesRichText>(
                find.descendant(
                  of: find.byType(ExpansionTile),
                  matching: find.byType(HermesRichText),
                ),
              )
              .selectable,
          isTrue,
        );

        // A resize inside the same layout retains the mounted row and exact focus.
        await resize(tester, initialWidth == 390 ? 430 : 1320);
        expect(FocusManager.instance.primaryFocus, same(original));
        expectSummary(tester, 'Thinking…', expanded: true);
        expectBodyBounds(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await settle(tester);
        expectSummary(tester, 'Thinking…', expanded: false);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await settle(tester);

        for (final width in [
          initialWidth == 390 ? 1280.0 : 390.0,
          initialWidth,
        ]) {
          final oldElement = tester.element(find.byType(ExpansionTile));
          final oldFocus = FocusManager.instance.primaryFocus;
          await resize(tester, width);
          // The exact-owner row survives, but the accessibility avatar wrapper
          // remounts its tile. Expansion must still agree with the visible body.
          expect(oldElement.mounted, isFalse);
          expect(FocusManager.instance.primaryFocus, isNot(same(oldFocus)));
          expect(
            find.text('Synthetic accessibility reasoning at [redacted-path]'),
            findsOneWidget,
          );
          expectSummary(tester, 'Thinking…', expanded: true);
          expectBodyBounds(tester);
          await reachSummary(tester, backwards: true);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await settle(tester);
          expectSummary(tester, 'Thinking…', expanded: false);
          expect(
            find.textContaining('Synthetic accessibility reasoning'),
            findsNothing,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await settle(tester);
          expectSummary(tester, 'Thinking…', expanded: true);
          expectBodyBounds(tester);
          expect(
            find.text('Synthetic accessibility reasoning at [redacted-path]'),
            findsOneWidget,
          );
        }

        final completedFocus = FocusManager.instance.primaryFocus;
        channel.completeStreamingTurn(text: 'Synthetic accessibility answer');
        await tester.pumpAndSettle();
        expectSummary(tester, 'Thought', expanded: true);
        expect(find.text('Thinking…'), findsNothing);
        expect(FocusManager.instance.primaryFocus, same(completedFocus));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expectSummary(tester, 'Thought', expanded: false);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(summaryFocused(), isFalse);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(completedFocus));
        expectReadOnly(channel);

        // Reused IDs do not restore the old owner's body after the accessibility return.
        final reused = channel.state.activeMessages.firstWhere(
          (t) => t.kind == HermesTurnKind.reasoning,
        );
        channel.replaceSessions(
          const [
            HermesSession(id: 'synthetic-accessibility-other', source: 'fake'),
          ],
          activeSessionId: 'synthetic-accessibility-other',
          messages: {
            'synthetic-accessibility-other': [
              HermesChatTurn(
                id: reused.id,
                sessionId: 'synthetic-accessibility-other',
                author: HermesTurnAuthor.system,
                createdAt: DateTime.utc(2026),
                kind: HermesTurnKind.reasoning,
                text: 'Synthetic other reasoning',
              ),
            ],
          },
        );
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, isNot(same(completedFocus)));
        expectSummary(tester, 'Thought', expanded: false);
        await reachSummary(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Synthetic other reasoning'), findsOneWidget);
        expect(
          find.textContaining('Synthetic accessibility reasoning'),
          findsNothing,
        );
        expect(find.textContaining('/tmp/'), findsNothing);
        expectReadOnly(channel);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
