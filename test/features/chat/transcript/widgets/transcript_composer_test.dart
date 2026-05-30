import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_composer.dart';

void main() {
  testWidgets('sends typed text and inserts quick emoji', (tester) async {
    final sent = <String>[];
    final controller = TextEditingController(text: 'hello');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _ComposerHost(controller: controller, onSend: sent.add),
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
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var uploadedFile = false;
    var pickedMedia = false;
    var openedWorkspace = false;

    await tester.pumpWidget(
      _ComposerHost(
        controller: controller,
        onSend: (_) {},
        onUploadFile: () => uploadedFile = true,
        onPickPhotoOrVideo: () => pickedMedia = true,
        onOpenWorkspace: () => openedWorkspace = true,
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

  testWidgets('unplugged attachment rows explain unavailable upload support', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _ComposerHost(controller: controller, onSend: (_) {}),
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
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var openedSettings = false;

    await tester.pumpWidget(
      _ComposerHost(
        controller: controller,
        onSend: (_) {},
        voiceUnavailableReason: ' Device STT unavailable ',
        voiceRecoveryAction: 'Enable device speech recognition',
        onOpenVoiceSettings: () => openedSettings = true,
      ),
    );

    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expect(
      find.byTooltip('Voice unavailable: device STT unavailable'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pumpAndSettle();

    expect(find.text('Voice unavailable'), findsOneWidget);
    expect(find.text('device STT unavailable'), findsOneWidget);
    expect(find.text('Device STT unavailable'), findsNothing);
    expect(find.text('Recovery action'), findsOneWidget);
    expect(find.text('Enable device speech recognition'), findsOneWidget);
    expect(find.text('Open voice settings'), findsOneWidget);

    await tester.tap(find.text('Open voice settings'));
    await tester.pumpAndSettle();

    expect(openedSettings, isTrue);
  });

  testWidgets('shows capture and stop states through the same toggle intent', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var toggles = 0;

    await tester.pumpWidget(
      _ComposerHost(
        controller: controller,
        onSend: (_) {},
        voiceCaptureAvailable: true,
        onToggleVoice: () => toggles += 1,
      ),
    );

    expect(find.byIcon(Icons.mic), findsOneWidget);
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    expect(toggles, 1);

    await tester.pumpWidget(
      _ComposerHost(
        controller: controller,
        onSend: (_) {},
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

class _ComposerHost extends StatelessWidget {
  const _ComposerHost({
    required this.controller,
    required this.onSend,
    this.voiceCaptureAvailable = false,
    this.voiceUnavailableReason,
    this.voiceRecoveryAction,
    this.onOpenVoiceSettings,
    this.onUploadFile,
    this.onPickPhotoOrVideo,
    this.onOpenWorkspace,
    this.capturing = false,
    this.onToggleVoice,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool voiceCaptureAvailable;
  final String? voiceUnavailableReason;
  final String? voiceRecoveryAction;
  final VoidCallback? onOpenVoiceSettings;
  final VoidCallback? onUploadFile;
  final VoidCallback? onPickPhotoOrVideo;
  final VoidCallback? onOpenWorkspace;
  final bool capturing;
  final VoidCallback? onToggleVoice;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: TranscriptComposer(
          controller: controller,
          onSend: onSend,
          voiceCaptureAvailable: voiceCaptureAvailable,
          voiceUnavailableReason: voiceUnavailableReason,
          voiceRecoveryAction: voiceRecoveryAction,
          onOpenVoiceSettings: onOpenVoiceSettings,
          onUploadFile: onUploadFile,
          onPickPhotoOrVideo: onPickPhotoOrVideo,
          onOpenWorkspace: onOpenWorkspace,
          capturing: capturing,
          onToggleVoice: onToggleVoice,
        ),
      ),
    );
  }
}
