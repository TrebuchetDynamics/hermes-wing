import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';

class FakeHermesEndpointStore implements HermesEndpointStore {
  FakeHermesEndpointStore({
    HermesEndpointConfig? initial,
    List<HermesEndpointConfig>? profiles,
  }) : _config = initial,
       _profiles = profiles == null ? [] : [...profiles] {
    if (initial != null && _profiles.isEmpty) _profiles.add(initial);
  }

  HermesEndpointConfig? _config;
  final List<HermesEndpointConfig> _profiles;
  final List<HermesEndpointConfig> saveCalls = [];
  final List<String> deleteProfileCalls = [];
  int clearCalls = 0;

  @override
  Future<HermesEndpointConfig?> load() async => _config;

  @override
  Future<List<HermesEndpointConfig>> loadProfiles() async => [..._profiles];

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
  }) async {
    final publicBaseUrl = hermesPublicEndpointBaseUrl(baseUrl);
    _config = HermesEndpointConfig(
      id: profileId ?? publicBaseUrl,
      label: label,
      baseUrl: publicBaseUrl,
      apiKey: apiKey,
    );
    _profiles.removeWhere(
      (profile) =>
          profile.id == _config!.id || profile.baseUrl == publicBaseUrl,
    );
    _profiles.insert(0, _config!);
    saveCalls.add(_config!);
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    deleteProfileCalls.add(profileId);
    _profiles.removeWhere((profile) => profile.id == profileId);
    if (_config?.id == profileId) {
      _config = _profiles.isEmpty ? null : _profiles.first;
    }
  }

  @override
  Future<void> clear() async {
    _config = null;
    _profiles.clear();
    clearCalls += 1;
  }
}
