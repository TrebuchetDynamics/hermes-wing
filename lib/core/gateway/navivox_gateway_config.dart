import '../protocol/navivox_json.dart';
import '../protocol/navivox_memory.dart';

class NavivoxGatewayConfig {
  const NavivoxGatewayConfig({
    required this.baseUri,
    this.token,
    this.webSocketUri,
  });

  factory NavivoxGatewayConfig.fromBaseUrl(String baseUrl, {String? token}) {
    return NavivoxGatewayConfig(baseUri: Uri.parse(baseUrl), token: token);
  }

  final Uri baseUri;
  final String? token;
  final Uri? webSocketUri;

  Uri get healthUri => _withPath('/healthz');
  Uri get statusUri => _withPath('/v1/navivox/status');
  Uri get capabilitiesUri => _withPath('/v1/navivox/capabilities');
  Uri get profileContactsUri => _withPath('/v1/navivox/profile-contacts');
  Uri get profileRoutingUri => _withPath('/v1/navivox/profile-routing');
  Uri get profileSeedUri => _withPath('/v1/navivox/profile-seed');
  Uri get configAdminUri => _withPath('/v1/navivox/config-admin');
  Uri get configAdminSchemaUri => _withPath('/v1/navivox/config-admin/schema');
  Uri get configAdminDiffUri => _withPath('/v1/navivox/config-admin/diff');
  Uri get configAdminValidateUri =>
      _withPath('/v1/navivox/config-admin/validate');
  Uri get configAdminApplyUri => _withPath('/v1/navivox/config-admin/apply');
  Uri get voiceProfilesUri => _withPath('/v1/navivox/voice-profiles');
  Uri get voiceProfilesValidateUri =>
      _withPath('/v1/navivox/voice-profiles/validate');
  Uri get memoryActionUri => _withPath('/v1/navivox/memory/action');
  Uri memoryOverviewUri({String? serverId, String? profileId}) {
    final query = navivoxTrimmedStringFields({
      'server_id': serverId,
      'profile_id': profileId,
    });
    return _withPath(
      '/v1/navivox/memory/overview',
    ).replace(queryParameters: query.isEmpty ? null : query);
  }

  Uri memorySearchUri({
    String? serverId,
    String? profileId,
    String? query,
    NavivoxMemoryType type = NavivoxMemoryType.all,
    int limit = 20,
    String? pageToken,
  }) {
    final params = <String, String>{
      ...navivoxTrimmedStringFields({
        'server_id': serverId,
        'profile_id': profileId,
        'q': query,
        'page_token': pageToken,
      }),
      if (type != NavivoxMemoryType.all) 'type': type.wireValue,
      if (limit > 0) 'limit': limit.toString(),
    };
    return _withPath(
      '/v1/navivox/memory/search',
    ).replace(queryParameters: params.isEmpty ? null : params);
  }

  Uri memoryDetailUri({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
  }) {
    final params = <String, String>{
      ...navivoxTrimmedStringFields({
        'server_id': serverId,
        'profile_id': profileId,
      }),
      'id': id.trim(),
      if (type != NavivoxMemoryType.all) 'type': type.wireValue,
    };
    return _withPath(
      '/v1/navivox/memory/detail',
    ).replace(queryParameters: params);
  }

  Uri get sessionsUri => _withPath('/v1/navivox/sessions');
  Uri sessionUri(String sessionId) => _withPath(
    '/v1/navivox/sessions/${Uri.encodeComponent(sessionId.trim())}',
  );
  Uri runRecordUri(String runIdOrSessionId) => _withPath(
    '/v1/navivox/run-records/${Uri.encodeComponent(runIdOrSessionId.trim())}',
  );
  Uri get turnUri => _withPath('/v1/navivox/turn');

  Uri get streamUri {
    final explicit = webSocketUri;
    if (explicit != null) return explicit;
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
