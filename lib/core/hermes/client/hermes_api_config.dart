import '../shared/hermes_api_http.dart';
import '../shared/hermes_api_uri.dart';

class HermesApiConfig {
  const HermesApiConfig({required this.baseUri, this.apiKey});

  factory HermesApiConfig.fromBaseUrl(String baseUrl, {String? apiKey}) {
    final trimmed = hermesApiRequiredTrimmedValue(baseUrl, 'baseUrl');
    final Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } on FormatException catch (error) {
      throw ArgumentError.value(baseUrl, 'baseUrl', error.message);
    }
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'must include an http(s) scheme and host',
      );
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'must use http or https');
    }
    return HermesApiConfig(baseUri: uri, apiKey: apiKey);
  }

  final Uri baseUri;
  final String? apiKey;

  Uri get healthUri => _withPath('/health');
  Uri get healthDetailedUri => _withPath('/health/detailed');
  Uri get capabilitiesUri => _withPath('/v1/capabilities');
  Uri get modelsUri => _withPath('/v1/models');
  Uri get skillsUri => _withPath('/v1/skills');
  Uri get toolsetsUri => _withPath('/v1/toolsets');
  Uri get sessionsUri => _withPath('/api/sessions');
  Uri get jobsUri => _withPath('/api/jobs');
  Uri get runsUri => _withPath('/v1/runs');

  /// Unauthenticated one-time pairing endpoints; see
  /// docs/adr/0043-hardened-hermes-one-device-authorization.md. Callers must
  /// never attach [headers] (a saved bearer credential) to these requests.
  Uri get enrollmentInspectUri => _withPath('/v1/operator/enrollments/inspect');
  Uri get enrollmentExchangeUri =>
      _withPath('/v1/operator/enrollments/exchange');

  Uri sessionUri(String sessionId) => _withPath(
    '/api/sessions/${hermesApiTrimmedPathSegment(sessionId, name: 'sessionId')}',
  );

  Uri sessionMessagesUri(String sessionId) => _withPath(
    '/api/sessions/${hermesApiTrimmedPathSegment(sessionId, name: 'sessionId')}/messages',
  );

  Uri sessionForkUri(String sessionId) => _withPath(
    '/api/sessions/${hermesApiTrimmedPathSegment(sessionId, name: 'sessionId')}/fork',
  );

  Uri sessionChatUri(String sessionId) => _withPath(
    '/api/sessions/${hermesApiTrimmedPathSegment(sessionId, name: 'sessionId')}/chat',
  );

  Uri sessionChatStreamUri(String sessionId) => _withPath(
    '/api/sessions/${hermesApiTrimmedPathSegment(sessionId, name: 'sessionId')}/chat/stream',
  );

  Uri runUri(String runId) => _withPath(
    '/v1/runs/${hermesApiTrimmedPathSegment(runId, name: 'runId')}',
  );

  Uri runEventsUri(String runId) => _withPath(
    '/v1/runs/${hermesApiTrimmedPathSegment(runId, name: 'runId')}/events',
  );

  Uri runApprovalUri(String runId) => _withPath(
    '/v1/runs/${hermesApiTrimmedPathSegment(runId, name: 'runId')}/approval',
  );

  Uri runStopUri(String runId) => _withPath(
    '/v1/runs/${hermesApiTrimmedPathSegment(runId, name: 'runId')}/stop',
  );

  /// Administrative profile collection. Machine-scoped and keyed by name in
  /// the path, so it never carries the profile-owned `profile` query.
  Uri get profilesUri => _withPath('/api/profiles');

  Uri profileUri(String profileId) => _withPath(
    '/api/profiles/${hermesApiTrimmedPathSegment(profileId, name: 'profileId')}',
  );

  Uri profileSoulUri(String profileId) => _withPath(
    '/api/profiles/${hermesApiTrimmedPathSegment(profileId, name: 'profileId')}/soul',
  );

  /// Provider credential presence collection. Profile-owned: callers must wrap
  /// these in [profileScopedUri] so the mandatory `profile` query is attached.
  Uri get providersUri => _withPath('/api/providers');

  Uri providerCredentialUri(String slug) => _withPath(
    '/api/providers/${hermesApiTrimmedPathSegment(slug, name: 'slug')}/credential',
  );

  Uri providerCredentialValidateUri(String slug) => _withPath(
    '/api/providers/${hermesApiTrimmedPathSegment(slug, name: 'slug')}/credential/validate',
  );

  /// Model catalog + active/auxiliary assignment. Profile-owned, so callers
  /// wrap these in [profileScopedUri]. Distinct from [modelsUri] (`/v1/models`,
  /// the plain model-id list).
  Uri get modelCatalogUri => _withPath('/api/models');

  Uri get modelRefreshUri => _withPath('/api/models/refresh');

  Uri get modelAssignmentUri => _withPath('/api/models/assignment');

  /// Adds the mandatory `profile` query to a profile-owned request or SSE URL,
  /// including the literal `default` profile. The id is validated (non-blank)
  /// so an implicit/empty profile scope can never reach the wire, and existing
  /// query parameters on [uri] are preserved.
  Uri profileScopedUri(Uri uri, String profileId) {
    final id = hermesApiRequiredTrimmedValue(profileId, 'profileId');
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'profile': id},
    );
  }

  Map<String, String> get headers {
    final value = apiKey?.trim();
    if (value == null || value.isEmpty) return const {};
    return {hermesApiAuthorizationHeader: hermesApiBearerAuthorization(value)};
  }

  Uri _withPath(String path) => hermesApiEndpointUri(baseUri, path);
}
