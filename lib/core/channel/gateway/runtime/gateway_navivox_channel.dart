import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../gateway/navivox_gateway_protocol.dart';
import '../../../protocol/navivox_event.dart';
import '../../../protocol/navivox_memory.dart';
import '../../../protocol/navivox_profile_contact_key.dart';
import '../../../protocol/navivox_voice_run.dart';
import '../../../session/credentials/durable_credential_store.dart';
import '../../../session/identity/app_install_identity_service.dart';
import '../../../session/reconnect/durable_reconnect_issuance_coordinator.dart';
import '../../../session/session_persistence_service.dart';
import '../../contracts/navivox_channel.dart';
import '../../contracts/navivox_profile_contact_codec.dart';
import '../events/gateway_event_reducer.dart';
import '../client/gateway_capability_policy.dart';
import '../client/gateway_config_admin_policy.dart';
import '../lifecycle/gateway_connection_lifecycle_policy.dart';
import '../memory/gateway_memory_request_policy.dart';
import '../profiles/gateway_profile_contact_policy.dart';
import '../profiles/gateway_voice_run_policy.dart';
import '../state/gateway_channel_state_policy.dart';
import '../messages/gateway_user_turn_policy.dart';
import '../turns/gateway_turn_control_policy.dart';

class GatewayNavivoxChannel extends ChangeNotifier implements NavivoxChannel {
  GatewayNavivoxChannel({
    Uuid? uuid,
    DateTime Function()? clock,
    DurableCredentialStore? credentialStore,
    AppInstallIdentityService? appInstallIdentity,
  }) : _uuid = uuid ?? const Uuid(),
       _clock = clock ?? DateTime.now,
       _durableReconnect = DurableReconnectIssuanceCoordinator(
         appInstallIdentity:
             appInstallIdentity ?? AppInstallIdentityService(),
         credentialStore: credentialStore ?? const EmptyDurableCredentialStore(),
         clock: clock ?? DateTime.now,
       );

  final Uuid _uuid;
  final DateTime Function() _clock;
  final DurableReconnectIssuanceCoordinator _durableReconnect;
  final StreamController<NavivoxApprovalRequest> _approvals =
      StreamController<NavivoxApprovalRequest>.broadcast();

  final SessionPersistenceService _sessionService = SessionPersistenceService();
  NavivoxGatewayClient? _client;
  NavivoxCapabilityDocument? _capabilities;
  NavivoxGatewaySocket? _socket;
  StreamSubscription<NavivoxGatewayEvent>? _events;
  NavivoxChannelState _state = const NavivoxChannelState();
  bool _configAdminAvailable = false;
  bool _configAdminSupported = false;
  bool _configAdminLoadFailed = false;

  // Gateway sessions are tracked per profile contact so turn control and turn
  // submission target the right in-flight session when several profiles are
  // live at once. `_unscopedSessionId` is the fallback for gateways that report
  // a session without resolvable profile scope (single-profile behavior).
  final Map<String, String> _sessionIdsByProfileKey = <String, String>{};
  String? _unscopedSessionId;

  @override
  NavivoxChannelState get state => _state;

  @override
  void selectProfileRouting({
    String? workspace,
    String? provider,
    String? channel,
  }) {
    final next = _state.withActiveProfileRouting(
      workspace: workspace,
      provider: provider,
      channel: channel,
    );
    if (identical(next, _state)) return;
    _state = next;
    notifyListeners();
  }

  @override
  Stream<NavivoxApprovalRequest> get approvalRequests => _approvals.stream;

