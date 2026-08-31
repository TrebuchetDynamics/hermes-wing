import 'dart:async';
import 'dart:convert';

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
import 'package:wing/features/hermes_chat/presentation/hermes_rich_text.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';

import '../support/fake_hermes_channel.dart';

Widget _localizedApp(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  testWidgets('streaming turn uses a static indicator under reduced motion', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Keep working.');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _localizedApp(const HermesChatScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-streaming-reduced-motion')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

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

  testWidgets('two-finger pinch zoom changes transcript text size', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Zoom this conversation.');
    channel.completeStreamingTurn(text: 'Readable answer');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final transcript = find.byKey(const ValueKey('hermes-transcript'));
    final answer = find.text('Readable answer', findRichText: true);
    final before = MediaQuery.textScalerOf(tester.element(answer)).scale(16);
    final center = tester.getCenter(transcript);
    final first = await tester.startGesture(center - const Offset(20, 0));
    final second = await tester.startGesture(center + const Offset(20, 0));
    await first.moveTo(center - const Offset(70, 0));
    await second.moveTo(center + const Offset(70, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    final after = MediaQuery.textScalerOf(tester.element(answer)).scale(16);
    expect(after, greaterThan(before));

    final shrinkFirst = await tester.startGesture(center - const Offset(70, 0));
    final shrinkSecond = await tester.startGesture(
      center + const Offset(70, 0),
    );
    await shrinkFirst.moveTo(center - const Offset(2, 0));
    await shrinkSecond.moveTo(center + const Offset(2, 0));
    await tester.pump();
    await shrinkFirst.up();
    await shrinkSecond.up();
    await tester.pumpAndSettle();

    final smallest = MediaQuery.textScalerOf(tester.element(answer)).scale(16);
    expect(smallest, lessThan(before));
    expect(smallest, moreOrLessEquals(8));
  });

  testWidgets('user Markdown renders richly and copies its original source', (
    tester,
  ) async {
    const source = '**Review** `this()` from /tmp/example.md';
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn(source);
    channel.completeStreamingTurn(text: 'Acknowledged.');
    final userId = channel.state.activeMessages.first.id;
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

    expect(find.textContaining(source), findsNothing);
    expect(find.textContaining('Review', findRichText: true), findsOneWidget);
    expect(find.textContaining('this()', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('/tmp/example.md', findRichText: true),
      findsOneWidget,
    );

    await tester.longPress(find.byKey(ValueKey('hermes-turn-$userId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    expect(copiedText, source);
  });

  testWidgets('assistant Markdown keeps rich blocks usable on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Show rich formatting.');
    channel.completeStreamingTurn(
      text: '''## Result

> A quoted answer

- first
- second

`inline()`

```dart
final answer = veryLongFunctionNameThatMustScrollHorizontally();
```
''',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Result', findRichText: true), findsOneWidget);
    expect(find.text('A quoted answer', findRichText: true), findsOneWidget);
    expect(find.text('inline()', findRichText: true), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-code-block')), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-code-language')), findsOneWidget);
    expect(find.text('dart'), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-code-copy')), findsOneWidget);
  });

  testWidgets('sent attachments render as Telegram-style file cards', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await channel.sendText(
      'Please inspect this.',
      textAttachment: 'contents',
      attachmentName: 'purple plan.md',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-message-attachment-purple plan.md')),
      findsOneWidget,
    );
    expect(find.text('purple plan.md'), findsOneWidget);
    expect(find.textContaining('[File:'), findsNothing);
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
  });

  testWidgets('file cards preserve bounded bracket and newline filenames', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await channel.sendText(
      'Inspect this.',
      textAttachment: 'contents',
      attachmentName: 'purple ] plan\nfinal.md',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('hermes-message-attachment-purple ] plan final.md'),
      ),
      findsOneWidget,
    );
    expect(find.text('purple ] plan final.md'), findsOneWidget);
    expect(find.textContaining('[File:'), findsNothing);
  });

  testWidgets('marker-like prose remains ordinary message text', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn(
      '[File: first]\n\nordinary prose\n\n[File: actual.txt]',
    );
    channel.completeStreamingTurn(text: 'Literal markers stay literal.');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-message-attachment-actual.txt')),
      findsNothing,
    );
    expect(find.textContaining('ordinary prose'), findsOneWidget);
    expect(find.textContaining('[File: actual.txt]'), findsOneWidget);
  });

  testWidgets(
    'tool activity is contextualized without exposing commands or host results',
    (tester) async {
      final channel = FakeHermesChannel();
      channel.addToolCallTurn(
        const HermesToolCall(
          name: 'search_files',
          status: 'completed',
          preview: 'Search AGENTS.md before running piper',
          result: 'Created /tmp/sidon_audio_reply.wav',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: _localizedApp(const HermesChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('File activity'), findsOneWidget);
      expect(find.text('Completed on Hermes host'), findsOneWidget);
      expect(find.textContaining('search_files'), findsNothing);
      expect(find.textContaining('AGENTS.md'), findsNothing);
      expect(find.textContaining('/tmp/sidon_audio_reply.wav'), findsNothing);
    },
  );

  testWidgets('leaked tool payload stays out of message and clipboard', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(
      text:
          'Safe intro.\n<some_tool>{"command":"raw-command-value"}'
          '</some_tool>\nSafe outro.',
    );
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

    expect(find.textContaining('Safe intro.'), findsOneWidget);
    expect(find.textContaining('Safe outro.'), findsOneWidget);
    expect(find.textContaining('raw-command-value'), findsNothing);
    expect(find.textContaining('some_tool'), findsNothing);

    await tester.longPress(find.byKey(ValueKey('hermes-turn-$assistantId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    expect(copiedText, 'Safe intro.\n[tool activity hidden]\nSafe outro.');

    await tester.tap(
      find.byKey(const ValueKey('hermes-copy-transcript-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy as text'));
    await tester.pumpAndSettle();

    expect(
      copiedText,
      'You:\nQuestion\n\nHermes:\nSafe intro.\n'
      '[tool activity hidden]\nSafe outro.',
    );
  });

  testWidgets('running host activity is announced as live status', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final channel = FakeHermesChannel();
    channel.addToolCallTurn(
      const HermesToolCall(
        name: 'run_shell',
        status: 'running',
        preview: 'cat /home/operator/private/secret.txt',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final status = tester.getSemantics(
      find.byKey(const ValueKey('hermes-tool-activity-status-tool-0')),
    );
    expect(status.label, 'Working on Hermes host');
    expect(status.flagsCollection.isLiveRegion, isTrue);
    expect(find.textContaining('run_shell'), findsNothing);
    expect(find.textContaining('secret.txt'), findsNothing);
    semantics.dispose();
  });

  testWidgets('grouped host activity expands to safe per-step statuses', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.addToolCallTurn(
      const HermesToolCall(
        name: 'search_files',
        status: 'completed',
        preview: 'Search /home/operator/private',
        result: 'Found secret.txt',
      ),
    );
    channel.addToolCallTurn(
      const HermesToolCall(
        name: 'run_shell',
        status: 'failed',
        preview: 'cat /home/operator/private/secret.txt',
        result: 'permission denied',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hermes host activity · 2 steps'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-tool-activity-step-1')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-tool-activity-tool-0')));
    await tester.pumpAndSettle();

    expect(find.text('File activity'), findsOneWidget);
    expect(find.text('Code activity'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('hermes-tool-activity-step-1')),
        matching: find.text('Completed on Hermes host'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('hermes-tool-activity-step-2')),
        matching: find.text('Host action needs attention'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('search_files'), findsNothing);
    expect(find.textContaining('run_shell'), findsNothing);
    expect(find.textContaining('secret.txt'), findsNothing);
  });

  testWidgets('tool cards expose only allowlisted activity categories', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final channel = FakeHermesChannel();
    channel.addToolCallTurn(
      const HermesToolCall(
        name: 'web_search',
        status: 'completed',
        preview: 'Authorization: Bearer secret-sentinel',
        result: '/home/alice/private-result.txt',
      ),
    );
    channel.addToolCallTurn(
      const HermesToolCall(
        name: 'Bearer secret-sentinel /home/alice/private-tool',
        status: 'failed',
        preview: 'credential=secret-sentinel',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-tool-activity-tool-0')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('hermes-tool-activity-step-1')),
        matching: find.text('Web activity'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('hermes-tool-activity-step-2')),
        matching: find.text('Host step 2'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('web_search'), findsNothing);
    expect(find.textContaining('secret-sentinel'), findsNothing);
    expect(find.textContaining('/home/alice'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp(r'web_search|secret-sentinel|/home/alice')),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('tool calls separated only by a hidden empty turn stay grouped', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.addToolCallTurn(
      const HermesToolCall(name: 'search_files', status: 'completed'),
    );
    channel.addEmptyCompletedAssistantTurn();
    channel.addToolCallTurn(
      const HermesToolCall(name: 'run_shell', status: 'completed'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hermes host activity · 2 steps'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-tool-activity-tool-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-tool-activity-tool-2')),
      findsNothing,
    );
  });

  testWidgets(
    'host-local audio output is marked not delivered and its path is hidden',
    (tester) async {
      final channel = FakeHermesChannel();
      channel.beginStreamingTurn('Create an audio reply.');
      channel.completeStreamingTurn(
        text: 'Audio reply created at /tmp/sidon_audio_reply.wav.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: _localizedApp(const HermesChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('/tmp/sidon_audio_reply.wav'), findsNothing);
      expect(
        find.byKey(const ValueKey('hermes-undelivered-local-artifact')),
        findsOneWidget,
      );
      expect(find.text('Not delivered to this device'), findsOneWidget);
      expect(
        find.textContaining('did not receive a playable audio attachment'),
        findsOneWidget,
      );
    },
  );

  testWidgets('windows host audio is marked as undelivered', (tester) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Create an audio reply.');
    channel.completeStreamingTurn(
      text: r'Audio created at C:\Users\operator\voice reply.wav.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(r'C:\Users\operator'), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-undelivered-local-artifact')),
      findsOneWidget,
    );
    expect(
      find.textContaining('did not receive a playable audio attachment'),
      findsOneWidget,
    );
  });

  testWidgets('MEDIA tokens become a safe undelivered artifact notice', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Create a preview.');
    channel.completeStreamingTurn(
      text:
          'Preview created.\nMEDIA:"/home/operator/My Preview.png"\n'
          'Ask if you need anything else.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('MEDIA:'), findsNothing);
    expect(find.textContaining('/home/operator'), findsNothing);
    expect(find.textContaining('[media not delivered]'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-undelivered-local-artifact')),
      findsOneWidget,
    );
    expect(
      find.textContaining('did not receive an attachment'),
      findsOneWidget,
    );
  });

  testWidgets('labelled host files show undelivered attachment guidance', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Create a report.');
    channel.completeStreamingTurn(
      text: 'Report ready.\nSaved to: `/tmp/final report.pdf`',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('/tmp/'), findsNothing);
    expect(find.textContaining('final report.pdf'), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-undelivered-local-artifact')),
      findsOneWidget,
    );
    expect(find.textContaining('created a file on its host'), findsOneWidget);
  });

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

  testWidgets('wide assistant runs show one shared avatar', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Reason and use a tool.');
    channel.addReasoningTurn('Inspect the available evidence.');
    channel.completeStreamingTurn(text: 'Evidence reviewed.');
    channel.addToolCallTurn(
      const HermesToolCall(name: 'search_files', status: 'completed'),
    );
    channel.beginStreamingTurn('Start a separate request.');
    channel.completeStreamingTurn(text: 'Separate answer.');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-assistant-avatar')),
      findsNWidgets(2),
    );
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

    expect(
      find.text('Latest Hermes run · 12 input · 7 output · 19 total'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Latest Hermes run token usage: 12 input, 7 output, 19 total. '
        'Input can include instructions, conversation context, and tool results; '
        'this is not a billing estimate.',
      ),
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
    expect(
      find.text('Latest Hermes run · 1200 input · 700 output · 1900 total'),
      findsOneWidget,
    );
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

  testWidgets(
    'streaming preserves manual history position until the user sends',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      for (var index = 0; index < 24; index++) {
        await channel.sendText(
          'History message $index with enough detail to fill the transcript.',
        );
      }
      channel.beginStreamingTurn('Current request');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: _localizedApp(const HermesChatScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final transcript = find.byKey(const ValueKey('hermes-transcript'));
      final scrollable = find.descendant(
        of: transcript,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      await tester.drag(transcript, const Offset(0, 600));
      await tester.pump(const Duration(milliseconds: 500));
      expect(position.pixels, greaterThan(160));

      channel.appendStreamingTurnText('Streaming update.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        position.pixels,
        greaterThan(160),
        reason: 'streaming must not pull readers away from older messages',
      );

      channel.completeStreamingTurn(text: 'Current answer');
      await tester.pumpAndSettle();
      final composer = find.byKey(const ValueKey('hermes-composer-field'));
      await tester.enterText(composer, 'New question');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      await tester.pumpAndSettle();

      expect(
        position.pixels,
        closeTo(position.minScrollExtent, 1),
        reason: 'a new user turn should re-engage transcript following',
      );
    },
  );

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

  testWidgets('message timestamps expose their full local date and time', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn(
      'Question',
      createdAt: DateTime(2024, 1, 2, 15, 4),
    );
    channel.completeStreamingTurn(text: 'Answer');
    final assistantId = channel.state.activeMessages.last.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final timestamp = find.byKey(
      ValueKey('hermes-turn-timestamp-$assistantId'),
    );
    expect(timestamp, findsOneWidget);
    final semantics = tester.getSemantics(timestamp);
    expect(semantics.label, contains('2024'));
    expect(semantics.label, contains('3:04 PM'));
    final tooltip = tester.widget<Tooltip>(
      find.descendant(of: timestamp, matching: find.byType(Tooltip)),
    );
    expect(tooltip.message, semantics.label);
  });

  testWidgets('message timestamps show relative age with absolute details', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn(
      'Question',
      createdAt: DateTime.now().subtract(
        const Duration(minutes: 2, seconds: 5),
      ),
    );
    channel.completeStreamingTurn(text: 'Answer');
    final assistantId = channel.state.activeMessages.last.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final timestamp = find.byKey(
      ValueKey('hermes-turn-timestamp-$assistantId'),
    );
    expect(
      find.descendant(of: timestamp, matching: find.text('2 minutes ago')),
      findsOneWidget,
    );
    final semantics = tester.getSemantics(timestamp);
    expect(semantics.label, contains(DateTime.now().year.toString()));
    final tooltip = tester.widget<Tooltip>(
      find.descendant(of: timestamp, matching: find.byType(Tooltip)),
    );
    expect(tooltip.message, semantics.label);
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
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesTextToSpeechServiceProvider.overrideWithValue(null),
        ],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final bubble = find.byKey(ValueKey('hermes-turn-$assistantId'));
    await tester.longPress(bubble);
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Read aloud'), findsNothing);

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

  testWidgets('reply waits until the assistant turn is complete', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.appendStreamingTurnText('Partial answer');
    final assistantId = channel.state.activeMessages.last.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pump();

    final bubble = find.byKey(ValueKey('hermes-turn-$assistantId'));
    await tester.longPress(bubble);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Copy'), findsNothing);
    expect(find.text('Reply'), findsNothing);
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();

    channel.completeStreamingTurn(text: 'Complete answer');
    await tester.pumpAndSettle();
    await tester.longPress(bubble);
    await tester.pumpAndSettle();

    expect(find.text('Reply'), findsOneWidget);
  });

  testWidgets('read aloud waits until the assistant reply is complete', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.appendStreamingTurnText('Partial answer');
    final assistantId = channel.state.activeMessages.last.id;
    final tts = FakeTextToSpeechService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesTextToSpeechServiceProvider.overrideWithValue(tts),
        ],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pump();

    final bubble = find.byKey(ValueKey('hermes-turn-$assistantId'));
    await tester.longPress(bubble);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Read aloud'), findsNothing);
    expect(find.text('Copy'), findsNothing);

    channel.completeStreamingTurn(text: 'Complete answer');
    await tester.pumpAndSettle();
    await tester.longPress(bubble);
    await tester.pumpAndSettle();

    expect(find.text('Read aloud'), findsOneWidget);
  });

  testWidgets('assistant actions read a reply aloud when TTS is available', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer to hear');
    final assistantId = channel.state.activeMessages.last.id;
    final tts = FakeTextToSpeechService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesTextToSpeechServiceProvider.overrideWithValue(tts),
        ],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(ValueKey('hermes-turn-$assistantId')));
    await tester.pumpAndSettle();
    expect(find.text('Read aloud'), findsOneWidget);

    await tester.tap(find.text('Read aloud'));
    await tester.pumpAndSettle();

    expect(tts.spoken, ['Answer to hear']);
    expect(channel.state.voiceRuns, isEmpty);
  });

  testWidgets('read-aloud reply shows and operates its stop control', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer in progress');
    final assistantId = channel.state.activeMessages.last.id;
    final tts = _BlockingTextToSpeechService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesTextToSpeechServiceProvider.overrideWithValue(tts),
        ],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(ValueKey('hermes-turn-$assistantId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read aloud'));
    await tester.pump();

    expect(find.text('Reading aloud'), findsOneWidget);
    final stop = find.byKey(ValueKey('hermes-stop-read-aloud-$assistantId'));
    expect(stop, findsOneWidget);
    expect(find.byTooltip('Stop reading aloud'), findsOneWidget);

    await tester.tap(stop);
    await tester.pumpAndSettle();

    expect(tts.stopCalls, 1);
    expect(find.text('Reading aloud'), findsNothing);
  });

  testWidgets('desktop copy waits for a stable assistant reply', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.appendStreamingTurnText('Partial answer');
    final userId = channel.state.activeMessages.first.id;
    final assistantId = channel.state.activeMessages.last.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(ValueKey('hermes-copy-message-$userId')), findsOneWidget);
    expect(
      find.byKey(ValueKey('hermes-copy-message-$assistantId')),
      findsNothing,
    );
    await tester.tapAt(
      tester.getCenter(find.byKey(ValueKey('hermes-turn-$assistantId'))),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.byKey(const ValueKey('hermes-context-copy-message')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('hermes-context-copy-chat-text')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(4, 4));
    await tester.pump(const Duration(seconds: 1));

    channel.completeStreamingTurn(text: 'Complete answer');
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('hermes-copy-message-$assistantId')),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop message bubbles expose a direct copy action', (
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

    final copy = find.byKey(ValueKey('hermes-copy-message-$assistantId'));
    expect(copy, findsOneWidget);
    expect(find.byTooltip('Copy'), findsNWidgets(2));

    await tester.tap(copy);
    await tester.pumpAndSettle();

    expect(copiedText, 'Answer with **Markdown**.');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop transcript supports partial text selection', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question to select');
    channel.completeStreamingTurn(text: 'Answer excerpt to select');
    final userId = channel.state.activeMessages.first.id;
    final assistantId = channel.state.activeMessages.last.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(ValueKey('hermes-turn-$userId')),
        matching: find.byType(SelectionArea),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey('hermes-turn-$assistantId')),
        matching: find.byType(SelectionArea),
      ),
      findsOneWidget,
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final mobileUserBubble = find.byKey(ValueKey('hermes-turn-$userId'));
    expect(
      find.descendant(
        of: mobileUserBubble,
        matching: find.byType(SelectionArea),
      ),
      findsNothing,
    );
    await tester.longPress(mobileUserBubble);
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
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
      find.byKey(ValueKey('hermes-copy-message-$assistantId')),
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

  testWidgets('copies attachment-only turns in both transcript formats', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn(
      '',
      attachment: const HermesTurnAttachment(
        name: 'photo.png',
        kind: HermesAttachmentKind.image,
      ),
    );
    channel.completeStreamingTurn(text: 'Received.');
    // Attachment terminology must come from AppLocalizations for UI,
    // semantics, and transcript export.
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
    final strings = AppLocalizations.of(
      tester.element(find.byType(HermesChatScreen)),
    );
    expect(
      strings.chatImageAttachmentLabel('photo.png'),
      'Image attachment: photo.png',
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                strings.chatImageAttachmentLabel('photo.png'),
      ),
      findsOneWidget,
    );
    expect(find.text(strings.chatImageAttachmentTypeLabel), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('hermes-copy-transcript-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy as Markdown'));
    await tester.pumpAndSettle();
    expect(copiedText, contains(strings.chatImageAttachmentLabel('photo.png')));

    await tester.tap(
      find.byKey(const ValueKey('hermes-copy-transcript-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy as text'));
    await tester.pumpAndSettle();
    expect(copiedText, contains('Image attachment: photo.png'));
    semantics.dispose();
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
    expect(copiedText, contains('Session input tokens: 1200'));
    expect(copiedText, contains('Session output tokens: 300'));
    expect(copiedText, contains('Session cache read tokens: 800'));
    expect(copiedText, contains('Session cache write tokens: 50'));
    expect(copiedText, contains('Session reasoning tokens: 25'));
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
      text: 'Answer from /tmp/sidon_audio_reply.wav',
      usage: const HermesRunUsage(
        inputTokens: 12,
        outputTokens: 7,
        totalTokens: 19,
      ),
    );
    channel.addReasoningTurn('Checked constraints.');
    channel.addToolCallTurn(
      const HermesToolCall(
        name: 'piper',
        status: 'completed',
        result: 'Created /tmp/sidon_audio_reply.wav',
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
      'You:\nQuestion\n\nHermes:\nAnswer from [redacted-path]\nLatest Hermes run usage: 12 input · 7 output · 19 total tokens\n\nReasoning:\nChecked constraints.\n\nHermes host activity\nCompleted on Hermes host',
    );
    expect(copiedText, isNot(contains('piper')));
    expect(copiedText, isNot(contains('/tmp/sidon_audio_reply.wav')));
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

  testWidgets('failed direct image retry preserves the attachment payload', (
    tester,
  ) async {
    var attempts = 0;
    final channel = FakeHermesChannel(
      sendTextGate: () async {
        attempts += 1;
        if (attempts == 1) throw StateError('temporary send failure');
      },
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    composer.contentInsertionConfiguration!.onContentInserted(
      KeyboardInsertedContent(
        mimeType: 'image/png',
        uri: 'content://keyboard/retry-image',
        data: Uint8List.fromList([
          0x89,
          0x50,
          0x4e,
          0x47,
          0x0d,
          0x0a,
          0x1a,
          0x0a,
          0x00,
        ]),
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'Inspect this image',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-chat-error-retry')),
      findsOneWidget,
    );
    final originalPayload = channel.sentImageDataUrls.single;
    expect(originalPayload, isNotNull);

    await tester.tap(find.byKey(const ValueKey('hermes-chat-error-retry')));
    await tester.pumpAndSettle();

    expect(channel.sentImageDataUrls, hasLength(2));
    expect(channel.sentImageDataUrls.last, originalPayload);
    expect(find.byKey(const ValueKey('hermes-chat-error-retry')), findsNothing);
  });

  testWidgets('failed direct attachment-only turn remains retryable', (
    tester,
  ) async {
    var attempts = 0;
    final channel = FakeHermesChannel(
      sendTextGate: () async {
        attempts += 1;
        if (attempts == 1) throw StateError('temporary send failure');
      },
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    composer.contentInsertionConfiguration!.onContentInserted(
      KeyboardInsertedContent(
        mimeType: 'image/png',
        uri: 'content://keyboard/retry-image-only',
        data: Uint8List.fromList([
          0x89,
          0x50,
          0x4e,
          0x47,
          0x0d,
          0x0a,
          0x1a,
          0x0a,
          0x00,
        ]),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-chat-error-retry')),
      findsOneWidget,
    );
    final originalPayload = channel.sentImageDataUrls.single;
    await tester.tap(find.byKey(const ValueKey('hermes-chat-error-retry')));
    await tester.pumpAndSettle();

    expect(channel.sentImageDataUrls, hasLength(2));
    expect(channel.sentImageDataUrls.last, originalPayload);
  });

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

  testWidgets('active run recovery does not claim transport is unavailable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel(
      hasUnreconciledRun: true,
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
      find.text(
        'Hermes did not advertise a supported chat transport for this endpoint.',
      ),
      findsNothing,
    );
    expect(find.text('Transport unavailable'), findsNothing);
    final strings = AppLocalizations.of(
      tester.element(find.byType(HermesChatScreen)),
    );
    expect(
      find.text(strings.chatLayoutComposerRunRecoveryHint),
      findsOneWidget,
    );
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

  testWidgets('inline API transcript images render without network access', (
    tester,
  ) async {
    const onePixelPng =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

    await tester.pumpWidget(
      _localizedApp(
        const Scaffold(
          body: HermesRichText(
            '![Generated screenshot](data:image/png;base64,$onePixelPng)',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('image not loaded'), findsNothing);
  });

  testWidgets('inline transcript images share a decoded-pixel budget', (
    tester,
  ) async {
    const image =
        '![pixel](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=)';
    await tester.pumpWidget(
      _localizedApp(
        const Scaffold(
          body: HermesRichText(
            '$image\n\n$image\n\n$image',
            inlineImagePixelBudget: 2,
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsNWidgets(2));
    expect(find.text('pixel (image not loaded)'), findsOneWidget);
  });

  testWidgets('inline transcript images require matching image bytes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        const Scaffold(
          body: HermesRichText(
            '![Untrusted image](data:image/png;base64,SGVybWVzIFdpbmc=)',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.text('Untrusted image (image not loaded)'), findsOneWidget);
  });

  testWidgets('inline transcript images reject extreme dimensions', (
    tester,
  ) async {
    final data = base64Encode(_pngHeader(width: 9000, height: 1));

    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: HermesRichText(
            '![Oversized image](data:image/png;base64,$data)',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.text('Oversized image (image not loaded)'), findsOneWidget);
  });

  testWidgets('inline transcript images reject excessive decoded pixels', (
    tester,
  ) async {
    final data = base64Encode(_pngHeader(width: 5000, height: 5000));

    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: HermesRichText(
            '![Pixel-heavy image](data:image/png;base64,$data)',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.text('Pixel-heavy image (image not loaded)'), findsOneWidget);
  });

  testWidgets('inline transcript images reject excessive animation frames', (
    tester,
  ) async {
    final data = base64Encode(_animatedGif(frameCount: 61));

    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: HermesRichText(
            '![Busy animation](data:image/gif;base64,$data)',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.text('Busy animation (image not loaded)'), findsOneWidget);
  });

  testWidgets('inline transcript images expose their alt text to semantics', (
    tester,
  ) async {
    const onePixelPng =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _localizedApp(
        const Scaffold(
          body: HermesRichText(
            '![Generated screenshot](data:image/png;base64,$onePixelPng)',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Generated screenshot'), findsOneWidget);
    semantics.dispose();
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

  testWidgets('assistant HTTPS paths containing host-root names stay intact', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Show the setup guide.');
    channel.completeStreamingTurn(text: 'Docs: https://example.test/etc/setup');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('https://example.test/etc/setup', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('[redacted-path]'), findsNothing);
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

final class _BlockingTextToSpeechService implements TextToSpeechService {
  final _completion = Completer<void>();
  int stopCalls = 0;

  @override
  Future<void> speak(String text) => _completion.future;

  @override
  Future<void> stop() async {
    stopCalls += 1;
    if (!_completion.isCompleted) _completion.complete();
  }

  @override
  Future<void> dispose() => stop();
}

Uint8List _pngHeader({required int width, required int height}) {
  final bytes = Uint8List(24);
  bytes.setAll(0, const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  bytes.setAll(8, const [0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52]);
  final data = ByteData.sublistView(bytes);
  data.setUint32(16, width);
  data.setUint32(20, height);
  return bytes;
}

Uint8List _animatedGif({required int frameCount}) {
  final bytes = <int>[...ascii.encode('GIF89a'), 1, 0, 1, 0, 0, 0, 0];
  for (var index = 0; index < frameCount; index++) {
    bytes.addAll(const [0x2c, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 1, 0, 0]);
  }
  bytes.add(0x3b);
  return Uint8List.fromList(bytes);
}
