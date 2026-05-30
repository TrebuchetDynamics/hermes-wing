import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_surface_frame.dart';

void main() {
  testWidgets(
    'auto-scrolls to the latest Transcript surface message on mount',
    (tester) async {
      await tester.pumpWidget(_FrameHost(messages: _messages(40)));
      await tester.pumpAndSettle();

      final position = _threadScrollPosition(tester);

      expect(position.pixels, position.maxScrollExtent);
      expect(find.text('message 39'), findsOneWidget);
    },
  );

  testWidgets(
    'auto-scrolls when a new Transcript surface message is appended',
    (tester) async {
      await tester.pumpWidget(const _UpdatingFrameHost());
      await tester.pumpAndSettle();

      final initialPosition = _threadScrollPosition(tester);
      final initialMaxScrollExtent = initialPosition.maxScrollExtent;

      await tester.tap(find.text('Append message'));
      await tester.pumpAndSettle();

      final updatedPosition = _threadScrollPosition(tester);

      expect(
        updatedPosition.maxScrollExtent,
        greaterThan(initialMaxScrollExtent),
      );
      expect(updatedPosition.pixels, updatedPosition.maxScrollExtent);
      expect(find.text('message 30'), findsOneWidget);
    },
  );

  testWidgets('shows a Telegram-style jump-to-latest button when scrolled up', (
    tester,
  ) async {
    await tester.pumpWidget(_FrameHost(messages: _messages(60)));
    await tester.pumpAndSettle();

    final position = _threadScrollPosition(tester);
    expect(position.pixels, position.maxScrollExtent);
    expect(
      find.byKey(const ValueKey('transcript-jump-to-bottom')),
      findsNothing,
    );

    position.jumpTo(position.maxScrollExtent - 240);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('transcript-jump-to-bottom')),
      findsOneWidget,
    );
    expect(find.byTooltip('Jump to latest message'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('transcript-jump-to-bottom')));
    await tester.pumpAndSettle();

    expect(position.pixels, position.maxScrollExtent);
    expect(
      find.byKey(const ValueKey('transcript-jump-to-bottom')),
      findsNothing,
    );
  });

  testWidgets(
    'keeps reader position and badges new messages when scrolled up',
    (tester) async {
      await tester.pumpWidget(const _UpdatingFrameHost());
      await tester.pumpAndSettle();

      final position = _threadScrollPosition(tester);
      position.jumpTo(position.maxScrollExtent - 240);
      await tester.pump();
      final readerPosition = position.pixels;

      await tester.tap(find.text('Append message'));
      await tester.pumpAndSettle();

      final updatedPosition = _threadScrollPosition(tester);
      expect(updatedPosition.pixels, readerPosition);
      expect(updatedPosition.pixels, lessThan(updatedPosition.maxScrollExtent));
      expect(
        find.byKey(const ValueKey('transcript-jump-to-bottom')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('transcript-jump-to-bottom-badge')),
        findsOneWidget,
      );
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('transcript-jump-to-bottom')));
      await tester.pumpAndSettle();

      expect(updatedPosition.pixels, updatedPosition.maxScrollExtent);
      expect(
        find.byKey(const ValueKey('transcript-jump-to-bottom-badge')),
        findsNothing,
      );
    },
  );

  testWidgets('owns composer controller lifecycle and sends typed text', (
    tester,
  ) async {
    final sent = <String>[];

    await tester.pumpWidget(_FrameHost(messages: const [], onSend: sent.add));

    await tester.enterText(find.byType(TextField), 'hello from frame');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(sent, ['hello from frame']);
    expect(find.text('hello from frame'), findsNothing);
  });
}

class _FrameHost extends StatelessWidget {
  const _FrameHost({required this.messages, this.onSend});

  final List<NavivoxChatMessage> messages;
  final ValueChanged<String>? onSend;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 360,
          child: TranscriptSurfaceFrame(
            messages: messages,
            onSend: onSend ?? (_) {},
          ),
        ),
      ),
    );
  }
}

class _UpdatingFrameHost extends StatefulWidget {
  const _UpdatingFrameHost();

  @override
  State<_UpdatingFrameHost> createState() => _UpdatingFrameHostState();
}

class _UpdatingFrameHostState extends State<_UpdatingFrameHost> {
  var count = 30;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () => setState(() => count += 1),
              child: const Text('Append message'),
            ),
            Expanded(
              child: TranscriptSurfaceFrame(
                messages: _messages(count),
                onSend: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

ScrollPosition _threadScrollPosition(WidgetTester tester) {
  final scrollables = find
      .byType(Scrollable)
      .evaluate()
      .map((element) => (element as StatefulElement).state)
      .whereType<ScrollableState>()
      .where(
        (state) =>
            state.position.hasContentDimensions &&
            state.position.maxScrollExtent > 0,
      )
      .toList();

  expect(scrollables, hasLength(1));
  return scrollables.single.position;
}

List<NavivoxChatMessage> _messages(int count) {
  return [
    for (var index = 0; index < count; index += 1)
      NavivoxChatMessage(
        id: 'message-$index',
        author: index.isEven
            ? NavivoxMessageAuthor.user
            : NavivoxMessageAuthor.assistant,
        kind: NavivoxMessageKind.text,
        createdAt: DateTime.utc(2026, 5, 23, 12, index),
        text: 'message $index',
      ),
  ];
}
