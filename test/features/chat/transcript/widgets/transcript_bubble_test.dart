import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_bubble.dart';

const _support = NavivoxProfileContact(
  serverId: 'office',
  profileId: 'support',
  displayName: 'Support Triage',
  serverLabel: 'office',
  health: NavivoxProfileHealth.online,
  latestPreview: 'Watching tickets',
);

void main() {
  testWidgets('renders message text and opens assistant pause action', (
    tester,
  ) async {
    var paused = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'assistant-1',
              text: 'pause this answer',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
            onCancelActiveTurn: () => paused = true,
          ),
        ),
      ),
    );

    expect(find.text('pause this answer'), findsOneWidget);
    expect(find.text('11:15'), findsOneWidget);

    await tester.longPress(find.text('pause this answer'));
    await tester.pumpAndSettle();

    expect(find.text('Message actions'), findsOneWidget);
    expect(find.text('Pause stream'), findsOneWidget);

    await tester.tap(find.text('Pause stream'));
    await tester.pumpAndSettle();

    expect(paused, isTrue);
  });

  testWidgets('renders Telegram-style link preview for URL text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'link-1',
              text: 'Review https://docs.navivox.dev/setup?tab=android.',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('transcript-link-preview')),
      findsOneWidget,
    );
    expect(find.text('docs.navivox.dev'), findsOneWidget);
    expect(find.text('/setup?tab=android'), findsOneWidget);
  });

  testWidgets('renders Telegram-style inline text formatting', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'inline-format-1',
              text: 'Use *bold*, _italic_, `code`, and ~old~ safely.',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
          ),
        ),
      ),
    );

    final formatted = tester.widget<Text>(
      find.byKey(const ValueKey('transcript-formatted-inline-text')),
    );
    final rootSpan = formatted.textSpan!;

    expect(rootSpan.toPlainText(), 'Use bold, italic, code, and old safely.');
    expect(_spanFor(rootSpan, 'bold')?.style?.fontWeight, FontWeight.w700);
    expect(_spanFor(rootSpan, 'italic')?.style?.fontStyle, FontStyle.italic);
    expect(_spanFor(rootSpan, 'code')?.style?.fontFamily, 'monospace');
    expect(
      _spanFor(rootSpan, 'old')?.style?.decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('renders Telegram-style URL email and phone highlights', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'contact-patterns-1',
              text:
                  'Open https://navivox.dev, mail ops@navivox.dev, or call +1 555 010 1212.',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
          ),
        ),
      ),
    );

    final formatted = tester.widget<Text>(
      find.byKey(const ValueKey('transcript-formatted-inline-text')),
    );
    final rootSpan = formatted.textSpan!;

    expect(
      rootSpan.toPlainText(),
      'Open https://navivox.dev, mail ops@navivox.dev, or call +1 555 010 1212.',
    );
    expect(
      _spanFor(rootSpan, 'https://navivox.dev')?.style?.fontWeight,
      FontWeight.w700,
    );
    expect(
      _spanFor(rootSpan, 'ops@navivox.dev')?.style?.fontWeight,
      FontWeight.w700,
    );
    expect(
      _spanFor(rootSpan, '+1 555 010 1212')?.style?.fontWeight,
      FontWeight.w700,
    );
  });

  testWidgets('renders Telegram-style mention-with-id highlights', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'mention-id-1',
              text: 'Route this to [@Mineru:profile_mineru] now.',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
          ),
        ),
      ),
    );

    final formatted = tester.widget<Text>(
      find.byKey(const ValueKey('transcript-formatted-inline-text')),
    );
    final rootSpan = formatted.textSpan!;

    expect(rootSpan.toPlainText(), 'Route this to @Mineru now.');
    expect(_spanFor(rootSpan, '@Mineru')?.style?.fontWeight, FontWeight.w700);
    expect(_spanFor(rootSpan, '@Mineru')?.style?.color, isNotNull);
  });

  testWidgets('renders Telegram-style mention and hashtag highlights', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'mention-tag-1',
              text: 'Route this to @mineru for #deploy review.',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
          ),
        ),
      ),
    );

    final formatted = tester.widget<Text>(
      find.byKey(const ValueKey('transcript-formatted-inline-text')),
    );
    final rootSpan = formatted.textSpan!;

    expect(rootSpan.toPlainText(), 'Route this to @mineru for #deploy review.');
    expect(_spanFor(rootSpan, '@mineru')?.style?.fontWeight, FontWeight.w700);
    expect(_spanFor(rootSpan, '#deploy')?.style?.fontWeight, FontWeight.w700);
    expect(_spanFor(rootSpan, '@mineru')?.style?.color, isNotNull);
  });

  testWidgets('renders Telegram-style blockquotes in text bubbles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'quote-1',
              text: 'Context:\n> Keep *deployment* reversible\nNext step.',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
          ),
        ),
      ),
    );

    expect(find.text('Context:'), findsOneWidget);
    expect(find.text('Next step.'), findsOneWidget);
    expect(find.byKey(const ValueKey('transcript-blockquote')), findsOneWidget);
    final quoteText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('transcript-blockquote')),
        matching: find.byKey(
          const ValueKey('transcript-formatted-inline-text'),
        ),
      ),
    );
    final quoteSpan = quoteText.textSpan!;
    expect(quoteSpan.toPlainText(), 'Keep deployment reversible');
    expect(
      _spanFor(quoteSpan, 'deployment')?.style?.fontWeight,
      FontWeight.w700,
    );
  });

  testWidgets('renders Telegram-style bullet lists in text bubbles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'list-1',
              text: 'Checklist:\n- Back up `config`\n- Restart service\nDone.',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
          ),
        ),
      ),
    );

    expect(find.text('Checklist:'), findsOneWidget);
    expect(find.text('Done.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('transcript-bullet-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('transcript-bullet-marker')),
      findsNWidgets(2),
    );
    final listText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('transcript-bullet-list')),
        matching: find.byKey(
          const ValueKey('transcript-formatted-inline-text'),
        ),
      ),
    );
    final listSpan = listText.textSpan!;
    expect(listSpan.toPlainText(), 'Back up config');
    expect(_spanFor(listSpan, 'config')?.style?.fontFamily, 'monospace');
    expect(find.text('Restart service'), findsOneWidget);
  });

  testWidgets('renders Telegram-style numbered lists in text bubbles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'numbered-list-1',
              text: 'Plan:\n1. Back up config\n2. Restart service\nDone.',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
          ),
        ),
      ),
    );

    expect(find.text('Plan:'), findsOneWidget);
    expect(find.text('Done.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('transcript-numbered-list')),
      findsOneWidget,
    );
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('Back up config'), findsOneWidget);
    expect(find.text('Restart service'), findsOneWidget);
  });

  testWidgets('renders Telegram-style fenced code blocks in text bubbles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'code-1',
              text: "Run this:\n```dart\nprint('hi');\n```\nThen continue.",
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
          ),
        ),
      ),
    );

    expect(find.text('Run this:'), findsOneWidget);
    expect(find.text('Then continue.'), findsOneWidget);
    expect(find.byKey(const ValueKey('transcript-code-block')), findsOneWidget);
    expect(find.text('dart'), findsOneWidget);
    expect(find.text("print('hi');"), findsOneWidget);
    expect(find.byTooltip('Copy code'), findsOneWidget);

    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
  });

  testWidgets('collapses long Telegram-style text bubbles behind show more', (
    tester,
  ) async {
    final longText = List.filled(
      18,
      'Long deployment paragraph with enough details for a chat bubble.',
    ).join(' ');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TranscriptBubble(
              message: _textMessage(
                id: 'long-1',
                text: longText,
                author: NavivoxMessageAuthor.assistant,
              ),
              isUser: false,
              showTail: true,
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(longText));
    expect(text.maxLines, 8);
    expect(text.overflow, TextOverflow.fade);
    expect(find.text('Show more'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('transcript-expand-text-toggle')),
    );
    await tester.pump();

    final expandedText = tester.widget<Text>(find.text(longText));
    expect(expandedText.maxLines, isNull);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('renders Telegram-style voice waveform affordance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _voiceMessage(
              id: 'voice-wave-1',
              transcript: 'ship the voice note',
            ),
            isUser: true,
            showTail: true,
          ),
        ),
      ),
    );

    expect(find.text('Voice message'), findsOneWidget);
    expect(find.text('3s'), findsOneWidget);
    expect(find.text('ship the voice note'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('transcript-voice-waveform')),
      findsOneWidget,
    );
  });

  testWidgets('double tap toggles a local Telegram-style heart reaction', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'reaction-1',
              text: 'react locally',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('transcript-local-reaction')),
      findsNothing,
    );

    await tester.tap(find.text('react locally'));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('react locally'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('transcript-local-reaction')),
      findsOneWidget,
    );
    expect(find.text('❤️'), findsOneWidget);

    await tester.tap(find.text('react locally'));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('react locally'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('transcript-local-reaction')),
      findsNothing,
    );
  });

  testWidgets('renders Telegram-style sent tick for user messages', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptBubble(
              message: _textMessage(
                id: 'user-sent-1',
                text: 'sent text',
                author: NavivoxMessageAuthor.user,
              ),
              isUser: true,
              showTail: true,
            ),
          ),
        ),
      );

      expect(find.text('sent text'), findsOneWidget);
      expect(find.byIcon(Icons.done_all), findsOneWidget);
      expect(find.bySemanticsLabel('Sent'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('does not show pause action for user messages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'user-1',
              text: 'user text',
              author: NavivoxMessageAuthor.user,
            ),
            isUser: true,
            showTail: true,
            onCancelActiveTurn: () {},
          ),
        ),
      ),
    );

    await tester.longPress(find.text('user text'));
    await tester.pumpAndSettle();

    expect(find.text('Message actions'), findsOneWidget);
    expect(find.text('Pause stream'), findsNothing);
  });

  testWidgets('renders forward target and invokes selected Profile contact', (
    tester,
  ) async {
    NavivoxProfileContact? forwardedTo;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'forward-1',
              text: 'forward this update',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: false,
            forwardTargets: const [_support],
            onForward: (_, target) => forwardedTo = target,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('forward this update'));
    await tester.pumpAndSettle();

    expect(find.text('Forward to'), findsOneWidget);
    expect(find.text('Support Triage'), findsOneWidget);

    await tester.tap(find.text('Support Triage'));
    await tester.pumpAndSettle();

    expect(forwardedTo, _support);
  });
}

TextSpan? _spanFor(InlineSpan root, String text) {
  if (root is TextSpan) {
    if (root.text == text) return root;
    for (final child in root.children ?? const <InlineSpan>[]) {
      final match = _spanFor(child, text);
      if (match != null) return match;
    }
  }
  return null;
}

NavivoxChatMessage _textMessage({
  required String id,
  required String text,
  required NavivoxMessageAuthor author,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: NavivoxMessageKind.text,
    createdAt: DateTime.utc(2026, 5, 23, 11, 15),
    text: text,
  );
}

NavivoxChatMessage _voiceMessage({
  required String id,
  required String transcript,
}) {
  return NavivoxChatMessage(
    id: id,
    author: NavivoxMessageAuthor.user,
    kind: NavivoxMessageKind.voice,
    createdAt: DateTime.utc(2026, 5, 23, 11, 15),
    voice: NavivoxVoiceMessage(
      duration: const Duration(milliseconds: 3200),
      transcript: transcript,
      confidence: 0.86,
    ),
  );
}
