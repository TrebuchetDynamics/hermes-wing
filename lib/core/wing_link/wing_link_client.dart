// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import '../hermes/client/hermes_api_transport.dart';
import '../hermes/client/platform/hermes_api_transport_stub.dart'
    if (dart.library.io) '../hermes/client/platform/hermes_api_transport_io.dart'
    if (dart.library.html) '../hermes/client/platform/hermes_api_transport_web.dart'
    as transport;

class WingLinkProfile {
  const WingLinkProfile({
    required this.id,
    required this.name,
    required this.revision,
    required this.source,
    required this.gatewayState,
    this.description = '',
    this.model = '',
    this.skillsCount = 0,
    this.apiRevision = '',
    this.renameRevision,
    this.deleteRevision,
  });

  factory WingLinkProfile.fromJson(Map<String, Object?> json) {
    final actions = json['actions'];
    final rename = actions is Map ? actions['rename'] : null;
    final delete = actions is Map ? actions['delete'] : null;
    return WingLinkProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      revision:
          json['topology_revision']?.toString() ??
          json['revision']?.toString() ??
          '',
      source: json['source']?.toString() ?? 'wing_link',
      gatewayState: json['gateway_state']?.toString() ?? 'unknown',
      description: json['description']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      skillsCount: json['skills_count'] is int
          ? json['skills_count']! as int
          : 0,
      apiRevision: json['api_revision']?.toString() ?? '',
      renameRevision: rename is Map ? rename['revision']?.toString() : null,
      deleteRevision: delete is Map ? delete['revision']?.toString() : null,
    );
  }

  final String id;
  final String name;
  final String revision;
  final String source;
  final String gatewayState;
  final String description;
  final String model;
  final int skillsCount;
  final String apiRevision;
  final String? renameRevision;
  final String? deleteRevision;

  bool get canRename => renameRevision?.isNotEmpty ?? false;
  bool get canDelete => deleteRevision?.isNotEmpty ?? false;
}

class WingLinkProvider {
  const WingLinkProvider({
    required this.id,
    required this.baseUrl,
    required this.model,
    required this.revision,
  });

  factory WingLinkProvider.fromJson(Map<String, Object?> json) =>
      WingLinkProvider(
        id: json['id']?.toString() ?? '',
        baseUrl: json['base_url']?.toString() ?? '',
        model: json['model']?.toString() ?? '',
        revision: json['revision']?.toString() ?? '',
      );

  final String id;
  final String baseUrl;
  final String model;
  final String revision;
}

