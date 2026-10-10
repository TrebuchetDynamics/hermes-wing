import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

final source = StateProvider<HermesChannel>((_) => throw UnimplementedError());
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> reach(WidgetTester tester, String label) async {
  final target = find.text(label);
  expect(target, findsOneWidget);
  for (var i = 0; i < 60; i++) {
    final context = FocusManager.instance.primaryFocus?.context;
    final control =
        context?.findAncestorWidgetOfExactType<ListTile>() ??
        context?.findAncestorWidgetOfExactType<TextButton>() ??
        context?.findAncestorWidgetOfExactType<FilledButton>() ??
        context?.findAncestorWidgetOfExactType<OutlinedButton>();
    if (control != null &&
        find
            .descendant(of: find.byWidget(control), matching: target)
            .evaluate()
            .isNotEmpty) {
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('Keyboard could not reach $label');
}

List<HermesChatTurn> turns({
  bool complete = false,
  String session = 'sess_1',
}) => [
  HermesChatTurn(
    id: 'prompt',
    sessionId: session,
    author: HermesTurnAuthor.user,
    createdAt: DateTime.utc(2026),
    text: 'Synthetic ordered request',
  ),
  HermesChatTurn(
    id: 'reasoning',
    sessionId: session,
    author: HermesTurnAuthor.system,
    createdAt: DateTime.utc(2026),
    kind: HermesTurnKind.reasoning,
    text: 'Synthetic ordered reasoning',
  ),
  HermesChatTurn(
    id: 'commentary',
    sessionId: session,
    author: HermesTurnAuthor.assistant,
    createdAt: DateTime.utc(2026),
    text: 'Synthetic ordered commentary',
  ),
  for (final name in ['read_file', 'web_search'])
    HermesChatTurn(
      id: name,
      sessionId: session,
      author: HermesTurnAuthor.system,
      createdAt: DateTime.utc(2026),
      kind: HermesTurnKind.toolCall,
      toolCall: HermesToolCall(name: name, status: 'completed'),
    ),
  HermesChatTurn(
    id: 'answer',
    sessionId: session,
    author: HermesTurnAuthor.assistant,
    createdAt: DateTime.utc(2026),
    text: complete ? 'Synthetic ordered answer' : '',
    status: complete ? HermesTurnStatus.completed : HermesTurnStatus.streaming,
  ),
];

void replace(
  FakeHermesChannel channel, {
  bool complete = false,
  String session = 'sess_1',
}) {
  channel.replaceSessions(
    [HermesSession(id: session, source: 'fake')],
    activeSessionId: session,
    messages: {session: turns(complete: complete, session: session)},
  );
}

void noMutations(FakeHermesChannel channel) {
  expect(channel.sentImageDataUrls, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
  expect(channel.stopActiveTurnCalls, 0);
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.lockSessionModelCalls, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
}

Future<ProviderContainer> mount(
  WidgetTester tester,
  FakeHermesChannel channel,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 1100);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      source.overrideWith((_) => channel),
      hermesChannelProvider.overrideWith((ref) => ref.watch(source)),
      hermesVoiceCaptureServiceProvider.overrideWithValue(null),
      hermesTextToSpeechServiceProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(platform: TargetPlatform.linux),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const HermesChatScreen(),
      ),
    ),
  );
  await settle(tester);
  return container;
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );
  testWidgets(
    'canonical activity order survives completion and keyboard adaptive return',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      replace(channel);
      await mount(tester, channel);
      await reach(tester, 'Thought');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.text('Synthetic ordered reasoning'), findsOneWidget);
      for (final width in [390.0, 1280.0]) {
        tester.view.physicalSize = Size(width, 1100);
        await settle(tester);
        expect(find.text('Synthetic ordered reasoning'), findsOneWidget);
        await reach(tester, 'Thought');
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await settle(tester);
        expect(find.text('Synthetic ordered reasoning'), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await settle(tester);
      }
      replace(channel, complete: true);
      await settle(tester);
      final labels = [
        'Synthetic ordered request',
        'Thought',
        'Synthetic ordered commentary',
        'Hermes host activity · 2 steps',
        'Synthetic ordered answer',
      ];
      double? previous;
      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
        final y = tester.getTopLeft(find.text(label)).dy;
        if (previous != null) expect(y, greaterThan(previous));
        previous = y;
      }
      await reach(tester, 'Hermes host activity · 2 steps');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.text('File activity'), findsOneWidget);
      expect(find.text('Web activity'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('File activity')).dy,
        lessThan(tester.getTopLeft(find.text('Web activity')).dy),
      );
      expect(channel.state.activeMessages.map((t) => t.id).toList(), [
        'prompt',
        'reasoning',
        'commentary',
        'read_file',
        'web_search',
        'answer',
      ]);
      noMutations(channel);
      expect(tester.takeException(), isNull);
    },
  );

  for (final change in ['session', 'profile', 'channel']) {
    testWidgets(
      '$change replacement drops keyboard actionable obsolete approval',
      (tester) async {
        final channel = FakeHermesChannel(selectedProfileId: 'default');
        final replacement = FakeHermesChannel(selectedProfileId: 'default');
        addTearDown(channel.dispose);
        addTearDown(replacement.dispose);
        replace(channel);
        final container = await mount(tester, channel);
        final target = channel.activeTurnInterruptionTarget!;
        final approval = HermesApprovalRequest(
          id: 'ordered-approval',
          toolCallId: 'ordered-tool',
          prompt: 'Synthetic ordered approval',
          choices: {HermesApprovalDecision.once, HermesApprovalDecision.deny},
          runId: target.runId,
          sessionId: target.sessionId,
          profileId: target.profileId,
          connectionGeneration: target.connectionGeneration,
        );
        channel.emitApprovalRequest(approval);
        await settle(tester);
        await reach(tester, 'Approve once');
        expect(find.text('Synthetic ordered approval'), findsOneWidget);
        for (final width in [390.0, 1280.0]) {
          tester.view.physicalSize = Size(width, 1100);
          await settle(tester);
          expect(find.text('Approve once'), findsOneWidget);
          noMutations(channel);
        }
        await reach(tester, 'Approve once');
        final obsoleteFocus = FocusManager.instance.primaryFocus;
        if (change == 'session') {
          replace(channel, complete: true, session: 'synthetic-order-other');
        } else if (change == 'profile') {
          await channel.selectProfile('synthetic-other');
        } else {
          replace(replacement, complete: true);
          container.read(source.notifier).state = replacement;
        }
        await settle(tester);
        expect(find.text('Approve once'), findsNothing);
        expect(find.text('Synthetic ordered approval'), findsNothing);
        expect(FocusManager.instance.primaryFocus, isNot(same(obsoleteFocus)));
        // Re-activation on the retired focus cannot answer or stop the old run.
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        channel.emitApprovalRequest(approval);
        await settle(tester);
        expect(find.text('Approve once'), findsNothing);
        noMutations(channel);
        noMutations(replacement);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
