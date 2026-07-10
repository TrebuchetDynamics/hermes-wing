import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hermes_endpoint_store.dart';

/// [HermesEndpointStore] backed by shared preferences (non-secret profile
/// metadata/base URLs) and the platform secure-storage implementation
/// (per-profile API keys). Hardware backing and protection vary by platform.
/// Navivox never stores Hermes API keys in shared preferences.
class SecureHermesEndpointStore implements HermesEndpointStore {
  SecureHermesEndpointStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _legacyBaseUrlPreferenceKey = 'navivox.hermes.base_url';
  static const _legacyApiKeySecureStorageKey = 'navivox.hermes.api_key';
  static const _profilesPreferenceKey = 'navivox.hermes.profiles';
  static const _selectedProfilePreferenceKey =
      'navivox.hermes.selected_profile';
  static const _apiKeySecureStoragePrefix = 'navivox.hermes.profile_api_key.';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<HermesEndpointConfig?> load() async {
    final prefs = await _prefsOrNull();
    if (prefs == null) return null;
    final profiles = await _loadProfiles(prefs);
    if (profiles.isEmpty) return _loadLegacy(prefs);
    final selectedId = prefs.getString(_selectedProfilePreferenceKey);
    return profiles.firstWhere(
      (profile) => profile.id == selectedId,
      orElse: () => profiles.first,
    );
  }

  @override
  Future<List<HermesEndpointConfig>> loadProfiles() async {
    final prefs = await _prefsOrNull();
    if (prefs == null) return const [];
    final profiles = await _loadProfiles(prefs);
    if (profiles.isNotEmpty) return profiles;
    final legacy = await _loadLegacy(prefs);
    return legacy == null ? const [] : [legacy];
  }

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedBaseUrl = hermesPublicEndpointBaseUrl(baseUrl);
    final profiles = await _loadProfiles(prefs);
    final fallbackId = _profileIdForBaseUrl(normalizedBaseUrl);
    final existingIds = profiles
        .where((profile) => profile.baseUrl == normalizedBaseUrl)
        .map((profile) => profile.id)
        .whereType<String>();
    final id = (profileId?.trim().isNotEmpty ?? false)
        ? profileId!.trim()
        : existingIds.isEmpty
        ? fallbackId
        : existingIds.first;
    final next = HermesEndpointConfig(
      id: id,
      label: label?.trim().isEmpty ?? true ? null : label!.trim(),
      baseUrl: normalizedBaseUrl,
      apiKey: apiKey,
    );
    final updated = [
      next,
      for (final profile in profiles)
        if (profile.id != id && profile.baseUrl != normalizedBaseUrl) profile,
    ];
    await _saveProfileMetadata(prefs, updated);
    await prefs.setString(_selectedProfilePreferenceKey, id);
    await prefs.setString(_legacyBaseUrlPreferenceKey, normalizedBaseUrl);
    if (apiKey == null || apiKey.isEmpty) {
      await _secureStorage.delete(key: _apiKeyKey(id));
      await _secureStorage.delete(key: _legacyApiKeySecureStorageKey);
    } else {
      await _secureStorage.write(key: _apiKeyKey(id), value: apiKey);
      await _secureStorage.write(
        key: _legacyApiKeySecureStorageKey,
        value: apiKey,
      );
    }
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await _loadProfiles(prefs);
    final updated = [
      for (final profile in profiles)
        if (profile.id != profileId) profile,
    ];
    await _secureStorage.delete(key: _apiKeyKey(profileId));
    await _saveProfileMetadata(prefs, updated);
    final selectedId = prefs.getString(_selectedProfilePreferenceKey);
    if (selectedId == profileId) {
      if (updated.isEmpty) {
        await prefs.remove(_selectedProfilePreferenceKey);
        await prefs.remove(_legacyBaseUrlPreferenceKey);
        await _secureStorage.delete(key: _legacyApiKeySecureStorageKey);
      } else {
        await prefs.setString(_selectedProfilePreferenceKey, updated.first.id!);
        await prefs.setString(
          _legacyBaseUrlPreferenceKey,
          updated.first.baseUrl,
        );
        final apiKey = updated.first.apiKey;
        if (apiKey == null || apiKey.isEmpty) {
          await _secureStorage.delete(key: _legacyApiKeySecureStorageKey);
        } else {
          await _secureStorage.write(
            key: _legacyApiKeySecureStorageKey,
            value: apiKey,
          );
        }
      }
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedId = prefs.getString(_selectedProfilePreferenceKey);
    if (selectedId != null && selectedId.isNotEmpty) {
      await deleteProfile(selectedId);
      return;
    }
    await prefs.remove(_legacyBaseUrlPreferenceKey);
    await _secureStorage.delete(key: _legacyApiKeySecureStorageKey);
  }

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
      id: _profileIdForBaseUrl(publicBaseUrl),
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
      profiles.add(
        HermesEndpointConfig(
          id: id,
          label: item['label']?.toString(),
          baseUrl: publicBaseUrl,
          apiKey: apiKey,
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
        },
    ]);
    await prefs.setString(_profilesPreferenceKey, encoded);
  }

  static String _apiKeyKey(String id) => '$_apiKeySecureStoragePrefix$id';

  static String _profileIdForBaseUrl(String baseUrl) =>
      base64Url.encode(utf8.encode(baseUrl.trim())).replaceAll('=', '');
}
