import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/settings/providers/chat_preferences_provider.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/widgets/thread_timeline.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_transcript_viewport.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import '../support/fake_hermes_channel.dart';
import 'hermes_chat_window_test.dart' show history, open, rows, latest;

void main() {
  testWidgets(
    'loaded thread timeline navigates without changing chat ownership',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      HermesChatTurn prompt(
        String id,
        String text, {
        HermesTurnAuthor author = HermesTurnAuthor.user,
        HermesTurnKind kind = HermesTurnKind.text,
        String session = 'sess_1',
      }) => HermesChatTurn(
        id: id,
        sessionId: session,
        author: author,
        kind: kind,
        text: text,
        createdAt: DateTime.utc(2026),
      );
      final filtered = loadedThreadPrompts([
        prompt('one', ' First\n  prompt '),
        prompt('assistant', 'Not a prompt', author: HermesTurnAuthor.assistant),
        prompt('system', 'Not a prompt', author: HermesTurnAuthor.system),
        prompt('reason', 'Not a prompt', kind: HermesTurnKind.reasoning),
        prompt('tool', 'Not a prompt', kind: HermesTurnKind.toolCall),
        prompt('blank', '  '),
        prompt(' ', 'No identity'),
        prompt('duplicate', 'First'),
        prompt('duplicate', 'Second'),
        prompt('notification', '[IMPORTANT: Background process 7\nfinished]'),
        prompt('other', 'Other session', session: 'other'),
        prompt('safe', 'Synthetic token=example-secret /home/example/private'),
        prompt('long', List.filled(200, 'x').join()),
      ], 'sess_1');
      expect(filtered.map((e) => e.id), ['one', 'safe', 'long']);
      expect(filtered.first.preview, 'First prompt');
      expect(filtered[1].preview, isNot(contains('example-secret')));
      expect(filtered[1].preview, isNot(contains('/home/example')));
      expect(filtered.last.preview.length, 120);
      expect(filtered.last.preview.endsWith('…'), isTrue);
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final shortScroll = ScrollController();
      final shortViewport = HermesTranscriptViewportController(shortScroll)
        ..setOwner('short');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Center(
            child: SizedBox(
              width: 800,
              height: 80,
              child: HermesThreadTimeline(
                turns: history(3),
                sessionId: 'sess_1',
                viewport: shortViewport,
                hidden: false,
                onJump: (_) => fail('The opener must not activate a tick'),
                onEarlier: () {},
                canShowEarlier: false,
                loadingEarlier: false,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-timeline-rail')),
        findsNothing,
        reason: 'Short side-lane ticks must not overlap the 48px opener',
      );
      await tester.tap(find.byTooltip('Conversation timeline'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-timeline-prompts')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      shortViewport.dispose();
      shortScroll.dispose();
      final turns = history(10000);
      turns[5097] = turns[5096].copyWith(text: 'Ambiguous window boundary');
      turns[9950] = turns[9950].copyWith(
        text: List.filled(300, 'Tall synthetic output').join('\n\n'),
      );
      final channel = FakeHermesChannel(sessionsWithEarlierMessages: {'sess_1'})
        ..replaceTranscript(history(24));
      for (final width in [390.0, 600.0, 719.0, 1280.0]) {
        tester.view.physicalSize = Size(width, 1400);
        await open(tester, channel, scale: 2);
        final transcriptRect = tester.getRect(
          find.byKey(const ValueKey('hermes-transcript')),
        );
        final opener = find.byTooltip('Conversation timeline');
        expect(
          tester.getRect(opener).overlaps(transcriptRect),
          isFalse,
          reason: 'The full-size opener must not intercept transcript input',
        );
        final ticks = find.byKey(const ValueKey('hermes-timeline-rail'));
        if (ticks.evaluate().isNotEmpty) {
          final row = tester.getRect(
            find.byKey(const ValueKey('hermes-turn-synthetic-23')),
          );
          expect(tester.getRect(ticks).left, greaterThanOrEqualTo(row.right));
        }
        await tester.tap(opener);
        await tester.pumpAndSettle();
        for (final backwards in [true, false]) {
          if (backwards) {
            await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          }
          for (var i = 0; i < 30; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            var inNavigator = false;
            FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
              e,
            ) {
              inNavigator =
                  e.widget.key == const ValueKey('hermes-timeline-dialog');
              return !inNavigator;
            });
            expect(
              inNavigator,
              isTrue,
              reason: 'Traversal stays in the visible navigator',
            );
          }
          if (backwards) {
            await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          }
        }
        final coveredId = tester
            .getSemantics(
              find.byKey(const ValueKey('hermes-turn-synthetic-23')),
            )
            .id;
        final accessibleIds = <int>{};
        void inspect(SemanticsNode node) {
          accessibleIds.add(node.id);
          node.visitChildren((child) {
            inspect(child);
            return true;
          });
        }

        tester.binding.rootPipelineOwner.visitChildren((owner) {
          final root = owner.semanticsOwner?.rootSemanticsNode;
          if (root != null) inspect(root);
        });
        expect(
          accessibleIds,
          isNot(contains(coveredId)),
          reason: 'Covered transcript semantics are not exposed',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(opener.hitTestable(), findsOneWidget);
      }
      channel.replaceTranscript(turns);
      await open(tester, channel, scale: 2);
      final control = find.byTooltip('Conversation timeline');
      expect(control, findsOneWidget);
      final rail = find.byKey(const ValueKey('hermes-timeline-rail'));
      expect(
        tester.widget<ListView>(rail).controller!.offset,
        greaterThan(60000),
        reason: 'Latest marker is revealed without mounting 10000 ticks',
      );
      await tester.tap(control);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        tester.widget<ListView>(rail).controller!.offset,
        greaterThan(60000),
        reason: 'Cancel remounts the rail at the unchanged active prompt',
      );
      await tester.tap(control);
      await tester.pumpAndSettle();
      var tabbedPrompt = false;
      for (var i = 0; i < 20; i++) {
        FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
          tabbedPrompt =
              e.widget.key ==
              const ValueKey('hermes-timeline-prompt-synthetic-0');
          return !tabbedPrompt;
        });
        if (tabbedPrompt) break;
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(tabbedPrompt, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-turn-synthetic-1')),
        findsOneWidget,
      );
      final transcript = find.byKey(const ValueKey('hermes-transcript'));
      final element = tester.element(transcript);
      final scroll = tester.widget<ListView>(transcript).controller!;
      final composer = find.byType(TextField).last;
      final draft = tester.widget<TextField>(composer).controller!;
      draft.value = const TextEditingValue(
        text: 'Synthetic draft',
        selection: TextSelection(baseOffset: 1, extentOffset: 4),
        composing: TextRange(start: 0, end: 4),
      );
      final draftValue = draft.value;
      for (final target in [0, 5000, 9999]) {
        await tester.tap(control);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pumpAndSettle();
        if (target > 0) {
          await tester.sendKeyEvent(LogicalKeyboardKey.end);
          await tester.pumpAndSettle();
        }
        // Full-size lazy targets also allow touch navigation to a middle prompt.
        if (target == 5000) {
          final list = tester.widget<ListView>(
            find.byKey(const ValueKey('hermes-timeline-prompts')),
          );
          list.controller!.jumpTo(5000 * 208.0);
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('hermes-timeline-prompt-synthetic-5000')),
          );
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        }
        await tester.pumpAndSettle();
        final row = find.byKey(ValueKey('hermes-turn-synthetic-$target'));
        expect(row, findsOneWidget);
        final top = tester.getTopLeft(transcript).dy;
        if (target != 9999) {
          expect(tester.getTopLeft(row).dy, closeTo(top + 8, 16));
        } else {
          expect(row.hitTestable(), findsOneWidget);
          expect(
            scroll.offset,
            0,
            reason: 'Newest prompt clamps at the natural Latest edge',
          );
        }
        expect(rows(tester).length, lessThanOrEqualTo(102));
        if (target == 5000) {
          final railOffset = tester.widget<ListView>(rail).controller!.offset;
          expect(railOffset, inInclusiveRange(34000, 36000));
        }
        expect(channel.loadEarlierMessagesCalls, 0);
        expect(identical(tester.element(transcript), element), isTrue);
      }
      final container = ProviderScope.containerOf(tester.element(transcript));
      final prefs = container.read(wingChatPreferencesProvider.notifier);
      final offset = scroll.offset;
      prefs.setHideThreadTimeline(true);
      await tester.pumpAndSettle();
      expect(control, findsNothing);
      expect(scroll.offset, offset);
      prefs.setHideThreadTimeline(false);
      await tester.pumpAndSettle();
      expect(control, findsOneWidget);
      expect(
        tester.widget<ListView>(rail).controller!.offset,
        greaterThan(60000),
        reason: 'Hide/show also reveals the unchanged active prompt',
      );
      expect(
        identical(tester.widget<TextField>(composer).controller, draft),
        isTrue,
      );
      expect(draft.value, draftValue);
      expect(channel.state.activeMessages, turns);
      expect(channel.state.activeSessionId, 'sess_1');
      channel.beginStreamingTurn('Synthetic streamed prompt');
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(control);
      await tester.pump(const Duration(seconds: 1));
      final timelineFocus = FocusManager.instance.primaryFocus;
      channel.appendStreamingTurnText('Synthetic delta');
      await tester.pump(const Duration(seconds: 1));
      channel.completeStreamingTurn(text: 'Synthetic completion');
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus,
        timelineFocus,
        reason: 'Completion cannot steal timeline keyboard ownership',
      );
      expect(draft.value, draftValue);
      expect(identical(tester.element(transcript), element), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(latest);
      await tester.pumpAndSettle();
      expect(scroll.offset, 0);
      expect(rows(tester).length, 100);
      expect(channel.connectCalls, isEmpty);
      expect(channel.selectProfileCalls, isEmpty);
      expect(channel.loadProvidersCalls, 0);
      expect(channel.createSessionCalls, isEmpty);
      expect(channel.selectSessionCalls, isEmpty);
      // Compact uses the same full-size targets without tiny pointer ticks.
      tester.view.physicalSize = const Size(390, 1400);
      await open(tester, channel, scale: 2, theme: ThemeData.dark());
      expect(Theme.of(tester.element(transcript)).brightness, Brightness.dark);
      expect(identical(tester.element(transcript), element), isTrue);
      expect(control, findsOneWidget);
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Conversation timeline'), findsWidgets);
      expect(
        find.byKey(const ValueKey('hermes-timeline-prompts')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-timeline-prompt-synthetic-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-timeline-prompt-synthetic-5000')),
        findsNothing,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      final focus = FocusManager.instance.primaryFocus;
      expect(
        focus?.context?.findAncestorWidgetOfExactType<HermesThreadTimeline>(),
        isNotNull,
      );
      // Show earlier consumes loaded render budget before any Agent read.
      await tester.tap(control);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('hermes-timeline-earlier')));
      await tester.pumpAndSettle();
      expect(rows(tester).length, 200);
      expect(channel.loadEarlierMessagesCalls, 0);
      // A first-prompt jump leaves no earlier loaded rows.
      await tester.tap(control);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('hermes-timeline-earlier')));
      await tester.pumpAndSettle();
      expect(channel.loadEarlierMessagesCalls, 1);
      expect(draft.value, draftValue);
      final viewport = tester
          .widget<HermesThreadTimeline>(find.byType(HermesThreadTimeline))
          .viewport;
      viewport.jumpToPrompt('synthetic-5000', channel.state.activeMessages);
      prefs.setHideThreadTimeline(true);
      await tester.pumpAndSettle();
      expect(viewport.mode.name, 'browsing');
      prefs.setHideThreadTimeline(false);
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();
      final replacement = FakeHermesChannel()..replaceTranscript(turns);
      final ownerBefore = viewport.ownerIdentity;
      container.updateOverrides([
        hermesChannelProvider.overrideWithValue(replacement),
      ]);
      await tester.pumpAndSettle();
      expect(
        viewport.ownerIdentity,
        isNot(ownerBefore),
        reason:
            'Same origin/profile/session on a different channel is a new owner',
      );
      expect(
        find.byKey(const ValueKey('hermes-timeline-prompts')),
        findsNothing,
      );
      await tester.tap(control);
      await tester.pumpAndSettle();
      replacement.replaceSessions(const [
        HermesSession(id: 'sess_2', source: 'fake'),
      ], activeSessionId: 'sess_2');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-timeline-prompts')),
        findsNothing,
      );
      expect(channel.selectSessionCalls, isEmpty);
      expect(channel.stopActiveTurnCalls, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      channel.dispose();
      replacement.dispose();
      semantics.dispose();
    },
  );
}
