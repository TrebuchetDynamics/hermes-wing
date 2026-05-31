import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_tool_call_presentation.dart';

import '../../shared/transcript_test_fixtures.dart';

void main() {
  test('derives tool call display state and artifact rows', () {
    final presentation = TranscriptToolCallPresentation.fromToolCall(
      transcriptToolCall(
        name: 'shell.run',
        status: 'finished',
        summary: 'ran git diff',
        approval: transcriptShellApproval(),
        artifacts: [
          transcriptDiffArtifact(ref: 'artifact://a-1'),
          transcriptScreenshotArtifact(),
        ],
      ),
    );

    expect(presentation.name, 'shell.run');
    expect(presentation.statusLabel, 'finished');
    expect(presentation.statusTone, TranscriptToolCallStatusTone.success);
    expect(presentation.summary, 'ran git diff');
    expect(presentation.showSummary, isTrue);
    expect(presentation.approvalLabel, 'Approval required');
    expect(presentation.approvalPrompt, 'Approve shell.run?');
    expect(presentation.approvalRisk, 'Writes files');
    expect(
      presentation.artifacts.map(
        (artifact) =>
            '${artifact.id}:${artifact.kind}:${artifact.title}:${artifact.summary ?? ''}:${artifact.ref ?? ''}:${artifact.showSummary}',
      ),
      [
        'a-1:file:diff.patch:14 lines changed:artifact://a-1:true',
        'a-2:image:screenshot.png:::false',
      ],
    );
  });

  test('maps known tool statuses to stable tones', () {
    TranscriptToolCallStatusTone toneFor(String status) {
      return TranscriptToolCallPresentation.fromToolCall(
        transcriptToolCall(name: 'tool', status: status, summary: ''),
      ).statusTone;
    }

    expect(toneFor('started'), TranscriptToolCallStatusTone.active);
    expect(toneFor('updated'), TranscriptToolCallStatusTone.active);
    expect(toneFor('finished'), TranscriptToolCallStatusTone.success);
    expect(toneFor('completed'), TranscriptToolCallStatusTone.success);
    expect(toneFor('failed'), TranscriptToolCallStatusTone.failure);
  });

  test('omits summary rows when tool and artifact summaries are empty', () {
    final presentation = TranscriptToolCallPresentation.fromToolCall(
      transcriptToolCall(
        name: 'grep',
        status: 'completed',
        summary: '',
        artifacts: [
          transcriptDiffArtifact(
            kind: 'text',
            title: 'result.txt',
            summary: null,
          ),
          transcriptScreenshotArtifact(
            kind: 'log',
            title: 'empty.log',
            summary: '',
          ),
        ],
      ),
    );

    expect(presentation.showSummary, isFalse);
    expect(presentation.artifacts.map((artifact) => artifact.showSummary), [
      false,
      false,
    ]);
  });
}
