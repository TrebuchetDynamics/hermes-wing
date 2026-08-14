import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hermes_endpoint_store.dart';

/// [HermesEndpointStore] backed by shared preferences (non-secret profile
/// metadata/base URLs) and the platform secure-storage implementation
/// (per-profile API keys). Hardware backing and protection vary by platform.
/// Hermes Wing never stores Hermes API keys in shared preferences.
class SecureHermesEndpointStore implements HermesEndpointStore {
  SecureHermesEndpointStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _legacyBaseUrlPreferenceKey = 'wing.hermes.base_url';
  static const _legacyApiKeySecureStorageKey = 'wing.hermes.api_key';
  static const _profilesPreferenceKey = 'wing.hermes.profiles';
  static const _selectedProfilePreferenceKey = 'wing.hermes.selected_profile';
  static const _apiKeySecureStoragePrefix = 'wing.hermes.profile_api_key.';
  static const _wingLinkTokenSecureStoragePrefix =
      'wing.hermes.profile_wing_link_token.';
  static const _bundleSecureStorageKey = 'wing.hermes.endpoint_bundle.v1';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<HermesEndpointConfig?> load() async {
    final profiles = await loadProfiles();
    if (profiles.isEmpty) return null;
    final prefs = await _prefsOrNull();
    final selectedId = prefs?.getString(_selectedProfilePreferenceKey);
    return profiles.firstWhere(
      (profile) => profile.id == selectedId,
      orElse: () => profiles.first,
    );
  }

  @override
  Future<List<HermesEndpointConfig>> loadProfiles() async {
    List<HermesEndpointConfig>? bundle;
    try {
      bundle = await _loadSecureBundle();
    } catch (_) {
      // Secure storage can be unavailable in constrained desktop/test contexts.
      // Reads retain the legacy non-secret fallback; writes still fail closed.
    }
    if (bundle != null) return bundle;
    final prefs = await _prefsOrNull();
    if (prefs == null) return const [];
    final profiles = await _loadProfiles(prefs);
    if (profiles.isNotEmpty) return profiles;
    final legacy = await _loadLegacy(prefs);
    return legacy == null ? const [] : [legacy];
  }

