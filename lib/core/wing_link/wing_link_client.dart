// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import '../hermes/client/hermes_api_transport.dart';
import 'models/wing_link_device.dart';
import 'models/wing_link_directory.dart';

export 'models/wing_link_directory.dart';
import 'wing_link_transport.dart';

class WingLinkMetadata {
  const WingLinkMetadata({
    required this.protocolGeneration,
    required this.minimumProtocolGeneration,
    required this.supportedProtocolGenerations,
    required this.version,
    required this.hostFingerprint,
    required this.capabilities,
  });

  factory WingLinkMetadata.fromJson(Map<String, Object?> json) {
    final current = json['protocol_generation'];
    final minimum = json['minimum_protocol_generation'];
    final supported = json['supported_protocol_generations'];
    final capabilities = json['capabilities'];
    if (current is! int ||
        minimum is! int ||
        current < minimum ||
        supported is! List ||
        supported.isEmpty ||
        supported.length > 2 ||
        capabilities is! List ||
        capabilities.length > 64) {
      throw const WingLinkException('Wing Link returned invalid metadata');
    }
    final generations = <int>[];
    for (final generation in supported) {
      if (generation is! int || generations.contains(generation)) {
        throw const WingLinkException('Wing Link returned invalid metadata');
      }
      generations.add(generation);
    }
    generations.sort();
    final parsedCapabilities = <String>[];
    for (final capability in capabilities) {
      if (capability is! String ||
          capability.isEmpty ||
          capability.runes.length > 64) {
        throw const WingLinkException('Wing Link returned invalid metadata');
      }
      parsedCapabilities.add(capability);
    }
    final version = json['version']?.toString() ?? '';
    final fingerprint = json['host_fingerprint']?.toString() ?? '';
    if (version.runes.length > 64 || fingerprint.runes.length > 96) {
      throw const WingLinkException('Wing Link returned invalid metadata');
    }
    return WingLinkMetadata(
      protocolGeneration: current,
      minimumProtocolGeneration: minimum,
      supportedProtocolGenerations: List.unmodifiable(generations),
      version: version,
      hostFingerprint: fingerprint,
      capabilities: List.unmodifiable(parsedCapabilities),
    );
  }

  final int protocolGeneration;
  final int minimumProtocolGeneration;
  final List<int> supportedProtocolGenerations;
  final String version;
  final String hostFingerprint;
  final List<String> capabilities;
}

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

class WingLinkOperation {
  const WingLinkOperation({
    required this.id,
    required this.phase,
    required this.message,
    required this.percent,
    required this.terminal,
    this.errorCode = '',
  });

  factory WingLinkOperation.fromJson(Map<String, Object?> json) {
    final percent = json['percent'];
    return WingLinkOperation(
      id: json['operation_id']?.toString() ?? '',
      phase: json['phase']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      percent: percent is num ? percent.toInt().clamp(0, 100) : 0,
      terminal: json['terminal'] == true,
      errorCode: json['error_code']?.toString() ?? '',
    );
  }

  final String id;
  final String phase;
  final String message;
  final int percent;
  final bool terminal;
  final String errorCode;
}

class WingLinkException implements Exception {
  const WingLinkException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WingLinkPreconditionFailed extends WingLinkException {
  const WingLinkPreconditionFailed() : super('Wing Link HTTP 412');
}

class WingLinkUpgradeRequired extends WingLinkException {
  const WingLinkUpgradeRequired()
    : super('This Wing Link host requires a compatible Hermes Wing version');
}

class WingLinkApprovalRequired extends WingLinkException {
  const WingLinkApprovalRequired({
    required this.approvalId,
    required this.operationId,
    required this.idempotencyKey,
    required this.expiresAt,
  }) : super('This operation requires approval on the Wing Link host');

  final String approvalId;
  final String operationId;
  final String idempotencyKey;
  final int expiresAt;
}

class WingLinkClient {
  factory WingLinkClient({
    required Uri origin,
    required String token,
    String? hostFingerprint,
    HermesApiGet? get,
    HermesApiPost? post,
    HermesApiPatch? patch,
    HermesApiDelete? delete,
  }) {
    final transport = WingLinkTransport(
      expectedHostFingerprint: hostFingerprint,
    );
    return WingLinkClient._(
      origin: origin,
      token: token,
      get: get ?? transport.get,
      post: post ?? transport.post,
      patch: patch ?? transport.patch,
      delete: delete ?? transport.delete,
    );
  }

  const WingLinkClient._({
    required Uri origin,
    required String token,
    required HermesApiGet get,
    required HermesApiPost post,
    required HermesApiPatch patch,
    required HermesApiDelete delete,
  }) : _origin = origin,
       _token = token,
       _get = get,
       _post = post,
       _patch = patch,
       _delete = delete;

  final Uri _origin;
  final String _token;
  final HermesApiGet _get;
  final HermesApiPost _post;
  final HermesApiPatch _patch;
  final HermesApiDelete _delete;