class WingLinkException implements Exception {
  const WingLinkException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WingLinkClient {
  WingLinkClient({
    required Uri origin,
    required String token,
    HermesApiGet? get,
    HermesApiPost? post,
    HermesApiPatch? patch,
    HermesApiDelete? delete,
  }) : _origin = origin,
       _token = token,
       _get = get ?? transport.defaultGet,
       _post = post ?? transport.defaultPost,
       _patch = patch ?? transport.defaultPatch,
       _delete = delete ?? transport.defaultDelete;

  final Uri _origin;
  final String _token;
  final HermesApiGet _get;
  final HermesApiPost _post;
  final HermesApiPatch _patch;
  final HermesApiDelete _delete;

  Future<void> verifyPendingCredential() async {
    _decode(await _get(_uri('/v1/status'), _headers));
  }

  Future<void> acknowledgeCredential(String credentialId) async {
    await _post(
      _uri('/v1/auth/credentials/${Uri.encodeComponent(credentialId)}/ack'),
      _headers,
      '{}',
    );
  }

  Future<List<WingLinkProfile>> listProfiles() async {
    final json = _decode(await _get(_uri('/v1/profiles'), _headers));
    final profiles = json['profiles'];
    if (profiles is! List) {
      throw const WingLinkException('Wing Link returned invalid data');
    }
    return [
      for (final profile in profiles)
        if (profile is Map)
          WingLinkProfile.fromJson(profile.cast<String, Object?>()),
    ];
  }

  Future<List<WingLinkProvider>> listProviders({
    required String profile,
  }) async {
    final json = _decode(
      await _get(_profileUri('/v1/providers', profile), _headers),
    );
    final providers = json['providers'];
    if (providers is! List) {
      throw const WingLinkException('Wing Link returned invalid data');
    }
    return [
      for (final provider in providers)
        if (provider is Map)
          WingLinkProvider.fromJson(provider.cast<String, Object?>()),
    ];
  }

  Future<WingLinkProvider> createProvider({
    required String profile,
    required String id,
    required String baseUrl,
    required String model,
  }) => _mutateProvider(
    'POST',
    '/v1/providers',
    profile: profile,
    body: {'id': id, 'base_url': baseUrl, 'model': model},
  );

  Future<WingLinkProvider> updateProvider({
    required String profile,
    required String id,
    required String baseUrl,
    required String model,
    required String revision,
  }) => _mutateProvider(
    'PATCH',
    '/v1/providers/${Uri.encodeComponent(id)}',
    profile: profile,
    body: {'base_url': baseUrl, 'model': model, 'revision': revision},
  );

  Future<void> deleteProvider({
    required String profile,
    required String id,
    required String revision,
  }) async {
    await _delete(
      _profileUri('/v1/providers/${Uri.encodeComponent(id)}', profile),
      {..._headers, 'If-Match': revision},
    );
  }

  Future<WingLinkProfile> createProfile({
    required String name,
    String? cloneFrom,
  }) => _mutate(
    'POST',
    '/v1/profiles',
    body: {
      'name': name,
      if (cloneFrom != null && cloneFrom.isNotEmpty) 'clone_from': cloneFrom,
    },
  );

  Future<WingLinkProfile> renameProfile({
    required String id,
    required String name,
    required String revision,
  }) => _mutate(
    'PATCH',
    '/v1/profiles/${Uri.encodeComponent(id)}',
    body: {'name': name, 'revision': revision},
  );

  Future<void> deleteProfile({
    required String id,
    required String revision,
  }) async {
    await _delete(_uri('/v1/profiles/${Uri.encodeComponent(id)}'), {
      ..._headers,
      'If-Match': revision,
    });
  }

  Future<WingLinkProfile> _mutate(
    String method,
    String path, {
    required Map<String, Object?> body,
  }) async {
    final payload = jsonEncode(body);
    final response = switch (method) {
      'POST' => await _post(_uri(path), _headers, payload),
      'PATCH' => await _patch(_uri(path), _headers, payload),
      _ => throw const WingLinkException('Unsupported Wing Link request'),
    };
    final profile = _decode(response)['profile'];
    if (profile is! Map) {
      throw const WingLinkException('Wing Link returned invalid data');
    }
    return WingLinkProfile.fromJson(profile.cast<String, Object?>());
  }

  Future<WingLinkProvider> _mutateProvider(
    String method,
    String path, {
    required String profile,
    required Map<String, Object?> body,
  }) async {
    final payload = jsonEncode(body);
    final response = switch (method) {
      'POST' => await _post(_profileUri(path, profile), _headers, payload),
      'PATCH' => await _patch(_profileUri(path, profile), _headers, payload),
      _ => throw const WingLinkException('Unsupported Wing Link request'),
    };
    final provider = _decode(response)['provider'];
    if (provider is! Map) {
      throw const WingLinkException('Wing Link returned invalid data');
    }
    return WingLinkProvider.fromJson(provider.cast<String, Object?>());
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Uri _uri(String path) =>
      _origin.replace(path: path, query: null, fragment: null);

  Uri _profileUri(String path, String profile) =>
      _uri(path).replace(queryParameters: {'profile': profile});

  Map<String, Object?> _decode(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw const WingLinkException('Wing Link returned invalid data');
    }
    if (decoded is! Map) {
      throw const WingLinkException('Wing Link returned invalid data');
    }
    return decoded.cast<String, Object?>();
  }
}
