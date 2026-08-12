part of '../hermes_api_channel.dart';

extension _ConnectionExtension on HermesApiChannel {
  Future<void> _connect({required String baseUrl, String? apiKey}) async {
    final generation = _connectionGeneration + 1;
    _connectionGeneration = generation;
    _deletingSessionOperations.clear();
    _forkingSessionOperations.clear();
    _clearActiveRunTracking();
    _detachedRunsLoadFuture = null;
    _detachedRunsLoadFailed = false;
    _client = null;
    _setState(
      const HermesChannelState(status: HermesConnectionStatus.connecting),
    );
    HermesApiClient? client;
    try {
      client = _clientBuilder(
        HermesApiConfig.fromBaseUrl(baseUrl, apiKey: apiKey),
      );
      _client = client;
      final basicHealth = await client.health();
      if (!_isCurrentConnection(generation, client)) return;
      final capabilities = await client.capabilities();
      final initialProfileId =
          capabilities.profileContext.isSupportedQueryContext
          ? capabilities.profileContext.defaultProfileId
          : null;
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
      final modelsFuture = _loadOptional<List<HermesRuntimeModel>>(
        advertised: _capabilityEndpointAuthorized(
          capabilities,
          'models',
          'GET',
          '/v1/models',
        ),
        resource: HermesOptionalResource.models,
        load: () => client!.listRuntimeModels(profile: initialProfileId),
        errors: optionalResourceErrors,
      );
      final skillsFuture = _loadOptional<List<HermesSkill>>(
        advertised: _capabilityEndpointAuthorized(
          capabilities,
          'skills',
          'GET',
          '/v1/skills',
        ),
        resource: HermesOptionalResource.skills,
        load: () => client!.listSkillDetails(profile: initialProfileId),
        errors: optionalResourceErrors,
      );
      final toolsetsFuture = _loadOptional<List<HermesToolset>>(
        advertised: _capabilityEndpointAuthorized(
          capabilities,
          'toolsets',
          'GET',
          '/v1/toolsets',
        ),
        resource: HermesOptionalResource.toolsets,
        load: () => client!.listToolsets(profile: initialProfileId),
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
        load: () => client!.listJobs(profile: initialProfileId),
        errors: optionalResourceErrors,
      );
      final sessions = await client.listSessions(profile: initialProfileId);
      if (!_isCurrentConnection(generation, client)) return;
      final detachedActiveId = await _recoverActiveDetachedSession(
        client: client,
        capabilities: capabilities,
        baseUrl: baseUrl,
        profileId: initialProfileId,
        sessionIds: sessions.map((session) => session.id),
      );
      final activeId = detachedActiveId ?? sessions.firstOrNull?.id;
      final detachedRunConfirmed =
          detachedActiveId != null &&
          _detachedRuns.values.any(
            (run) =>
                run.baseUrl == _detachedRunBaseUrl(baseUrl) &&
                run.profileId == initialProfileId &&
                run.sessionId == detachedActiveId &&
                _confirmedDetachedRunKeys.contains(_detachedRunKey(run)),
          );
      List<HermesChatTurn>? messages;
      if (activeId != null) {
        messages = await _fetchTurns(
          client,
          activeId,
          profileId: initialProfileId,
        );
      }
      if (!_isCurrentConnection(generation, client)) return;
      final detailedHealth = await detailedHealthFuture;
      final runtimeModels = await modelsFuture ?? const <HermesRuntimeModel>[];
      final models = runtimeModels
          .map((model) => model.id)
          .toList(growable: false);
      final skillDetails = await skillsFuture ?? const <HermesSkill>[];
      final skills = skillDetails
          .map((skill) => skill.name)
          .toList(growable: false);
      final toolsets = await toolsetsFuture ?? const <HermesToolset>[];
      final enabledToolsets = toolsets
          .where((toolset) => toolset.enabled)
          .map((toolset) => toolset.name)
          .toList(growable: false);
      final jobs = await jobsFuture ?? const [];
      if (!_isCurrentConnection(generation, client)) return;
      _setState(
        _state.copyWith(
          status: HermesConnectionStatus.connected,
          capabilities: capabilities,
          basicHealth: basicHealth,
          detailedHealth: detailedHealth,
          models: models,
          runtimeModels: runtimeModels,
          skills: skills,
          skillDetails: skillDetails,
          toolsets: toolsets,
          enabledToolsets: enabledToolsets,
          jobs: jobs,
          optionalResourceErrors: optionalResourceErrors,
          sessions: sessions,
          selectedProfileId: initialProfileId,
          activeSessionId: activeId,
          clearActiveSessionId: activeId == null,
          connectedBaseUrl: baseUrl,
          connectedWithApiKey: apiKey?.trim().isNotEmpty ?? false,
          hasUnreconciledRun: detachedActiveId != null,
          errorMessage: detachedActiveId != null && !detachedRunConfirmed
              ? 'Hermes run is still active. Reconnect later before retrying.'
              : null,
          clearErrorMessage: detachedActiveId == null || detachedRunConfirmed,
          messages: activeId == null || messages == null
              ? _state.messages
              : {...(_state.messages), activeId: messages},
        ),
      );
      if (detachedRunConfirmed && activeId != null) {
        unawaited(
          _reattachDetachedRun(
            client: client,
            baseUrl: baseUrl,
            profileId: initialProfileId,
            sessionId: activeId,
          ),
        );
      }
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

  bool _isConnectedProfile(HermesApiClient client, String? profileId) {
    return _isConnectedClient(client) && _state.selectedProfileId == profileId;
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
    String sessionId, {
    String? profileId,
  }) async {
    final history = await client.sessionMessages(
      sessionId,
      profile: profileId ?? _state.selectedProfileId,
    );
    final fetchedAt = DateTime.now();
    final resolvedProfile = profileId ?? _state.selectedProfileId ?? 'default';
    final cacheKey = _recentTurnKey(
      client,
      sessionId,
      profileId: resolvedProfile,
    );
    final stateProfile = _state.selectedProfileId ?? 'default';
    final unmatched = List<HermesChatTurn>.of(
      (resolvedProfile == stateProfile ? _state.messages[sessionId] : null) ??
          _recentTurns[cacheKey] ??
          const [],
    );
    final turns = [
      for (final message in history)
        (() {
          final author = switch (message.role) {
            'user' => HermesTurnAuthor.user,
            'assistant' => HermesTurnAuthor.assistant,
            _ => HermesTurnAuthor.system,
          };
          var match = unmatched.indexWhere((turn) => turn.id == message.id);
          if (match < 0) {
            match = unmatched.indexWhere(
              (turn) =>
                  turn.author == author &&
                  turn.text.trim() == message.content.trim(),
            );
          }
          final existing = match < 0 ? null : unmatched.removeAt(match);
          final parsedTimestamp = DateTime.tryParse(message.timestamp ?? '');
          final serverTimestamp =
              parsedTimestamp != null &&
                  parsedTimestamp.isAfter(DateTime.utc(2000)) &&
                  parsedTimestamp.isBefore(
                    fetchedAt.toUtc().add(const Duration(days: 1)),
                  )
              ? parsedTimestamp.toLocal()
              : null;
          return HermesChatTurn(
            id: message.id,
            sessionId: sessionId,
            author: author,
            createdAt: serverTimestamp ?? existing?.createdAt ?? fetchedAt,
            text: message.content,
            usage: message.usage ?? existing?.usage,
          );
        })(),
    ];
    _recentTurns.remove(cacheKey);
    _recentTurns[cacheKey] = turns.length <= 500
        ? List.unmodifiable(turns)
        : List.unmodifiable(turns.sublist(turns.length - 500));
    while (_recentTurns.length > 32) {
      _recentTurns.remove(_recentTurns.keys.first);
    }
    return turns;
  }
}

bool _capabilityEndpointAuthorized(
  HermesCapabilityDocument capabilities,
  String name,
  String method,
  String path,
) {
  if (!capabilities.supportsSchema ||
      !capabilities.advertisesEndpoint(name, method, path)) {
    return false;
  }
  final endpoint = capabilities.endpoints[name];
  return endpoint != null &&
      endpoint.requiredScopes.every(capabilities.auth.allows);
}
