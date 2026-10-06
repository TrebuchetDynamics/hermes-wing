/// Native web DTOs deliberately do not reuse the gateway /v1 schema.
/// Only presentation-safe fields are retained; host paths and domain extras die
/// at this decoder boundary. No server advertisement here is an operation grant.
enum HermesWebProductAuthorization { unsupportedAuthorization }

enum HermesWebFailureKind {
  malformed,
  oversized,
  identity,
  authentication,
  notFound,
  redirect,
  network,
  timeout,
  disconnected,
  stale,
  rpc,
  busy,
  storageUnavailable,
}

final class HermesWebReadException implements Exception {
  const HermesWebReadException(this.kind, {this.rpcCode});
  final HermesWebFailureKind kind;
  final int? rpcCode;
  @override
  String toString() => 'Hermes native web read failed: ${kind.name}';
}

Never webMalformed() =>
    throw const HermesWebReadException(HermesWebFailureKind.malformed);
Map<String, dynamic> webObject(Object? value) =>
    value is Map<String, dynamic> ? value : webMalformed();
String webString(Object? value, {int maximum = 4096}) =>
    value is String && value.length <= maximum ? value : webMalformed();
String? _nullableString(Object? value) =>
    value == null ? null : webString(value);
int webInteger(Object? value, {int maximum = 1000000}) =>
    value is int && value >= 0 && value <= maximum ? value : webMalformed();
DateTime? _time(Object? value) {
  if (value == null) return null;
  if (value is! num || !value.isFinite || value < 0 || value > 253402300799) {
    webMalformed();
  }
  return DateTime.fromMicrosecondsSinceEpoch(
    (value * 1000000).round(),
    isUtc: true,
  );
}

List<dynamic> webRows(Object? value, int maximum) {
  if (value is! List || value.length > maximum) webMalformed();
  return value;
}

void webIdentity(Object? actual, Object expected) {
  if (actual != expected) {
    throw const HermesWebReadException(HermesWebFailureKind.identity);
  }
}

final class HermesWebSession {
  HermesWebSession.fromJson(Map<String, dynamic> row, String profile)
    : id = webString(row['id']),
      title = _nullableString(row['title']),
      model = _nullableString(row['model']),
      preview = _nullableString(row['preview']),
      source = _nullableString(row['source']),
      startedAt = _time(row['started_at']),
      endedAt = _time(row['ended_at']),
      messageCount = webInteger(row['message_count']),
      isActive = row['is_active'] is bool
          ? row['is_active'] as bool
          : webMalformed() {
    if (id.isEmpty) webMalformed();
    webIdentity(row['profile'], profile);
  }
  final String id;
  final String? title, model, preview, source;
  final DateTime? startedAt, endedAt;
  final int messageCount;
  final bool isActive;
}

final class HermesWebSessionPage {
  HermesWebSessionPage.fromJson(
    Map<String, dynamic> json,
    String profile, {
    required this.limit,
    required this.offset,
  }) : total = webInteger(json['total'], maximum: 1000000000),
       sessions = List.unmodifiable(
         webRows(
           json['sessions'],
           limit,
         ).map((r) => HermesWebSession.fromJson(webObject(r), profile)),
       ) {
    webIdentity(json['limit'], limit);
    webIdentity(json['offset'], offset);
    if (total < sessions.length) webMalformed();
    final state = webObject(json['storage']);
    if (state.isNotEmpty) {
      if (state.length != 1 || state[profile] != 'corrupt') webMalformed();
      throw const HermesWebReadException(
        HermesWebFailureKind.storageUnavailable,
      );
    }
  }
  final int total;
  final int limit, offset;
  final List<HermesWebSession> sessions;
  // Storage is decoded into a typed failure, never exposed as a raw map.
}

final class HermesWebMessage {
  HermesWebMessage.fromJson(Map<String, dynamic> row, String session)
    : id = webInteger(row['id'], maximum: 9007199254740991),
      role = webString(row['role'], maximum: 64),
      content = row['content'] == null
          ? null
          : webString(row['content'], maximum: 1048576),
      timestamp = _time(row['timestamp']),
      toolName = _nullableString(row['tool_name']),
      toolCallId = _nullableString(row['tool_call_id']),
      reasoning = row['reasoning'] == null
          ? null
          : webString(row['reasoning'], maximum: 1048576),
      displayKind = _nullableString(row['display_kind']) {
    webIdentity(row['session_id'], session);
  }
  final int id;
  final String role;
  final String? content, toolName, toolCallId, reasoning, displayKind;
  final DateTime? timestamp;
}

final class HermesWebHistoryPage {
  HermesWebHistoryPage.fromJson(
    Map<String, dynamic> json,
    String profile,
    String session, {
    required this.limit,
    required this.offset,
    required this.order,
  }) : messages = List.unmodifiable(
         webRows(
           json['messages'],
           limit,
         ).map((r) => HermesWebMessage.fromJson(webObject(r), session)),
       ),
       returned = webInteger(
         webObject(json['pagination'])['returned'],
         maximum: limit,
       ) {
    webIdentity(json['profile'], profile);
    webIdentity(json['session_id'], session);
    final pagination = webObject(json['pagination']);
    webIdentity(pagination['limit'], limit);
    webIdentity(pagination['offset'], offset);
    webIdentity(pagination['order'], order);
    if (returned != messages.length) webMalformed();
  }
  final List<HermesWebMessage> messages;
  final String order;
  final int returned;
  final int limit, offset;
}
