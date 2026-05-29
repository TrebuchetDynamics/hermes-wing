import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/presentation/transcript/transcript_message_action_presentation.dart';
import 'package:navivox/features/chat/widgets/transcript/transcript_message_action_sheet.dart';

const _support = NavivoxProfileContact(
  serverId: 'office',
  profileId: 'support',
  displayName: 'Support Triage',
  serverLabel: 'office',
  health: NavivoxProfileHealth.online,
  latestPreview: 'Watching tickets',
);

void main() {
  testWidgets('renders action text and invokes pause, copy, and read actions', (
    tester,
  ) async {
    final actions = <String>[];
    final presentation = TranscriptMessageActionPresentation.fromMessage(
      _textMessage('dispatch note', runRecordReference: 'run-ref-1'),
      textToSpeechAvailable: true,
      canCancelActiveTurn: true,
      runRecordInspectionAvailable: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptMessageActionSheet(
            presentation: presentation,
            onPauseStream: () async => actions.add('pause'),
            onCopyText: () async => actions.add('copy:${presentation.text}'),
            onReadAloud: () async => actions.add('read:${presentation.text}'),
            onInspectRunRecord: () async => actions.add('inspect'),
          ),
        ),
      ),
    );

    expect(find.text('Message actions'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('dispatch note'), findsOneWidget);
    expect(find.text('Pause stream'), findsOneWidget);
    expect(find.text('Stop the current assistant response.'), findsOneWidget);
    expect(find.text('Copy text'), findsOneWidget);
    expect(find.text('Read aloud'), findsOneWidget);
    expect(find.text('View evidence'), findsOneWidget);
    expect(
      find.text(
        'Show redacted transcript, voice, tool, usage, and cost evidence.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Pause stream'));
    await tester.tap(find.text('Copy text'));
    await tester.tap(find.text('Read aloud'));
    await tester.tap(find.text('View evidence'));
    await tester.pumpAndSettle();

    expect(actions, [
      'pause',
      'copy:dispatch note',
      'read:dispatch note',
      'inspect',
    ]);
  });

  testWidgets('renders forward targets and invokes selected Profile contact', (
    tester,
  ) async {
    NavivoxProfileContact? forwardedTo;
    final presentation = TranscriptMessageActionPresentation.fromMessage(
      _textMessage('forward this'),
      forwardTargets: const [_support],
      forwardingAvailable: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptMessageActionSheet(
            presentation: presentation,
            onForward: (target) => forwardedTo = target,
          ),
        ),
      ),
    );

    expect(find.text('Forward to'), findsOneWidget);
    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.text('office'), findsOneWidget);

    await tester.tap(find.text('Support Triage'));
    await tester.pumpAndSettle();

    expect(forwardedTo, _support);
  });

  testWidgets('renders unavailable TTS row when text has no TTS action', (
    tester,
  ) async {
    final presentation = TranscriptMessageActionPresentation.fromMessage(
      _textMessage('silent note'),
      textToSpeechAvailable: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptMessageActionSheet(presentation: presentation),
        ),
      ),
    );

    expect(find.text('Read aloud unavailable'), findsOneWidget);
    expect(find.text('Device TTS is not connected.'), findsOneWidget);
    expect(find.text('Read aloud'), findsNothing);
  });
}

NavivoxChatMessage _textMessage(String text, {String? runRecordReference}) {
  return NavivoxChatMessage(
    id: 'text-1',
    author: NavivoxMessageAuthor.assistant,
    kind: NavivoxMessageKind.text,
    createdAt: DateTime.utc(2026, 5, 23, 11, 15),
    text: text,
    runRecordReference: runRecordReference,
  );
}
