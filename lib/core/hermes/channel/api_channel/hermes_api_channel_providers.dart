part of '../hermes_api_channel.dart';

/// Provider-credential and model-selection operations. Mirrors the milestone-1
/// profile pattern: every operation is capability- and scope-gated, requires a
/// client-selected profile (so the mandatory `profile` query is always
/// present), and drops responses that land after a reconnect via the
/// connection-generation check.
///
/// Secret invariant: [_setProviderCredential] transmits the credential value
/// to the server but nothing here ever stores it — only presence
/// (`configured` + masked hint) is reconciled into state.
extension _ProvidersExtension on HermesApiChannel {
  Future<void> _loadProviders() async {
    final client = _requireConnectedClient();
    _requireProviderModelCapability(
      'providers',
      'GET',
      '/api/providers',
      'providers:read',
      'list providers',
    );
    final profile = _requireSelectedProfile('list providers');
    final generation = _connectionGeneration;
    final providers = await client.listProviders(profile: profile);
    if (!_isCurrentConnection(generation, client)) return;
    _setState(_state.copyWith(providers: providers));
  }

  Future<void> _setProviderCredential({
    required String slug,
    required String envVar,
    required String value,
  }) async {
    final client = _requireConnectedClient();
    _requireProviderModelCapability(
      'provider_credential_set',
      'PUT',
      '/api/providers/{slug}/credential',
      'providers:write',
      'set a provider credential',
    );
    final profile = _requireSelectedProfile('set a provider credential');
    _requireNonBlank(slug, 'slug');
    _requireNonBlank(envVar, 'envVar');
    _requireNonBlank(value, 'value');
    final generation = _connectionGeneration;
    final provider = await client.setProviderCredential(
      slug: slug,
      envVar: envVar,
      value: value,
      profile: profile,
    );
    if (!_isCurrentConnection(generation, client)) return;
    _replaceProvider(provider);
  }

  Future<void> _removeProviderCredential({
    required String slug,
    required String envVar,
  }) async {
    final client = _requireConnectedClient();
    _requireProviderModelCapability(
      'provider_credential_delete',
      'DELETE',
      '/api/providers/{slug}/credential',
      'providers:write',
      'remove a provider credential',
    );
    final profile = _requireSelectedProfile('remove a provider credential');
    _requireNonBlank(slug, 'slug');
    _requireNonBlank(envVar, 'envVar');
    final generation = _connectionGeneration;
    final provider = await client.removeProviderCredential(
      slug: slug,
      envVar: envVar,
      profile: profile,
    );
    if (!_isCurrentConnection(generation, client)) return;
    _replaceProvider(provider);
  }

  Future<HermesCredentialProbe> _validateProviderCredential({
    required String slug,
  }) async {
    final client = _requireConnectedClient();
    _requireProviderModelCapability(
      'provider_credential_validate',
      'POST',
      '/api/providers/{slug}/credential/validate',
      'providers:write',
      'validate a provider credential',
    );
    final profile = _requireSelectedProfile('validate a provider credential');
    _requireNonBlank(slug, 'slug');
    return client.validateProviderCredential(slug: slug, profile: profile);
  }

  Future<void> _loadModels() async {
    final client = _requireConnectedClient();
    _requireProviderModelCapability(
      'models',
      'GET',
      '/api/models',
      'models:read',
      'list models',
    );
    final profile = _requireSelectedProfile('list models');
    final generation = _connectionGeneration;
    final inventory = await client.getModelInventory(profile: profile);
    if (!_isCurrentConnection(generation, client)) return;
    _setState(_state.copyWith(modelInventory: inventory));
  }

  Future<void> _refreshModels() async {
    final client = _requireConnectedClient();
    _requireProviderModelCapability(
      'models_refresh',
      'POST',
      '/api/models/refresh',
      'models:write',
      'refresh the model catalog',
    );
    final profile = _requireSelectedProfile('refresh the model catalog');
    final generation = _connectionGeneration;
    final catalog = await client.refreshModelCatalog(profile: profile);
    if (!_isCurrentConnection(generation, client)) return;
    final current = _state.modelInventory ?? const HermesModelInventory();
    _setState(_state.copyWith(modelInventory: current.withCatalog(catalog)));
  }

  Future<void> _assignModel({
    required String scope,
    String? task,
    required String provider,
    required String model,
    required String revision,
  }) async {
    final client = _requireConnectedClient();
    _requireProviderModelCapability(
      'models_assignment',
      'PUT',
      '/api/models/assignment',
      'models:write',
      'assign a model',
    );
    final profile = _requireSelectedProfile('assign a model');
    _requireNonBlank(provider, 'provider');
    _requireNonBlank(model, 'model');
    _requireRevision(revision);
    final generation = _connectionGeneration;
    final assignment = await client.assignModel(
      scope: scope,
      task: task,
      provider: provider,
      model: model,
      revision: revision,
      profile: profile,
    );
    if (!_isCurrentConnection(generation, client)) return;
    final current = _state.modelInventory ?? const HermesModelInventory();
    _setState(
      _state.copyWith(modelInventory: current.withAssignment(assignment)),
    );
  }

  void _replaceProvider(HermesProvider updated) {
    _setState(
      _state.copyWith(
        providers: [
          for (final provider in _state.providers)
            if (provider.slug == updated.slug) updated else provider,
        ],
      ),
    );
  }

  /// Requires the endpoint to be advertised AND the connected token to hold
  /// [scope], failing before any network I/O when either is missing.
  void _requireProviderModelCapability(
    String name,
    String method,
    String path,
    String scope,
    String action,
  ) {
    final capabilities = _state.capabilities;
    if (capabilities == null ||
        !capabilities.supportsSchema ||
        !capabilities.advertisesEndpoint(name, method, path)) {
      throw StateError('Hermes did not advertise support to $action.');
    }
    if (!capabilities.auth.allows(scope)) {
      throw StateError('This device is not authorized to $action.');
    }
  }

  /// Provider/model operations are profile-owned and reject an implicit scope:
  /// a profile must be selected before they touch the wire.
  String _requireSelectedProfile(String action) {
    _requireProfileContext(action);
    final id = _state.selectedProfileId;
    if (id == null || id.trim().isEmpty) {
      throw StateError('Select a Hermes profile before you $action.');
    }
    return id;
  }

  void _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be blank');
    }
  }
}
