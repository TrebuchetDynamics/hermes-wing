import 'dart:async';
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

HermesChatTurn reasoning(String body, {String session = 'sess_1'}) =>
    HermesChatTurn(
      id: 'synthetic-recovery-reasoning',
      sessionId: session,
      author: HermesTurnAuthor.system,
      createdAt: DateTime.utc(2026),
      kind: HermesTurnKind.reasoning,
      text: '$body at /tmp/synthetic-recovery.txt',
    );

Future<void> mount(WidgetTester tester, FakeHermesChannel channel) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(platform: TargetPlatform.linux),
        home: const HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<FocusNode> openWithKeyboard(WidgetTester tester) async {
  bool focused() =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<ExpansionTile>() !=
      null;
  for (var i = 0; i < 40 && !focused(); i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  expect(focused(), isTrue);
  final node = FocusManager.instance.primaryFocus!;
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
  expect(
    tester.getSemantics(find.text('Thought')).flagsCollection.isExpanded,
    Tristate.isTrue,
  );
  return node;
}

void noMutations(FakeHermesChannel channel) {
  expect(channel.sentImageDataUrls, isEmpty);
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.lockSessionModelCalls, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
  expect(channel.connectCalls, isEmpty);
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );

  testWidgets(
    'mounted exact-ID update retains disclosure focus and redacted selectable body',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      channel.replaceTranscript([reasoning('Synthetic before')]);
      await mount(tester, channel);
      final focus = await openWithKeyboard(tester);
      channel.replaceTranscript([reasoning('Synthetic canonical update')]);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(find.textContaining('Synthetic before'), findsNothing);
      expect(
        find.textContaining('Synthetic canonical update at [redacted-path]'),
        findsOneWidget,
      );
      expect(find.textContaining('/tmp/'), findsNothing);
      expect(
        tester.widget<HermesRichText>(find.byType(HermesRichText)).selectable,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.textContaining('Synthetic canonical update'), findsNothing);
      noMutations(channel);
      semantics.dispose();
    },
  );

  testWidgets(
    'bounded window eviction disposes disclosure and deliberate reveal remounts collapsed',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      final first = reasoning('Synthetic evicted');
      channel.replaceTranscript([first]);
      await mount(tester, channel);
      final oldFocus = await openWithKeyboard(tester);
      final oldTile = tester.element(find.byType(ExpansionTile));
      channel.replaceTranscript([
        first,
        for (var i = 0; i < 100; i++)
          HermesChatTurn(
            id: 'synthetic-filler-$i',
            sessionId: 'sess_1',
            author: HermesTurnAuthor.assistant,
            createdAt: DateTime.utc(2026),
            text: 'Synthetic filler $i',
          ),
      ]);
      await tester.pumpAndSettle();
      expect(oldTile.mounted, isFalse);
      expect(FocusManager.instance.primaryFocus, isNot(same(oldFocus)));
      expect(find.text('Thought'), findsNothing);
      expect(find.textContaining('Synthetic evicted'), findsNothing);
      final reveal = find.textContaining('Show up to 100 earlier loaded turns');
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      final thought = find.text('Thought', skipOffstage: false);
      await tester.scrollUntilVisible(
        thought,
        500,
        scrollable: find.descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Synthetic evicted'), findsNothing);
      expect(
        tester.getSemantics(find.text('Thought')).flagsCollection.isExpanded,
        Tristate.isFalse,
      );
      await openWithKeyboard(tester);
      expect(
        find.textContaining('Synthetic evicted at [redacted-path]'),
        findsOneWidget,
      );
      noMutations(channel);
      expect(channel.selectSessionCalls, isEmpty);
      semantics.dispose();
    },
  );

  testWidgets(
    'read-only resume refresh retains mounted summary and rejects obsolete owner restoration',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      channel.replaceTranscript([reasoning('Synthetic original')]);
      await mount(tester, channel);
      final focus = await openWithKeyboard(tester);
      channel.onReconcileActiveSession = () async {
        channel.replaceTranscript([reasoning('Synthetic canonical')]);
      };
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(channel.reconcileActiveSessionCalls, 1);
      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(
        find.textContaining('Synthetic canonical at [redacted-path]'),
        findsOneWidget,
      );
      final pending = Completer<void>();
      channel.onReconcileActiveSession = () => pending.future;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(channel.reconcileActiveSessionCalls, 2);
      channel.replaceSessions(
        const [HermesSession(id: 'synthetic-B', source: 'fake')],
        activeSessionId: 'synthetic-B',
        messages: {
          'synthetic-B': [
            reasoning('Synthetic replacement', session: 'synthetic-B'),
          ],
        },
      );
      await tester.pumpAndSettle();
      pending.complete();
      await tester.pumpAndSettle();
      expect(channel.state.activeSessionId, 'synthetic-B');
      expect(find.textContaining('Synthetic canonical'), findsNothing);
      expect(find.textContaining('Synthetic replacement'), findsNothing);
      expect(FocusManager.instance.primaryFocus, isNot(same(focus)));
      expect(
        tester.getSemantics(find.text('Thought')).flagsCollection.isExpanded,
        Tristate.isFalse,
      );
      await openWithKeyboard(tester);
      expect(
        find.textContaining('Synthetic replacement at [redacted-path]'),
        findsOneWidget,
      );
      noMutations(channel);
      expect(channel.selectSessionCalls, isEmpty);
      semantics.dispose();
    },
  );
}
