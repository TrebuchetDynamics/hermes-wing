import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_rich_text.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/settings/providers/chat_preferences_provider.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

Future<ProviderContainer> mount(
  WidgetTester tester,
  FakeHermesChannel channel, {
  bool? collapsed,
  bool preload = true,
}) async {
  SharedPreferences.setMockInitialValues({
    'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    'wing.chat.reasoning_collapsed_by_default': ?collapsed,
  });
  tester.view.physicalSize = const Size(1280, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [hermesChannelProvider.overrideWithValue(channel)],
  );
  addTearDown(container.dispose);
  if (preload) {
    container.read(wingChatPreferencesProvider);
    await tester.pumpAndSettle();
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HermesChatScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  return container;
}

void main() {
  testWidgets(
    'saved collapsed choice never creates a preview latch before hydration',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      channel.beginStreamingTurn('Synthetic request');
      channel.addReasoningTurn('Synthetic private reasoning');
      final container = await mount(
        tester,
        channel,
        collapsed: true,
        preload: false,
      );
      expect(find.text('Synthetic private reasoning'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Synthetic private reasoning'), findsNothing);
      channel.completeStreamingTurn(text: 'Synthetic reply');
      await tester.pumpAndSettle();
      container
          .read(wingChatPreferencesProvider.notifier)
          .setReasoningCollapsedByDefault(false);
      await tester.pumpAndSettle();
      expect(find.text('Synthetic private reasoning'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'live thinking preview settles without remounting and explicit user collapse wins',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      channel.beginStreamingTurn('Synthetic request');
      channel.addReasoningTurn('Synthetic live reasoning');
      final container = await mount(tester, channel);
      expect(find.text('Synthetic live reasoning'), findsOneWidget);
      final body = tester.element(find.byType(HermesRichText).last);
      channel.completeStreamingTurn(text: 'Synthetic reply');
      await tester.pumpAndSettle();
      expect(find.text('Synthetic live reasoning'), findsOneWidget);
      expect(body.mounted, isTrue);
      final preference = container.read(wingChatPreferencesProvider.notifier);
      final state = channel.state;
      preference.setReasoningCollapsedByDefault(true);
      await tester.pumpAndSettle();
      expect(find.text('Synthetic live reasoning'), findsNothing);
      preference.setReasoningCollapsedByDefault(false);
      await tester.pumpAndSettle();
      expect(find.text('Synthetic live reasoning'), findsOneWidget);
      await tester.tap(find.text('Thought'));
      await tester.pumpAndSettle();
      preference.setReasoningCollapsedByDefault(true);
      await tester.pumpAndSettle();
      preference.setReasoningCollapsedByDefault(false);
      await tester.pumpAndSettle();
      expect(find.text('Synthetic live reasoning'), findsNothing);
      expect(identical(channel.state, state), isTrue);
      expect(channel.stopActiveTurnCalls, 0);
    },
  );

  testWidgets(
    'explicitly opened thinking outranks collapse preference through completion',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      channel.beginStreamingTurn('Synthetic request');
      channel.addReasoningTurn('Synthetic opt-in reasoning');
      final container = await mount(tester, channel, collapsed: true);
      expect(find.text('Synthetic opt-in reasoning'), findsNothing);
      await tester.drag(
        find.byKey(const ValueKey('hermes-transcript')),
        const Offset(0, 600),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.ensureVisible(find.text('Thinking…'));
      await tester.pump();
      await tester.tap(find.text('Thinking…'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Synthetic opt-in reasoning'), findsOneWidget);
      final preference = container.read(wingChatPreferencesProvider.notifier);
      preference.setReasoningCollapsedByDefault(false);
      await tester.pump(const Duration(seconds: 1));
      preference.setReasoningCollapsedByDefault(true);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Synthetic opt-in reasoning'), findsOneWidget);
      channel.completeStreamingTurn(text: 'Synthetic reply');
      await tester.pumpAndSettle();
      expect(find.text('Synthetic opt-in reasoning'), findsOneWidget);
      expect(channel.stopActiveTurnCalls, 0);
    },
  );

  testWidgets(
    'never-previewed completed thinking and replacement owners start collapsed',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      channel.beginStreamingTurn('Synthetic request');
      channel.addReasoningTurn('Synthetic hidden reasoning');
      final id = channel.state.activeMessages
          .firstWhere((turn) => turn.kind == HermesTurnKind.reasoning)
          .id;
      final container = await mount(tester, channel, collapsed: true);
      channel.completeStreamingTurn(text: 'Synthetic reply');
      await tester.pumpAndSettle();
      container
          .read(wingChatPreferencesProvider.notifier)
          .setReasoningCollapsedByDefault(false);
      await tester.pumpAndSettle();
      expect(find.text('Synthetic hidden reasoning'), findsNothing);
      await tester.tap(find.text('Thought'));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic hidden reasoning'), findsOneWidget);
      channel.replaceSessions(
        const [HermesSession(id: 'replacement', source: 'fake')],
        activeSessionId: 'replacement',
        messages: {
          'replacement': [
            HermesChatTurn(
              id: id,
              sessionId: 'replacement',
              author: HermesTurnAuthor.system,
              createdAt: DateTime.utc(2026),
              kind: HermesTurnKind.reasoning,
              text: 'Synthetic replacement reasoning',
            ),
          ],
        },
      );
      await tester.pumpAndSettle();
      expect(find.text('Synthetic hidden reasoning'), findsNothing);
      expect(find.text('Synthetic replacement reasoning'), findsNothing);
      await tester.tap(find.text('Thought'));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic replacement reasoning'), findsOneWidget);
      expect(channel.selectSessionCalls, isEmpty);
      expect(channel.stopActiveTurnCalls, 0);
    },
  );

  testWidgets(
    'automatic long thinking stays bounded and respects a scrolled preview',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      final text = List.generate(
        60,
        (index) => 'Synthetic reasoning line $index',
      ).join('\n\n');
      channel.beginStreamingTurn('Synthetic request');
      channel.addReasoningTurn(text);
      await mount(tester, channel);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      final preview = find.byKey(const ValueKey('hermes-reasoning-preview'));
      expect(tester.getSize(preview).height, lessThanOrEqualTo(160));
      final scroller = find
          .descendant(of: preview, matching: find.byType(SingleChildScrollView))
          .first;
      final controller = tester
          .widget<SingleChildScrollView>(scroller)
          .controller!;
      expect(controller.offset, controller.position.maxScrollExtent);
      controller.jumpTo(0);
      await tester.pump();
      channel.replaceTranscript(
        channel.state.activeMessages
            .map(
              (turn) => turn.kind == HermesTurnKind.reasoning
                  ? turn.copyWith(text: '$text\n\nSynthetic added reasoning')
                  : turn,
            )
            .toList(),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.offset, 0);
      await tester.ensureVisible(find.text('Thinking…'));
      await tester.pump();
      await tester.tap(find.text('Thinking…'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.text('Thinking…'));
      await tester.pump();
      await tester.tap(find.text('Thinking…'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getSize(preview).height, greaterThan(160));
      channel.completeStreamingTurn(text: 'Synthetic reply');
      await tester.pumpAndSettle();
      expect(channel.stopActiveTurnCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
