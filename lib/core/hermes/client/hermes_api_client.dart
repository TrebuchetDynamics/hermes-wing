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

  Future<Map<String, Object?>> _getJson(Uri uri) async {
    return _decodeObject(await _get(uri, config.headers));
  }

  Future<Map<String, Object?>> _postJson(
    Uri uri,
    Map<String, Object?> body,
  ) async {
    final headers = <String, String>{
      ...config.headers,
      hermesApiContentTypeHeader: hermesApiJsonContentType,
    };
    return _decodeObject(await _post(uri, headers, jsonEncode(body)));
  }

  Future<Map<String, Object?>> _patchJson(
    Uri uri,
    Map<String, Object?> body,
  ) async {
    final headers = <String, String>{
      ...config.headers,
      hermesApiContentTypeHeader: hermesApiJsonContentType,
    };
    return _decodeObject(await _patch(uri, headers, jsonEncode(body)));
  }

  Future<Map<String, Object?>> _deleteJson(Uri uri) async {
    return _decodeObject(await _delete(uri, config.headers));
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
