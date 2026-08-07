import '../../protocol/wing_json.dart';
import 'hermes_run.dart';

class HermesSession {
  const HermesSession({
    required this.id,
    required this.source,
    this.model,
    this.title,
    this.messageCount = 0,
    this.toolCallCount,
    this.inputTokens,
    this.outputTokens,
    this.cacheReadTokens,
    this.cacheWriteTokens,
    this.reasoningTokens,
    this.apiCallCount,
    this.estimatedCostUsd,
    this.actualCostUsd,
    this.startedAt,
    this.endedAt,
    this.endReason,
    this.hasSystemPrompt,
    this.hasModelConfig,
    this.lastActive,
    this.preview,
    this.parentSessionId,
  });

  factory HermesSession.fromJson(Map<String, Object?> json) {
    return HermesSession(
      id: wingStringFieldFromJson(json, 'id'),
      source: wingStringFromJson(json['source'], fallback: 'api_server'),
      model: wingOptionalStringFromJson(json['model']),
      title: wingOptionalStringFromJson(json['title']),
      messageCount: wingIntFromJson(json['message_count']),
      toolCallCount: _optionalNonNegativeInt(json['tool_call_count']),
      inputTokens: _optionalNonNegativeInt(json['input_tokens']),
      outputTokens: _optionalNonNegativeInt(json['output_tokens']),
      cacheReadTokens: _optionalNonNegativeInt(json['cache_read_tokens']),
      cacheWriteTokens: _optionalNonNegativeInt(json['cache_write_tokens']),
      reasoningTokens: _optionalNonNegativeInt(json['reasoning_tokens']),
      apiCallCount: _optionalNonNegativeInt(json['api_call_count']),
      estimatedCostUsd: _optionalNonNegativeDouble(json['estimated_cost_usd']),
      actualCostUsd: _optionalNonNegativeDouble(json['actual_cost_usd']),
      startedAt: _sessionTimestampFromJson(json['started_at']),
      endedAt: _sessionTimestampFromJson(json['ended_at']),
      endReason: wingOptionalStringFromJson(json['end_reason']),
      hasSystemPrompt: _optionalBool(json, 'has_system_prompt'),
      hasModelConfig: _optionalBool(json, 'has_model_config'),
      lastActive: _sessionTimestampFromJson(json['last_active']),
      preview: wingOptionalStringFromJson(json['preview']),
      parentSessionId: wingOptionalStringFromJson(json['parent_session_id']),
    );
  }

  final String id;
  final String source;
  final String? model;
  final String? title;
  final int messageCount;
  final int? toolCallCount;
  final int? inputTokens;
  final int? outputTokens;
  final int? cacheReadTokens;
  final int? cacheWriteTokens;
  final int? reasoningTokens;
  final int? apiCallCount;
  final double? estimatedCostUsd;
  final double? actualCostUsd;
  final String? startedAt;
  final String? endedAt;
  final String? endReason;
  final bool? hasSystemPrompt;
  final bool? hasModelConfig;
  final String? lastActive;
  final String? preview;
  final String? parentSessionId;
}

const _maxSafeSessionCount = 9007199254740991;
const _maxSessionCostUsd = 1000000000000.0;

int? _optionalNonNegativeInt(Object? value) {
  if (value == null) return null;
  final parsed = value is num
      ? value.toInt()
      : int.tryParse(value.toString().trim());
  if (parsed == null || parsed < 0) return null;
  return parsed.clamp(0, _maxSafeSessionCount);
}

double? _optionalNonNegativeDouble(Object? value) {
  final parsed = wingDoubleFromJson(value);
  if (parsed == null || !parsed.isFinite || parsed < 0) return null;
  return parsed.clamp(0, _maxSessionCostUsd);
}

String? _sessionTimestampFromJson(Object? value) {
  final text = wingOptionalStringFromJson(value);
  if (text == null) return null;
  final seconds = value is num ? value.toDouble() : double.tryParse(text);
  if (seconds == null) return text;
  if (!seconds.isFinite || seconds < 0) return text;
  final milliseconds = seconds * Duration.millisecondsPerSecond;
  if (!milliseconds.isFinite || milliseconds > 8640000000000000) {
    return text;
  }
  try {
    return DateTime.fromMillisecondsSinceEpoch(
      milliseconds.round(),
      isUtc: true,
    ).toIso8601String();
  } on RangeError {
    return text;
  }
}

bool? _optionalBool(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) return null;
  final value = json[key];
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true') return true;
  if (normalized == 'false') return false;
  return null;
}

class HermesMessage {
  const HermesMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.toolName,
    this.timestamp,
    this.finishReason,
    this.usage,
  });

  factory HermesMessage.fromJson(Map<String, Object?> json) {
    final role = wingStringFromJson(json['role'], fallback: '');
    return HermesMessage(
      id: wingStringFieldFromJson(json, 'id'),
      sessionId: wingStringFieldFromJson(json, 'session_id'),
      role: role,
      content: _hermesMessageContent(
        json['content'],
        summarizeTextFiles: role == 'user',
      ),
      toolName: wingOptionalStringFromJson(json['tool_name']),
      timestamp: _sessionTimestampFromJson(json['timestamp']),
      finishReason: wingOptionalStringFromJson(json['finish_reason']),
      usage: wingMapFromJson(json['usage']).isEmpty
          ? null
          : HermesRunUsage.fromJson(wingMapFromJson(json['usage'])),
    );
  }

  final String id;
  final String sessionId;
  final String role;
  final String content;
  final String? toolName;
  final String? timestamp;
  final String? finishReason;
  final HermesRunUsage? usage;
}

String _hermesMessageContent(
  Object? value, {
  required bool summarizeTextFiles,
}) {
  final content = value is String
      ? value
      : value is List
      ? [
          for (final part in value)
            if (part is Map)
              switch (part['type']) {
                'text' ||
                'input_text' => wingStringFromJson(part['text'], fallback: ''),
                'image_url' || 'input_image' => '[Image]',
                _ => '',
              },
        ].where((part) => part.isNotEmpty).join('\n\n')
      : '';
  if (!summarizeTextFiles) return content;
  return content
      .replaceFirstMapped(
        RegExp(
          r'(?:\n\n)?<file name="([^"]*)" mime="[^"]*">\n.*\n</file>$',
          dotAll: true,
        ),
        (match) => '\n\n[File: ${_unescapeAttachmentXml(match[1]!)}]',
      )
      .trim();
}

String _unescapeAttachmentXml(String value) => value
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&gt;', '>')
    .replaceAll('&lt;', '<')
    .replaceAll('&amp;', '&');
