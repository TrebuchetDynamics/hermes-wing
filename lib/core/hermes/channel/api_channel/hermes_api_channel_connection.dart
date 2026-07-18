part of '../hermes_api_channel.dart';

extension _ConnectionExtension on HermesApiChannel {
  Future<void> _connect({required String baseUrl, String? apiKey}) async {
    final generation = _connectionGeneration + 1;
    _connectionGeneration = generation;
    _streamGeneration += 1;
    _deletingSessionIds.clear();
    unawaited(_activeStream?.cancel());
    _activeStream = null;
    _activeRunId = null;
    _client = null;
    final activeCompleter = _activeStreamCompleter;
    _activeStreamCompleter = null;
    if (activeCompleter != null && !activeCompleter.isCompleted) {
      activeCompleter.complete();
    }
    _setState(
      const HermesChannelState(status: HermesConnectionStatus.connecting),
    );
    HermesApiClient? client;
    try {
      client = _clientBuilder(
        HermesApiConfig.fromBaseUrl(baseUrl, apiKey: apiKey),
      );
      _client = client;
      await client.health();
      if (!_isCurrentConnection(generation, client)) return;
      final capabilities = await client.capabilities();
      final optionalResourceErrors = <HermesOptionalResource, String>{};
      final detailedHealthFuture = _loadOptional<HermesHealthStatus>(
        advertised:
            capabilities.auth.allows('gateway:read') &&
            capabilities.advertisesScopedEndpoint(
              'health_detailed',
              'GET',
              '/health/detailed',
              'gateway:read',
            ),
        resource: HermesOptionalResource.detailedHealth,
        load: client.healthDetailed,
        errors: optionalResourceErrors,
      );
      final modelsFuture = _loadOptional<List<String>>(
        advertised: capabilities.advertisesEndpoint(
          'models',
          'GET',
          '/v1/models',
        ),
        resource: HermesOptionalResource.models,
        load: client.listModels,
        errors: optionalResourceErrors,
      );
      final skillsFuture = _loadOptional<List<HermesSkill>>(
        advertised: capabilities.advertisesEndpoint(
          'skills',
          'GET',
          '/v1/skills',
        ),
        resource: HermesOptionalResource.skills,
        load: client.listSkillDetails,
        errors: optionalResourceErrors,
      );
      final enabledToolsetsFuture = _loadOptional<List<String>>(
        advertised: capabilities.advertisesEndpoint(
          'toolsets',
          'GET',
          '/v1/toolsets',
        ),
        resource: HermesOptionalResource.toolsets,
        load: client.listEnabledToolsets,
        errors: optionalResourceErrors,
      );
      final jobsFuture = _loadOptional<List<HermesJob>>(
        advertised:
            capabilities.auth.allows('tasks:read') &&
            capabilities.advertisesScopedEndpoint(
              'jobs',
              'GET',
              '/api/jobs',
              'tasks:read',
            ),
        resource: HermesOptionalResource.jobs,
        load: client.listJobs,
        errors: optionalResourceErrors,
      );
      final sessions = await client.listSessions();
      if (!_isCurrentConnection(generation, client)) return;
      final activeId = sessions.firstOrNull?.id;
      List<HermesChatTurn>? messages;
      if (activeId != null) {
        messages = await _fetchTurns(client, activeId);
      }
      if (!_isCurrentConnection(generation, client)) return;
      final detailedHealth = await detailedHealthFuture;
      final models = await modelsFuture ?? const [];
      final skillDetails = await skillsFuture ?? const <HermesSkill>[];
      final skills = skillDetails
          .map((skill) => skill.name)
          .toList(growable: false);
      final enabledToolsets = await enabledToolsetsFuture ?? const [];
      final jobs = await jobsFuture ?? const [];
      if (!_isCurrentConnection(generation, client)) return;
      _setState(
        _state.copyWith(
          status: HermesConnectionStatus.connected,
          capabilities: capabilities,
          detailedHealth: detailedHealth,
          models: models,
          skills: skills,
          skillDetails: skillDetails,
          enabledToolsets: enabledToolsets,
          jobs: jobs,
          optionalResourceErrors: optionalResourceErrors,
          sessions: sessions,
          activeSessionId: activeId,
          clearActiveSessionId: activeId == null,
          connectedBaseUrl: baseUrl,
          connectedWithApiKey: apiKey?.trim().isNotEmpty ?? false,
          messages: activeId == null || messages == null
              ? _state.messages
              : {...(_state.messages), activeId: messages},
        ),
      );
    } catch (error) {
      if (generation != _connectionGeneration ||
          (client != null && !identical(_client, client))) {
        return;
      }
      _setState(
        _state.copyWith(
          status: HermesConnectionStatus.error,
          errorMessage: _safeHermesError(error),
        ),
      );
    }
  }

