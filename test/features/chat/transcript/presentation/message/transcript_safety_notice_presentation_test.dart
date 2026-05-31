import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_safety_notice_presentation.dart';

import '../../shared/transcript_test_fixtures.dart';

void main() {
  test('derives safety warning display state', () {
    final presentation = TranscriptSafetyNoticePresentation.fromNotice(
      transcriptSafetyNotice(
        id: 'safe-1',
        severity: 'high',
        message: 'Shell command wants to modify files',
        risk: 'Writes may change the workspace',
      ),
      approval: false,
    );

    expect(presentation.tone, TranscriptSafetyNoticeTone.warning);
    expect(presentation.cardKeyValue, 'safety-warning-card');
    expect(presentation.title, 'Safety warning');
    expect(presentation.message, 'Shell command wants to modify files');
    expect(presentation.severityLabel, 'high');
    expect(presentation.showSeverity, isTrue);
    expect(presentation.risk, 'Writes may change the workspace');
    expect(presentation.showRisk, isTrue);
  });

  test('derives approval notice display state without severity badge', () {
    final presentation = TranscriptSafetyNoticePresentation.fromNotice(
      transcriptApprovalNotice(
        id: 'approval-1',
        severity: 'high',
        approvalId: 'approval-1',
        toolCallId: 'call-shell',
        message: 'Approve shell.run?',
        risk: 'Command can edit files',
      ),
      approval: true,
    );

    expect(presentation.tone, TranscriptSafetyNoticeTone.approval);
    expect(presentation.cardKeyValue, 'approval-required-card');
    expect(presentation.title, 'Approval required');
    expect(presentation.message, 'Approve shell.run?');
    expect(presentation.severityLabel, 'high');
    expect(presentation.showSeverity, isFalse);
    expect(presentation.risk, 'Command can edit files');
    expect(presentation.showRisk, isTrue);
  });

  test(
    'omits optional safety rows when severity or risk are missing or blank',
    () {
      final missing = TranscriptSafetyNoticePresentation.fromNotice(
        transcriptSafetyNotice(id: 'safe-empty', message: 'Watch this'),
        approval: false,
      );
      final blankRisk = TranscriptSafetyNoticePresentation.fromNotice(
        transcriptSafetyNotice(
          id: 'safe-blank',
          severity: '',
          message: 'Still safe',
          risk: '',
        ),
        approval: false,
      );

      expect(missing.showSeverity, isFalse);
      expect(missing.showRisk, isFalse);
      expect(blankRisk.showSeverity, isFalse);
      expect(blankRisk.showRisk, isFalse);
    },
  );
}
