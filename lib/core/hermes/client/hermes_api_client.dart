import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../protocol/wing_json.dart';
import '../models/hermes_capabilities.dart';
import '../models/hermes_health.dart';
import '../models/hermes_job.dart';
import '../models/hermes_model_assignment.dart';
import '../models/hermes_profile.dart';
import '../models/hermes_provider.dart';
import '../models/hermes_run.dart';
import '../models/hermes_runtime_model.dart';
import '../models/hermes_session.dart';
import '../models/hermes_skill.dart';
import '../models/hermes_toolset.dart';
import '../shared/hermes_api_http.dart';
import '../sse/hermes_sse_event_decoder.dart';
import 'hermes_api_config.dart';
import 'hermes_api_transport.dart';
import 'platform/hermes_api_transport_stub.dart'
    if (dart.library.io) 'platform/hermes_api_transport_io.dart'
    if (dart.library.html) 'platform/hermes_api_transport_web.dart'
    as transport;

class HermesApiClient {
  HermesApiClient({
    required this.config,
    HermesApiGet? get,
    HermesApiPost? post,
    HermesApiPatch? patch,
    HermesApiPut? put,
    HermesApiDelete? delete,
    HermesApiPostStream? postStream,
    HermesApiGetStream? getStream,
    this.requestTimeout = const Duration(seconds: 20),
  }) : _get = get ?? transport.defaultGet,
       _post = post ?? transport.defaultPost,
       _patch = patch ?? transport.defaultPatch,
       _put = put ?? transport.defaultPut,
       _delete = delete ?? transport.defaultDelete,
       _postStream = postStream ?? transport.defaultPostStream,
       _getStream = getStream ?? transport.defaultGetStream;

  final HermesApiConfig config;
  final HermesApiGet _get;
  final HermesApiPost _post;
  final HermesApiPatch _patch;
  final HermesApiPut _put;
  final HermesApiDelete _delete;
  final HermesApiPostStream _postStream;
  final HermesApiGetStream _getStream;
  final Duration requestTimeout;

  Future<HermesHealthStatus> health() async {
    return HermesHealthStatus.fromJson(await _getJson(config.healthUri));
  }

  Future<HermesHealthStatus> healthDetailed() async {
    return HermesHealthStatus.fromJson(
      await _getJson(config.healthDetailedUri),
    );
  }

  Future<HermesCapabilityDocument> capabilities() async {
    return HermesCapabilityDocument.fromJson(
      await _getJson(config.capabilitiesUri),
    );
  }

  Future<List<String>> listModels({String? profile}) async {
    return (await listRuntimeModels(
      profile: profile,
    )).map((model) => model.id).toList(growable: false);
  }

  Future<List<HermesRuntimeModel>> listRuntimeModels({String? profile}) async {
    final body = await _getJson(_scoped(config.modelsUri, profile));
    final models = <String, HermesRuntimeModel>{};
    for (final row in wingMapListFromJson(body['data'])) {
      final model = HermesRuntimeModel.fromJson(row);
      if (model.id.isNotEmpty) models.putIfAbsent(model.id, () => model);
      if (models.length == 128) break;
    }
    return List.unmodifiable(models.values);
  }

  Future<List<String>> listSkills({String? profile}) async {
    return (await listSkillDetails(
      profile: profile,
    )).map((skill) => skill.name).toList(growable: false);
  }

