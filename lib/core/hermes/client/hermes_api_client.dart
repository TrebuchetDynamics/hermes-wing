import 'dart:async';
import 'dart:convert';

import '../../protocol/navivox_json.dart';
import '../models/hermes_capabilities.dart';
import '../models/hermes_health.dart';
import '../models/hermes_job.dart';
import '../models/hermes_model_assignment.dart';
import '../models/hermes_profile.dart';
import '../models/hermes_provider.dart';
import '../models/hermes_run.dart';
import '../models/hermes_session.dart';
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
    return _namedList(
      await _getJson(_scoped(config.modelsUri, profile)),
      const ['id', 'root', 'model', 'name'],
    );
  }

  Future<List<String>> listSkills({String? profile}) async {
    return _namedList(
      await _getJson(_scoped(config.skillsUri, profile)),
      const ['name'],
    );
  }

  Future<List<String>> listEnabledToolsets({String? profile}) async {
    final body = await _getJson(_scoped(config.toolsetsUri, profile));
    return navivoxMapListFromJson(body['data'])
        .where((item) => navivoxBoolFromJson(item['enabled']))
        .map((item) => navivoxOptionalStringFromJson(item['name']))
        .whereType<String>()
        .toList(growable: false);
  }

  Future<List<HermesSession>> listSessions({String? profile}) async {
    final body = await _getJson(_scoped(config.sessionsUri, profile));
    return navivoxMapListFromJson(body['data'])
        .map(HermesSession.fromJson)
        .where((session) => session.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<HermesJob>> listJobs({String? profile}) async {
    final body = await _getJson(_scoped(config.jobsUri, profile));
    final rawJobs = body['jobs'] ?? body['data'];
    return navivoxMapListFromJson(rawJobs)
        .map(HermesJob.fromJson)
        .where((job) => job.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<HermesSession> createSession({
    required String id,
    String? title,
    String? model,
    String? systemPrompt,
  }) async {
    final body = <String, Object?>{
      'id': id.trim(),
      ...navivoxTrimmedStringFields({
        'title': title,
        'model': model,
        'system_prompt': systemPrompt,
      }),
    };
    final response = await _postJson(config.sessionsUri, body);
    return HermesSession.fromJson(navivoxMapFieldFromJson(response, 'session'));
  }

  Future<List<HermesMessage>> sessionMessages(String sessionId) async {
    final body = await _getJson(config.sessionMessagesUri(sessionId));
    return navivoxMapListFromJson(
      body['data'],
    ).map(HermesMessage.fromJson).toList(growable: false);
  }

  Future<HermesSession> updateSessionTitle(
    String sessionId, {
    required String title,
  }) async {
    final response = await _patchJson(config.sessionUri(sessionId), {
      'title': title.trim(),
    });
    return HermesSession.fromJson(navivoxMapFieldFromJson(response, 'session'));
  }

  Future<void> deleteSession(String sessionId) async {
    final trimmed = sessionId.trim();
    final response = await _deleteJson(config.sessionUri(trimmed));
    final id = navivoxOptionalStringFromJson(response['id']);
    final deleted = navivoxBoolFromJson(response['deleted']);
    if (id != trimmed || !deleted) {
      throw StateError('Hermes session delete was not confirmed.');
    }
  }

  Future<HermesSession> forkSession(
    String sourceSessionId, {
    required String id,
    String? title,
  }) async {
    final response = await _postJson(config.sessionForkUri(sourceSessionId), {
      'id': id.trim(),
      ...navivoxTrimmedStringFields({'title': title}),
    });
    return HermesSession.fromJson(navivoxMapFieldFromJson(response, 'session'));
  }

  Stream<HermesStreamEvent> streamSessionChat(
    String sessionId, {
    required String message,
  }) {
    final headers = <String, String>{
      ...config.headers,
      hermesApiContentTypeHeader: hermesApiJsonContentType,
      hermesApiAcceptHeader: hermesApiEventStreamContentType,
      hermesApiCacheControlHeader: hermesApiNoCache,
    };
    final body = jsonEncode({'message': message});
    final chunks = _postStream(
      config.sessionChatStreamUri(sessionId),
      headers,
      body,
    );
    return const HermesSseEventDecoder().decodeJsonEventStream(chunks);
  }

  Future<HermesRun> startRun({
    required String sessionId,
    required String message,
  }) async {
    final response = await _postJson(config.runsUri, {
      'session_id': sessionId,
      // Hermes Agent 0.18 accepts `input`; older test fixtures accepted
      // `message`. Send both so the client remains compatible across the
      // transition while parsing either flat or enveloped run responses below.
      'input': message,
      'message': message,
    });
    final run = response['run'] is Map
        ? navivoxMapFromJson(response['run'])
        : response;
    return HermesRun.fromJson(run);
  }

  Stream<HermesStreamEvent> runEvents(String runId) {
    final headers = <String, String>{
      ...config.headers,
      hermesApiAcceptHeader: hermesApiEventStreamContentType,
      hermesApiCacheControlHeader: hermesApiNoCache,
    };
    final chunks = _getStream(config.runEventsUri(runId), headers);
    return const HermesSseEventDecoder().decodeJsonEventStream(chunks);
  }

  Future<void> respondApproval({
    required String runId,
    required String approvalId,
    required String decision,
  }) async {
    await _postJson(config.runApprovalUri(runId), {
      'approval_id': approvalId,
      'decision': decision,
    });
  }

  Future<void> stopRun(String runId) async {
    await _postJson(config.runStopUri(runId), const {});
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
    return navivoxMapListFromJson(body['data'])
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
      ...navivoxTrimmedStringFields({'clone_from': cloneFrom}),
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
    final id = navivoxOptionalStringFromJson(response['id']);
    final deleted = navivoxBoolFromJson(response['deleted']);
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
    return navivoxMapListFromJson(body['data'])
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
    return HermesProvider.fromJson(navivoxMapFieldFromJson(response, 'data'));
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
    return HermesProvider.fromJson(navivoxMapFieldFromJson(response, 'data'));
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
      ...navivoxTrimmedStringFields({'task': task}),
    };
    final response = await _putJson(uri, body, ifMatch: revision);
    return HermesModelAssignment.fromJson(response);
  }

  Map<String, Object?> _profileEnvelope(Map<String, Object?> response) {
    return response['profile'] is Map
        ? navivoxMapFromJson(response['profile'])
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

  List<String> _namedList(
    Map<String, Object?> body,
    List<String> candidateFields,
  ) {
    return navivoxMapListFromJson(body['data'])
        .map(
          (item) => candidateFields
              .map((field) => navivoxOptionalStringFromJson(item[field]))
              .whereType<String>()
              .firstOrNull,
        )
        .whereType<String>()
        .toList(growable: false);
  }

  Map<String, Object?> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Hermes API response must be a JSON object');
    }
    return navivoxMapFromJson(decoded);
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
      label: navivoxStringFromJson(json['label'], fallback: ''),
      origin: navivoxStringFromJson(json['origin'], fallback: ''),
      scopes: navivoxStringListFromJson(json['scopes']),
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
  });

  factory HermesIssuedOperatorToken.fromJson(Map<String, Object?> json) {
    return HermesIssuedOperatorToken(
      token: navivoxStringFromJson(json['token'], fallback: ''),
      label: navivoxStringFromJson(json['label'], fallback: ''),
      credentialId: navivoxStringFromJson(json['credential_id'], fallback: ''),
    );
  }

  final String token;
  final String label;
  final String credentialId;
}

DateTime? _epochSecondsToUtcDateTime(Object? value) {
  final seconds = navivoxDoubleFromJson(value);
  if (seconds == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(
    (seconds * 1000).round(),
    isUtc: true,
  );
}
