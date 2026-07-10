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
      final detailedHealth = await _loadOptional<HermesHealthStatus>(
        advertised: capabilities.advertisesEndpoint(
          'health_detailed',
          'GET',
          '/health/detailed',
        ),
        resource: HermesOptionalResource.detailedHealth,
        load: client.healthDetailed,
        errors: optionalResourceErrors,
      );
      final models =
          await _loadOptional<List<String>>(
            advertised: capabilities.advertisesEndpoint(
              'models',
              'GET',
              '/v1/models',
            ),
            resource: HermesOptionalResource.models,
            load: client.listModels,
            errors: optionalResourceErrors,
          ) ??
          const [];
      final skills =
          await _loadOptional<List<String>>(
            advertised: capabilities.advertisesEndpoint(
              'skills',
              'GET',
              '/v1/skills',
            ),
            resource: HermesOptionalResource.skills,
            load: client.listSkills,
            errors: optionalResourceErrors,
          ) ??
          const [];
      final enabledToolsets =
          await _loadOptional<List<String>>(
            advertised: capabilities.advertisesEndpoint(
              'toolsets',
              'GET',
              '/v1/toolsets',
            ),
            resource: HermesOptionalResource.toolsets,
            load: client.listEnabledToolsets,
            errors: optionalResourceErrors,
          ) ??
          const [];
      final jobs =
          await _loadOptional<List<HermesJob>>(
            advertised: capabilities.advertisesEndpoint(
              'jobs',
              'GET',
              '/api/jobs',
            ),
            resource: HermesOptionalResource.jobs,
            load: client.listJobs,
            errors: optionalResourceErrors,
          ) ??
          const [];
      if (!_isCurrentConnection(generation, client)) return;
      var sessions = await client.listSessions();
      if (!_isCurrentConnection(generation, client)) return;
      String? activeId;
      List<HermesChatTurn>? messages;
      if (sessions.isEmpty) {
        if (capabilities.advertisesEndpoint(
          'session_create',
          'POST',
          '/api/sessions',
        )) {
          final created = await client.createSession(id: _sessionIdFactory());
          sessions = [created];
          activeId = created.id;
        }
      } else {
        activeId = sessions.first.id;
      }
      if (activeId != null) {
        messages = await _fetchTurns(client, activeId);
      }
      if (!_isCurrentConnection(generation, client)) return;
      _setState(
        _state.copyWith(
          status: HermesConnectionStatus.connected,
          capabilities: capabilities,
          detailedHealth: detailedHealth,
          models: models,
          skills: skills,
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
