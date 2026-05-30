import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_run_record_sheet.dart';

void main() {
  testWidgets(
    'renders redacted run record transcript, voice, tool, and usage rows',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TranscriptRunRecordSheet(
              record: NavivoxRunRecordSnapshot(
                runId: 'req-run-record',
                sessionId: 's-run-record',
                status: 'completed',
                createdAt: null,
                updatedAt: null,
                completedAt: null,
                raw: {
                  'transcript': [
                    {'role': 'user', 'text': 'transcribed voice command'},
                    {'role': 'assistant', 'text': 'assistant final answer'},
                  ],
                  'voice': {
                    'device_transcript': 'transcribed voice command',
                    'audio': {
                      'duration_ms': 1200,
                      'raw_audio_stored': false,
                      'retention': 'not_stored',
                    },
                    'server_stt': {'provider': 'local', 'status': 'available'},
                    'tts': {'provider': 'piper', 'status': 'ready'},
                  },
                  'provider_usage': {'status': 'unknown'},
                  'provider_cost': {'status': 'unknown'},
                  'tool_events': [
                    {
                      'tool_call_id': 'tool-1',
                      'name': 'read_file',
                      'status': 'finished',
                      'metadata': {'artifact_ref': 'artifact://readme'},
                    },
                  ],
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Evidence'), findsOneWidget);
      expect(find.text('req-run-record'), findsOneWidget);
      expect(find.text('s-run-record'), findsOneWidget);
      expect(find.text('completed'), findsOneWidget);
      expect(find.text('Provider usage'), findsOneWidget);
      expect(find.text('Provider cost'), findsOneWidget);
      expect(find.text('unknown'), findsWidgets);
      expect(find.text('Device transcript'), findsOneWidget);
      expect(find.text('transcribed voice command'), findsWidgets);
      expect(find.textContaining('raw audio not stored'), findsOneWidget);
      expect(find.text('read_file'), findsOneWidget);
      expect(find.textContaining('artifact://readme'), findsOneWidget);
    },
  );
}