  Future<List<HermesSkill>> listSkillDetails({String? profile}) async {
    final body = await _getJson(_scoped(config.skillsUri, profile));
    return wingMapListFromJson(body['data'])
        .map(HermesSkill.fromJson)
        .where((skill) => skill.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<HermesToolset>> listToolsets({String? profile}) async {
    final body = await _getJson(_scoped(config.toolsetsUri, profile));
    return wingMapListFromJson(body['data'])
        .map(HermesToolset.fromJson)
        .where((toolset) => toolset.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> listEnabledToolsets({String? profile}) async {
    return (await listToolsets(profile: profile))
        .where((toolset) => toolset.enabled)
        .map((toolset) => toolset.name)
        .toList(growable: false);
  }

  Future<List<HermesSession>> listSessions({String? profile}) async {
    final body = await _getJson(_scoped(config.sessionsUri, profile));
    return wingMapListFromJson(body['data'])
        .map(HermesSession.fromJson)
        .where((session) => session.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<HermesJob>> listJobs({String? profile}) async {
    final body = await _getJson(_scoped(config.jobsUri, profile));
    final rawJobs = body['jobs'] ?? body['data'];
    return wingMapListFromJson(rawJobs)
        .map(HermesJob.fromJson)
        .where((job) => job.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<HermesSession> createSession({
    required String id,
    String? title,
    String? model,
    String? systemPrompt,
    String? profile,
  }) async {
    final body = <String, Object?>{
      'id': id.trim(),
      ...wingTrimmedStringFields({
        'title': title,
        'model': model,
        'system_prompt': systemPrompt,
      }),
    };
    final response = await _postJson(
      _scoped(config.sessionsUri, profile),
      body,
    );
    return HermesSession.fromJson(wingMapFieldFromJson(response, 'session'));
  }

  Future<List<HermesMessage>> sessionMessages(
    String sessionId, {
    String? profile,
  }) async {
    final body = await _getJson(
      _scoped(config.sessionMessagesUri(sessionId), profile),
    );
    return wingMapListFromJson(
      body['data'],
    ).map(HermesMessage.fromJson).toList(growable: false);
  }

  Future<HermesSession> updateSessionTitle(
    String sessionId, {
    required String title,
    String? profile,
  }) async {
    final response = await _patchJson(
      _scoped(config.sessionUri(sessionId), profile),
      {'title': title.trim()},
    );
    return HermesSession.fromJson(wingMapFieldFromJson(response, 'session'));
  }

  Future<void> deleteSession(String sessionId, {String? profile}) async {
    final trimmed = sessionId.trim();
    final response = await _deleteJson(
      _scoped(config.sessionUri(trimmed), profile),
    );
    final id = wingOptionalStringFromJson(response['id']);
    final deleted = wingBoolFromJson(response['deleted']);
    if (id != trimmed || !deleted) {
      throw StateError('Hermes session delete was not confirmed.');
    }
  }

  Future<HermesSession> forkSession(
    String sourceSessionId, {
    required String id,
    String? title,
    String? profile,
  }) async {
    final response = await _postJson(
      _scoped(config.sessionForkUri(sourceSessionId), profile),
      {
        'id': id.trim(),
        ...wingTrimmedStringFields({'title': title}),
      },
    );
    return HermesSession.fromJson(wingMapFieldFromJson(response, 'session'));
  }

  Stream<HermesStreamEvent> streamSessionChat(
    String sessionId, {
    required Object message,
    String? profile,
  }) {
    final headers = <String, String>{
      ...config.headers,
      hermesApiContentTypeHeader: hermesApiJsonContentType,
      hermesApiAcceptHeader: hermesApiEventStreamContentType,
      hermesApiCacheControlHeader: hermesApiNoCache,
    };
    final body = jsonEncode({'message': message});
    final chunks = _postStream(
      _scoped(config.sessionChatStreamUri(sessionId), profile),
      headers,
      body,
    );
    return const HermesSseEventDecoder().decodeJsonEventStream(chunks);
  }

  Future<String> transcribePcm16(Uint8List pcm16, {String? profile}) async {
    final wav = _pcm16MonoWav(pcm16, sampleRate: 16000);
    final response = await _postJson(
      _scoped(config.audioTranscribeUri, profile),
      {'data_url': 'data:audio/wav;base64,${base64Encode(wav)}'},
    );
    final transcript = wingStringFromJson(
      response['transcript'],
      fallback: '',
    ).trim();
    if (transcript.isEmpty) {
      throw const FormatException('Hermes returned an empty transcript.');
    }
    return transcript;
  }

  Future<Uint8List> synthesizeSpeech(String text, {String? profile}) async {
    final response = await _postJson(_scoped(config.audioSpeakUri, profile), {
      'text': text.trim(),
    });
    final dataUrl = wingStringFromJson(response['data_url'], fallback: '');
    final data = UriData.parse(dataUrl);
    if (!data.isBase64 || !data.mimeType.startsWith('audio/')) {
      throw const FormatException('Hermes returned invalid speech audio.');
    }
    final bytes = data.contentAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('Hermes returned empty speech audio.');
    }
    return bytes;
  }

  Future<HermesRun> startRun({
    required String sessionId,
    required Object message,
    String? profile,
  }) async {
    final input = message is String
        ? message
        : [
            {'role': 'user', 'content': message},
          ];
    final response = await _postJson(_scoped(config.runsUri, profile), {
      'session_id': sessionId,
      // Hermes Agent 0.18 accepts `input`; older test fixtures accepted
      // `message`. Send both so the client remains compatible across the
      // transition while parsing either flat or enveloped run responses below.
      'input': input,
      'message': message,
    });
    final run = response['run'] is Map
        ? wingMapFromJson(response['run'])
        : response;
    final parsed = HermesRun.fromJson(run);
    if (parsed.sessionId.isNotEmpty) return parsed;
    return HermesRun(
      id: parsed.id,
      sessionId: sessionId,
      status: parsed.status,
      output: parsed.output,
      error: parsed.error,
      usage: parsed.usage,
    );
  }

  Future<HermesRun> getRunStatus(String runId, {String? profile}) async {
    return HermesRun.fromJson(
      await _getJson(_scoped(config.runUri(runId), profile)),
    );
  }

  Stream<HermesStreamEvent> runEvents(String runId, {String? profile}) {
    final headers = <String, String>{
      ...config.headers,
      hermesApiAcceptHeader: hermesApiEventStreamContentType,
      hermesApiCacheControlHeader: hermesApiNoCache,
    };
    final chunks = _getStream(
      _scoped(config.runEventsUri(runId), profile),
      headers,
    );
    return const HermesSseEventDecoder().decodeJsonEventStream(chunks);
  }

  Future<void> respondApproval({
    required String runId,
    required String approvalId,
    required String decision,
    String? profile,
  }) async {
    await _postJson(_scoped(config.runApprovalUri(runId), profile), {
      'approval_id': approvalId,
      'decision': decision,
    });
  }

  Future<void> stopRun(String runId, {String? profile}) async {
    await _postJson(_scoped(config.runStopUri(runId), profile), const {});
  }

  /// Inspects a one-time pairing code against the operator-supplied
  /// [origin] so the operator can review label/scopes/expiry before
  /// exchanging it. Unauthenticated by design: this never sends this
  /// client's configured bearer header, even when [origin] matches
  /// [config].
  Future<HermesEnrollmentPreview> inspectEnrollment({
    required Uri origin,
    required String code,
  }) async {
    final originConfig = HermesApiConfig.fromBaseUrl(origin.toString());
    return HermesEnrollmentPreview.fromJson(
      await _postJsonUnauthenticated(originConfig.enrollmentInspectUri, {
        'origin': origin.toString(),
        'code': code,
      }),
    );
  }

  /// Exchanges a one-time pairing code for a bearer token, once, after
  /// operator confirmation. Unauthenticated by design; see
  /// [inspectEnrollment]. The returned raw token must never be logged or
  /// displayed — persist it only via `HermesEndpointStore.save`.
  Future<HermesIssuedOperatorToken> exchangeEnrollment({
    required Uri origin,
    required String code,
  }) async {
    final originConfig = HermesApiConfig.fromBaseUrl(origin.toString());
    return HermesIssuedOperatorToken.fromJson(
      await _postJsonUnauthenticated(originConfig.enrollmentExchangeUri, {
        'origin': origin.toString(),
        'code': code,
      }),
    );
  }

  Future<List<HermesProfile>> listProfiles() async {
    final body = await _getJson(config.profilesUri);
    return wingMapListFromJson(body['data'])
        .map(HermesProfile.fromJson)
        .where((profile) => profile.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<HermesProfile> createProfile({
    required String name,
    String? cloneFrom,
  }) async {
    final response = await _postJson(config.profilesUri, {
      'name': name.trim(),
      ...wingTrimmedStringFields({'clone_from': cloneFrom}),
    });
    return HermesProfile.fromJson(_profileEnvelope(response));
  }

  Future<HermesProfile> renameProfile({
    required String profileId,
    required String name,
    required String revision,
  }) async {
    final response = await _patchJson(config.profileUri(profileId), {
      'name': name.trim(),
    }, ifMatch: revision);
    return HermesProfile.fromJson(_profileEnvelope(response));
  }

  Future<void> deleteProfile({
    required String profileId,
    required String revision,
  }) async {
    final trimmed = profileId.trim();
    final response = await _deleteJson(
      config.profileUri(trimmed),
      ifMatch: revision,
    );
    final id = wingOptionalStringFromJson(response['id']);
    final deleted = wingBoolFromJson(response['deleted']);
    if (id != trimmed || !deleted) {
      throw StateError('Hermes profile delete was not confirmed.');
    }
  }

  Future<HermesProfileSoul> readProfileSoul(String profileId) async {
    final uri = config.profileScopedUri(
      config.profileSoulUri(profileId),
      profileId,
    );
    return HermesProfileSoul.fromJson(await _getJson(uri));
  }

  Future<HermesProfileSoul> writeProfileSoul({
    required String profileId,
    required String soul,
    required String revision,
  }) async {
    final uri = config.profileScopedUri(
      config.profileSoulUri(profileId),
      profileId,
    );
    return HermesProfileSoul.fromJson(
      await _putJson(uri, {'soul': soul}, ifMatch: revision),
    );
  }

  /// Lists providers and their write-only credential presence for [profile].
  /// Rows with a blank slug are discarded. The response body never carries a
  /// raw key — only `configured` and a masked `key_hint`.
  Future<List<HermesProvider>> listProviders({required String profile}) async {
    final body = await _getJson(
      config.profileScopedUri(config.providersUri, profile),
    );
    return wingMapListFromJson(body['data'])
        .map(HermesProvider.fromJson)
        .where((provider) => provider.slug.isNotEmpty)
        .toList(growable: false);
  }

  /// Sets a provider credential, write-only. [value] is transmitted in the PUT
  /// body but is NEVER stored on this client or returned to callers: the
  /// response carries only updated presence for the provider.
  Future<HermesProvider> setProviderCredential({
    required String slug,
    required String envVar,
    required String value,
    required String profile,
  }) async {
    final uri = config.profileScopedUri(
      config.providerCredentialUri(slug),
      profile,
    );
    final response = await _putJson(uri, {'env_var': envVar, 'value': value});
    return HermesProvider.fromJson(wingMapFieldFromJson(response, 'data'));
  }

  /// Removes a provider credential and returns updated presence. [envVar] is
  /// sent as a query parameter (the transport has no DELETE body).
  Future<HermesProvider> removeProviderCredential({
    required String slug,
    required String envVar,
    required String profile,
  }) async {
    final scoped = config.profileScopedUri(
      config.providerCredentialUri(slug),
      profile,
    );
    final uri = scoped.replace(
      queryParameters: {...scoped.queryParameters, 'env_var': envVar},
    );
    final response = await _deleteJson(uri);
    return HermesProvider.fromJson(wingMapFieldFromJson(response, 'data'));
  }

  /// Probes the stored credential for [slug]. Returns only `{ok, detail}`; the
  /// detail is a non-secret string that never carries the credential.
  Future<HermesCredentialProbe> validateProviderCredential({
    required String slug,
    required String profile,
  }) async {
    final uri = config.profileScopedUri(
      config.providerCredentialValidateUri(slug),
      profile,
    );
    return HermesCredentialProbe.fromJson(await _postJson(uri, const {}));
  }

  /// Reads the cached model catalog plus the active/auxiliary assignment for
  /// [profile]. Makes no outbound catalog fetch — that is [refreshModelCatalog].
  Future<HermesModelInventory> getModelInventory({
    required String profile,
  }) async {
    final body = await _getJson(
      config.profileScopedUri(config.modelCatalogUri, profile),
    );
    return HermesModelInventory.fromJson(body);
  }

  /// Triggers the one gated outbound catalog fetch and returns the refreshed
  /// catalog (no assignment change).
  Future<HermesModelCatalog> refreshModelCatalog({
    required String profile,
  }) async {
    final body = await _postJson(
      config.profileScopedUri(config.modelRefreshUri, profile),
      const {},
    );
    return HermesModelCatalog.fromJson(body['catalog']);
  }

  /// Assigns a model to the main or an auxiliary slot with an `If-Match`
  /// precondition on [revision]. Returns the new active/auxiliary + revision.
  Future<HermesModelAssignment> assignModel({
    required String scope,
    String? task,
    required String provider,
    required String model,
    required String revision,
    required String profile,
  }) async {
    final uri = config.profileScopedUri(config.modelAssignmentUri, profile);
    final body = <String, Object?>{
      'scope': scope,
      'provider': provider,
      'model': model,
      ...wingTrimmedStringFields({'task': task}),
    };
    final response = await _putJson(uri, body, ifMatch: revision);
    return HermesModelAssignment.fromJson(response);
  }

  Map<String, Object?> _profileEnvelope(Map<String, Object?> response) {
    return response['profile'] is Map
        ? wingMapFromJson(response['profile'])
        : response;
  }

  Uri _scoped(Uri uri, String? profile) {
    return profile == null ? uri : config.profileScopedUri(uri, profile);
  }

  Future<Map<String, Object?>> _getJson(Uri uri) async {
    return _decodeObject(await _bounded(_get(uri, config.headers), uri));
  }

  Future<Map<String, Object?>> _postJson(
    Uri uri,
    Map<String, Object?> body,
  ) async {
    final headers = <String, String>{
      ...config.headers,
      hermesApiContentTypeHeader: hermesApiJsonContentType,
    };
    return _decodeObject(
      await _bounded(_post(uri, headers, jsonEncode(body)), uri),
    );
  }

  Future<Map<String, Object?>> _patchJson(
    Uri uri,
    Map<String, Object?> body, {
    String? ifMatch,
  }) async {
    final headers = <String, String>{
      ...config.headers,
      hermesApiContentTypeHeader: hermesApiJsonContentType,
      ..._ifMatchHeader(ifMatch),
    };
    return _decodeObject(
      await _bounded(_patch(uri, headers, jsonEncode(body)), uri),
    );
  }

  Future<Map<String, Object?>> _putJson(
    Uri uri,
    Map<String, Object?> body, {
    String? ifMatch,
  }) async {
    final headers = <String, String>{
      ...config.headers,
      hermesApiContentTypeHeader: hermesApiJsonContentType,
      ..._ifMatchHeader(ifMatch),
    };
    return _decodeObject(
      await _bounded(_put(uri, headers, jsonEncode(body)), uri),
    );
  }

  Future<Map<String, Object?>> _deleteJson(Uri uri, {String? ifMatch}) async {
    final headers = <String, String>{
      ...config.headers,
      ..._ifMatchHeader(ifMatch),
    };
    return _decodeObject(await _bounded(_delete(uri, headers), uri));
  }

  /// Builds the optimistic-concurrency precondition header. A blank revision
  /// is omitted so the server answers `428 Precondition Required` rather than
  /// silently accepting an unconditional write.
  Map<String, String> _ifMatchHeader(String? revision) {
    final value = revision?.trim();
    if (value == null || value.isEmpty) return const {};
    return {hermesApiIfMatchHeader: value};
  }

  /// Posts JSON without any bearer credential, regardless of [config]. Used
  /// only by the unauthenticated one-time enrollment endpoints so a saved
  /// API key is never attached to an inspect/exchange request.
  Future<Map<String, Object?>> _postJsonUnauthenticated(
    Uri uri,
    Map<String, Object?> body,
  ) async {
    const headers = {hermesApiContentTypeHeader: hermesApiJsonContentType};
    return _decodeObject(
      await _bounded(_post(uri, headers, jsonEncode(body)), uri),
    );
  }

  Future<T> _bounded<T>(Future<T> request, Uri uri) {
    return request.timeout(
      requestTimeout,
      onTimeout: () => throw TimeoutException(
        'Hermes API request timed out: ${uri.path}',
        requestTimeout,
      ),
    );
  }

  Map<String, Object?> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Hermes API response must be a JSON object');
    }
    return wingMapFromJson(decoded);
  }
}

/// Server-side inspection of a one-time pairing code: what an operator is
/// about to grant before they confirm the exchange. Carries no secret.
class HermesEnrollmentPreview {
  const HermesEnrollmentPreview({
    required this.label,
    required this.origin,
    required this.scopes,
    this.expiresAt,
  });

  factory HermesEnrollmentPreview.fromJson(Map<String, Object?> json) {
    return HermesEnrollmentPreview(
      label: wingStringFromJson(json['label'], fallback: ''),
      origin: wingStringFromJson(json['origin'], fallback: ''),
      scopes: wingStringListFromJson(json['scopes']),
      expiresAt: _epochSecondsToUtcDateTime(json['expires_at']),
    );
  }

  final String label;
  final String origin;
  final List<String> scopes;
  final DateTime? expiresAt;
}

/// Result of a successful one-time enrollment exchange. [token] is the raw
/// bearer credential, returned exactly once by the server; callers must
/// persist it via `HermesEndpointStore.save` and never log or display it.
class HermesIssuedOperatorToken {
  const HermesIssuedOperatorToken({
    required this.token,
    this.label = '',
    this.credentialId = '',
    this.wingLinkOrigin = '',
    this.wingLinkToken = '',
    this.wingLinkCredentialId = '',
    this.connections = const [],
  });

  factory HermesIssuedOperatorToken.fromJson(Map<String, Object?> json) {
    final rawConnections = json['connections'];
    final connections = <HermesIssuedConnection>[];
    if (json.containsKey('connections')) {
      if (rawConnections is! List || rawConnections.isEmpty) {
        throw const FormatException('Hermes connection bundle is invalid.');
      }
      for (final row in rawConnections) {
        if (row is! Map) {
          throw const FormatException('Hermes connection bundle is invalid.');
        }
        final connection = HermesIssuedConnection.fromJson(
          Map<String, Object?>.from(row),
        );
        if (connection.origin.isEmpty ||
            connection.token.isEmpty ||
            connection.profileId.isEmpty ||
            connection.credentialId.isEmpty) {
          throw const FormatException('Hermes connection bundle is invalid.');
        }
        connections.add(connection);
      }
    }
    return HermesIssuedOperatorToken(
      token: wingStringFromJson(json['token'], fallback: ''),
      label: wingStringFromJson(json['label'], fallback: ''),
      credentialId: wingStringFromJson(json['credential_id'], fallback: ''),
      wingLinkOrigin: wingStringFromJson(
        json['wing_link_origin'],
        fallback: '',
      ),
      wingLinkToken: wingStringFromJson(json['wing_link_token'], fallback: ''),
      wingLinkCredentialId: wingStringFromJson(
        json['wing_link_credential_id'],
        fallback: '',
      ),
      connections: List.unmodifiable(connections),
    );
  }

  final String token;
  final String label;
  final String credentialId;
  final String wingLinkOrigin;
  final String wingLinkToken;
  final String wingLinkCredentialId;
  final List<HermesIssuedConnection> connections;
}

/// One Hermes-owned endpoint included in a reviewed Wing Link pairing bundle.
/// The token is write-only pairing material and must never reach presentation.
class HermesIssuedConnection {
  const HermesIssuedConnection({
    required this.origin,
    required this.token,
    required this.label,
    required this.profileId,
    this.credentialId = '',
  });

  factory HermesIssuedConnection.fromJson(Map<String, Object?> json) =>
      HermesIssuedConnection(
        origin: wingStringFromJson(json['origin'], fallback: ''),
        token: wingStringFromJson(json['token'], fallback: ''),
        label: wingStringFromJson(json['label'], fallback: ''),
        profileId: wingStringFromJson(json['profile_id'], fallback: ''),
        credentialId: wingStringFromJson(json['credential_id'], fallback: ''),
      );

  final String origin;
  final String token;
  final String label;
  final String profileId;
  final String credentialId;
}

Uint8List _pcm16MonoWav(Uint8List pcm16, {required int sampleRate}) {
  if (pcm16.isEmpty || pcm16.length.isOdd) {
    throw const FormatException('PCM16 audio must contain complete samples.');
  }
  final wav = ByteData(44 + pcm16.length);
  void ascii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      wav.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  wav.setUint32(4, 36 + pcm16.length, Endian.little);
  ascii(8, 'WAVEfmt ');
  wav.setUint32(16, 16, Endian.little);
  wav.setUint16(20, 1, Endian.little);
  wav.setUint16(22, 1, Endian.little);
  wav.setUint32(24, sampleRate, Endian.little);
  wav.setUint32(28, sampleRate * 2, Endian.little);
  wav.setUint16(32, 2, Endian.little);
  wav.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  wav.setUint32(40, pcm16.length, Endian.little);
  wav.buffer.asUint8List(44).setAll(0, pcm16);
  return wav.buffer.asUint8List();
}

DateTime? _epochSecondsToUtcDateTime(Object? value) {
  final seconds = wingDoubleFromJson(value);
  if (seconds == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(
    (seconds * 1000).round(),
    isUtc: true,
  );
}
