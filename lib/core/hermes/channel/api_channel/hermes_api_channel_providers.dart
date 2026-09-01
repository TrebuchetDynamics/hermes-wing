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
    final profileGeneration = _profileSelectionGeneration;
    final providers = await client.listProviders(profile: profile);
    if (!_isCurrentProviderModelRequest(
      generation,
      profileGeneration,
      client,
      profile,
    )) {
      return;
    }
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
    final profileGeneration = _profileSelectionGeneration;
    final inventory = await client.getModelInventory(profile: profile);
    if (!_isCurrentProviderModelRequest(
      generation,
      profileGeneration,
      client,
      profile,
    )) {
      return;
    }
    _setState(_state.copyWith(modelInventory: inventory));
  }

  Future<void> _loadModelOptions({bool refresh = false}) async {
    final client = _requireConnectedClient();
    if (!_state.canReadModelOptions) {
      throw StateError(
        'Hermes did not advertise support to list model options.',
      );
    }
    final endpoint = _state.capabilities?.endpoints['model_options'];
    final profile = endpoint?.profileScoped == true
        ? _requireSelectedProfile('list model options')
        : null;
    final generation = _connectionGeneration;
    final profileGeneration = _profileSelectionGeneration;
    final options = await client.getModelOptions(
      profile: profile,
      refresh: refresh,
    );
    if (!_isCurrentProviderModelRequest(
      generation,
      profileGeneration,
      client,
      profile,
    )) {
      return;
    }
    _setState(_state.copyWith(modelOptions: options));
  }

  Future<void> _lockSessionModel({
    required String sessionId,
    required String provider,
    required String model,
  }) async {
    final client = _requireConnectedClient();
    if (!_state.canLockSessionModel) {
      throw StateError(
        'Hermes did not advertise support to lock a session model.',
      );
    }
    final endpoint = _state.capabilities?.endpoints['session_model_lock'];
    final profile = endpoint?.profileScoped == true
        ? _requireSelectedProfile('lock a session model')
        : null;
    final profileGeneration = _profileSelectionGeneration;
    _requireNonBlank(sessionId, 'sessionId');
    _requireNonBlank(provider, 'provider');
    _requireNonBlank(model, 'model');
    if (!_state.sessions.any((session) => session.id == sessionId.trim())) {
      throw StateError(
        'Hermes session is not available in the selected profile.',
      );
    }
    final generation = _connectionGeneration;
    final lock = await client.lockSessionModel(
      sessionId: sessionId,
      provider: provider,
      model: model,
      profile: profile,
    );
    if (!_isCurrentProviderModelRequest(
      generation,
      profileGeneration,
      client,
      profile,
    )) {
      return;
    }
    if (!lock.accepted || lock.sessionId != sessionId.trim()) {
      throw StateError('Hermes did not confirm the session model lock.');
    }
    _setState(
      _state.copyWith(
        sessionModelLocks: {
          ..._state.sessionModelLocks,
          sessionId.trim(): lock,
        },
      ),
    );
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
    final HermesModelAssignment assignment;
    try {
      assignment = await client.assignModel(
        scope: scope,
        task: task,
        provider: provider,
        model: model,
        revision: revision,
        profile: profile,
      );
    } catch (error) {
      // On a stale-revision 412, reload the model inventory (the same GET
      // path _loadModels uses) so the caller sees the winning revision rather
      // than retrying forever with the cached one. Responses that land after a
      // reconnect are dropped by the generation guard.
      if (_isPreconditionFailed(error) &&
          _isCurrentConnection(generation, client)) {
        await _refreshModelInventory(client, profile, generation);
      }
      rethrow;
    }
    if (!_isCurrentConnection(generation, client)) return;
    final current = _state.modelInventory ?? const HermesModelInventory();
    _setState(
      _state.copyWith(modelInventory: current.withAssignment(assignment)),
    );
  }

  Future<void> _refreshModelInventory(
    HermesApiClient client,
    String profile,
    int generation,
  ) async {
    final inventory = await client.getModelInventory(profile: profile);
    if (!_isCurrentConnection(generation, client)) return;
    _setState(_state.copyWith(modelInventory: inventory));
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

  bool _isCurrentProviderModelRequest(
    int connectionGeneration,
    int profileGeneration,
    HermesApiClient client,
    String? profile,
  ) =>
      _isCurrentConnection(connectionGeneration, client) &&
      _profileSelectionGeneration == profileGeneration &&
      (profile == null || _state.selectedProfileId == profile);

  /// Requires the endpoint to be advertised AND the connected token to hold
  /// every scope declared by it, failing before any network I/O when either is
  /// missing.
  void _requireProviderModelCapability(
    String name,
    String method,
    String path,
    String scope,
    String action,
  ) {
    final capabilities = _state.capabilities;
    final endpoint = capabilities?.endpoints[name];
    if (capabilities == null ||
        !capabilities.supportsSchema ||
        endpoint == null ||
        !capabilities.advertisesScopedEndpoint(name, method, path, scope)) {
      throw StateError('Hermes did not advertise support to $action.');
    }
    if (!capabilities.auth.allows(scope) ||
        !endpoint.requiredScopes.every(capabilities.auth.allows)) {
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
