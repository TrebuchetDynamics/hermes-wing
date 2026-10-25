import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/providers/chat_preferences_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [390.0, 960.0, 1440.0]) {
    testWidgets('transcript and composer share panel geometry at $width', (
      tester,
    ) async {
      final channel = FakeHermesChannel();
      channel.beginStreamingTurn('Synthetic question');
      channel.completeStreamingTurn(
        text: 'Synthetic answer with readable prose.',
      );
      await _mount(tester, channel, width);
      final id = channel.state.activeMessages.last.id;
      final transcript = tester.getRect(
        find.byKey(const ValueKey('hermes-transcript')),
      );
      final reply = tester.getRect(find.byKey(ValueKey('hermes-turn-$id')));
      final replyBox =
          tester
                  .widget<Container>(find.byKey(ValueKey('hermes-turn-$id')))
                  .decoration!
              as BoxDecoration;
      expect(replyBox.color, Colors.transparent);
      expect(replyBox.borderRadius, BorderRadius.zero);
      final user = channel.state.activeMessages.firstWhere(
        (turn) => turn.author.name == 'user',
      );
      final userRect = tester.getRect(
        find.byKey(ValueKey('hermes-turn-${user.id}')),
      );
      expect(userRect.left, reply.left);
      expect(userRect.width, reply.width);
      final userBox =
          tester
                  .widget<Container>(
                    find.byKey(ValueKey('hermes-turn-${user.id}')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(userBox.borderRadius, BorderRadius.circular(3.2));
      final desktop = width >= 720;
      expect(reply.left - transcript.left, desktop ? 24 : 12);
      expect(transcript.right - reply.right, desktop ? 24 : 12);
      if (desktop) {
        final composer = tester.getRect(
          find.byKey(const ValueKey('hermes-desktop-command-bar')),
        );
        expect(composer.left - transcript.left, 16);
        expect(transcript.right - composer.right, 16);
        expect(reply.width, composer.width - 16);
      }
      final prose = find.text('Synthetic answer with readable prose.');
      final metadata = find.byKey(ValueKey('hermes-turn-metadata-$id'));
      expect(
        tester.getRect(metadata).top,
        greaterThanOrEqualTo(tester.getRect(prose).bottom),
      );
      expect(
        find.byKey(const ValueKey('hermes-assistant-avatar')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets(
    'local bubble transparency changes only user fill without changing draft ownership',
    (tester) async {
      for (final brightness in Brightness.values) {
        SharedPreferences.setMockInitialValues({
          'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
        });
        final channel = FakeHermesChannel();
        final turns = [
          for (final (id, author, text) in [
            ('bubble-user', HermesTurnAuthor.user, 'Synthetic question'),
            (
              'bubble-assistant',
              HermesTurnAuthor.assistant,
              'Synthetic answer',
            ),
            (
              'bubble-error',
              HermesTurnAuthor.assistant,
              '{"status":"error","error":"Synthetic failure","tool_calls_made":0}',
            ),
          ])
            HermesChatTurn(
              id: id,
              sessionId: 'sess_1',
              author: author,
              text: text,
              createdAt: DateTime.utc(2026),
            ),
        ];
        channel.replaceTranscript(turns);
        // A partly transparent theme fill detects alpha replacement, not just fading from 1.
        final theme = ThemeData(brightness: brightness);
        final baseFill = theme.colorScheme.surfaceContainerLowest.withValues(
          alpha: 0.64,
        );
        await _mount(
          tester,
          channel,
          1280,
          theme: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              surfaceContainerLowest: baseFill,
            ),
          ),
        );
        final field = find.byKey(const ValueKey('hermes-composer-field'));
        final container = ProviderScope.containerOf(tester.element(field));
        final owner = tester.state(find.byType(HermesChatScreen));
        final original = tester.widget<TextField>(field);
        final controller = original.controller!;
        final focus = original.focusNode!;
        focus.requestFocus();
        const draft = TextEditingValue(
          text: 'Unsent synthetic draft',
          selection: TextSelection(baseOffset: 1, extentOffset: 6),
          composing: TextRange(start: 0, end: 6),
        );
        controller.value = draft;
        await tester.pumpAndSettle();
        Finder bubble(String id) => find.byKey(ValueKey('hermes-turn-$id'));
        BoxDecoration decoration(String id) =>
            tester.widget<Container>(bubble(id)).decoration! as BoxDecoration;
        List<InlineSpan> text(String id) => tester
            .renderObjectList<RenderParagraph>(
              find.descendant(of: bubble(id), matching: find.byType(RichText)),
            )
            .map((p) => p.text)
            .toList();
        List<(IconData?, Color?, double?)> icons(String id) => tester
            .widgetList<Icon>(
              find.descendant(of: bubble(id), matching: find.byType(Icon)),
            )
            .map((icon) => (icon.icon, icon.color, icon.size))
            .toList();
        final surfaces = {
          for (final turn in turns) turn.id: decoration(turn.id),
        };
        final rectangles = {
          for (final turn in turns) turn.id: tester.getRect(bubble(turn.id)),
        };
        final prose = {for (final turn in turns) turn.id: text(turn.id)};
        final actions = {for (final turn in turns) turn.id: icons(turn.id)};
        final composerRect = tester.getRect(field);
        final state = channel.state;
        expect(
          find.byKey(const ValueKey('hermes-structured-assistant-error')),
          findsOneWidget,
        );
        expect(surfaces['bubble-user']!.color, baseFill);
        for (final value in [0, 37, 100, 0]) {
          container
              .read(wingChatPreferencesProvider.notifier)
              .setUserBubbleTransparency(value.toDouble());
          await tester.pumpAndSettle();
          final fill = value == 0
              ? baseFill
              : baseFill.withValues(alpha: baseFill.a * (1 - value / 100));
          expect(
            decoration('bubble-user'),
            surfaces['bubble-user']!.copyWith(color: fill),
          );
          for (final turn in turns) {
            if (turn.author != HermesTurnAuthor.user) {
              expect(decoration(turn.id), surfaces[turn.id]);
            }
            expect(tester.getRect(bubble(turn.id)), rectangles[turn.id]);
            expect(text(turn.id), prose[turn.id]);
            expect(icons(turn.id), actions[turn.id]);
          }
          final current = tester.widget<TextField>(field);
          expect(tester.state(find.byType(HermesChatScreen)), same(owner));
          expect(current.controller, same(controller));
          expect(current.focusNode, same(focus));
          expect(focus.hasFocus, isTrue);
          expect(controller.value, draft);
          expect(tester.getRect(field), composerRect);
          expect(container.read(hermesChannelProvider), same(channel));
          expect(channel.state, same(state));
        }
        expect(channel.stopActiveTurnCalls, 0);
        expect(channel.selectSessionCalls, isEmpty);
        expect(channel.selectProfileCalls, isEmpty);
        expect(channel.connectCalls, isEmpty);
        expect(channel.createSessionCalls, isEmpty);
        expect(channel.loadEarlierMessagesCalls, 0);
        expect(channel.loadProvidersCalls, 0);
        expect(channel.reconcileActiveSessionCalls, 0);
        expect(channel.sentImageDataUrls, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('Stop remains pinned when secondary controls scroll at 200%', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await _mount(tester, channel, 960, scale: 2);
    final field = find.byKey(const ValueKey('hermes-composer-field'));
    await tester.enterText(field, 'Retained local draft');
    channel.beginStreamingTurn('Synthetic active run');
    await tester.pump();
    final stop = find.byKey(const ValueKey('hermes-composer-stop-chip'));
    final original = tester.getRect(stop);
    final secondary = find.byKey(
      const ValueKey('hermes-composer-secondary-controls'),
    );
    await tester.drag(secondary, const Offset(-600, 0));
    await tester.pump();
    expect(tester.getRect(stop), original);
    expect(stop.hitTestable(), findsOneWidget);
    await tester.tap(stop);
    await tester.pumpAndSettle();
    expect(channel.stopActiveTurnCalls, 1);
    expect(
      tester.widget<TextField>(field).controller!.text,
      'Retained local draft',
    );
    expect(channel.state.activeSessionId, 'sess_1');
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}

Future<void> _mount(
  WidgetTester tester,
  FakeHermesChannel channel,
  double width, {
  double scale = 1,
  ThemeData? theme,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(channel.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const AppShellSessionNavigation(child: HermesChatScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
