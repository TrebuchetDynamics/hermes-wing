import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_composer_presentation.dart';

import '../../../shared/voice/voice_recovery_test_fixtures.dart';

void main() {
  test('canonicalizes device STT unavailable recovery copy', () {
    final presentation = TranscriptComposerPresentation.fromState(
      voiceCaptureAvailable: true,
      voiceUnavailableReason: rawDeviceSttUnavailableReason,
      voiceRecoveryAction: '  $androidSpeechRecognitionRecoveryAction  ',
      canOpenVoiceSettings: true,
      capturing: false,
      emojiOpen: false,
    );

    expect(
      presentation.voiceButtonState,
      TranscriptComposerVoiceButtonState.unavailable,
    );
    expect(presentation.voiceAvailable, isFalse);
    expect(presentation.voiceUnavailableReason, deviceSttUnavailableReason);
    expect(
      presentation.voiceTooltip,
      'Voice unavailable: $deviceSttUnavailableReason',
    );
    expect(presentation.voiceUnavailableTitle, deviceSttUnavailableReason);
    expect(presentation.voiceUnavailableHelpText, deviceSttRecoveryCopy);
    expect(
      presentation.voiceRecoveryAction,
      androidSpeechRecognitionRecoveryAction,
    );
    expect(presentation.showVoiceSettings, isTrue);
    expect(presentation.voiceSettingsSubtitle, deviceSttSettingsReviewCopy);
    expect(presentation.voiceSheetTitle, 'Voice unavailable');
    expect(
      presentation.voiceSheetRows.map(
        (row) =>
            '${row.kind.name}:${row.title}:${row.subtitle}:${row.actionKind?.name ?? 'none'}',
      ),
      [
        'status:$deviceSttUnavailableReason:$deviceSttRecoveryCopy:none',
        'recoveryAction:Recovery action:$androidSpeechRecognitionRecoveryAction:none',
        'openVoiceSettings:Open voice settings:$deviceSttSettingsReviewCopy:openVoiceSettings',
      ],
    );
  });

  test('derives microphone permission and generic unavailable copy', () {
    final permission = TranscriptComposerPresentation.fromState(
      voiceCaptureAvailable: true,
      voiceUnavailableReason: microphonePermissionDeniedReason,
      voiceRecoveryAction: '  ',
      canOpenVoiceSettings: true,
      capturing: false,
      emojiOpen: false,
    );
    final generic = TranscriptComposerPresentation.fromState(
      voiceCaptureAvailable: false,
      voiceUnavailableReason: 'select a profile contact',
      voiceRecoveryAction: null,
      canOpenVoiceSettings: false,
      capturing: false,
      emojiOpen: false,
    );

    expect(permission.voiceUnavailableTitle, microphonePermissionDeniedReason);
    expect(
      permission.voiceUnavailableHelpText,
      microphonePermissionRecoveryCopy,
    );
    expect(permission.voiceRecoveryAction, isNull);
    expect(
      permission.voiceSettingsSubtitle,
      microphonePermissionSettingsReviewCopy,
    );
    expect(generic.voiceUnavailableTitle, 'select a profile contact');
    expect(
      generic.voiceUnavailableHelpText,
      'Select a profile contact before using continuous voice.',
    );
    expect(
      generic.voiceSettingsSubtitle,
      'Select a profile contact before reviewing continuous voice settings.',
    );
    expect(permission.voiceSheetRows.map((row) => row.kind), [
      TranscriptComposerVoiceSheetRowKind.status,
      TranscriptComposerVoiceSheetRowKind.openVoiceSettings,
    ]);
    expect(
      permission.voiceSheetRows.last.actionKind,
      TranscriptComposerVoiceSheetActionKind.openVoiceSettings,
    );
    expect(
      generic.voiceSheetRows.single.kind,
      TranscriptComposerVoiceSheetRowKind.status,
    );
  });

  test('derives available and capturing voice button states', () {
    final available = TranscriptComposerPresentation.fromState(
      voiceCaptureAvailable: true,
      voiceUnavailableReason: null,
      voiceRecoveryAction: null,
      canOpenVoiceSettings: false,
      capturing: false,
      emojiOpen: false,
    );
    final capturing = TranscriptComposerPresentation.fromState(
      voiceCaptureAvailable: true,
      voiceUnavailableReason: null,
      voiceRecoveryAction: null,
      canOpenVoiceSettings: false,
      capturing: true,
      emojiOpen: true,
    );

    expect(available.voiceAvailable, isTrue);
    expect(
      available.voiceButtonState,
      TranscriptComposerVoiceButtonState.capture,
    );
    expect(available.voiceTooltip, isNull);
    expect(capturing.voiceButtonState, TranscriptComposerVoiceButtonState.stop);
    expect(capturing.showEmoji, isTrue);
  });

  test('exposes stable composer copy, quick emoji, and share options', () {
    final presentation = TranscriptComposerPresentation.fromState(
      voiceCaptureAvailable: false,
      voiceUnavailableReason: null,
      voiceRecoveryAction: null,
      canOpenVoiceSettings: false,
      capturing: false,
      emojiOpen: true,
    );

    expect(presentation.messageHint, 'Message Gormes');
    expect(presentation.emojiTooltip, 'Emoji');
    expect(presentation.attachTooltip, 'Attach');
    expect(presentation.quickEmoji, ['😀', '👍', '🙏', '🔥', '✅', '👀']);
    expect(presentation.shareTitle, 'Share');
    expect(
      presentation.shareOptions.map(
        (option) => '${option.kind.name}:${option.title}:${option.subtitle}',
      ),
      [
        'uploadFile:Upload file:Attach a local file after upload support is enabled.',
        'photoOrVideo:Photo or video:Pick media after upload support is enabled.',
        'workspaceFile:Workspace file:Share a file from the active Gormes workspace.',
      ],
    );
  });
}
