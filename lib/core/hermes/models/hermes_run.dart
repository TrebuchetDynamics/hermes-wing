import '../../protocol/wing_json.dart';

enum HermesRunLifecycle {
  queued,
  running,
  completed,
  failed,
  cancelled,
  unknown,
}

class HermesRunUsage {
  const HermesRunUsage({
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
  });

  factory HermesRunUsage.fromJson(Map<String, Object?> json) {
    final inputTokens = _nonNegativeInt(
      json['input_tokens'] ?? json['prompt_tokens'],
    );
    final outputTokens = _nonNegativeInt(
      json['output_tokens'] ?? json['completion_tokens'],
    );
    final suppliedTotal = _nonNegativeInt(json['total_tokens']);
    return HermesRunUsage(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: suppliedTotal == 0
          ? inputTokens + outputTokens
          : suppliedTotal,
    );
  }

  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  bool get hasTokens => inputTokens > 0 || outputTokens > 0 || totalTokens > 0;
}

class HermesRun {
  const HermesRun({
    required this.id,
    required this.sessionId,
    this.status = HermesRunLifecycle.unknown,
    this.output,
    this.error,
    this.usage,
  });

  factory HermesRun.fromJson(Map<String, Object?> json) {
    final usageJson = wingMapFromJson(json['usage']);
    final usage = usageJson.isEmpty ? null : HermesRunUsage.fromJson(usageJson);
    final status = _runLifecycle(json['status']);
    return HermesRun(
      id: wingStringFromJson(json['id'] ?? json['run_id'], fallback: ''),
      sessionId: wingStringFromJson(json['session_id'], fallback: ''),
      status: status,
      output: wingOptionalStringFromJson(json['output']),
      error: _runFailureDetail(
        json,
        includeGenericFields: status == HermesRunLifecycle.failed,
      ),
      usage: usage,
    );
  }

  final String id;
  final String sessionId;
  final HermesRunLifecycle status;
  final String? output;
  final String? error;
  final HermesRunUsage? usage;
}

String? _runFailureDetail(
  Map<String, Object?> json, {
  required bool includeGenericFields,
}) {
  for (final value in [json['error'], json['last_error'], json['failure']]) {
    final text = wingOptionalLiteralStringFromJson(value);
    if (text != null) return text;
    final nested = wingMapFromJson(value);
    if (nested.isEmpty) continue;
    final code = wingFirstStringFieldFromJson(nested, const ['code', 'type']);
    final message = wingFirstStringFieldFromJson(nested, const [
      'message',
      'detail',
      'reason',
    ]);
    if (code != null && message != null) return '$code: $message';
    if (message != null || code != null) return message ?? code;
  }
  return wingFirstStringFieldFromJson(json, [
    'error_message',
    'failure_reason',
    if (includeGenericFields) ...['message', 'detail', 'reason'],
  ]);
}

HermesRunLifecycle _runLifecycle(Object? value) {
  return switch (wingOptionalStringFromJson(value)?.toLowerCase()) {
    'queued' => HermesRunLifecycle.queued,
    'running' || 'in_progress' => HermesRunLifecycle.running,
    'completed' || 'succeeded' => HermesRunLifecycle.completed,
    'failed' => HermesRunLifecycle.failed,
    'cancelled' || 'canceled' => HermesRunLifecycle.cancelled,
    _ => HermesRunLifecycle.unknown,
  };
}

const _maximumReportedTokens = 999999999;

int _nonNegativeInt(Object? value) {
  final parsed = wingIntFromJson(value);
  return parsed.clamp(0, _maximumReportedTokens);
}