  Future<WingLinkMetadata> getMetadata() async {
    final Map<String, Object?> json;
    try {
      json = _decode(await _get(_uri('/meta'), _headers));
    } catch (error) {
      if (error.toString().contains('HTTP 426')) {
        throw const WingLinkUpgradeRequired();
      }
      rethrow;
    }
    final metadata = WingLinkMetadata.fromJson(json);
    if (!metadata.supportedProtocolGenerations.any(
      (generation) => generation == 1 || generation == 2,
    )) {
      throw const WingLinkUpgradeRequired();
    }
    return metadata;
  }

  Future<void> verifyPendingCredential() async {
    _decode(await _get(_uri('/v1/status'), _headers));
  }

  Future<List<WingLinkDirectory>> listDirectoryRoots() async {
    final json = _decode(await _get(_uri('/v2/directories'), _headers));
    try {
      return WingLinkDirectoryPage.fromJson(
        json,
        maximumDirectories: 32,
        allowNextOffset: false,
      ).directories;
    } on FormatException {
      throw const WingLinkException(
        'Wing Link returned invalid directory data',
      );
    }
  }

  Future<WingLinkDirectoryPage> listChildDirectories({
    required String handle,
    int offset = 0,
    int limit = 50,
  }) async {
    if (!WingLinkDirectory.isValidHandle(handle) ||
        offset < 0 ||
        offset > 1000 ||
        limit < 1 ||
        limit > 100) {
      throw const WingLinkException('Wing Link directory request is invalid');
    }
    final uri = _uri('/v2/directories/${Uri.encodeComponent(handle)}/children')
        .replace(
          queryParameters: {
            'offset': offset.toString(),
            'limit': limit.toString(),
          },
        );
    final json = _decode(await _get(uri, _headers));
    try {
      return WingLinkDirectoryPage.fromJson(
        json,
        maximumDirectories: 100,
        allowNextOffset: true,
      );
    } on FormatException {
      throw const WingLinkException(
        'Wing Link returned invalid directory data',
      );
    }
  }

  Future<WingLinkDevice> getCurrentDevice() async {
    final json = _decode(await _get(_uri('/v2/devices/self'), _headers));
    try {
      return WingLinkDevice.fromJson(json);
    } on FormatException {
      throw const WingLinkException('Wing Link returned invalid device data');
    }
  }

  Future<void> revokeCurrentDevice() async {
    await _delete(_uri('/v2/devices/self'), _headers);
  }

  Future<void> acknowledgeCredential(String credentialId) async {
    await _post(
      _uri('/v1/auth/credentials/${Uri.encodeComponent(credentialId)}/ack'),
      _headers,
      '{}',
    );
  }

  Future<String> startSetup({String? idempotencyKey}) async {
    final key =
        idempotencyKey ??
        'setup-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    if (!_idempotencyKeyPattern.hasMatch(key)) {
      throw const WingLinkException('Wing Link idempotency key is invalid');
    }
    final json = _decode(
      await _post(_uri('/v1/setup'), {
        ..._headers,
        'Idempotency-Key': key,
      }, '{}'),
    );
    final operationId = json['operation_id']?.toString() ?? '';
    _requireOperationId(operationId);
    final error = json['error'];
    if (error is Map && error['code'] == 'approval_required') {
      final approvalId = json['approval_id']?.toString() ?? '';
      final expiresAt = json['expires_at'];
      if (!_approvalIdPattern.hasMatch(approvalId) ||
          expiresAt is! int ||
          !_validApprovalExpiry(expiresAt)) {
        throw const WingLinkException(
          'Wing Link returned invalid approval data',
        );
      }
      throw WingLinkApprovalRequired(
        approvalId: approvalId,
        operationId: operationId,
        idempotencyKey: key,
        expiresAt: expiresAt,
      );
    }
    return operationId;
  }