  @override
  Future<void> connect({
    required String baseUrl,
    String? token,
    String? webSocketUrl,
  }) async {
    await _closeConnection(clearSavedSession: false);
    try {
      final config = NavivoxGatewayConfig(
        baseUri: Uri.parse(baseUrl),
        token: token,
        webSocketUri: _optionalUri(webSocketUrl),
      );
      final client = NavivoxGatewayClient(config: config);
      final status = await client.gatewayStatus();
      _client = client;
      if (!status.enabled) {
        _capabilities = null;
        _enterClosedCapabilityMode(
          config,
          status: 'Gateway disabled',
          gatewayLabel: status.gatewayLabel,
        );
        return;
      }
      final capabilities = await _loadCapabilities(client);
      _capabilities = capabilities;
      if (capabilities == null) {
        _enterClosedCapabilityMode(
          config,
          status: 'Capabilities unavailable',
          gatewayLabel: status.gatewayLabel,
        );
        return;
      }

      final contacts = navivoxProfileContactsAvailable(capabilities)
          ? await _loadProfileContacts(client)
          : [navivoxFallbackProfileContact(serverLabel: status.gatewayLabel)];
      final profileRouting = navivoxProfileRoutingAvailable(capabilities)
          ? await client.profileRouting()
          : const NavivoxProfileRoutingReport();
      final configAdminSupported = navivoxConfigAdminSupported(capabilities);
      ({Map<String, Object?> schema, Map<String, Object?> values})?
      configAdminState;
      _configAdminSupported = configAdminSupported;
      _configAdminLoadFailed = false;
      if (configAdminSupported) {
        try {
          configAdminState = await navivoxRefreshGatewayConfigAdminState(
            client: client,
          );
        } catch (_) {
          _configAdminLoadFailed = true;
        }
      }
      _configAdminAvailable = configAdminState != null;
      final streamAvailable = navivoxStreamAvailable(capabilities);
      if (streamAvailable) {
        final socket = await client.connectStream();
        _socket = socket;
        _events = client
            .decodeEvents(socket.events)
            .listen(
              _onEvent,
              onError: (Object error) {
                _handleStreamClosed();
                _appendSystemMessage('Gateway stream error');
              },
              onDone: () {
                _handleStreamClosed();
                _setServerStatus('Gateway disconnected');
              },
            );
      }
      _state = navivoxConnectedGatewayState(
        state: _state,
        config: config,
        capabilities: capabilities,
        contacts: contacts,
        profileRouting: profileRouting,
        configSchema: configAdminState?.schema ?? const {},
        configValues: configAdminState?.values ?? const {},
      );
      notifyListeners();
      // Persist connection parameters so the app can reconnect automatically.
      unawaited(
        _sessionService.saveConnection(
          baseUrl: baseUrl,
          webSocketUrl: webSocketUrl,
          gatewayId: status.gatewayId,
        ),
      );
      if (!streamAvailable) {
        _appendSystemMessage(
          'Navivox stream is not advertised by this gateway.',
        );
      }
      // Durable reconnect: when the gateway advertises support, issue and store
      // an interim credential before any chat turn. The coordinator swallows
      // its own failures (returning session-only readiness), so this never
      // breaks the live connection.
      if (_state.reconnectReadiness.kind == ReconnectReadinessKind.available) {
        final readiness = await _durableReconnect.persist(
          client: client,
          gatewayId: status.gatewayId ?? '',
          currentReadiness: _state.reconnectReadiness,
        );
        _state = _state.copyWith(reconnectReadiness: readiness);
        notifyListeners();
      }
    } catch (_) {
      await _closeConnection(clearSavedSession: false);
      _clearSessions();
      _state = const NavivoxChannelState();
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _closeConnection(clearSavedSession: true);
    _clearSessions();
    _state = const NavivoxChannelState();
    notifyListeners();
  }

  Future<void> _closeConnection({required bool clearSavedSession}) async {
    await _events?.cancel();
    _events = null;
    await _socket?.close();
    _socket = null;
    _client = null;
    _capabilities = null;
    _clearSessions();
    _configAdminAvailable = false;
    _configAdminSupported = false;
    _configAdminLoadFailed = false;
    if (clearSavedSession) {
      unawaited(_sessionService.clearSession());
    }
  }

  // Records a gateway session under its profile contact, or under the unscoped
  // fallback when the gateway reported no resolvable profile scope.
  void _recordSession({
    required String? sessionId,
    required String? profileContactKey,
  }) {
    if (sessionId == null) return;
    if (profileContactKey != null) {
      _sessionIdsByProfileKey[profileContactKey] = sessionId;
    } else {
      _unscopedSessionId = sessionId;
    }
  }

  String? _sessionIdForActiveProfile() {
    return _sessionIdForProfileKey(_state.activeProfileContact?.key);
  }

  String? _sessionIdForProfileKey(String? profileContactKey) {
    if (profileContactKey != null) {
      final scoped = _sessionIdsByProfileKey[profileContactKey];
      if (scoped != null) return scoped;
    }
    return _unscopedSessionId;
  }

  void _clearSessions() {
    _sessionIdsByProfileKey.clear();
    _unscopedSessionId = null;
  }

  Uri? _optionalUri(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return Uri.parse(trimmed);
  }

  bool _frameExceedsGatewayMaxRequestBytes(String frame) {
    final maxRequestBytes = _capabilities?.attachments.maxRequestBytes ?? 0;
    if (maxRequestBytes <= 0) return false;
    return utf8.encode(frame).length > maxRequestBytes;
  }

  Future<NavivoxCapabilityDocument?> _loadCapabilities(
    NavivoxGatewayClient client,
  ) async {
    try {
      final capabilities = await client.capabilities();
      return navivoxCapabilityDocumentUsable(capabilities)
          ? capabilities
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<NavivoxProfileContact>> _loadProfileContacts(
    NavivoxGatewayClient client,
  ) async {
    final contactPayloads = await client.profileContacts();
    return navivoxProfileContactsFromGatewayPayloads(contactPayloads);
  }

  void _enterClosedCapabilityMode(
    NavivoxGatewayConfig config, {
    required String status,
    String? gatewayLabel,
  }) {
    _state = navivoxClosedCapabilityGatewayState(
      state: _state,
      config: config,
      status: status,
      gatewayLabel: gatewayLabel,
    );
    notifyListeners();
  }

  @override
  void sendText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final socket = _socket;
    if (socket == null) {
      _appendSystemMessage('Gateway is not connected.');
      return;
    }

    final requestId = _uuid.v4();
    final submission = navivoxGatewayUserTurnSubmission(
      requestId: requestId,
      sessionId: _sessionIdForActiveProfile(),
      text: trimmed,
      createdAt: _clock(),
      profile: _state.activeProfileContact,
      routing: _state.activeProfileRoutingSelection,
    );
    if (_frameExceedsGatewayMaxRequestBytes(submission.frame)) {
      _appendSystemMessage('Message is too large for this gateway.');
      return;
    }
    _putMessage(submission.message);
    socket.add(submission.frame);
  }

  @override
  void sendVoice({required String transcript}) {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty) {
      _appendSystemMessage('Voice transcript is empty.');
      return;
    }

    final voiceRunId = startVoiceRun();
    stageVoiceRunTranscript(
      voiceRunId: voiceRunId,
      transcript: trimmed,
      duration: Duration.zero,
      confidence: 1,
    );
    submitVoiceRun(voiceRunId);
  }

  @override
  String startVoiceRun() {
    final id = 'voice-${_uuid.v4()}';
    final run = navivoxGatewayRecordingVoiceRun(
      id: id,
      profile: _state.activeProfileContact,
      createdAt: _clock(),
    );
    _putVoiceRun(run, active: true);
    return id;
  }

  @override
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
    NavivoxTranscriptSource transcriptSource = NavivoxTranscriptSource.device,
  }) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    _putVoiceRun(
      navivoxGatewayStagedVoiceRun(
        run: run,
        transcript: transcript,
        duration: duration,
        confidence: confidence,
        transcriptSource: transcriptSource,
        updatedAt: _clock(),
      ),
      active: true,
    );
  }

  @override
  void cancelVoiceRun(
    String voiceRunId, {
    String reason = 'cancelled before send',
  }) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    _putVoiceRun(run.markCancelled(reason), active: true);
  }

  @override
  void failVoiceRun(String voiceRunId, {required String reason}) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    _putVoiceRun(run.markFailed(reason), active: true);
    _appendSystemMessage(reason);
  }

  @override
  void submitVoiceRun(String voiceRunId) {
    final run = _state.voiceRuns[voiceRunId];
    final trimmed = run?.transcript?.trim() ?? '';
    if (run == null) return;
    if (trimmed.isEmpty) {
      failVoiceRun(voiceRunId, reason: 'Voice transcript is empty.');
      return;
    }

    final socket = _socket;
    if (socket == null) {
      failVoiceRun(voiceRunId, reason: 'Gateway is not connected.');
      return;
    }

    // The active profile may have changed during the staged auto-send gap, so a
    // voice turn is submitted to the run's own profile and session, not whatever
    // contact happens to be active now.
    final runProfileKey = navivoxProfileContactKey(
      serverId: run.serverId,
      profileId: run.profileId,
    );
    final runProfile =
        _state.profileContacts
            .where((contact) => contact.key == runProfileKey)
            .firstOrNull ??
        _state.activeProfileContact;
    final requestId = _uuid.v4();
    final sessionId = _sessionIdForProfileKey(runProfileKey);
    final submitted = navivoxGatewaySubmittedVoiceRun(
      run: run,
      requestId: requestId,
      sessionId: sessionId,
    );
    final submission = navivoxGatewayUserTurnSubmission(
      requestId: requestId,
      sessionId: sessionId,
      text: trimmed,
      createdAt: _clock(),
      profile: runProfile,
      routing: _state.profileRoutingSelectionFor(runProfile),
      voice: navivoxGatewaySubmittedVoiceMessage(
        run: submitted,
        voiceRunId: voiceRunId,
        transcript: trimmed,
      ),
    );
    if (_frameExceedsGatewayMaxRequestBytes(submission.frame)) {
      failVoiceRun(
        voiceRunId,
        reason: 'Message is too large for this gateway.',
      );
      return;
    }
    _putVoiceRun(submitted, active: true);
    _putMessage(submission.message);
    socket.add(submission.frame);
  }

  @override
  void cancelActiveTurn() {
    _sendTurnControl(stop: false);
  }

  @override
  void stopActiveTurn() {
    _sendTurnControl(stop: true);
  }

  @override
  void respondToApproval({required String approvalId, required bool approved}) {
    _appendSystemMessage(
      'Tool approvals are not available on this channel yet.',
    );
  }

  @override
  void requestAgentList() {
    unawaited(_refreshProfileContacts());
  }

  @override
  Future<NavivoxProfileSeedResult> profileSeed({
    required String seed,
    bool apply = false,
    List<String> workspaceRoots = const [],
  }) async {
    final client = navivoxRequireGatewayCapability(
      client: _client,
      capabilities: _capabilities,
      isAvailable: navivoxProfileSeedAvailable,
      connectMessage: 'Connect to Gormes to create profiles from seed.',
      unavailableMessage: 'Gormes profile seed is not advertised.',
    );
    final result = await client.profileSeed(
      seed: seed,
      apply: apply,
      workspaceRoots: workspaceRoots,
    );
    if (result.isApplied) {
      final contactPayload = result.contact;
      if (contactPayload.isNotEmpty) {
        final contact = navivoxProfileContactFromJson(contactPayload);
        _upsertProfileContact(contact);
        selectProfileContact(
          serverId: contact.serverId,
          profileId: contact.profileId,
        );
      } else {
        await _refreshProfileContacts();
      }
    }
    return result;
  }

  @override
  Future<NavivoxVoiceProfilesResponse> voiceProfiles() async {
    final client = navivoxRequireGatewayCapability(
      client: _client,
      capabilities: _capabilities,
      isAvailable: navivoxVoiceProfilesAvailable,
      connectMessage: 'Connect to Gormes to load voice profiles.',
      unavailableMessage: 'Gormes voice profiles are not advertised.',
    );
    return client.voiceProfiles();
  }

  @override
  Future<NavivoxVoiceProfileValidationResponse> validateVoiceProfile({
    required String profileId,
    required NavivoxProfileVoiceProfile voiceProfile,
  }) async {
    final client = navivoxRequireGatewayCapability(
      client: _client,
      capabilities: _capabilities,
      isAvailable: navivoxVoiceProfileValidationAvailable,
      connectMessage: 'Connect to Gormes to validate voice profiles.',
      unavailableMessage: 'Gormes voice profile validation is not advertised.',
    );
    return client.validateVoiceProfile(
      profileId: profileId,
      voiceProfile: voiceProfile,
    );
  }

  @override
  Future<NavivoxRunRecordSnapshot> runRecord(String runIdOrSessionId) async {
    final client = navivoxRequireGatewayCapability(
      client: _client,
      capabilities: _capabilities,
      isAvailable: navivoxRunRecordsSupported,
      connectMessage: 'Connect to Gormes to load run records.',
      unavailableMessage: 'Gormes run records are not advertised.',
    );
    return client.runRecord(runIdOrSessionId);
  }

  Future<void> _refreshProfileContacts() async {
    final client = _client;
    if (client == null) {
      _appendSystemMessage('Connect to Gormes to refresh profiles.');
      return;
    }
    final capabilities = _capabilities;
    if (capabilities == null ||
        !navivoxProfileContactsAvailable(capabilities)) {
      _appendSystemMessage('Gormes profile contacts are not advertised.');
      return;
    }
    try {
      final contactPayloads = await client.profileContacts();
      final contacts = navivoxProfileContactsFromGatewayPayloads(
        contactPayloads,
      );
      _state = navivoxStateWithProfileContacts(
        state: _state,
        contacts: contacts,
        config: client.config,
        preferredKey: _state.selectedProfileContactKey,
      );
      notifyListeners();
    } catch (_) {
      _appendSystemMessage('Could not refresh Gormes profiles.');
    }
  }

  @override
  Future<NavivoxMemoryOverview> memoryOverview({
    String? serverId,
    String? profileId,
  }) async {
    return navivoxGatewayMemoryRequest(
      client: _client,
      activeProfile: _state.activeProfileContact,
      serverId: serverId,
      profileId: profileId,
      disconnectedReason: 'Connect to Gormes to load Goncho memory.',
      unavailableReason: 'Gormes memory API is unavailable.',
      degraded: (scope, reason) => NavivoxMemoryOverview.degraded(
        profileId: scope.profileId,
        reason: reason,
      ),
      request: (client, scope) => client.memoryOverview(
        serverId: scope.serverId,
        profileId: scope.profileId,
      ),
    );
  }

  @override
  Future<NavivoxMemorySearchResult> memorySearch({
    String? serverId,
    String? profileId,
    String query = '',
    NavivoxMemoryType type = NavivoxMemoryType.all,
    int limit = 20,
    String? pageToken,
  }) async {
    return navivoxGatewayMemoryRequest(
      client: _client,
      activeProfile: _state.activeProfileContact,
      serverId: serverId,
      profileId: profileId,
      disconnectedReason: 'Connect to Gormes to search Goncho memory.',
      unavailableReason: 'Gormes memory search API is unavailable.',
      degraded: (_, reason) =>
          NavivoxMemorySearchResult.degraded(reason: reason),
      request: (client, scope) => client.memorySearch(
        serverId: scope.serverId,
        profileId: scope.profileId,
        query: query,
        type: type,
        limit: limit,
        pageToken: pageToken,
      ),
    );
  }

  @override
  Future<NavivoxMemoryDetail> memoryDetail({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
  }) async {
    return navivoxGatewayMemoryRequest(
      client: _client,
      activeProfile: _state.activeProfileContact,
      serverId: serverId,
      profileId: profileId,
      disconnectedReason: 'Connect to Gormes to inspect Goncho memory.',
      unavailableReason: 'Gormes memory detail API is unavailable.',
      degraded: (_, reason) =>
          NavivoxMemoryDetail.degraded(id: id, reason: reason),
      request: (client, scope) => client.memoryDetail(
        serverId: scope.serverId,
        profileId: scope.profileId,
        id: id,
        type: type,
      ),
    );
  }

  @override
  Future<NavivoxMemoryActionResult> memoryAction({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
    required NavivoxMemoryActionType action,
    String? correction,
  }) async {
    return navivoxGatewayMemoryRequest(
      client: _client,
      activeProfile: _state.activeProfileContact,
      serverId: serverId,
      profileId: profileId,
      disconnectedReason: 'Connect to Gormes to manage Goncho memory.',
      unavailableReason: 'Gormes memory management API is unavailable.',
      degraded: (_, reason) =>
          NavivoxMemoryActionResult.degraded(action: action, reason: reason),
      request: (client, scope) => client.memoryAction(
        serverId: scope.serverId,
        profileId: scope.profileId,
        id: id,
        type: type,
        action: action,
        correction: correction,
      ),
    );
  }

  @override
  void selectAgent(String agentId) {
    _state = _state.copyWith(selectedAgentId: agentId);
    notifyListeners();
  }

  @override
  void selectProfileContact({
    required String serverId,
    required String profileId,
  }) {
    final key = navivoxProfileContactKey(
      serverId: serverId,
      profileId: profileId,
    );
    if (_state.selectedProfileContactKey == key &&
        _state.activeServerId == serverId) {
      return;
    }
    _state = _state.copyWith(
      selectedProfileContactKey: key,
      activeServerId: serverId,
    );
    notifyListeners();
  }

  @override
  bool get configAdminAvailable => _configAdminAvailable;

  @override
  bool get configAdminSupported => _configAdminSupported;

  @override
  bool get configAdminLoadFailed => _configAdminLoadFailed;

  @override
  Future<void> refreshConfigAdmin() async {
    final client = _requireConfigAdminRefreshClient('refresh config admin');
    try {
      final configAdminState = await navivoxRefreshGatewayConfigAdminState(
        client: client,
      );
      _configAdminAvailable = true;
      _configAdminLoadFailed = false;
      _state = _state.copyWith(
        configSchema: configAdminState.schema,
        configValues: configAdminState.values,
        clearConfigDiff: true,
      );
      notifyListeners();
    } catch (_) {
      _configAdminAvailable = false;
      _configAdminLoadFailed = true;
      _state = _state.copyWith(
        clearConfigSchema: true,
        configValues: const {},
        clearConfigDiff: true,
      );
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<NavivoxConfigAdminResponse> validateConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    final client = _requireConfigAdminClient('validate config');
    final response = await client.validateConfigAdmin(changes);
    _state = navivoxStateWithConfigAdminResponse(
      state: _state,
      response: response,
    );
    notifyListeners();
    return response;
  }

  @override
  Future<NavivoxConfigAdminResponse> diffConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    final client = _requireConfigAdminClient('diff config');
    final response = await client.diffConfigAdmin(changes);
    _state = navivoxStateWithConfigAdminResponse(
      state: _state,
      response: response,
    );
    notifyListeners();
    return response;
  }

  @override
  Future<NavivoxConfigAdminResponse> applyConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    final client = _requireConfigAdminClient('apply config');
    final response = await client.applyConfigAdmin(changes);
    final nextValues = await navivoxConfigAdminValuesAfterAppliedResponse(
      client: client,
      response: response,
    );
    _state = navivoxStateWithConfigAdminResponse(
      state: _state,
      response: response,
      nextValues: nextValues,
    );
    notifyListeners();
    return response;
  }

  NavivoxGatewayClient _requireConfigAdminClient(String action) {
    return navivoxRequireGatewayConfigAdminClient(
      client: _client,
      available: _configAdminAvailable,
      action: action,
    );
  }

  NavivoxGatewayClient _requireConfigAdminRefreshClient(String action) {
    return navivoxRequireGatewayConfigAdminClient(
      client: _client,
      available: _configAdminSupported,
      action: action,
    );
  }

  @override
  void sendConfigSet({required String field, required Object? value}) {
    if (!_configAdminAvailable) {
      _appendSystemMessage(navivoxConfigEditUnavailableMessage(secret: false));
      return;
    }
    unawaited(_applyConfigSetInBackground(field: field, value: value));
  }

  @override
  void sendConfigSecretSet({required String name, required String secret}) {
    if (!_configAdminAvailable) {
      _appendSystemMessage(navivoxConfigEditUnavailableMessage(secret: true));
      return;
    }
    unawaited(_applyConfigSetInBackground(field: name, value: secret));
  }

  Future<void> _applyConfigSetInBackground({
    required String field,
    required Object? value,
  }) async {
    try {
      await applyConfigAdmin([
        NavivoxConfigAdminChange(key: field, value: value),
      ]);
    } catch (_) {
      _appendSystemMessage('Config apply failed.');
    }
  }

  /// Attempt to reconnect using a saved durable reconnect credential.
  ///
  /// Saved connection metadata alone is not a session and is not sufficient for
  /// silent reconnect. It can identify a known gateway, but reconnect remains
  /// disabled until durable credential auth is available for that gateway.
  Future<bool> tryReconnect() async {
    final session = await _sessionService.loadSession();
    if (session == null || session.isStale) return false;
    // Saved metadata can identify a known gateway, but durable silent reconnect
    // needs a device-credential challenge flow that is not implemented yet
    // (blocked on the Gormes durable-credential protocol; see the [PLANNED]
    // durable-credential item in TODO.md), so `canAttemptReconnect` stays
    // false. Surface the known gateway and ask the operator to pair again.
    //
    // Deliberately do NOT attempt a token-less `connect()` and do NOT delete a
    // stored credential here. A reconnect path that authenticates with no token
    // would always fail against an authenticated gateway and then revoke the
    // very credential it never used. When durable reconnect lands it must mint
    // a session token through the challenge flow, not reuse this method's
    // bootstrap `connect(token:)` seam.
    _appendSystemMessage('Known gateway saved. Pair again to reconnect.');
    return false;
  }

  @override
  void dispose() {
    unawaited(_closeConnection(clearSavedSession: false));
    unawaited(_approvals.close());
    super.dispose();
  }

  void _onEvent(NavivoxGatewayEvent event) {
    final reduction = navivoxReduceGatewayEvent(
      event: event,
      state: _state,
      fallbackId: _uuid.v4,
      clock: _clock,
    );
    _applyGatewayEventReduction(reduction);
  }

  void _applyGatewayEventReduction(GatewayEventReduction reduction) {
    switch (reduction) {
      case IgnoreGatewayEvent():
        return;
      case UpdateGatewayActiveSession(:final sessionId, :final profileContactKey):
        _recordSession(
          sessionId: sessionId,
          profileContactKey: profileContactKey,
        );
      case PutGatewayEventMessage(:final message):
        _putMessage(message);
      case PutGatewayApprovalEvent(:final messages, :final notice):
        for (final message in messages) {
          _putMessage(message);
        }
        _approvals.add(notice.toChannelRequest());
      case UpsertGatewayProfileContact(:final contact):
        _upsertProfileContact(contact);
      case AppendGatewaySystemMessage(:final text):
        _appendSystemMessage(text);
    }
  }

  void _appendSystemMessage(String text) {
    if (!navivoxShouldAppendGatewaySystemMessage(state: _state, text: text)) {
      return;
    }

    _putMessage(
      NavivoxChatMessage(
        id: _uuid.v4(),
        author: NavivoxMessageAuthor.system,
        kind: NavivoxMessageKind.text,
        createdAt: _clock(),
        text: text,
      ),
    );
  }

  // Drops the live socket once the gateway-closed stream ends so subsequent
  // sends hit the not-connected guard instead of writing to a dead sink.
  void _handleStreamClosed() {
    final socket = _socket;
    _socket = null;
    _events = null;
    unawaited(socket?.close());
  }

  void _setServerStatus(String status) {
    if (_state.servers.isEmpty) return;
    _state = _state.copyWith(
      servers: [
        for (final server in _state.servers)
          NavivoxServer(id: server.id, name: server.name, status: status),
      ],
    );
    notifyListeners();
  }

  void _upsertProfileContact(NavivoxProfileContact contact) {
    _state = navivoxStateWithProfileContactUpsert(
      state: _state,
      contact: contact,
    );
    notifyListeners();
  }

  void _putMessage(NavivoxChatMessage message) {
    _state = navivoxStateWithGatewayMessage(state: _state, message: message);
    notifyListeners();
  }

  void _putVoiceRun(NavivoxVoiceRun run, {required bool active}) {
    _state = navivoxStateWithGatewayVoiceRun(
      state: _state,
      run: run,
      active: active,
    );
    notifyListeners();
  }

  void _sendTurnControl({required bool stop}) {
    final socket = _socket;
    final sessionId = _sessionIdForActiveProfile();
    if (socket == null || sessionId == null || sessionId.trim().isEmpty) {
      _appendSystemMessage(navivoxGatewayNoActiveTurnMessage(stop: stop));
      return;
    }
    final requestId = _uuid.v4();
    socket.add(
      navivoxGatewayTurnControlFrame(
        stop: stop,
        requestId: requestId,
        sessionId: sessionId,
      ),
    );
    _appendSystemMessage(navivoxGatewayTurnControlSubmittedMessage(stop: stop));
  }
}
