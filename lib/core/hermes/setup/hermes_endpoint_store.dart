import 'dart:convert';

/// Returns the non-secret Hermes API origin suitable for display/persistence.
///
/// API keys sometimes arrive in copied setup URLs as userinfo, query strings, or
/// fragments. Keep those out of shared preferences, logs, and diagnostics.
String hermesPublicEndpointBaseUrl(String baseUrl) {
  final trimmed = baseUrl.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return trimmed;
  final pathSegments = uri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  final profilePath = pathSegments.length == 2 && pathSegments.first == 'p'
      ? '/p/${Uri.encodeComponent(pathSegments.last)}'
      : '';
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: profilePath,
  ).toString();
}

/// Returns Wing's stable gateway identity for one canonical Hermes endpoint.
///
/// Agent profile IDs are scoped to their owning gateway and must not be used as
/// globally unique saved-gateway keys.
String hermesEndpointIdForBaseUrl(String baseUrl) => base64Url
    .encode(utf8.encode(hermesPublicEndpointBaseUrl(baseUrl)))
    .replaceAll('=', '');

/// A saved Hermes endpoint: base URL (non-secret) plus an optional bearer
/// API key (secret). [id] and [label] are non-secret profile metadata used by
/// the Hermes connect form to switch between multiple saved endpoints.
class HermesEndpointConfig {
  const HermesEndpointConfig({
    required this.baseUrl,
    this.apiKey,
    this.id,
    this.label,
    this.wingLinkOrigin,
    this.wingLinkToken,
    this.wingLinkPendingCredentialId,
    this.wingLinkHostFingerprint,
    this.wingLinkDeviceId,
  });

  final String baseUrl;
  final String? apiKey;
  final String? id;
  final String? label;
  final String? wingLinkOrigin;
  final String? wingLinkToken;
  final String? wingLinkPendingCredentialId;
  final String? wingLinkHostFingerprint;
  final String? wingLinkDeviceId;

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
/// docs/adr/security-and-privacy.md.
abstract interface class HermesEndpointStore {
  Future<HermesEndpointConfig?> load();

  Future<List<HermesEndpointConfig>> loadProfiles();

  /// Atomically replaces the authoritative enrolled endpoint set. Auxiliary
  /// non-secret compatibility projections may be updated separately, but
  /// modern readers must never observe a prefix of [profiles].
  Future<void> saveAll(List<HermesEndpointConfig> profiles);

  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
    String? wingLinkOrigin,
    String? wingLinkToken,
    String? wingLinkPendingCredentialId,
    String? wingLinkHostFingerprint,
    String? wingLinkDeviceId,
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
  Future<void> saveAll(List<HermesEndpointConfig> profiles) async {}

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
    String? wingLinkOrigin,
    String? wingLinkToken,
    String? wingLinkPendingCredentialId,
    String? wingLinkHostFingerprint,
    String? wingLinkDeviceId,
  }) async {}

  @override
  Future<void> deleteProfile(String profileId) async {}

  @override
  Future<void> clear() async {}
}
