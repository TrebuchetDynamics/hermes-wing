import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../shared/transcript_attachment_test_helpers.dart';
import '../shared/transcript_controller_test_helpers.dart';
import '../shared/transcript_voice_recovery_test_helpers.dart';
import '../shared/transcript_widget_test_app.dart';

void main() {
  testWidgets('sends typed text and inserts quick emoji', (tester) async {
    final sent = <String>[];
    final controller = transcriptTextController(text: 'hello');

    await tester.pumpWidget(
      transcriptComposerTestApp(controller: controller, onSend: sent.add),
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

  testWidgets('opens and plugs the shared attachment sheet', (tester) async {
    final controller = transcriptTextController();
    final attachmentActions = TranscriptAttachmentActions();

    await tester.pumpWidget(
      transcriptComposerTestApp(
        controller: controller,
        onSend: transcriptNoopSend,
        onUploadFile: attachmentActions.uploadFile,
        onPickPhotoOrVideo: attachmentActions.pickPhotoOrVideo,
        onOpenWorkspace: attachmentActions.openWorkspace,
      ),
    );

    await expectTranscriptAttachmentSheetActions(tester, attachmentActions);
  });

  testWidgets('unplugged attachment rows explain unavailable upload support', (
    tester,
  ) async {
    final controller = transcriptTextController();

    await tester.pumpWidget(
      transcriptComposerTestApp(
        controller: controller,
        onSend: transcriptNoopSend,
      ),
    );

    await tester.tap(find.byTooltip('Attach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload file'));
    await tester.pumpAndSettle();

    expect(find.text('File upload unavailable'), findsOneWidget);
    expect(find.textContaining('upload endpoint'), findsOneWidget);
  });

  testWidgets('explains unavailable voice and opens voice settings', (
    tester,
  ) async {
    final controller = transcriptTextController();
    var openedSettings = false;

    await tester.pumpWidget(
      transcriptComposerTestApp(
        controller: controller,
        onSend: transcriptNoopSend,
        voiceUnavailableReason: rawDeviceSttUnavailableReason,
        voiceRecoveryAction: deviceSttRecoveryAction,
        onOpenVoiceSettings: () => openedSettings = true,
      ),
    );

    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expectVoiceUnavailableTooltip(deviceSttUnavailableReason);

    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pumpAndSettle();

    expectVoiceUnavailableSheetTitle();
    expectCanonicalDeviceSttRecoverySheet();
    expect(find.text('Recovery action'), findsOneWidget);
    expect(find.text(deviceSttRecoveryAction), findsOneWidget);
    expect(find.text('Open voice settings'), findsOneWidget);

    await tester.tap(find.text('Open voice settings'));
    await tester.pumpAndSettle();

    expect(openedSettings, isTrue);
  });

  testWidgets('shows capture and stop states through the same toggle intent', (
    tester,
  ) async {
    final controller = transcriptTextController();
    var toggles = 0;

    await tester.pumpWidget(
      transcriptComposerTestApp(
        controller: controller,
        onSend: transcriptNoopSend,
        voiceCaptureAvailable: true,
        onToggleVoice: () => toggles += 1,
      ),
    );

    expect(find.byIcon(Icons.mic), findsOneWidget);
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    expect(toggles, 1);

    await tester.pumpWidget(
      transcriptComposerTestApp(
        controller: controller,
        onSend: transcriptNoopSend,
        voiceCaptureAvailable: true,
        capturing: true,
        onToggleVoice: () => toggles += 1,
      ),
    );

    expect(find.byIcon(Icons.stop), findsOneWidget);
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    expect(toggles, 2);
  });
}
