import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_transcript_viewport.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import '../support/fake_hermes_channel.dart';

List<HermesChatTurn> history(int count) => List.generate(
  count,
  (i) => HermesChatTurn(
    id: 'synthetic-$i',
    sessionId: 'sess_1',
    author: HermesTurnAuthor.user,
    createdAt: DateTime.utc(2026),
    text: 'Synthetic loaded turn $i',
  ),
);

final reveal = find.byKey(const ValueKey('hermes-transcript-reveal-earlier'));
final latest = find.byKey(const ValueKey('hermes-transcript-latest'));
List<Widget> rows(WidgetTester tester) =>
    (tester
                .widget<ListView>(
                  find.byKey(const ValueKey('hermes-transcript')),
                )
                .childrenDelegate
            as SliverChildListDelegate)
        .children
        .whereType<KeyedSubtree>()
        .toList();

Future<void> open(
  WidgetTester tester,
  FakeHermesChannel channel, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final ownerChange in ['origin', 'profile', 'session']) {
    testWidgets(
      '$ownerChange resets expansion and rejects old-owner restoration',
      (tester) async {
        final channel = FakeHermesChannel()..replaceTranscript(history(250));
        addTearDown(channel.dispose);
        await open(tester, channel);
        await tester.tap(reveal);
        await tester.pumpAndSettle();
        expect(rows(tester).length, 200);
        if (ownerChange == 'origin') {
          await channel.connect(baseUrl: 'http://127.0.0.1:12345');
        } else if (ownerChange == 'profile') {
          await channel.selectProfile('synthetic-profile');
        } else {
          await channel.createSession();
        }
        channel.replaceTranscript(history(250));
        await tester.pumpAndSettle();
        expect(rows(tester).length, 100);
        expect(
          tester
              .widget<ListView>(find.byKey(const ValueKey('hermes-transcript')))
              .controller!
              .offset,
          0,
        );
        expect(latest, findsNothing);
      },
    );
  }
  testWidgets(
    '300 consecutive tools are continued and deliberate reveals make progress',
    (tester) async {
      final channel = FakeHermesChannel()
        ..replaceTranscript(
          List.generate(
            300,
            (i) => HermesChatTurn(
              id: 'tool-$i',
              sessionId: 'sess_1',
              author: HermesTurnAuthor.system,
              createdAt: DateTime.utc(2026),
              kind: HermesTurnKind.toolCall,
              toolCall: const HermesToolCall(
                name: 'web_search',
                status: 'completed',
              ),
            ),
          ),
        );
      addTearDown(channel.dispose);
      await open(tester, channel);
      expect(
        find.text('Hermes host activity · 100 steps (continued)'),
        findsOneWidget,
      );
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      expect(
        find.text('Hermes host activity · 200 steps (continued)'),
        findsOneWidget,
      );
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      expect(find.text('Hermes host activity · 300 steps'), findsOneWidget);
      expect(reveal, findsNothing);
    },
  );
  testWidgets(
    'pending approval and error stay recoverable outside the loaded window',
    (tester) async {
      final channel = FakeHermesChannel(
        errorMessage: 'Synthetic stream failure',
      )..replaceTranscript(history(1000));
      addTearDown(channel.dispose);
      await open(tester, channel);
      expect(find.byKey(const ValueKey('hermes-chat-error')), findsOneWidget);
      channel.emitApprovalRequest(
        const HermesApprovalRequest(
          id: 'synthetic-approval',
          toolCallId: 'synthetic-tool',
          runId: 'synthetic-run',
          prompt: 'Synthetic approval',
        ),
      );
      await tester.pumpAndSettle();
      expect(rows(tester).length, 100);
      await tester.drag(
        find.byKey(const ValueKey('hermes-transcript')),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      await tester.tap(latest);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('hermes-approval-review')));
      await tester.pumpAndSettle();
      expect(find.text('Review Hermes approval'), findsOneWidget);
    },
  );
  for (final ambiguous in [false, true]) {
    testWidgets(
      '${ambiguous ? 'duplicate' : 'deleted'} canonical anchor safely recovers Latest',
      (tester) async {
        final turns = history(250);
        final channel = FakeHermesChannel()..replaceTranscript(turns);
        addTearDown(channel.dispose);
        await open(tester, channel);
        await tester.drag(
          find.byKey(const ValueKey('hermes-transcript')),
          const Offset(0, 330),
        );
        await tester.pumpAndSettle();
        final listTop = tester
            .getTopLeft(find.byKey(const ValueKey('hermes-transcript')))
            .dy;
        final mounted =
            rows(tester)
                .map((row) => (row.key as GlobalKey).currentContext)
                .whereType<BuildContext>()
                .where((context) {
                  final box = context.findRenderObject()! as RenderBox;
                  final y = box.localToGlobal(Offset.zero).dy - listTop;
                  return y + box.size.height > 0 && y < 300;
                })
                .toList()
              ..sort(
                (a, b) => (a.findRenderObject()! as RenderBox)
                    .localToGlobal(Offset.zero)
                    .dy
                    .compareTo(
                      (b.findRenderObject()! as RenderBox)
                          .localToGlobal(Offset.zero)
                          .dy,
                    ),
              );
        final first = mounted.first;
        String? anchorId;
        void locate(Element element) {
          final key = element.widget.key;
          if (key is ValueKey<String> &&
              key.value.startsWith('hermes-turn-synthetic-')) {
            anchorId = key.value.substring('hermes-turn-'.length);
          }
          element.visitChildElements(locate);
        }

        (first as Element).visitChildElements(locate);
        expect(anchorId, isNotNull);
        channel.replaceTranscript(
          ambiguous
              ? [...turns, turns.firstWhere((turn) => turn.id == anchorId)]
              : turns.where((turn) => turn.id != anchorId).toList(),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ListView>(find.byKey(const ValueKey('hermes-transcript')))
              .controller!
              .offset,
          0,
        );
        expect(rows(tester).length, 100);
        expect(latest, findsNothing);
      },
    );
  }
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );
  for (final count in [20, 250, 1000]) {
    testWidgets('$count loaded turns are projected before row allocation', (
      tester,
    ) async {
      final channel = FakeHermesChannel()..replaceTranscript(history(count));
      addTearDown(channel.dispose);
      await open(tester, channel);
      expect(rows(tester).length, count < 100 ? count : 100);
      expect(channel.state.activeMessages.length, count);
      expect(reveal, count < 100 ? findsNothing : findsOneWidget);
      if (count > 100) {
        await tester.tap(reveal);
        await tester.pumpAndSettle();
        expect(rows(tester).length, 200);
        await tester.tap(reveal);
        await tester.pumpAndSettle();
        expect(rows(tester).length, count < 300 ? count : 300);
        await tester.tap(latest);
        await tester.pumpAndSettle();
        expect(rows(tester).length, 100);
      }
    });
  }
  testWidgets(
    'local reveal is not Agent pagination; canonical copy remains complete',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final channel = FakeHermesChannel(sessionsWithEarlierMessages: {'sess_1'})
        ..replaceTranscript(history(250));
      addTearDown(channel.dispose);
      await open(tester, channel);
      // The existing toolbar copies canonical state, not the row projection.
      await tester.tap(
        find.byKey(const ValueKey('hermes-copy-transcript-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-copy-transcript-text')),
      );
      await tester.pumpAndSettle();
      expect(copied, contains('Synthetic loaded turn 0'));
      expect(copied, contains('Synthetic loaded turn 249'));
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      expect(channel.loadEarlierMessagesCalls, 0);
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      final fetch = find.byKey(
        const ValueKey('hermes-transcript-load-earlier-action'),
      );
      final list = tester.widget<ListView>(
        find.byKey(const ValueKey('hermes-transcript')),
      );
      list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.tap(fetch);
      await tester.pumpAndSettle();
      expect(channel.loadEarlierMessagesCalls, 1);
    },
  );
  testWidgets(
    'browsing live append and canonical replacement keep dynamic reading position',
    (tester) async {
      final turns = history(250);
      final channel = FakeHermesChannel()..replaceTranscript(turns);
      addTearDown(channel.dispose);
      await open(tester, channel);
      await tester.drag(
        find.byKey(const ValueKey('hermes-transcript')),
        const Offset(0, 330),
      );
      await tester.pumpAndSettle();
      final list = tester.widget<ListView>(
        find.byKey(const ValueKey('hermes-transcript')),
      );
      final before = list.controller!.offset;
      expect(before, greaterThan(80));
      final visible = find
          .textContaining('Synthetic loaded turn')
          .evaluate()
          .where((e) {
            final box = e.renderObject;
            return box is RenderBox &&
                box.localToGlobal(Offset.zero).dy > 150 &&
                box.localToGlobal(Offset.zero).dy < 400;
          })
          .first;
      final textWidget = visible.widget as Text;
      final text = textWidget.data ?? textWidget.textSpan!.toPlainText();
      final y = tester.getTopLeft(find.text(text)).dy;
      channel.replaceTranscript(history(1000));
      await tester.pumpAndSettle();
      expect(rows(tester).length, 100);
      expect(tester.getTopLeft(find.text(text)).dy, closeTo(y, 1));
      channel.replaceTranscript(
        history(1000).map((turn) => turn.copyWith()).toList(),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text(text)).dy, closeTo(y, 1));
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text(text)).dy, closeTo(y, 1));
      final dynamicTurns = history(1000);
      dynamicTurns[249] = dynamicTurns[249].copyWith(
        text: List.filled(100, 'Synthetic dynamic output').join('\n\n'),
      );
      channel.replaceTranscript(dynamicTurns);
      await tester.pumpAndSettle();
      expect(latest, findsOneWidget);
      expect(tester.getTopLeft(find.text(text)).dy, closeTo(y, 1));
      expect(
        tester
            .widget<ListView>(find.byKey(const ValueKey('hermes-transcript')))
            .controller!
            .offset,
        greaterThan(80),
      );
      await tester.tap(latest);
      await tester.pumpAndSettle();
      expect(rows(tester).length, 100);
      expect(list.controller!.offset, 0);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reveal is semantic and keyboard operable at 200 percent with reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final channel = FakeHermesChannel()..replaceTranscript(history(250));
      addTearDown(channel.dispose);
      await open(tester, channel, scale: 2);
      expect(
        find.bySemanticsLabel(RegExp('Show up to 100 earlier loaded turns')),
        findsOneWidget,
      );
      Focus.of(
        tester.element(
          find.descendant(of: reveal, matching: find.byType(Text)).first,
        ),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(rows(tester).length, 200);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  test(
    'short tool groups stay whole; 300-turn groups never bypass initial bound',
    () {
      final scroll = ScrollController();
      final viewport = HermesTranscriptViewportController(scroll)
        ..setOwner('A');
      addTearDown(viewport.dispose);
      addTearDown(scroll.dispose);
      HermesChatTurn tool(int i) => HermesChatTurn(
        id: 'tool-$i',
        sessionId: 'sess_1',
        author: HermesTurnAuthor.system,
        createdAt: DateTime.utc(2026),
        kind: HermesTurnKind.toolCall,
        toolCall: const HermesToolCall(name: 'web_search', status: 'completed'),
      );
      final short = [
        ...history(40),
        ...List.generate(5, tool),
        ...history(97).map(
          (t) => HermesChatTurn(
            id: 'tail-${t.id}',
            sessionId: t.sessionId,
            author: t.author,
            createdAt: t.createdAt,
            text: t.text,
          ),
        ),
      ];
      expect(viewport.project(short).length, 102);
      for (var i = 0; i < 5; i++) {
        expect(viewport.project(short).length, 102);
      }
      viewport.followLatest();
      final long = List.generate(300, tool);
      expect(viewport.project(long).length, 100);
      expect(viewport.continuedTools, isTrue);
      viewport.userScrolled(nearLatest: false);
      expect(viewport.project([...long, ...history(1000)]).length, 100);
      viewport.revealEarlier();
      expect(viewport.project(long).length, 200);
      viewport.setOwner('B');
      expect(viewport.project(long).length, 100);
    },
  );
}
