import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/voice/hermes_voice_input_controller.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';
import 'package:wing/shared/voice/voice_settings.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';

void main() {
  for (final continuous in [false, true]) {
    for (final withTail in [false, true]) {
      for (final completeBeforeHistory in [false, true]) {
        test(
          'history replacement does not replay TTS; continuous $continuous tail $withTail completion before history $completeBeforeHistory',
          () async {
            final events = StreamController<String>();
            final history = Completer<String>();
            var reads = 0;
            final channel = HermesApiChannel(
              clientBuilder: (config) => HermesApiClient(
                config: config,
                get: (uri, headers) async => switch (uri.path) {
                  '/health' => '{"status":"ok"}',
                  '/v1/capabilities' => jsonEncode({
                    'features': {'session_chat_streaming': true},
                    'endpoints': {
                      'session_chat_stream': {
                        'method': 'POST',
                        'path': '/api/sessions/{session_id}/chat/stream',
                      },
                    },
                  }),
                  '/api/sessions' =>
                    '{"data":[{"id":"sess_1","title":"Synthetic"}]}',
                  '/api/sessions/sess_1/messages' =>
                    reads++ == 0
                        ? '{"object":"list","session_id":"sess_1","data":[]}'
                        : await history.future,
                  _ => throw StateError('Unexpected synthetic route'),
                },
                postStream: (uri, headers, body) => events.stream,
              ),
            );
            final tts = _QueuedSpeech();
            final capture = _BlockedCapture();
            final controller = HermesVoiceInputController(
              channel: () => channel,
              captureService: () => capture,
              textToSpeechService: () => tts,
              settings: () => const WingVoiceSettings(
                speakRepliesEnabled: true,
                continuousVoiceEnabled: true,
              ),
              onDraft: (_) {},
            );
            addTearDown(channel.dispose);
            addTearDown(controller.dispose);
            channel.addListener(() => unawaited(controller.maybeContinue()));
            await channel.connect(baseUrl: 'http://127.0.0.1:8642');
            expect(
              channel.state.isConnected,
              isTrue,
              reason: channel.state.errorMessage,
            );
            expect(channel.state.activeSessionId, 'sess_1');
            if (continuous) {
              unawaited(controller.enableContinuous());
              await pumpEventQueue();
            } else {
              controller.speakNextReply();
            }
            final send = channel.sendText('Synthetic question');
            await pumpEventQueue();
            events.add(
              'data: {"event":"message.delta","delta":"First sentence."}\n\n',
            );
            await pumpEventQueue();
            final streamedId = channel.state.activeMessages.last.id;
            expect(tts.spoken, ['First sentence.']);
            if (completeBeforeHistory) {
              tts.completeNext();
              await pumpEventQueue();
            }
            events.add('data: [DONE]\n\n');
            await events.close();
            await pumpEventQueue();
            history.complete(
              jsonEncode({
                'object': 'list',
                'session_id': 'sess_1',
                'data': [
                  {
                    'id': 'server-user',
                    'session_id': 'sess_1',
                    'role': 'user',
                    'content': 'Synthetic question',
                  },
                  {
                    'id': 'server-assistant',
                    'session_id': 'sess_1',
                    'role': 'assistant',
                    'content': withTail
                        ? 'First sentence. Final tail'
                        : 'First sentence.',
                  },
                ],
              }),
            );
            await send;
            expect(channel.state.activeMessages.last.id, 'server-assistant');
            expect(streamedId, isNot('server-assistant'));
            expect(
              channel.state.activeMessages.where(
                (turn) => turn.author == HermesTurnAuthor.assistant,
              ),
              hasLength(1),
            );
            if (!completeBeforeHistory) tts.completeNext();
            await pumpEventQueue();
            final expected = ['First sentence.', if (withTail) 'Final tail'];
            expect(tts.spoken, expected);
            if (withTail) tts.completeNext();
            await pumpEventQueue();
            await Future.wait(
              List.generate(8, (_) => controller.maybeContinue()),
            );
            expect(tts.spoken, expected);
            expect(tts.maximumConcurrent, 1);
            if (continuous) {
              expect(controller.capturing, isTrue);
              expect(capture.calls, 1);
            }
          },
        );
      }
    }
  }
}

class _BlockedCapture implements VoiceCaptureService {
  final pending = Completer<VoiceCapture>();
  int calls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    calls += 1;
    return pending.future;
  }

  @override
  Future<void> cancel() async {
    if (!pending.isCompleted) pending.completeError(StateError('cancelled'));
  }
}

class _QueuedSpeech implements TextToSpeechService {
  final spoken = <String>[];
  final pending = <Completer<void>>[];
  var maximumConcurrent = 0;

  @override
  Future<void> speak(String text) {
    spoken.add(text);
    final completion = Completer<void>();
    pending.add(completion);
    if (pending.length > maximumConcurrent) maximumConcurrent = pending.length;
    return completion.future;
  }

  void completeNext() => pending.removeAt(0).complete();

  @override
  Future<void> stop() async {
    while (pending.isNotEmpty) {
      completeNext();
    }
  }

  @override
  Future<void> dispose() => stop();
}
