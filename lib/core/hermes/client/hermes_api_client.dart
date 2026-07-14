import 'dart:async';
import 'dart:convert';

import '../../protocol/navivox_json.dart';
import '../models/hermes_capabilities.dart';
import '../models/hermes_health.dart';
import '../models/hermes_job.dart';
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
    HermesApiDelete? delete,
    HermesApiPostStream? postStream,
    HermesApiGetStream? getStream,
    this.requestTimeout = const Duration(seconds: 20),
  }) : _get = get ?? transport.defaultGet,
       _post = post ?? transport.defaultPost,
       _patch = patch ?? transport.defaultPatch,
       _delete = delete ?? transport.defaultDelete,
       _postStream = postStream ?? transport.defaultPostStream,
       _getStream = getStream ?? transport.defaultGetStream;

  final HermesApiConfig config;
  final HermesApiGet _get;
  final HermesApiPost _post;
  final HermesApiPatch _patch;
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

  Future<List<String>> listModels() async {
    return _namedList(await _getJson(config.modelsUri), const [
      'id',
      'root',
      'model',
      'name',
    ]);
  }

  Future<List<String>> listSkills() async {
    return _namedList(await _getJson(config.skillsUri), const ['name']);
  }

  Future<List<String>> listEnabledToolsets() async {
    final body = await _getJson(config.toolsetsUri);
    return navivoxMapListFromJson(body['data'])
        .where((item) => navivoxBoolFromJson(item['enabled']))
        .map((item) => navivoxOptionalStringFromJson(item['name']))
        .whereType<String>()
        .toList(growable: false);
  }

  Future<List<HermesSession>> listSessions() async {
    final body = await _getJson(config.sessionsUri);
    return navivoxMapListFromJson(body['data'])
        .map(HermesSession.fromJson)
        .where((session) => session.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<HermesJob>> listJobs() async {
    final body = await _getJson(config.jobsUri);
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
    Map<String, Object?> body,
  ) async {
    final headers = <String, String>{
      ...config.headers,
      hermesApiContentTypeHeader: hermesApiJsonContentType,
    };
    return _decodeObject(
      await _bounded(_patch(uri, headers, jsonEncode(body)), uri),
    );
  }

  Future<Map<String, Object?>> _deleteJson(Uri uri) async {
    return _decodeObject(await _bounded(_delete(uri, config.headers), uri));
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
