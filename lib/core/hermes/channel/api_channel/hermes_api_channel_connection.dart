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
      final detailedHealth = await _optionalHealth(
        capabilities.advertisesEndpoint(
          'health_detailed',
          'GET',
          '/health/detailed',
        ),
        client.healthDetailed,
      );
      final models = await _optionalCatalogList(
        capabilities.advertisesEndpoint('models', 'GET', '/v1/models'),
        client.listModels,
      );
      final skills = await _optionalCatalogList(
        capabilities.advertisesEndpoint('skills', 'GET', '/v1/skills'),
        client.listSkills,
      );
      final enabledToolsets = await _optionalCatalogList(
        capabilities.advertisesEndpoint('toolsets', 'GET', '/v1/toolsets'),
        client.listEnabledToolsets,
      );
      final jobs = await _optionalJobs(
        capabilities.advertisesEndpoint('jobs', 'GET', '/api/jobs'),
        client.listJobs,
      );
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

  Future<HermesHealthStatus?> _optionalHealth(
    bool advertised,
    Future<HermesHealthStatus> Function() load,
  ) async {
    if (!advertised) return null;
    try {
      return await load();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _optionalCatalogList(
    bool advertised,
    Future<List<String>> Function() load,
  ) async {
    if (!advertised) return const [];
    try {
      return await load();
    } catch (_) {
      return const [];
    }
  }

  Future<List<HermesJob>> _optionalJobs(
    bool advertised,
    Future<List<HermesJob>> Function() load,
  ) async {
    if (!advertised) return const [];
    try {
      return await load();
    } catch (_) {
      return const [];
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
