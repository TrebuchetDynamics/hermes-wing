import '../../protocol/wing_json.dart';

class HermesSession {
  const HermesSession({
    required this.id,
    required this.source,
    this.model,
    this.title,
    this.messageCount = 0,
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
      lastActive: wingOptionalStringFromJson(json['last_active']),
      preview: wingOptionalStringFromJson(json['preview']),
      parentSessionId: wingOptionalStringFromJson(json['parent_session_id']),
    );
  }

  final String id;
  final String source;
  final String? model;
  final String? title;
  final int messageCount;
  final String? lastActive;
  final String? preview;
  final String? parentSessionId;
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
  });

  factory HermesMessage.fromJson(Map<String, Object?> json) {
    return HermesMessage(
      id: wingStringFieldFromJson(json, 'id'),
      sessionId: wingStringFieldFromJson(json, 'session_id'),
      role: wingStringFromJson(json['role'], fallback: ''),
      content: wingStringFromJson(json['content'], fallback: ''),
      toolName: wingOptionalStringFromJson(json['tool_name']),
      timestamp: wingOptionalStringFromJson(json['timestamp']),
      finishReason: wingOptionalStringFromJson(json['finish_reason']),
    );
  }

  final String id;
  final String sessionId;
  final String role;
  final String content;
  final String? toolName;
  final String? timestamp;
  final String? finishReason;
}
