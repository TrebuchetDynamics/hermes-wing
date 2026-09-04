import '../../protocol/wing_json.dart';
import 'hermes_chat_turn.dart';
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
      source: wingStringFromJson(json['source'], fallback: ''),
      model: wingOptionalStringFromJson(json['model']),
      title: wingOptionalStringFromJson(json['title']),
      messageCount: _optionalNonNegativeInt(json['message_count']) ?? 0,
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

class HermesSessionPage {
  const HermesSessionPage({
    required this.sessions,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory HermesSessionPage.fromJson(Map<String, Object?> json) {
    final limit = (_optionalNonNegativeInt(json['limit']) ?? 50).clamp(1, 200);
    final offset = (_optionalNonNegativeInt(json['offset']) ?? 0).clamp(
      0,
      1000000,
    );
    return HermesSessionPage(
      sessions: wingMapListFromJson(json['data'])
          .take(200)
          .map(HermesSession.fromJson)
          .where((session) => session.id.isNotEmpty)
          .toList(growable: false),
      limit: limit,
      offset: offset,
      hasMore: json['has_more'] == true,
    );
  }

  final List<HermesSession> sessions;
  final int limit;
  final int offset;
  final bool hasMore;

  int get nextOffset => offset + limit;
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
    this.attachment,
    this.toolName,
    this.timestamp,
    this.finishReason,
    this.usage,
    this.hasStructuredContent = false,
    this.hasModelContext = false,
  });

  factory HermesMessage.fromJson(Map<String, Object?> json) {
    final role = wingStringFromJson(json['role'], fallback: '');
    final parsed = _hermesMessageContent(
      json['content'],
      extractAttachment: role == 'user',
    );
    return HermesMessage(
      id: wingStringFieldFromJson(json, 'id'),
      sessionId: wingStringFieldFromJson(json, 'session_id'),
      role: role,
      content: parsed.text,
      attachment: parsed.attachment,
      toolName: wingOptionalStringFromJson(json['tool_name']),
      timestamp: _sessionTimestampFromJson(json['timestamp']),
      finishReason: wingOptionalStringFromJson(json['finish_reason']),
      usage: wingMapFromJson(json['usage']).isEmpty
          ? null
          : HermesRunUsage.fromJson(wingMapFromJson(json['usage'])),
      hasStructuredContent: json['content'] is! String,
      hasModelContext:
          role == 'tool' ||
          const [
            'tool_call_id',
            'tool_calls',
            'tool_name',
            'reasoning',
            'reasoning_content',
          ].any((key) => json[key] != null),
    );
  }

  final String id;
  final String sessionId;
  final String role;
  final String content;
  final HermesTurnAttachment? attachment;
  final String? toolName;
  final String? timestamp;
  final String? finishReason;
  final HermesRunUsage? usage;
  final bool hasStructuredContent;
  final bool hasModelContext;

  bool get isPlainRunHistoryMessage =>
      (role == 'user' || role == 'assistant') &&
      content.trim().isNotEmpty &&
      !hasStructuredContent &&
      !hasModelContext;
}

class HermesMessagePage {
  const HermesMessagePage({
    required this.messages,
    required this.limit,
    required this.offset,
    required this.order,
  });

  factory HermesMessagePage.fromJson(
    Map<String, Object?> json, {
    required int requestedLimit,
    required int requestedOffset,
    required String requestedOrder,
  }) {
    final pagination = wingMapFromJson(json['pagination']);
    final limit =
        (_optionalNonNegativeInt(pagination['limit']) ?? requestedLimit).clamp(
          1,
          500,
        );
    final offset =
        (_optionalNonNegativeInt(pagination['offset']) ?? requestedOffset)
            .clamp(0, 1000000);
    final parsedOrder = wingStringFromJson(
      pagination['order'],
      fallback: requestedOrder,
    );
    return HermesMessagePage(
      messages: wingMapListFromJson(
        json['data'],
      ).take(500).map(HermesMessage.fromJson).toList(growable: false),
      limit: limit,
      offset: offset,
      order: parsedOrder == 'oldest' || parsedOrder == 'latest'
          ? parsedOrder
          : requestedOrder,
    );
  }

  final List<HermesMessage> messages;
  final int limit;
  final int offset;
  final String order;

  int get returned => messages.length;
  int get nextOffset => offset + returned;
  bool get hasMore => returned >= limit;
}

({String text, HermesTurnAttachment? attachment}) _hermesMessageContent(
  Object? value, {
  required bool extractAttachment,
}) {
  if (value is String) return (text: value, attachment: null);
  if (value is! List) return (text: '', attachment: null);

  final textParts = <String>[];
  final attachments = <({int? textIndex, HermesTurnAttachment value})>[];
  for (final rawPart in value) {
    if (rawPart is! Map) continue;
    final type = rawPart['type'];
    if (type == 'image_url' || type == 'input_image') {
      if (extractAttachment) {
        attachments.add((
          textIndex: null,
          value: const HermesTurnAttachment(
            name: 'attachment',
            kind: HermesAttachmentKind.image,
          ),
        ));
      }
      continue;
    }
    if (type != 'text' && type != 'input_text') continue;
    final text = wingStringFromJson(rawPart['text'], fallback: '');
    if (text.isEmpty) continue;
    final textIndex = textParts.length;
    textParts.add(text);
    final file = extractAttachment ? _parseTextFilePart(text) : null;
    if (file != null) {
      attachments.add((textIndex: textIndex, value: file));
    }
  }
  if (attachments.length != 1) {
    final privateTextIndexes = attachments
        .where((attachment) => attachment.textIndex != null)
        .map((attachment) => attachment.textIndex!)
        .toSet();
    return (
      text: [
        for (var index = 0; index < textParts.length; index++)
          if (!privateTextIndexes.contains(index)) textParts[index],
      ].join('\n\n'),
      attachment: null,
    );
  }
  final attachment = attachments.single;
  final textIndex = attachment.textIndex;
  if (textIndex != null) textParts.removeAt(textIndex);
  return (text: textParts.join('\n\n'), attachment: attachment.value);
}

HermesTurnAttachment? _parseTextFilePart(String value) {
  final match = RegExp(
    '^<file name="([^"\\r\\n]{1,$hermesAttachmentEncodedNameLimit})" mime="text/plain">\\n[\\s\\S]*\\n</file>\$',
  ).firstMatch(value);
  if (match == null) return null;
  final name = canonicalHermesAttachmentName(
    _unescapeAttachmentXml(match[1]!),
    fallback: 'attachment.txt',
  );
  return HermesTurnAttachment(name: name, kind: HermesAttachmentKind.file);
}

String _unescapeAttachmentXml(String value) => value
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&gt;', '>')
    .replaceAll('&lt;', '<')
    .replaceAll('&amp;', '&');
