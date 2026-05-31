import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_run_record_presentation.dart';

void main() {
  test(
    'summarizes text and voice run record evidence without secret metadata',
    () {
      final presentation = TranscriptRunRecordPresentation.fromRecord(
        NavivoxRunRecordSnapshot(
          runId: 'req-run-record',
          sessionId: 's-run-record',
          status: 'completed',
          createdAt: DateTime.utc(2026, 5, 23, 10),
          updatedAt: DateTime.utc(2026, 5, 23, 10, 0, 4),
          completedAt: DateTime.utc(2026, 5, 23, 10, 0, 8),
          raw: const {
            'transcript': [
              {'role': 'user', 'text': 'transcribed voice command'},
              {'role': 'assistant', 'text': 'assistant final answer'},
            ],
            'voice': {
              'device_transcript': 'transcribed voice command',
              'audio': {
                'duration_ms': 1200,
                'codec': 'opus',
                'raw_audio_stored': false,
                'retention': 'not_stored',
              },
              'server_stt': {'provider': 'local', 'status': 'available'},
              'tts': {
                'provider': 'piper',
                'voice_id': 'amy',
                'status': 'ready',
              },
            },
            'provider_usage': {'status': 'unknown'},
            'provider_cost': {'status': 'unknown'},
            'tool_events': [
              {
                'tool_call_id': 'tool-1',
                'name': 'read_file',
                'status': 'finished',
                'metadata': {
                  'artifact_ref': 'artifact://readme',
                  'secret_token': 'must-not-render',
                },
              },
            ],
          },
        ),
      );

      expect(presentation.title, 'Evidence');
      expect(presentation.runId, 'req-run-record');
      expect(presentation.sessionId, 's-run-record');
      expect(presentation.statusLabel, 'completed');
      expect(presentation.providerUsageLabel, 'unknown');
      expect(presentation.providerCostLabel, 'unknown');
      expect(
        presentation.transcriptRows.map((row) => '${row.role}:${row.text}'),
        ['user:transcribed voice command', 'assistant:assistant final answer'],
      );
      expect(presentation.voiceRows.map((row) => '${row.label}:${row.value}'), [
        'Device transcript:transcribed voice command',
        'Audio:1200 ms • codec opus • raw audio not stored • retention not_stored',
        'Server STT:local • available',
        'TTS:piper • ready • voice amy',
      ]);
      expect(
        presentation.toolRows.map(
          (row) => '${row.name}:${row.status}:${row.artifactRef}',
        ),
        ['read_file:finished:artifact://readme'],
      );
      expect(presentation.searchableText, isNot(contains('must-not-render')));
    },
  );

  test(
    'uses explicit unknown states instead of fabricated zero usage or cost',
    () {
      final presentation = TranscriptRunRecordPresentation.fromRecord(
        const NavivoxRunRecordSnapshot(
          runId: 'req-usage-missing',
          sessionId: '',
          status: '',
          createdAt: null,
          updatedAt: null,
          completedAt: null,
          raw: {},
        ),
      );

      expect(presentation.runId, 'req-usage-missing');
      expect(presentation.statusLabel, 'unknown');
      expect(presentation.sessionId, 'unknown');
      expect(presentation.providerUsageLabel, 'unknown');
      expect(presentation.providerCostLabel, 'unknown');
      expect(presentation.createdAtLabel, 'unknown');
      expect(presentation.transcriptRows, isEmpty);
      expect(presentation.voiceRows.map((row) => '${row.label}:${row.value}'), [
        'Raw audio retention:unknown',
      ]);
    },
  );

  test(
    'trims run record identifiers through shared transcript text policy',
    () {
      final presentation = TranscriptRunRecordPresentation.fromRecord(
        const NavivoxRunRecordSnapshot(
          runId: '  req-trimmed  ',
          sessionId: '  ',
          status: '  completed  ',
          createdAt: null,
          updatedAt: null,
          completedAt: null,
          raw: {},
        ),
      );

      expect(presentation.runId, 'req-trimmed');
      expect(presentation.sessionId, 'unknown');
      expect(presentation.statusLabel, 'completed');
    },
  );
}
