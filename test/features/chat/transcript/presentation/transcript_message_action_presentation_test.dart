import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_message_action_presentation.dart';

import '../shared/transcript_test_fixtures.dart';

void main() {
  test(
    'derives action text for text, voice, tool, safety, and approval messages',
    () {
      final text = TranscriptMessageActionPresentation.fromMessage(
        transcriptTextMessage(text: 'copy this'),
      );
      final voice = TranscriptMessageActionPresentation.fromMessage(
        transcriptVoiceMessage(transcript: 'captured voice'),
      );
      final tool = TranscriptMessageActionPresentation.fromMessage(
        transcriptToolMessage(
          toolCall: const NavivoxToolCall(
            name: 'grep',
            status: 'finished',
            summary: 'Matched 2 files',
          ),
        ),
      );
      final safety = TranscriptMessageActionPresentation.fromMessage(
        transcriptNoticeMessage(
          kind: NavivoxMessageKind.safetyWarning,
          notice: const NavivoxSafetyNotice(
            id: 'safety-1',
            message: 'Unsafe exposure',
            risk: 'Public gateway',
          ),
        ),
      );
      final approval = TranscriptMessageActionPresentation.fromMessage(
        transcriptNoticeMessage(
          kind: NavivoxMessageKind.approvalRequest,
          notice: const NavivoxSafetyNotice(
            id: 'approval-1',
            message: 'Approve restart?',
            risk: 'Interrupts active run',
          ),
        ),
      );

      expect(text.text, 'copy this');
      expect(voice.text, 'captured voice');
      expect(tool.text, 'grep\nfinished\nMatched 2 files');
      expect(safety.text, 'Unsafe exposure\nPublic gateway');
      expect(approval.text, 'Approve restart?\nInterrupts active run');
    },
  );

  test('exposes copy, read-aloud, unavailable TTS, and pause copy', () {
    final withTts = TranscriptMessageActionPresentation.fromMessage(
      transcriptTextMessage(text: 'read this', runRecordReference: 'run-ref-1'),
      textToSpeechAvailable: true,
      canCancelActiveTurn: true,
      runRecordInspectionAvailable: true,
    );
    final withoutTts = TranscriptMessageActionPresentation.fromMessage(
      transcriptTextMessage(text: 'read this later'),
      textToSpeechAvailable: false,
    );

    expect(withTts.title, 'Message actions');
    expect(withTts.copyLabel, 'Copy text');
    expect(withTts.copySnackbar, 'Message copied');
    expect(withTts.readAloudLabel, 'Read aloud');
    expect(withTts.readAloudSnackbar, 'Reading aloud');
    expect(withTts.canReadAloud, isTrue);
    expect(withTts.runRecordId, 'run-ref-1');
    expect(withTts.showInspectRunRecord, isTrue);
    expect(withTts.inspectRunRecordLabel, 'View evidence');
    expect(
      withTts.inspectRunRecordSubtitle,
      'Show redacted transcript, voice, tool, usage, and cost evidence.',
    );
    expect(withTts.showReadAloudUnavailable, isFalse);
    expect(withTts.pauseLabel, 'Pause stream');
    expect(withTts.pauseSubtitle, 'Stop the current assistant response.');
    expect(withTts.pauseSnackbar, 'Stream pause requested');

    expect(withoutTts.canReadAloud, isFalse);
    expect(withoutTts.showReadAloudUnavailable, isTrue);
    expect(withoutTts.readAloudUnavailableLabel, 'Read aloud unavailable');
    expect(
      withoutTts.readAloudUnavailableSubtitle,
      'Device TTS is not connected.',
    );
  });

  test('requires an explicit run record reference before showing evidence', () {
    final presentation = TranscriptMessageActionPresentation.fromMessage(
      transcriptTextMessage(text: 'ordinary message'),
      runRecordInspectionAvailable: true,
    );
    final blankReference = TranscriptMessageActionPresentation.fromMessage(
      transcriptTextMessage(
        text: 'ordinary message',
        runRecordReference: '   ',
      ),
      runRecordInspectionAvailable: true,
    );

    expect(presentation.runRecordId, isNull);
    expect(presentation.showInspectRunRecord, isFalse);
    expect(blankReference.runRecordId, isNull);
    expect(blankReference.showInspectRunRecord, isFalse);
  });

  test('exposes forward target rows when forwarding is available', () {
    final presentation = TranscriptMessageActionPresentation.fromMessage(
      transcriptTextMessage(text: 'send to someone'),
      forwardTargets: const [transcriptSupportContact, transcriptOpsContact],
      forwardingAvailable: true,
    );

    expect(presentation.showForwardSection, isTrue);
    expect(presentation.forwardTitle, 'Forward to');
    expect(
      presentation.forwardTargets.map(
        (target) => '${target.displayName}:${target.subtitle}',
      ),
      ['Support Triage:office', 'Ops Desk:lab'],
    );
  });

  test('hides text-dependent actions for empty action text', () {
    final presentation = TranscriptMessageActionPresentation.fromMessage(
      transcriptTextMessage(text: ''),
      textToSpeechAvailable: true,
      canCancelActiveTurn: true,
      forwardTargets: const [transcriptSupportContact],
      forwardingAvailable: true,
    );

    expect(presentation.text, isEmpty);
    expect(presentation.hasText, isFalse);
    expect(presentation.showCopy, isFalse);
    expect(presentation.canReadAloud, isFalse);
    expect(presentation.showReadAloudUnavailable, isFalse);
    expect(presentation.showForwardSection, isFalse);
    expect(presentation.showPauseStream, isTrue);
  });
}
