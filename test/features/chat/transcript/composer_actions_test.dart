import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/widgets/transcript/transcript_surface.dart';

void main() {
  testWidgets('composer attachment button opens Telegram-style upload sheet', (
    tester,
  ) async {
    var uploadedFile = false;
    var pickedMedia = false;
    var openedWorkspace = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: const <NavivoxChatMessage>[],
            onSend: (_) {},
            onUploadFile: () => uploadedFile = true,
            onPickPhotoOrVideo: () => pickedMedia = true,
            onOpenWorkspace: () => openedWorkspace = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Attach'));
    await tester.pumpAndSettle();

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Upload file'), findsOneWidget);
    expect(find.text('Photo or video'), findsOneWidget);
    expect(find.text('Workspace file'), findsOneWidget);

    await tester.tap(find.text('Upload file'));
    await tester.pumpAndSettle();
    expect(uploadedFile, isTrue);

    await tester.tap(find.byTooltip('Attach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo or video'));
    await tester.pumpAndSettle();
    expect(pickedMedia, isTrue);

    await tester.tap(find.byTooltip('Attach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workspace file'));
    await tester.pumpAndSettle();
    expect(openedWorkspace, isTrue);
  });

  testWidgets('composer emoji picker inserts emoji before sending', (
    tester,
  ) async {
    final sent = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: const <NavivoxChatMessage>[],
            onSend: sent.add,
          ),
        ),
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
