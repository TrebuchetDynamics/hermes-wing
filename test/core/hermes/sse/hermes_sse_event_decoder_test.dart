import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/sse/hermes_sse_event_decoder.dart';

void main() {
  test('flushes the final unterminated batch SSE frame', () {
    final events = const HermesSseEventDecoder().decodeJsonEvents([
      'event: done\ndata: {}\n',
    ]);

    expect(events, hasLength(1));
    expect(events.single.isDone, isTrue);
  });

  test('normalizes a direct JSON event using its embedded type', () {
    final event = HermesStreamEvent.fromJson({
      'type': 'tool.progress',
      'run_id': 'run-1',
      'delta': 'working',
    });

    expect(event.name, 'tool.progress');
    expect(event.runId, 'run-1');
    expect(event.delta, 'working');
  });

  test('prefers an explicit wire event name over an embedded type', () {
    final event = HermesStreamEvent.fromJson({
      'type': 'message.delta',
      'delta': 'hello',
    }, eventName: 'assistant.delta');

    expect(event.name, 'assistant.delta');
    expect(event.delta, 'hello');
  });

  test('normalizes the Agent JSON-RPC event envelope and nested payload', () {
    final event = HermesStreamEvent.fromJsonRpc({
      'jsonrpc': '2.0',
      'method': 'event',
      'params': {
        'type': 'message.delta',
        'session_id': 'session-1',
        'payload': {'run_id': 'run-1', 'delta': 'hello'},
      },
    });

    expect(event.name, 'message.delta');
    expect(event.sessionId, 'session-1');
    expect(event.runId, 'run-1');
    expect(event.delta, 'hello');
  });

  test('normalizes the advertised JSON-RPC event envelope', () {
    final event = HermesStreamEvent.fromJsonRpc({
      'jsonrpc': '2.0',
      'method': 'event',
      'params': {
        'type': 'approval.request',
        'run_id': 'run-1',
        'payload': {'approval_id': 'approval-1'},
      },
    });

    expect(event.name, 'approval.request');
    expect(event.runId, 'run-1');
    expect(event.payload['approval_id'], 'approval-1');
  });

  test('rejects non-object event frames', () {
    expect(
      () => HermesStreamEvent.fromJson(const ['not', 'an', 'event']),
      throwsFormatException,
    );
  });

  test('does not treat a JSON-RPC response as a stream event', () {
    expect(
      () => HermesStreamEvent.fromJsonRpc({
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'ok': true},
      }),
      throwsFormatException,
    );
  });
}
