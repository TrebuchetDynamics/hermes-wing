import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import '../../shared/transcript_attachment_test_helpers.dart';
import '../../shared/transcript_surface_test_app.dart';

void main() {
  testWidgets('composer attachment button opens Telegram-style upload sheet', (
    tester,
  ) async {
    final attachmentActions = TranscriptAttachmentActions();

    await tester.pumpWidget(
      transcriptSurfaceTestApp(
        messages: const <NavivoxChatMessage>[],
        onSend: transcriptNoopSend,
        onUploadFile: attachmentActions.uploadFile,
        onPickPhotoOrVideo: attachmentActions.pickPhotoOrVideo,
        onOpenWorkspace: attachmentActions.openWorkspace,
      ),
    );

    await expectTranscriptAttachmentSheetActions(tester, attachmentActions);
  });

  testWidgets('composer emoji picker inserts emoji before sending', (
    tester,
  ) async {
    final sent = <String>[];

    await tester.pumpWidget(
      transcriptSurfaceTestApp(
        messages: const <NavivoxChatMessage>[],
        onSend: sent.add,
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Gormes'),
      'hello',
    );
    await tester.tap(find.byTooltip('Emoji'));
    await tester.pumpAndSettle();

    expect(find.text('😀'), findsOneWidget);
    expect(find.text('👍'), findsOneWidget);

    await tester.tap(find.text('😀'));
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(sent, ['hello😀']);
  });
}
