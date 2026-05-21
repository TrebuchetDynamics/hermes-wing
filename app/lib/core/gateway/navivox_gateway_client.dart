import 'dart:async';
import 'dart:convert';

import '../protocol/navivox_memory.dart';
import 'navivox_gateway_protocol.dart';
import 'navivox_gateway_transport_stub.dart'
    if (dart.library.io) 'navivox_gateway_transport_io.dart'
    if (dart.library.html) 'navivox_gateway_transport_web.dart'
    as transport;

typedef NavivoxGatewaySocket = transport.NavivoxGatewaySocket;

typedef NavivoxGatewayGet =
    Future<String> Function(Uri uri, Map<String, String> headers);

typedef NavivoxGatewayPost =
    Future<String> Function(Uri uri, Map<String, String> headers, String body);

typedef NavivoxGatewayWebSocketConnector =
    Future<NavivoxGatewaySocket> Function(Uri uri, Map<String, String> headers);

class NavivoxGatewayClient {
  NavivoxGatewayClient({
    required this.config,
    NavivoxGatewayGet? get,
    NavivoxGatewayPost? post,
    NavivoxGatewayWebSocketConnector? connectWebSocket,
  }) : _get = get ?? _defaultGet,
       _post = post ?? _defaultPost,
       _connectWebSocket = connectWebSocket ?? _defaultConnectWebSocket;

  final NavivoxGatewayConfig config;
  final NavivoxGatewayGet _get;
  final NavivoxGatewayPost _post;
  final NavivoxGatewayWebSocketConnector _connectWebSocket;

  Future<Map<String, Object?>> health() => _getJson(config.healthUri);
  Future<Map<String, Object?>> status() => _getJson(config.statusUri);
  Future<NavivoxGatewayStatus> gatewayStatus() async {
    return NavivoxGatewayStatus.fromJson(await status());
  }

  Future<NavivoxMemoryOverview> memoryOverview({
    String? serverId,
    String? profileId,
  }) async {
    return NavivoxMemoryOverview.fromJson(
      await _getJson(
        config.memoryOverviewUri(serverId: serverId, profileId: profileId),
      ),
    );
  }

  Future<NavivoxMemorySearchResult> memorySearch({
    String? serverId,
    String? profileId,
    String query = '',
    NavivoxMemoryType type = NavivoxMemoryType.all,
    int limit = 20,
    String? pageToken,
  }) async {
    return NavivoxMemorySearchResult.fromJson(
      await _getJson(
        config.memorySearchUri(
          serverId: serverId,
          profileId: profileId,
          query: query,
          type: type,
          limit: limit,
          pageToken: pageToken,
        ),
      ),
    );
  }

  Future<NavivoxMemoryDetail> memoryDetail({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
  }) async {
    return NavivoxMemoryDetail.fromJson(
      await _getJson(
        config.memoryDetailUri(
          serverId: serverId,
          profileId: profileId,
          id: id,
          type: type,
        ),
      ),
    );
  }

  Future<NavivoxMemoryActionResult> memoryAction({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
    required NavivoxMemoryActionType action,
    String? correction,
  }) async {
    final body = <String, Object?>{
      if (serverId != null && serverId.trim().isNotEmpty)
        'server_id': serverId.trim(),
      if (profileId != null && profileId.trim().isNotEmpty)
        'profile_id': profileId.trim(),
      'id': id.trim(),
      'type': type.wireValue,
      'action': action.wireValue,
      if (correction != null && correction.trim().isNotEmpty)
        'correction': correction.trim(),
    };
    return NavivoxMemoryActionResult.fromJson(
      await _postJson(config.memoryActionUri, body),
    );
  }

  Future<List<Map<String, Object?>>> profileContacts() async {
    final body = await _getJson(config.profileContactsUri);
    final contacts = body['contacts'];
    if (contacts is! List) {
      return const [];
    }
    return contacts
        .whereType<Map>()
        .map((contact) => Map<String, Object?>.from(contact))
        .toList(growable: false);
  }

  Future<NavivoxGatewaySocket> connectStream() {
    return _connectWebSocket(config.streamUri, config.headers);
  }

  Duration reconnectDelay(int attempt) {
    final bounded = attempt.clamp(0, 6).toInt();
    return Duration(milliseconds: 250 * (1 << bounded));
  }

  Stream<NavivoxGatewayEvent> decodeEvents(Stream<dynamic> wireEvents) {
    return wireEvents.map((event) {
      final decoded = event is String ? jsonDecode(event) : event;
      if (decoded is! Map) {
        return const NavivoxGatewayEvent(
          type: 'error',
          code: 'bad_response',
          message: 'Invalid gateway event',
        );
      }
      return NavivoxGatewayEvent.fromJson(Map<String, Object?>.from(decoded));
    });
  }

  Future<Map<String, Object?>> _getJson(Uri uri) async {
    final body = await _get(uri, config.headers);
    return _decodeObject(body);
  }

  Future<Map<String, Object?>> _postJson(
    Uri uri,
    Map<String, Object?> body,
  ) async {
    final headers = <String, String>{
      ...config.headers,
      'Content-Type': 'application/json',
    };
    return _decodeObject(await _post(uri, headers, jsonEncode(body)));
  }

  Map<String, Object?> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('expected JSON object');
    }
    return Map<String, Object?>.from(decoded);
  }

  static Future<String> _defaultGet(Uri uri, Map<String, String> headers) {
    return transport.defaultGet(uri, headers);
  }

  static Future<String> _defaultPost(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) {
    return transport.defaultPost(uri, headers, body);
  }

  static Future<NavivoxGatewaySocket> _defaultConnectWebSocket(
    Uri uri,
    Map<String, String> headers,
  ) {
    return transport.defaultConnectWebSocket(uri, headers);
  }
}
