const navivoxWebSocketProtocol = 'navivox.v1';
const navivoxLegacyWebSocketProtocol = 'gormes.navivox.v1';
const navivoxWebSocketTokenProtocolPrefix = 'gormes.navivox.token.';

class NavivoxGatewayStatus {
  const NavivoxGatewayStatus({
    required this.enabled,
    required this.protocolVersion,
    required this.websocketProtocols,
    required this.capabilities,
  });

  factory NavivoxGatewayStatus.fromJson(Map<String, Object?> json) {
    return NavivoxGatewayStatus(
      enabled: json['enabled'] == true,
      protocolVersion: _stringFromJson(
        json['protocol_version'],
        fallback: navivoxLegacyWebSocketProtocol,
      ),
      websocketProtocols: _stringListFromJson(json['websocket_protocols']),
      capabilities: _stringListFromJson(json['capabilities']),
    );
  }

  final bool enabled;
  final String protocolVersion;
  final List<String> websocketProtocols;
  final List<String> capabilities;

  bool supports(String capability) => capabilities.contains(capability);
}

String _stringFromJson(Object? value, {required String fallback}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

List<String> _stringListFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

class NavivoxGatewayConfig {
  const NavivoxGatewayConfig({required this.baseUri, this.token});

  factory NavivoxGatewayConfig.fromBaseUrl(String baseUrl, {String? token}) {
    return NavivoxGatewayConfig(baseUri: Uri.parse(baseUrl), token: token);
  }

  final Uri baseUri;
  final String? token;

  Uri get healthUri => _withPath('/healthz');
  Uri get statusUri => _withPath('/v1/navivox/status');
  Uri get profileContactsUri => _withPath('/v1/navivox/profile-contacts');
  Uri get sessionsUri => _withPath('/v1/navivox/sessions');
  Uri sessionUri(String sessionId) =>
      _withPath('/v1/navivox/sessions/$sessionId');
  Uri get turnUri => _withPath('/v1/navivox/turn');

  Uri get streamUri {
    final scheme = switch (baseUri.scheme) {
      'https' => 'wss',
      'http' => 'ws',
      'wss' || 'ws' => baseUri.scheme,
      _ => 'ws',
    };
    return _withPath('/v1/navivox/stream').replace(scheme: scheme);
  }

  Map<String, String> get headers {
    final value = token?.trim();
    if (value == null || value.isEmpty) {
      return const {};
    }
    return {'Authorization': 'Bearer $value'};
  }

  Uri _withPath(String path) {
    return baseUri.replace(path: path, query: null);
  }
}

class NavivoxGatewayMessage {
  const NavivoxGatewayMessage._(this.body);

  factory NavivoxGatewayMessage.ping({required String requestId}) {
    return NavivoxGatewayMessage._({'type': 'ping', 'request_id': requestId});
  }

  factory NavivoxGatewayMessage.startTurn({
    required String requestId,
    String? sessionId,
    required String text,
    Map<String, Object?> metadata = const {
      'client': 'navivox',
      'platform': 'flutter',
    },
  }) {
    return NavivoxGatewayMessage._({
      'type': 'start_turn',
      'request_id': requestId,
      if (sessionId != null && sessionId.trim().isNotEmpty)
        'session_id': sessionId,
      'text': text,
      'metadata': metadata,
    });
  }

  factory NavivoxGatewayMessage.cancelTurn({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._({
      'type': 'cancel_turn',
      'request_id': requestId,
      'session_id': sessionId,
    });
  }

  factory NavivoxGatewayMessage.stopTurn({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._({
      'type': 'stop_turn',
      'request_id': requestId,
      'session_id': sessionId,
    });
  }

  factory NavivoxGatewayMessage.subscribeSession({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._({
      'type': 'subscribe_session',
      'request_id': requestId,
      'session_id': sessionId,
    });
  }

  final Map<String, Object?> body;
}

class NavivoxGatewayEvent {
  const NavivoxGatewayEvent({
    required this.type,
    this.requestId,
    this.sessionId,
    this.text,
    this.code,
    this.message,
    this.toolName,
    this.toolCallId,
    this.status,
    this.safetyId,
    this.approvalId,
    this.severity,
    this.risk,
    this.contact,
  });

  factory NavivoxGatewayEvent.fromJson(Map<String, Object?> json) {
    final contact = json['contact'];
    return NavivoxGatewayEvent(
      type: json['type']?.toString() ?? '',
      requestId: json['request_id']?.toString(),
      sessionId: json['session_id']?.toString(),
      text: json['text']?.toString(),
      code: json['code']?.toString(),
      message: json['message']?.toString(),
      toolName: json['tool_name']?.toString(),
      toolCallId: json['tool_call_id']?.toString(),
      status: json['status']?.toString(),
      safetyId: json['safety_id']?.toString(),
      approvalId: json['approval_id']?.toString(),
      severity: json['severity']?.toString(),
      risk: json['risk']?.toString(),
      contact: contact is Map ? Map<String, Object?>.from(contact) : null,
    );
  }

  final String type;
  final String? requestId;
  final String? sessionId;
  final String? text;
  final String? code;
  final String? message;
  final String? toolName;
  final String? toolCallId;
  final String? status;
  final String? safetyId;
  final String? approvalId;
  final String? severity;
  final String? risk;
  final Map<String, Object?>? contact;

  bool get isError => type == 'error';
}
