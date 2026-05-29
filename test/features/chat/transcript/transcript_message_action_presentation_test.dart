import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/presentation/transcript/transcript_message_action_presentation.dart';

const _support = NavivoxProfileContact(
  serverId: 'office',
  profileId: 'support',
  displayName: 'Support Triage',
  serverLabel: 'office',
  health: NavivoxProfileHealth.online,
  latestPreview: 'Watching tickets',
);

const _ops = NavivoxProfileContact(
  serverId: 'lab',
  profileId: 'ops',
  displayName: 'Ops Desk',
  serverLabel: 'lab',
  health: NavivoxProfileHealth.warning,
  latestPreview: 'Watching devices',
);

void main() {
  test(
    'derives action text for text, voice, tool, safety, and approval messages',
    () {
      final text = TranscriptMessageActionPresentation.fromMessage(
        _textMessage('copy this'),
      );
      final voice = TranscriptMessageActionPresentation.fromMessage(
        _voiceMessage('captured voice'),
      );
      final tool = TranscriptMessageActionPresentation.fromMessage(
        _toolMessage(
          const NavivoxToolCall(
            name: 'grep',
            status: 'finished',
            summary: 'Matched 2 files',
          ),
        ),
      );
      final safety = TranscriptMessageActionPresentation.fromMessage(
        _noticeMessage(
          kind: NavivoxMessageKind.safetyWarning,
          notice: const NavivoxSafetyNotice(
            id: 'safety-1',
            message: 'Unsafe exposure',
            risk: 'Public gateway',
          ),
        ),
      );
      final approval = TranscriptMessageActionPresentation.fromMessage(
        _noticeMessage(
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
      _textMessage('read this', runRecordReference: 'run-ref-1'),
      textToSpeechAvailable: true,
      canCancelActiveTurn: true,
      runRecordInspectionAvailable: true,
    );
    final withoutTts = TranscriptMessageActionPresentation.fromMessage(
      _textMessage('read this later'),
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
      _textMessage('ordinary message'),
      runRecordInspectionAvailable: true,
    );

    expect(presentation.runRecordId, isNull);
    expect(presentation.showInspectRunRecord, isFalse);
  });

  test('exposes forward target rows when forwarding is available', () {
    final presentation = TranscriptMessageActionPresentation.fromMessage(
      _textMessage('send to someone'),
      forwardTargets: const [_support, _ops],
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
      _textMessage(''),
      textToSpeechAvailable: true,
      canCancelActiveTurn: true,
      forwardTargets: const [_support],
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

NavivoxChatMessage _textMessage(String text, {String? runRecordReference}) {
  return NavivoxChatMessage(
    id: 'text-1',
    author: NavivoxMessageAuthor.assistant,
    kind: NavivoxMessageKind.text,
    createdAt: DateTime.utc(2026, 5, 23, 11),
    text: text,
    runRecordReference: runRecordReference,
  );
}

NavivoxChatMessage _voiceMessage(String transcript) {
  return NavivoxChatMessage(
    id: 'voice-1',
    author: NavivoxMessageAuthor.user,
    kind: NavivoxMessageKind.voice,
    createdAt: DateTime.utc(2026, 5, 23, 11),
    voice: NavivoxVoiceMessage(
      duration: const Duration(seconds: 1),
      transcript: transcript,
      confidence: 0.9,
    ),
  );
}

NavivoxChatMessage _toolMessage(NavivoxToolCall toolCall) {
  return NavivoxChatMessage(
    id: 'tool-1',
    author: NavivoxMessageAuthor.system,
    kind: NavivoxMessageKind.toolCall,
    createdAt: DateTime.utc(2026, 5, 23, 11),
    toolCall: toolCall,
  );
}

NavivoxChatMessage _noticeMessage({
  required NavivoxMessageKind kind,
  required NavivoxSafetyNotice notice,
}) {
  return NavivoxChatMessage(
    id: 'notice-1',
    author: NavivoxMessageAuthor.system,
    kind: kind,
    createdAt: DateTime.utc(2026, 5, 23, 11),
    safetyNotice: notice,
  );
}
