part of '../hermes_api_channel.dart';

extension _ProfilesExtension on HermesApiChannel {
  /// Client-local profile selection. Never calls a server active-profile
  /// endpoint: it refreshes the advertised profile list, then reloads the
  /// profile-owned sessions and inventory scoped by the mandatory `profile`
  /// query. Capability/profile-context gaps fail before any network I/O, and
  /// responses that arrive after a reconnect are dropped by generation check.
  Future<void> _selectProfile(
    String profileId, {
    bool allowDiscovered = false,
  }) async {
    final client = _requireConnectedClient();
    final id = profileId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        profileId,
        'profileId',
        'Profile id cannot be empty.',
      );
    }
    if (!allowDiscovered) {
      _requireProfileEndpoint(
        'profiles',
        'GET',
        '/api/profiles',
        'profiles:read',
        'list profiles',
      );
    }
    _requireProfileContext('select a profile');

    final generation = _connectionGeneration;
    final capabilities = _state.capabilities;
    final selectionGeneration = _beginProfileSelection(id);

    try {
      final profiles = allowDiscovered
          ? [
              ..._state.profiles.where((profile) => profile.id != id),
              HermesProfile(id: id, displayName: id, revision: ''),
            ]
          : await client.listProfiles();
      if (!_isCurrentProfileSelection(
        selectionGeneration,
        generation,
        client,
      )) {
        return;
      }
      if (!allowDiscovered && !profiles.any((profile) => profile.id == id)) {
        throw StateError('Hermes profile "$id" is not available.');
      }

      final sessions = await client.listSessions(profile: id);
      if (!_isCurrentProfileSelection(
        selectionGeneration,
        generation,
        client,
      )) {
        return;
      }

      final errors = <HermesOptionalResource, String>{};
      final runtimeModels =
          await _loadOptional<List<HermesRuntimeModel>>(
            advertised:
                capabilities != null &&
                _capabilityEndpointAuthorized(
                  capabilities,
                  'models',
                  'GET',
                  '/v1/models',
                ),
            resource: HermesOptionalResource.models,
            load: () => client.listRuntimeModels(profile: id),
            errors: errors,
          ) ??
          const <HermesRuntimeModel>[];
      final models = runtimeModels
          .map((model) => model.id)
          .toList(growable: false);
      final skillDetails =
          await _loadOptional<List<HermesSkill>>(
            advertised:
                capabilities != null &&
                _capabilityEndpointAuthorized(
                  capabilities,
                  'skills',
                  'GET',
                  '/v1/skills',
                ),
            resource: HermesOptionalResource.skills,
            load: () => client.listSkillDetails(profile: id),
            errors: errors,
          ) ??
          const <HermesSkill>[];
      final skills = skillDetails
          .map((skill) => skill.name)
          .toList(growable: false);
      final toolsets =
          await _loadOptional<List<HermesToolset>>(
            advertised:
                capabilities != null &&
                _capabilityEndpointAuthorized(
                  capabilities,
                  'toolsets',
                  'GET',
                  '/v1/toolsets',
                ),
            resource: HermesOptionalResource.toolsets,
            load: () => client.listToolsets(profile: id),
            errors: errors,
          ) ??
          const <HermesToolset>[];
      final enabledToolsets = toolsets
          .where((toolset) => toolset.enabled)
          .map((toolset) => toolset.name)
          .toList(growable: false);
      final jobs =
          await _loadOptional<List<HermesJob>>(
            advertised:
                capabilities?.supportsSchema == true &&
                capabilities!.auth.allows('tasks:read') &&
                capabilities.advertisesScopedEndpoint(
                  'jobs',
                  'GET',
                  '/api/jobs',
                  'tasks:read',
                ),
            resource: HermesOptionalResource.jobs,
            load: () => client.listJobs(profile: id),
            errors: errors,
          ) ??
          const <HermesJob>[];
      if (!_isCurrentProfileSelection(
        selectionGeneration,
        generation,
        client,
      )) {
        return;
      }

      final detachedActiveId = capabilities == null
          ? null
          : await _recoverActiveDetachedSession(
              client: client,
              capabilities: capabilities,
              baseUrl: _state.connectedBaseUrl ?? '',
              profileId: id,
              sessionIds: sessions.map((session) => session.id),
            );
      final activeId = detachedActiveId ?? sessions.firstOrNull?.id;
      final detachedRunStillActive = detachedActiveId != null;
      var messages = const <String, List<HermesChatTurn>>{};
      if (activeId != null) {
        final turns = await _fetchTurns(client, activeId, profileId: id);
        if (!_isCurrentProfileSelection(
          selectionGeneration,
          generation,
          client,
        )) {
          return;
        }
        messages = {activeId: turns};
      }

      _finishAllTurnsLocally();
      _setState(
        _state.copyWith(
          profiles: profiles,
          selectedProfileId: id,
          sessions: sessions,
          activeSessionId: activeId,
          clearActiveSessionId: activeId == null,
          hasUnreconciledRun: detachedRunStillActive,
          models: models,
          runtimeModels: runtimeModels,
          skills: skills,
          skillDetails: skillDetails,
          toolsets: toolsets,
          enabledToolsets: enabledToolsets,
          jobs: jobs,
          providers: const [],
          clearModelInventory: true,
          optionalResourceErrors: errors,
          errorMessage: detachedRunStillActive
              ? 'Hermes run is still active. Reconnect later before retrying.'
              : null,
          clearErrorMessage: !detachedRunStillActive,
          messages: messages,
          voiceRuns: const {},
          clearActiveVoiceRunId: true,
        ),
      );
      if (detachedRunStillActive && activeId != null) {
        unawaited(
          _reattachDetachedRun(
            client: client,
            baseUrl: _state.connectedBaseUrl ?? '',
            profileId: id,
            sessionId: activeId,
          ),
        );
      }
    } finally {
      _finishProfileSelection(selectionGeneration);
    }
  }

  Future<void> _createProfile({required String name, String? cloneFrom}) async {
    final client = _requireConnectedClient();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name cannot be empty.');
    }
    _requireProfileEndpoint(
      'profile_create',
      'POST',
      '/api/profiles',
      'profiles:write',
      'create profiles',
    );
    await _runProfileMutation(
      client,
      () => client.createProfile(name: trimmed, cloneFrom: cloneFrom),
    );
  }

  Future<void> _renameProfile({
    required String profileId,
    required String name,
    required String revision,
  }) async {
    final client = _requireConnectedClient();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name cannot be empty.');
    }
    _requireProfileEndpoint(
      'profile_update',
      'PATCH',
      '/api/profiles/{name}',
      'profiles:write',
      'rename profiles',
    );
    _requireRevision(revision);
    await _runProfileMutation(
      client,
      () => client.renameProfile(
        profileId: profileId,
        name: trimmed,
        revision: revision,
      ),
    );
  }

  Future<void> _deleteProfile({
    required String profileId,
    required String revision,
  }) async {
    final client = _requireConnectedClient();
    _requireProfileEndpoint(
      'profile_delete',
      'DELETE',
      '/api/profiles/{name}',
      'profiles:write',
      'delete profiles',
    );
    _requireRevision(revision);
    final id = profileId.trim();
    final generation = _connectionGeneration;
    final selectionGeneration = _profileSelectionGeneration;
    final pendingSelectionAtStart = _pendingProfileSelectionId;
    await _runProfileMutation(
      client,
      () => client.deleteProfile(profileId: id, revision: revision),
    );
    if (!_isCurrentConnection(generation, client)) return;
    if (_profileSelectionGeneration != selectionGeneration ||
        pendingSelectionAtStart != null) {
      final requestedSelection =
          _pendingProfileSelectionId ??
          (_profileSelectionGeneration != selectionGeneration
              ? _state.selectedProfileId
              : pendingSelectionAtStart);
      _invalidateProfileSelection();
      if (requestedSelection != null &&
          _state.profiles.any((profile) => profile.id == requestedSelection)) {
        await _selectProfile(requestedSelection);
        return;
      }
    }
    if (_state.selectedProfileId != id) return;
    final survivor = _state.profiles.firstOrNull;
    if (survivor != null) {
      await _selectProfile(survivor.id);
      return;
    }
    // Deleting the final profile clears every profile-owned snapshot: there
    // is no survivor to reselect, so nothing else may keep pointing at it.
    _setState(
      _state.copyWith(
        clearSelectedProfileId: true,
        sessions: const [],
        clearActiveSessionId: true,
        messages: const {},
        providers: const [],
        clearModelInventory: true,
      ),
    );
  }

  Future<HermesProfileSoul> _readProfileSoul(String profileId) async {
    final client = _requireConnectedClient();
    _requireProfileEndpoint(
      'profile_soul',
      'GET',
      '/api/profiles/{name}/soul',
      'profiles:read',
      'read a persona',
    );
    _requireProfileContext('read a persona');
    return client.readProfileSoul(profileId);
  }

  Future<void> _writeProfileSoul({
    required String profileId,
    required String soul,
    required String revision,
  }) async {
    final client = _requireConnectedClient();
    _requireProfileEndpoint(
      'profile_soul_update',
      'PUT',
      '/api/profiles/{name}/soul',
      'profiles:write',
      'edit a persona',
    );
    _requireProfileContext('edit a persona');
    _requireRevision(revision);
    await _runProfileMutation(
      client,
      () => client.writeProfileSoul(
        profileId: profileId,
        soul: soul,
        revision: revision,
      ),
    );
  }

  /// Runs a profile mutation and reconciles the local profile list. On success
  /// the list is refreshed; on a `412` stale-revision conflict the list is also
  /// refreshed (so the caller sees the winning revision) before the error is
  /// rethrown. Responses that land after a reconnect are ignored.
  Future<void> _runProfileMutation(
    HermesApiClient client,
    Future<Object?> Function() operation,
  ) async {
    final generation = _connectionGeneration;
    try {
      await operation();
    } catch (error) {
      if (_isPreconditionFailed(error) &&
          _isCurrentConnection(generation, client)) {
        await _refreshProfiles(client, generation);
      }
      rethrow;
    }
    if (!_isCurrentConnection(generation, client)) return;
    await _refreshProfiles(client, generation);
  }

  Future<void> _refreshProfiles(HermesApiClient client, int generation) async {
    final profiles = await client.listProfiles();
    if (!_isCurrentConnection(generation, client)) return;
    _setState(_state.copyWith(profiles: profiles));
  }

  HermesApiClient _requireConnectedClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    return client;
  }

  void _requireProfileEndpoint(
    String name,
    String method,
    String path,
    String scope,
    String action,
  ) {
    final capabilities = _state.capabilities;
    if (capabilities == null ||
        !capabilities.supportsSchema ||
        !capabilities.advertisesScopedEndpoint(name, method, path, scope)) {
      throw StateError('Hermes did not advertise support to $action.');
    }
    if (!capabilities.auth.allows(scope)) {
      throw StateError('This device is not authorized to $action.');
    }
  }

  void _requireProfileContext(String action) {
    final capabilities = _state.capabilities;
    if (capabilities == null ||
        !capabilities.supportsSchema ||
        !capabilities.profileContext.isSupportedQueryContext) {
      throw StateError(
        'Hermes did not advertise the profile query context needed to $action.',
      );
    }
  }

  void _requireRevision(String revision) {
    if (revision.trim().isEmpty) {
      throw ArgumentError.value(
        revision,
        'revision',
        'A profile revision is required as an If-Match precondition.',
      );
    }
  }

  bool _isPreconditionFailed(Object error) {
    return error.toString().contains('HTTP 412');
  }
}
