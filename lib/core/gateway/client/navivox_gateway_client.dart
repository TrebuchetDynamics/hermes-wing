import 'dart:async';
import 'dart:convert';

import '../../protocol/navivox_json.dart';
import '../../protocol/navivox_memory.dart';
import 'navivox_gateway_config.dart';
import '../capabilities/navivox_gateway_capabilities.dart';
import '../config_admin/navivox_gateway_config_admin.dart';
import '../messages/navivox_gateway_event.dart';
import '../messages/navivox_gateway_event_decoder.dart';
import '../observations/navivox_gateway_observations.dart';
import '../shared/navivox_gateway_http.dart';
import '../shared/navivox_gateway_json.dart';
import '../transport/navivox_gateway_socket_contract.dart';
import '../transport/navivox_gateway_transport_contracts.dart';
import '../voice/navivox_gateway_voice.dart';
import '../transport/navivox_gateway_transport_stub.dart'
    if (dart.library.io) '../transport/navivox_gateway_transport_io.dart'
    if (dart.library.html) '../transport/navivox_gateway_transport_web.dart'
    as transport;

/// Compatibility socket type exposed by the gateway client.
typedef NavivoxGatewaySocket = NavivoxGatewaySocketConnection;

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
  Future<NavivoxCapabilityDocument> capabilities() async {
    return NavivoxCapabilityDocument.fromJson(
      await _getJson(config.capabilitiesUri),
    );
  }

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
      ...navivoxTrimmedStringFields({
        'server_id': serverId,
        'profile_id': profileId,
        'correction': correction,
      }),
      'id': id.trim(),
      'type': type.wireValue,
      'action': action.wireValue,
    };
    return NavivoxMemoryActionResult.fromJson(
      await _postJson(config.memoryActionUri, body),
    );
  }

  Future<List<Map<String, Object?>>> profileContacts() async {
    final body = await _getJson(config.profileContactsUri);
    return navivoxMapListFromJson(body['contacts']);
  }

  Future<NavivoxProfileRoutingReport> profileRouting() async {
    return NavivoxProfileRoutingReport.fromJson(
      await _getJson(config.profileRoutingUri),
    );
  }

  Future<List<NavivoxGatewaySessionSnapshot>> sessions() async {
    final body = await _getJson(config.sessionsUri);
    return navivoxGatewayObjectListWhereHasText(
      body['sessions'],
      NavivoxGatewaySessionSnapshot.fromJson,
      (session) => session.sessionId,
    );
  }

  Future<NavivoxGatewaySessionSnapshot> session(String sessionId) async {
    final body = await _getJson(config.sessionUri(sessionId));
    return NavivoxGatewaySessionSnapshot.fromJson(
      navivoxGatewayObjectField(body, 'session'),
    );
  }

  Future<NavivoxRunRecordSnapshot> runRecord(String runIdOrSessionId) async {
    final body = await _getJson(config.runRecordUri(runIdOrSessionId));
    return NavivoxRunRecordSnapshot.fromJson(
      navivoxGatewayObjectField(body, 'run_record'),
    );
  }

  Future<NavivoxProfileSeedResult> profileSeed({
    required String seed,
    bool apply = false,
    List<String> workspaceRoots = const [],
  }) async {
    final trimmedWorkspaceRoots = navivoxTrimmedStringList(workspaceRoots);
    final body = <String, Object?>{
      'seed': seed.trim(),
      if (apply) 'apply': true,
      if (trimmedWorkspaceRoots.isNotEmpty)
        'workspace_roots': trimmedWorkspaceRoots,
    };
    return NavivoxProfileSeedResult.fromJson(
      await _postJson(config.profileSeedUri, body),
    );
  }

  Future<NavivoxConfigAdminSchemaResponse> configAdminSchema() async {
    return NavivoxConfigAdminSchemaResponse.fromJson(
      await _getJson(config.configAdminSchemaUri),
    );
  }

  Future<NavivoxConfigAdminGetResponse> configAdminValues() async {
    return NavivoxConfigAdminGetResponse.fromJson(
      await _getJson(config.configAdminUri),
    );
  }

  Future<NavivoxConfigAdminResponse> diffConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    return NavivoxConfigAdminResponse.fromJson(
      await _postJson(config.configAdminDiffUri, _configAdminBody(changes)),
    );
  }

  Future<NavivoxConfigAdminResponse> validateConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    return NavivoxConfigAdminResponse.fromJson(
      await _postJson(config.configAdminValidateUri, _configAdminBody(changes)),
    );
  }

  Future<NavivoxConfigAdminResponse> applyConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    return NavivoxConfigAdminResponse.fromJson(
      await _postJson(config.configAdminApplyUri, _configAdminBody(changes)),
    );
  }

  Future<NavivoxVoiceProfilesResponse> voiceProfiles() async {
    return NavivoxVoiceProfilesResponse.fromJson(
      await _getJson(config.voiceProfilesUri),
    );
  }

  Future<NavivoxVoiceProfileValidationResponse> validateVoiceProfile({
    required String profileId,
    required NavivoxProfileVoiceProfile voiceProfile,
  }) async {
    return NavivoxVoiceProfileValidationResponse.fromJson(
      await _postJson(config.voiceProfilesValidateUri, {
        'profile_id': profileId.trim(),
        'voice_profile': voiceProfile.toJson(),
      }),
    );
  }

  Future<NavivoxGatewaySocket> connectStream() {
    return _connectWebSocket(config.streamUri, config.headers);
  }

  Duration reconnectDelay(int attempt) {
    final bounded = attempt.clamp(0, 6).toInt();
    return Duration(milliseconds: 250 * (1 << bounded));
  }

  Stream<NavivoxGatewayEvent> decodeEvents(Stream<dynamic> wireEvents) {
    return wireEvents.map(navivoxGatewayEventFromWire);
  }

  Map<String, Object?> _configAdminBody(
    List<NavivoxConfigAdminChange> changes,
  ) {
    return {
      'changes': changes
          .map((change) => change.toJson())
          .where((change) => navivoxGatewayHasText(change['key']))
          .toList(growable: false),
    };
  }

  Future<Map<String, Object?>> _getJson(Uri uri) async {
    final body = await _get(uri, config.headers);
    return navivoxGatewayDecodeObject(body);
  }

  Future<Map<String, Object?>> _postJson(
    Uri uri,
    Map<String, Object?> body,
  ) async {
    final headers = <String, String>{
      ...config.headers,
      navivoxGatewayContentTypeHeader: navivoxGatewayJsonContentType,
    };
    return navivoxGatewayDecodeObject(
      await _post(uri, headers, jsonEncode(body)),
    );
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
