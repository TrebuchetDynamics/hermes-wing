import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_run.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/hermes_rich_text.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

Widget _localizedApp(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  testWidgets(
    'assistant markdown renders without exposing formatting markers',
    (tester) async {
      final channel = FakeHermesChannel();
      channel.beginStreamingTurn('Format this response.');
      channel.completeStreamingTurn(text: '**Strong answer**');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: _localizedApp(const HermesChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('**Strong answer**'), findsNothing);
      expect(find.text('Strong answer', findRichText: true), findsOneWidget);
    },
  );

  testWidgets('reasoning is available in a collapsed readable card', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Reason about this.');
    channel.addReasoningTurn('Compare constraints before answering.');
    channel.completeStreamingTurn(text: 'Reasoned answer.');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reasoning'), findsOneWidget);
    expect(find.text('Compare constraints before answering.'), findsNothing);

    await tester.tap(find.text('Reasoning'));
    await tester.pumpAndSettle();

    expect(find.text('Compare constraints before answering.'), findsOneWidget);
  });

  testWidgets('assistant replies show server-reported token usage', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Measure this.');
    channel.completeStreamingTurn(
      text: 'Measured answer.',
      usage: const HermesRunUsage(
        inputTokens: 12,
        outputTokens: 7,
        totalTokens: 19,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12 in · 7 out · 19 total tokens'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Token usage: 12 input, 7 output, 19 total'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('token usage remains readable at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Measure this.');
    channel.completeStreamingTurn(
      text: 'Measured answer.',
      usage: const HermesRunUsage(
        inputTokens: 1200,
        outputTokens: 700,
        totalTokens: 1900,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: const HermesChatScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('1200 in · 700 out · 1900 total tokens'), findsOneWidget);
  });

  testWidgets('short conversations stay anchored above the composer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer');
    final assistantId = channel.state.activeMessages.last.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final bubbleBottom = tester
        .getBottomLeft(find.byKey(ValueKey('hermes-turn-$assistantId')))
        .dy;
    final composerTop = tester
        .getTopLeft(find.byKey(const ValueKey('hermes-composer-surface')))
        .dy;
    expect(composerTop - bubbleBottom, lessThan(48));
  });

  testWidgets('message bubbles keep Telegram-style bottom tails', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer');
    final userId = channel.state.activeMessages.first.id;
    final assistantId = channel.state.activeMessages.last.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    BoxDecoration decoration(String id) =>
        tester
                .widget<Container>(find.byKey(ValueKey('hermes-turn-$id')))
                .decoration
            as BoxDecoration;
    final userRadius = decoration(userId).borderRadius! as BorderRadius;
    final assistantRadius =
        decoration(assistantId).borderRadius! as BorderRadius;
    expect(userRadius.bottomRight, const Radius.circular(5));
    expect(userRadius.topRight, const Radius.circular(16));
    expect(assistantRadius.bottomLeft, const Radius.circular(5));
    expect(assistantRadius.topLeft, const Radius.circular(16));
  });

  testWidgets('long press offers copy and reply actions', (tester) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer to reuse');
    final assistantId = channel.state.activeMessages.last.id;
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final bubble = find.byKey(ValueKey('hermes-turn-$assistantId'));
    await tester.longPress(bubble);
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copiedText, 'Answer to reuse');

    await tester.longPress(bubble);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(composer.controller?.text, '> Answer to reuse\n\n');
  });

  testWidgets('desktop context menus copy a message or the whole chat', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer with **Markdown**.');
    final assistantId = channel.state.activeMessages.last.id;
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final bubble = find.byKey(ValueKey('hermes-turn-$assistantId'));
    await tester.tapAt(
      tester.getCenter(bubble),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-context-reply-message')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-context-copy-message')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-context-copy-chat-markdown')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-context-copy-chat-markdown')),
    );
    await tester.pumpAndSettle();
    expect(
      copiedText,
      '## You\n\nQuestion\n\n## Hermes\n\nAnswer with **Markdown**.',
    );

    await tester.tapAt(
      tester.getCenter(bubble),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-context-copy-message')));
    await tester.pumpAndSettle();
    expect(copiedText, 'Answer with **Markdown**.');

    final transcript = tester.getRect(
      find.byKey(const ValueKey('hermes-transcript')),
    );
    await tester.tapAt(
      transcript.topLeft + const Offset(24, 24),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hermes-context-copy-chat-text')),
      findsOneWidget,
    );
    expect(find.text('Reply'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('secondary transcript menus stay disabled on mobile', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer');
    final assistantId = channel.state.activeMessages.last.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(find.byKey(ValueKey('hermes-turn-$assistantId'))),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-context-copy-message')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('hermes-context-copy-chat-text')),
      findsNothing,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('copies the active transcript as Markdown', (tester) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer with **Markdown**.');
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('hermes-copy-transcript-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Copy as text'), findsOneWidget);
    expect(find.text('Copy as Markdown'), findsOneWidget);

    await tester.tap(find.text('Copy as Markdown'));
    await tester.pumpAndSettle();

    expect(
      copiedText,
      '## You\n\nQuestion\n\n## Hermes\n\nAnswer with **Markdown**.',
    );
    expect(find.text('Transcript copied as Markdown'), findsOneWidget);
  });

  testWidgets('exports bounded server session metadata with the transcript', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.replaceSessions(const [
      HermesSession(
        id: 'sess_1',
        source: 'api_server',
        title: 'Export metadata',
        model: 'anthropic/claude-sonnet',
        messageCount: 2,
        toolCallCount: 4,
        inputTokens: 1200,
        outputTokens: 300,
        cacheReadTokens: 800,
        cacheWriteTokens: 50,
        reasoningTokens: 25,
        apiCallCount: 3,
        estimatedCostUsd: 0.0125,
        actualCostUsd: 0.01,
        startedAt: '2026-07-16T10:25:00Z',
        endedAt: '2026-07-16T10:30:00Z',
        endReason: 'completed',
        hasSystemPrompt: true,
        hasModelConfig: false,
      ),
    ], activeSessionId: 'sess_1');
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer');
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('hermes-copy-transcript-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy as Markdown'));
    await tester.pumpAndSettle();

    expect(copiedText, startsWith('## Session metadata\n\n'));
    expect(copiedText, contains('Session: Export metadata'));
    expect(copiedText, contains('Session ID: sess_1'));
    expect(copiedText, contains('Tool calls: 4'));
    expect(copiedText, contains('Input tokens: 1200'));
    expect(copiedText, contains('Output tokens: 300'));
    expect(copiedText, contains('Cache read tokens: 800'));
    expect(copiedText, contains('Cache write tokens: 50'));
    expect(copiedText, contains('Reasoning tokens: 25'));
    expect(copiedText, contains('API calls: 3'));
    expect(copiedText, contains('Actual cost (USD): 0.01'));
    expect(copiedText, contains('Estimated cost (USD): 0.0125'));
    expect(copiedText, contains('End reason: completed'));
    expect(copiedText, contains('System prompt snapshot: yes'));
    expect(copiedText, contains('Model config snapshot: no'));
    expect(copiedText, endsWith('## You\n\nQuestion\n\n## Hermes\n\nAnswer'));
  });

  testWidgets('copies the active transcript as plain text', (tester) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(
      text: 'Answer',
      usage: const HermesRunUsage(
        inputTokens: 12,
        outputTokens: 7,
        totalTokens: 19,
      ),
    );
    channel.addReasoningTurn('Checked constraints.');
    channel.addToolCallTurn(
      const HermesToolCall(
        name: 'web_search',
        status: 'completed',
        result: '2 results',
      ),
    );
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('hermes-copy-transcript-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy as text'));
    await tester.pumpAndSettle();

    expect(
      copiedText,
      'You:\nQuestion\n\nHermes:\nAnswer\nUsage: 12 input · 7 output · 19 total tokens\n\nReasoning:\nChecked constraints.\n\nTool: web_search\nStatus: completed\n2 results',
    );
    expect(find.text('Transcript copied as text'), findsOneWidget);
  });

  testWidgets('compact header offers transcript copy in overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-more-actions-button')));
    await tester.pumpAndSettle();

    expect(find.text('Copy transcript'), findsOneWidget);
  });

  testWidgets(
    'empty completed assistant turns do not render timestamp bubbles',
    (tester) async {
      final channel = FakeHermesChannel();
      channel.beginStreamingTurn('Do not leave an empty bubble.');
      channel.completeStreamingTurn(text: '');
      final emptyTurnId = channel.state.activeMessages.last.id;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: _localizedApp(const HermesChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('hermes-turn-$emptyTurnId')), findsNothing);
    },
  );

  testWidgets('active run recovery never offers a duplicate retry', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.addFailedExchange(
      'Perform this once.',
      errorMessage:
          'Hermes run is still active after its event stream closed. Reconnect before retrying.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-chat-error-reconnect')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('hermes-chat-error-retry')), findsNothing);
    expect(find.textContaining('send again'), findsNothing);
  });

  testWidgets('process-recreated active run offers reconciliation, not retry', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.addFailedExchange(
      'Do not duplicate this.',
      errorMessage:
          'Hermes run is still active. Reconnect later before retrying.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hermes run is still active.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-chat-error-reconnect')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('hermes-chat-error-retry')), findsNothing);
  });

  testWidgets('exhausted provider usage directs away from futile retry', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.addFailedExchange(
      'Try the exhausted model.',
      errorMessage: 'Hermes run failed: 429 Too Many Requests',
    );

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HermesChatScreen()),
        GoRoute(
          path: '/providers',
          builder: (_, _) => const Scaffold(body: Text('Provider settings')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Provider usage limit reached.'), findsOneWidget);
    expect(find.text('Switch provider or model'), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-chat-error-retry')), findsNothing);

    await tester.tap(find.text('Switch provider or model'));
    await tester.pumpAndSettle();
    expect(find.text('Provider settings'), findsOneWidget);
  });

  testWidgets(
    'run failures show redacted server detail without opening a sheet',
    (tester) async {
      final channel = FakeHermesChannel();
      channel.addFailedExchange(
        'Run it.',
        errorMessage:
            'Hermes run failed: provider_error: Quota exceeded for api_key=secret-key',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: _localizedApp(const HermesChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('hermes-chat-error-summary')),
        findsOneWidget,
      );
      expect(
        find.textContaining('provider_error: Quota exceeded'),
        findsOneWidget,
      );
      expect(find.textContaining('secret-key'), findsNothing);
    },
  );

  testWidgets('structured assistant errors render as readable messages', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Run it.');
    channel.completeStreamingTurn(
      text:
          '{"status":"error","error":"BLOCKED: execution needs approval. Do not retry the command until approval is available. The requested action was not run and no external state changed. Choose another approach or review the request details.","tool_calls_made":0}',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-structured-assistant-error')),
      findsOneWidget,
    );
    expect(find.text('Action blocked'), findsOneWidget);
    expect(find.textContaining('execution needs approval'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.textContaining('tool_calls_made'), findsNothing);

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(find.text('Hide details'), findsOneWidget);
  });

  testWidgets('assistant prose remains visible to accessibility', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _localizedApp(const Scaffold(body: HermesRichText('Accessible answer'))),
    );

    expect(find.bySemanticsLabel('Accessible answer'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('assistant code blocks can be copied', (tester) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Show the code.');
    channel.completeStreamingTurn(text: '```dart\nfinal answer = 42;\n```');
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-code-copy')));
    await tester.pump();

    expect(copiedText, 'final answer = 42;');
  });

  testWidgets('long code blocks start collapsed and can be expanded', (
    tester,
  ) async {
    final code = List.generate(16, (index) => 'line ${index + 1}').join('\n');

    await tester.pumpWidget(
      _localizedApp(Scaffold(body: HermesRichText('```text\n$code\n```'))),
    );

    expect(find.text('Show more'), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-code-content')), findsNothing);

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    expect(find.text('Show less'), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-code-content')), findsOneWidget);
  });

  testWidgets('diff code blocks distinguish additions removals and hunks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        const Scaffold(
          body: HermesRichText(
            '```diff\n+added\n-removed\n@@ changed @@\n unchanged\n```',
          ),
        ),
      ),
    );

    final colors = Theme.of(
      tester.element(find.byType(HermesRichText)),
    ).colorScheme;
    expect(find.text('diff'), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('hermes-diff-line-0')),
          )
          .style
          ?.color,
      colors.onTertiaryContainer,
    );
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('hermes-diff-line-1')),
          )
          .style
          ?.color,
      colors.onErrorContainer,
    );
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('hermes-diff-line-2')),
          )
          .style
          ?.color,
      colors.onSecondaryContainer,
    );
  });

  testWidgets('remote transcript images stay deferred', (tester) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Show the diagram.');
    channel.completeStreamingTurn(
      text: '![Architecture diagram](https://example.com/private.png)',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(
      find.text('Architecture diagram (image not loaded)'),
      findsOneWidget,
    );
  });

  testWidgets('safe transcript links use the external launcher', (
    tester,
  ) async {
    Uri? launchedUri;

    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: HermesRichText(
            '[Open docs](https://example.com/docs)',
            launchUri: (uri) async {
              launchedUri = uri;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open docs', findRichText: true));
    await tester.pump();

    expect(launchedUri, Uri.parse('https://example.com/docs'));
  });

  testWidgets('unsafe transcript link schemes stay inert', (tester) async {
    var launchCount = 0;

    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: HermesRichText(
            '[Do not run](javascript:alert(1))',
            launchUri: (uri) async {
              launchCount++;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Do not run', findRichText: true));
    await tester.pump();

    expect(launchCount, 0);
  });
}
