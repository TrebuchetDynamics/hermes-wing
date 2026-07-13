import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/needle_spike/services/needle_engine.dart';
import 'package:navivox/features/needle_spike/services/needle_spike_service.dart';

class _FakeEngine implements NeedleEngineApi {
  _FakeEngine(this.rawResponse);

  final String rawResponse;
  String? lastMessagesJson;
  String? lastToolsJson;
  String? lastOptionsJson;
  int completeCalls = 0;

  @override
  bool get isLoaded => true;

  @override
  Future<void> load(String modelDir) async {}

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) async {
    completeCalls += 1;
    lastMessagesJson = messagesJson;
    lastToolsJson = toolsJson;
    lastOptionsJson = optionsJson;
    return rawResponse;
  }

  @override
  Future<void> unload() async {}
}

void main() {
  const toolCallResponse =
      '{"success": true, "response": "", "function_calls": '
      '[{"name": "show_status", "arguments": {}}], "total_time_ms": 42.0}';

  test(
    'parseTranscript sends the transcript, catalog, and on-device options',
    () async {
      final engine = _FakeEngine(toolCallResponse);
      final service = NeedleSpikeService(engine: engine);

      final result = await service.parseTranscript('is the agent connected');

      expect(result.functionCalls.single.name, 'show_status');
      expect(result.wallLatencyMs, greaterThanOrEqualTo(0));
      final messages = jsonDecode(engine.lastMessagesJson!) as List<dynamic>;
      expect((messages.single as Map)['role'], 'user');
      expect((messages.single as Map)['content'], 'is the agent connected');
      final tools = jsonDecode(engine.lastToolsJson!) as List<dynamic>;
      expect(tools, hasLength(10));
      final options =
          jsonDecode(engine.lastOptionsJson!) as Map<String, dynamic>;
      expect(options['auto_handoff'], isFalse);
      expect(options['force_tools'], isTrue);
      expect(options['tool_rag_top_k'], 0);
    },
  );

  test('concurrent parse attempts are rejected while busy', () async {
    final engine = _FakeEngine(toolCallResponse);
    final service = NeedleSpikeService(engine: engine);

    final first = service.parseTranscript('one');
    expect(() => service.parseTranscript('two'), throwsStateError);
    await first;
    expect(engine.completeCalls, 1);
  });
}