  Future<WingLinkOperation> getOperation(String operationId) async {
    _requireOperationId(operationId);
    final json = _decode(
      await _get(
        _uri('/v1/operations/${Uri.encodeComponent(operationId)}'),
        _headers,
      ),
    );
    final operation = WingLinkOperation.fromJson(json);
    if (operation.id != operationId || operation.phase.isEmpty) {
      throw const WingLinkException('Wing Link returned invalid data');
    }
    return operation;
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

  Future<WingLinkProfile> createProfile({
    required String name,
    String? cloneFrom,
    String? description,
    String? provider,
    String? model,
    String? providerApiKey,
    String? idempotencyKey,
  }) => _mutate(
    'POST',
    '/v1/profiles',
    body: {
      'name': name,
      if (cloneFrom != null && cloneFrom.isNotEmpty) 'clone_from': cloneFrom,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (provider != null && provider.trim().isNotEmpty)
        'provider': provider.trim(),
      if (model != null && model.trim().isNotEmpty) 'model': model.trim(),
      if (providerApiKey != null && providerApiKey.isNotEmpty)
        'provider_api_key': providerApiKey,
    },
    idempotencyKey: idempotencyKey,
    expectedCreatedProfileId: name,
  );

  Future<WingLinkProfile> renameProfile({
    required String id,
    required String name,
    required String revision,
  }) => _profileMutation(
    () => _mutate(
      'PATCH',
      '/v1/profiles/${Uri.encodeComponent(id)}',
      body: {'name': name, 'revision': revision},
    ),
  );

  Future<void> deleteProfile({
    required String id,
    required String revision,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _newIdempotencyKey('profile-delete');
    final response = await _profileMutation(
      () => _delete(_uri('/v1/profiles/${Uri.encodeComponent(id)}'), {
        ..._headers,
        'If-Match': revision,
        'Idempotency-Key': key,
      }),
    );
    if (response.trim().isEmpty) return;
    final json = _decode(response);
    _throwIfApprovalRequired(json, key);
    if (json['replayed'] == true && !_isSuccessfulTerminalReplay(json)) {
      throw const WingLinkException('Wing Link profile deletion failed');
    }
  }

  Future<T> _profileMutation<T>(Future<T> Function() mutation) async {
    try {
      return await mutation();
    } catch (error) {
      if (error.toString().contains('HTTP 412')) {
        throw const WingLinkPreconditionFailed();
      }
      rethrow;
    }
  }

  Future<WingLinkProfile> _mutate(
    String method,
    String path, {
    required Map<String, Object?> body,
    String? idempotencyKey,
    String? expectedCreatedProfileId,
  }) async {
    final payload = jsonEncode(body);
    final key = idempotencyKey ?? _newIdempotencyKey('profile-mutation');
    final headers = {..._headers, 'Idempotency-Key': key};
    final response = switch (method) {
      'POST' => await _post(_uri(path), headers, payload),
      'PATCH' => await _patch(_uri(path), headers, payload),
      _ => throw const WingLinkException('Unsupported Wing Link request'),
    };
    final json = _decode(response);
    _throwIfApprovalRequired(json, key);
    final profile = json['profile'];
    if (profile is Map) {
      return WingLinkProfile.fromJson(profile.cast<String, Object?>());
    }
    final normalizedExpectedProfileId = expectedCreatedProfileId
        ?.trim()
        .toLowerCase();
    if (normalizedExpectedProfileId == null ||
        !_profileIdPattern.hasMatch(normalizedExpectedProfileId) ||
        !_isSuccessfulTerminalReplay(json)) {
      throw const WingLinkException('Wing Link returned invalid data');
    }
    final matches = (await listProfiles())
        .where((profile) => profile.id == normalizedExpectedProfileId)
        .toList(growable: false);
    if (matches.length != 1) {
      throw const WingLinkException(
        'Wing Link could not reconcile the created profile',
      );
    }
    return matches.single;
  }

  void _throwIfApprovalRequired(
    Map<String, Object?> json,
    String idempotencyKey,
  ) {
    final error = json['error'];
    if (error is! Map || error['code'] != 'approval_required') {
      return;
    }
    final approvalId = json['approval_id']?.toString() ?? '';
    final operationId = json['operation_id']?.toString() ?? '';
    final expiresAt = json['expires_at'];
    if (!_approvalIdPattern.hasMatch(approvalId) ||
        !_operationIdPattern.hasMatch(operationId) ||
        expiresAt is! int ||
        !_validApprovalExpiry(expiresAt)) {
      throw const WingLinkException('Wing Link returned invalid approval data');
    }
    throw WingLinkApprovalRequired(
      approvalId: approvalId,
      operationId: operationId,
      idempotencyKey: idempotencyKey,
      expiresAt: expiresAt,
    );
  }

  bool _isSuccessfulTerminalReplay(Map<String, Object?> json) {
    if (json['replayed'] != true) return false;
    final operationId = json['operation_id']?.toString() ?? '';
    final operationJson = json['operation'];
    if (!_operationIdPattern.hasMatch(operationId) || operationJson is! Map) {
      return false;
    }
    final operation = operationJson.cast<String, Object?>();
    final percent = operation['percent'];
    final errorCode = operation['error_code'];
    return operation['operation_id'] == operationId &&
        operation['terminal'] == true &&
        operation['phase'] == 'committed' &&
        percent is int &&
        percent == 100 &&
        (errorCode == null || errorCode == '');
  }

  bool _validApprovalExpiry(int expiresAt) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expiresAt > now && expiresAt <= now + 5 * 60 + 5;
  }

  String _newIdempotencyKey(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Wing-Protocol': '2',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static final RegExp _operationIdPattern = RegExp(r'^op_[A-Za-z0-9_-]{1,92}$');
  static final RegExp _approvalIdPattern = RegExp(
    r'^appr_[A-Za-z0-9_-]{1,91}$',
  );
  static final RegExp _idempotencyKeyPattern = RegExp(r'^[!-~]{1,128}$');
  static final RegExp _profileIdPattern = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');

  void _requireOperationId(String value) {
    if (!_operationIdPattern.hasMatch(value)) {
      throw const WingLinkException('Wing Link operation ID is invalid');
    }
  }

  Uri _uri(String path) =>
      _origin.replace(path: path, query: null, fragment: null);

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
    final json = decoded.cast<String, Object?>();
    final generation = json['protocol_version'];
    if (generation != null && generation != 1 && generation != 2) {
      throw const WingLinkUpgradeRequired();
    }
    return json;
  }
}
