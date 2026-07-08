/// Returns the non-secret Hermes API origin suitable for display/persistence.
///
/// API keys sometimes arrive in copied setup URLs as userinfo, query strings, or
/// fragments. Keep those out of shared preferences, logs, and diagnostics.
String hermesPublicEndpointBaseUrl(String baseUrl) {
  final trimmed = baseUrl.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return trimmed;
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
  ).toString();
}

/// A saved Hermes endpoint: base URL (non-secret) plus an optional bearer
/// API key (secret). [id] and [label] are non-secret profile metadata used by
/// the Hermes connect form to switch between multiple saved endpoints.
class HermesEndpointConfig {
  const HermesEndpointConfig({
    required this.baseUrl,
    this.apiKey,
    this.id,
    this.label,
  });

  final String baseUrl;
  final String? apiKey;
  final String? id;
  final String? label;

  String get displayLabel {
    final trimmed = label?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return baseUrl;
  }
}

/// Persists Hermes endpoints the operator connected to, so the app does not
/// require re-entering the base URL/API key on every open. Implementations must
/// never write [HermesEndpointConfig.apiKey] to shared preferences, logs, or
/// other non-secure storage — see
/// docs/adr/0004-hermes-endpoint-and-secret-storage.md.
abstract interface class HermesEndpointStore {
  Future<HermesEndpointConfig?> load();

  Future<List<HermesEndpointConfig>> loadProfiles();

  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
  });

  Future<void> deleteProfile(String profileId);

  Future<void> clear();
}

/// Default store that persists nothing, so no API key is ever written to
/// insecure storage before a platform-backed store is injected.
class EmptyHermesEndpointStore implements HermesEndpointStore {
  const EmptyHermesEndpointStore();

  @override
  Future<HermesEndpointConfig?> load() async => null;

  @override
  Future<List<HermesEndpointConfig>> loadProfiles() async => const [];

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
  }) async {}

  @override
  Future<void> deleteProfile(String profileId) async {}

  @override
  Future<void> clear() async {}
}
