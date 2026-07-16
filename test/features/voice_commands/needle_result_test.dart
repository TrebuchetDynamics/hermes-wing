import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice_commands/core/needle_result.dart';

void main() {
  test('parses a successful tool-call response', () {
    const raw =
        '{"success": true, "error": null, "response": "", '
        '"function_calls": [{"name": "send_message", '
        '"arguments": {"text": "good morning"}}], '
        '"confidence": 0.91, "time_to_first_token_ms": 12.5, '
        '"total_time_ms": 80.2}';
    final result = NeedleResult.fromEngineJson(raw, wallLatencyMs: 95);
    expect(result.success, isTrue);
    expect(result.error, isNull);
    expect(result.functionCalls, hasLength(1));
    expect(result.functionCalls.single.name, 'send_message');
    expect(result.functionCalls.single.arguments['text'], 'good morning');
    expect(result.confidence, closeTo(0.91, 1e-9));
    expect(result.totalTimeMs, closeTo(80.2, 1e-9));
    expect(result.wallLatencyMs, 95);
  });

  test('parses nested function shape with string-encoded arguments', () {
    const raw =
        '{"success": true, "response": "", "function_calls": '
        '[{"function": {"name": "set_speech_rate", '
        '"arguments": "{\\"rate\\": 0.5}"}}]}';
    final result = NeedleResult.fromEngineJson(raw, wallLatencyMs: 40);
    expect(result.functionCalls.single.name, 'set_speech_rate');
    expect(result.functionCalls.single.arguments['rate'], 0.5);
  });

  test('parses an engine error response', () {
    const raw =
        '{"success": false, "error": "model not loaded", '
        '"response": "", "function_calls": []}';
    final result = NeedleResult.fromEngineJson(raw, wallLatencyMs: 3);
    expect(result.success, isFalse);
    expect(result.error, 'model not loaded');
    expect(result.functionCalls, isEmpty);
  });

  test('malformed engine output becomes a failed result, not a throw', () {
    final result = NeedleResult.fromEngineJson('not json', wallLatencyMs: 3);
    expect(result.success, isFalse);
    expect(result.error, contains('Unparseable engine response'));
  });

  test('wrong-typed leaf fields degrade gracefully instead of throwing', () {
    const raw =
        '{"success": true, "error": 123, "response": 42, '
        '"confidence": "high", "total_time_ms": "slow", '
        '"time_to_first_token_ms": [], "function_calls": []}';
    final result = NeedleResult.fromEngineJson(raw, wallLatencyMs: 7);
    expect(result.success, isTrue);
    expect(result.error, isNull);
    expect(result.response, '');
    expect(result.confidence, isNull);
    expect(result.totalTimeMs, isNull);
    expect(result.timeToFirstTokenMs, isNull);
  });

  test('no tool call is represented as an empty list', () {
    const raw = '{"success": true, "response": "hello", "function_calls": []}';
    final result = NeedleResult.fromEngineJson(raw, wallLatencyMs: 5);
    expect(result.functionCalls, isEmpty);
    expect(result.response, 'hello');
  });
}