  bool _isCurrentConnection(int generation, HermesApiClient client) {
    return generation == _connectionGeneration && identical(_client, client);
  }

  bool _isConnectedClient(HermesApiClient client) {
    return identical(_client, client) &&
        _state.status == HermesConnectionStatus.connected;
  }

  Future<T?> _loadOptional<T>({
    required bool advertised,
    required HermesOptionalResource resource,
    required Future<T> Function() load,
    required Map<HermesOptionalResource, String> errors,
  }) async {
    if (!advertised) return null;
    try {
      return await load();
    } catch (error) {
      errors[resource] = _safeHermesError(error);
      return null;
    }
  }

  Future<void> _reloadDetailedHealth() async {
    final client = _requireConnectedClient();
    if (!_state.canReadDetailedHealth) {
      throw StateError('Hermes did not advertise detailed gateway health.');
    }
    final generation = _connectionGeneration;
    try {
      final health = await client.healthDetailed();
      if (!_isCurrentConnection(generation, client)) return;
      final errors = Map<HermesOptionalResource, String>.from(
        _state.optionalResourceErrors,
      )..remove(HermesOptionalResource.detailedHealth);
      _setState(
        _state.copyWith(detailedHealth: health, optionalResourceErrors: errors),
      );
    } catch (error) {
      if (_isCurrentConnection(generation, client)) {
        final errors = Map<HermesOptionalResource, String>.from(
          _state.optionalResourceErrors,
        )..[HermesOptionalResource.detailedHealth] = _safeHermesError(error);
        _setState(
          _state.copyWith(
            clearDetailedHealth: true,
            optionalResourceErrors: errors,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _reloadJobs() async {
    final client = _requireConnectedClient();
    if (!_state.canReadJobs) {
      throw StateError('Hermes did not advertise scheduled-job inventory.');
    }
    final generation = _connectionGeneration;
    try {
      final jobs = await client.listJobs(profile: _state.selectedProfileId);
      if (!_isCurrentConnection(generation, client)) return;
      final errors = Map<HermesOptionalResource, String>.from(
        _state.optionalResourceErrors,
      )..remove(HermesOptionalResource.jobs);
      _setState(_state.copyWith(jobs: jobs, optionalResourceErrors: errors));
    } catch (error) {
      if (_isCurrentConnection(generation, client)) {
        final errors = Map<HermesOptionalResource, String>.from(
          _state.optionalResourceErrors,
        )..[HermesOptionalResource.jobs] = _safeHermesError(error);
        _setState(
          _state.copyWith(jobs: const [], optionalResourceErrors: errors),
        );
      }
      rethrow;
    }
  }

  Future<List<HermesChatTurn>> _fetchTurns(
    HermesApiClient client,
    String sessionId,
  ) async {
    final history = await client.sessionMessages(sessionId);
    return [
      for (final message in history)
        HermesChatTurn(
          id: message.id,
          sessionId: sessionId,
          author: switch (message.role) {
            'user' => HermesTurnAuthor.user,
            'assistant' => HermesTurnAuthor.assistant,
            _ => HermesTurnAuthor.system,
          },
          createdAt: DateTime.now(),
          text: message.content,
        ),
    ];
  }
}