  @override
  Future<void> saveAll(List<HermesEndpointConfig> profiles) async {
    final normalized = <HermesEndpointConfig>[];
    final ids = <String>{};
    final origins = <String>{};
    for (final profile in profiles) {
      final id = profile.id?.trim() ?? '';
      final baseUrl = hermesPublicEndpointBaseUrl(profile.baseUrl);
      if (id.isEmpty ||
          baseUrl.isEmpty ||
          !ids.add(id) ||
          !origins.add(baseUrl)) {
        throw ArgumentError(
          'Endpoint bundle contains invalid or duplicate rows.',
        );
      }
      normalized.add(
        HermesEndpointConfig(
          id: id,
          label: profile.label?.trim(),
          baseUrl: baseUrl,
          apiKey: profile.apiKey,
          wingLinkOrigin: profile.wingLinkOrigin == null
              ? null
              : hermesPublicEndpointBaseUrl(profile.wingLinkOrigin!),
          wingLinkToken: profile.wingLinkToken,
          wingLinkPendingCredentialId: profile.wingLinkPendingCredentialId,
        ),
      );
    }
    final payload = jsonEncode([
      for (final profile in normalized)
        {
          'id': profile.id,
          'baseUrl': profile.baseUrl,
          if (profile.label?.isNotEmpty ?? false) 'label': profile.label,
          if (profile.apiKey?.isNotEmpty ?? false) 'apiKey': profile.apiKey,
          if (profile.wingLinkOrigin?.isNotEmpty ?? false)
            'wingLinkOrigin': profile.wingLinkOrigin,
          if (profile.wingLinkToken?.isNotEmpty ?? false)
            'wingLinkToken': profile.wingLinkToken,
          if (profile.wingLinkPendingCredentialId?.isNotEmpty ?? false)
            'wingLinkPendingCredentialId': profile.wingLinkPendingCredentialId,
        },
    ]);
    final prefs = await SharedPreferences.getInstance();
    final legacyProfiles = await _loadProfiles(prefs);

    // This single secure write is the authoritative endpoint-set commit. Do not
    // destroy the currently readable legacy enrollment until this succeeds.
    await _secureStorage.write(key: _bundleSecureStorageKey, value: payload);

    // The modern bundle is now authoritative. Purge rollback-readable legacy
    // credentials and metadata before publishing compatibility projections.
    final legacyIds = <String>{
      ...legacyProfiles.map((profile) => profile.id).whereType<String>(),
      ...normalized.map((profile) => profile.id).whereType<String>(),
    };
    for (final id in legacyIds) {
      await _secureStorage.delete(key: _apiKeyKey(id));
      await _secureStorage.delete(key: _wingLinkTokenKey(id));
    }
    await _secureStorage.delete(key: _legacyApiKeySecureStorageKey);
    await prefs.remove(_legacyBaseUrlPreferenceKey);

    // Shared preferences contain non-secret compatibility metadata only. A
    // projection failure cannot expose a partial endpoint bundle to modern
    // readers and must not make a completed secure commit look rolled back.
    try {
      await _saveProfileMetadata(prefs, normalized);
      if (normalized.isEmpty) {
        await prefs.remove(_selectedProfilePreferenceKey);
      } else {
        await prefs.setString(
          _selectedProfilePreferenceKey,
          normalized.first.id!,
        );
      }
    } catch (_) {
      // The secure bundle remains the sole source of truth.
    }
  }

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
    String? wingLinkOrigin,
    String? wingLinkToken,
    String? wingLinkPendingCredentialId,
  }) async {
    final normalizedBaseUrl = hermesPublicEndpointBaseUrl(baseUrl);
    final profiles = await loadProfiles();
    final existing = profiles
        .where(
          (profile) =>
              profile.id == profileId || profile.baseUrl == normalizedBaseUrl,
        )
        .firstOrNull;
    final id = profileId?.trim().isNotEmpty ?? false
        ? profileId!.trim()
        : existing?.id ?? hermesEndpointIdForBaseUrl(normalizedBaseUrl);
    final next = HermesEndpointConfig(
      id: id,
      label: label?.trim().isEmpty ?? true ? null : label!.trim(),
      baseUrl: normalizedBaseUrl,
      apiKey: apiKey,
      wingLinkOrigin: wingLinkOrigin == null
          ? existing?.wingLinkOrigin
          : hermesPublicEndpointBaseUrl(wingLinkOrigin),
      wingLinkToken: wingLinkToken ?? existing?.wingLinkToken,
      wingLinkPendingCredentialId: wingLinkPendingCredentialId == null
          ? existing?.wingLinkPendingCredentialId
          : wingLinkPendingCredentialId.trim().isEmpty
          ? null
          : wingLinkPendingCredentialId.trim(),
    );
    await saveAll([
      next,
      for (final profile in profiles)
        if (profile.id != id && profile.baseUrl != normalizedBaseUrl) profile,
    ]);
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    final profiles = await loadProfiles();
    await saveAll([
      for (final profile in profiles)
        if (profile.id != profileId) profile,
    ]);
  }

  @override
  Future<void> clear() => saveAll(const []);

  Future<SharedPreferences?> _prefsOrNull() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<HermesEndpointConfig?> _loadLegacy(SharedPreferences prefs) async {
    final baseUrl = prefs.getString(_legacyBaseUrlPreferenceKey);
    if (baseUrl == null || baseUrl.isEmpty) return null;
    final apiKey = await _secureStorage.read(
      key: _legacyApiKeySecureStorageKey,
    );
    final publicBaseUrl = hermesPublicEndpointBaseUrl(baseUrl);
    return HermesEndpointConfig(
      id: hermesEndpointIdForBaseUrl(publicBaseUrl),
      baseUrl: publicBaseUrl,
      apiKey: apiKey,
    );
  }

  Future<List<HermesEndpointConfig>> _loadProfiles(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_profilesPreferenceKey);
    if (raw == null || raw.isEmpty) return const [];
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];
    final profiles = <HermesEndpointConfig>[];
    final seenBaseUrls = <String>{};
    for (final item in decoded) {
      if (item is! Map) continue;
      final id = item['id']?.toString();
      final baseUrl = item['baseUrl']?.toString();
      if (id == null || id.isEmpty || baseUrl == null || baseUrl.isEmpty) {
        continue;
      }
      final publicBaseUrl = hermesPublicEndpointBaseUrl(baseUrl);
      if (publicBaseUrl.isEmpty || !seenBaseUrls.add(publicBaseUrl)) continue;
      final apiKey = await _secureStorage.read(key: _apiKeyKey(id));
      final wingLinkToken = await _secureStorage.read(
        key: _wingLinkTokenKey(id),
      );
      profiles.add(
        HermesEndpointConfig(
          id: id,
          label: item['label']?.toString(),
          baseUrl: publicBaseUrl,
          apiKey: apiKey,
          wingLinkOrigin: item['wingLinkOrigin']?.toString(),
          wingLinkToken: wingLinkToken,
          wingLinkPendingCredentialId: item['wingLinkPendingCredentialId']
              ?.toString(),
        ),
      );
    }
    return profiles;
  }

  Future<List<HermesEndpointConfig>?> _loadSecureBundle() async {
    final raw = await _secureStorage.read(key: _bundleSecureStorageKey);
    if (raw == null) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];
    final profiles = <HermesEndpointConfig>[];
    final ids = <String>{};
    final origins = <String>{};
    for (final item in decoded) {
      if (item is! Map) return const [];
      final id = item['id']?.toString() ?? '';
      final baseUrl = hermesPublicEndpointBaseUrl(
        item['baseUrl']?.toString() ?? '',
      );
      if (id.isEmpty ||
          baseUrl.isEmpty ||
          !ids.add(id) ||
          !origins.add(baseUrl)) {
        return const [];
      }
      profiles.add(
        HermesEndpointConfig(
          id: id,
          baseUrl: baseUrl,
          label: item['label']?.toString(),
          apiKey: item['apiKey']?.toString(),
          wingLinkOrigin: item['wingLinkOrigin']?.toString(),
          wingLinkToken: item['wingLinkToken']?.toString(),
          wingLinkPendingCredentialId: item['wingLinkPendingCredentialId']
              ?.toString(),
        ),
      );
    }
    return profiles;
  }

  Future<void> _saveProfileMetadata(
    SharedPreferences prefs,
    List<HermesEndpointConfig> profiles,
  ) async {
    if (profiles.isEmpty) {
      await prefs.remove(_profilesPreferenceKey);
      return;
    }
    final encoded = jsonEncode([
      for (final profile in profiles)
        {
          'id': profile.id,
          if (profile.label?.trim().isNotEmpty ?? false)
            'label': profile.label!.trim(),
          'baseUrl': profile.baseUrl,
          if (profile.wingLinkOrigin?.trim().isNotEmpty ?? false)
            'wingLinkOrigin': hermesPublicEndpointBaseUrl(
              profile.wingLinkOrigin!,
            ),
          if (profile.wingLinkPendingCredentialId?.trim().isNotEmpty ?? false)
            'wingLinkPendingCredentialId': profile.wingLinkPendingCredentialId!
                .trim(),
        },
    ]);
    await prefs.setString(_profilesPreferenceKey, encoded);
  }

  static String _apiKeyKey(String id) => '$_apiKeySecureStoragePrefix$id';
  static String _wingLinkTokenKey(String id) =>
      '$_wingLinkTokenSecureStoragePrefix$id';
}
