import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../gateway/navivox_gateway_protocol.dart';
import '../../../protocol/navivox_event.dart';
import '../../../protocol/navivox_memory.dart';
import '../../../protocol/navivox_profile_contact_key.dart';
import '../../../protocol/navivox_voice_run.dart';
import '../../../session/session_persistence_service.dart';
import '../../contracts/navivox_channel.dart';
import '../../contracts/navivox_message_scope.dart';
import '../../contracts/navivox_profile_contact_codec.dart';
import '../approvals/gateway_approval_notice.dart';
import '../client/gateway_capability_policy.dart';
import '../client/gateway_config_admin_policy.dart';
import '../memory/gateway_memory_request_policy.dart';
import '../profiles/gateway_profile_contact_policy.dart';
import '../profiles/gateway_voice_run_policy.dart';
import '../state/gateway_channel_state_policy.dart';
import '../messages/gateway_assistant_message_policy.dart';
import '../messages/gateway_message_scope_policy.dart';
import '../messages/gateway_safety_notice_policy.dart';
import '../messages/gateway_tool_call_policy.dart';
import '../messages/gateway_user_turn_policy.dart';
import '../turns/gateway_turn_control_policy.dart';

class GatewayNavivoxChannel extends ChangeNotifier implements NavivoxChannel {
  GatewayNavivoxChannel({Uuid? uuid, DateTime Function()? clock})
    : _uuid = uuid ?? const Uuid(),
      _clock = clock ?? DateTime.now;

  final Uuid _uuid;
  final DateTime Function() _clock;
  final StreamController<NavivoxApprovalRequest> _approvals =
      StreamController<NavivoxApprovalRequest>.broadcast();

  final SessionPersistenceService _sessionService = SessionPersistenceService();
  NavivoxGatewayClient? _client;
  NavivoxCapabilityDocument? _capabilities;
  NavivoxGatewaySocket? _socket;
  StreamSubscription<NavivoxGatewayEvent>? _events;
  NavivoxChannelState _state = const NavivoxChannelState();
  bool _configAdminAvailable = false;
  String? _activeSessionId;

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
        _enterClosedCapabilityMode(config, status: 'Gateway disabled');
        return;
      }
      final capabilities = await _loadCapabilities(client);
      _capabilities = capabilities;
      if (capabilities == null) {
        _enterClosedCapabilityMode(config, status: 'Capabilities unavailable');
        return;
      }

      final contacts = navivoxProfileContactsAvailable(capabilities)
          ? await _loadProfileContacts(client)
          : [navivoxFallbackProfileContact()];
      final profileRouting = navivoxProfileRoutingAvailable(capabilities)
          ? await client.profileRouting()
          : const NavivoxProfileRoutingReport();
      final configAdminState = await navivoxLoadGatewayConfigAdminState(
        client: client,
        capabilities: capabilities,
      );
      _configAdminAvailable = configAdminState != null;
      final streamAvailable = navivoxStreamAvailable(capabilities);
      if (streamAvailable) {
        final socket = await client.connectStream();
        _socket = socket;
        _events = client
            .decodeEvents(socket.events)
            .listen(
              _onEvent,
              onError: (Object error) =>
                  _appendSystemMessage('Gateway stream error'),
              onDone: () => _setServerStatus('Gateway disconnected'),
            );
      }
      _state =
          navivoxStateWithProfileContacts(
            state: _state,
            contacts: contacts,
            config: config,
          ).copyWith(
            profileRouting: profileRouting,
            runRecordInspectionAvailable: navivoxRunRecordsSupported(
              capabilities,
            ),
            configSchema: configAdminState?.schema ?? const {},
            configValues: configAdminState?.values ?? const {},
            configDiff: const {},
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
    } catch (_) {
      await _closeConnection(clearSavedSession: false);
      _activeSessionId = null;
      _state = const NavivoxChannelState();
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _closeConnection(clearSavedSession: true);
    _activeSessionId = null;
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
    _activeSessionId = null;
    _configAdminAvailable = false;
    if (clearSavedSession) {
      unawaited(_sessionService.clearSession());
    }
  }

  Uri? _optionalUri(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return Uri.parse(trimmed);
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
  }) {
    final contact = navivoxClosedCapabilityProfileContact(status);
    _state = _state.copyWith(
      servers: [
        NavivoxServer(
          id: contact.serverId,
          name: contact.serverLabel,
          status: '$status - ${config.baseUri.host}:${config.baseUri.port}',
        ),
      ],
      activeServerId: contact.serverId,
      profileContacts: [contact],
      selectedProfileContactKey: contact.key,
      profileRouting: const NavivoxProfileRoutingReport(),
      profileRoutingSelections: const {},
      runRecordInspectionAvailable: false,
      configSchema: const {},
      configValues: const {},
      configDiff: const {},
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
      sessionId: _activeSessionId,
      text: trimmed,
      createdAt: _clock(),
      profile: _state.activeProfileContact,
      routing: _state.activeProfileRoutingSelection,
    );
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

    final requestId = _uuid.v4();
    final submitted = navivoxGatewaySubmittedVoiceRun(
      run: run,
      requestId: requestId,
      sessionId: _activeSessionId,
    );
    _putVoiceRun(submitted, active: true);
    final submission = navivoxGatewayUserTurnSubmission(
      requestId: requestId,
      sessionId: _activeSessionId,
      text: trimmed,
      createdAt: _clock(),
      profile: _state.activeProfileContact,
      routing: _state.activeProfileRoutingSelection,
      voice: navivoxGatewaySubmittedVoiceMessage(
        run: submitted,
        voiceRunId: voiceRunId,
        transcript: trimmed,
      ),
    );
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
  Future<void> refreshConfigAdmin() async {
    final client = _requireConfigAdminClient('refresh config admin');
    final configAdminState = await navivoxRefreshGatewayConfigAdminState(
      client: client,
    );
    _state = _state.copyWith(
      configSchema: configAdminState.schema,
      configValues: configAdminState.values,
    );
    notifyListeners();
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

  /// Attempt to reconnect using a previously saved session.
  /// Returns true if a session was found and connection succeeded.
  Future<bool> tryReconnect() async {
    final session = await _sessionService.loadSession();
    if (session == null || !session.canAttemptReconnect) return false;
    try {
      await connect(
        baseUrl: session.baseUrl,
        webSocketUrl: session.webSocketUrl,
      );
      return true;
    } catch (_) {
      // Saved session expired or invalid — clear it so the user sees setup.
      await _sessionService.clearSession();
      _state = _state.copyWith(servers: [], clearActiveServerId: true);
      notifyListeners();
      _appendSystemMessage(
        'Saved session expired. Please re-pair with your gateway.',
      );
      return false;
    }
  }

  @override
  void dispose() {
    unawaited(_closeConnection(clearSavedSession: false));
    unawaited(_approvals.close());
    super.dispose();
  }

  void _onEvent(NavivoxGatewayEvent event) {
    switch (event.type) {
      case 'pong':
        return;
      case 'session_started':
        _activeSessionId = event.sessionId ?? _activeSessionId;
      case 'gateway_identity':
        // Gormes gateway identity updates are ignored by the client;
        // persistent session identity is in saved session metadata.
        return;
      case 'assistant_delta':
        _appendAssistantDelta(event);
      case 'assistant_message':
        _upsertAssistantMessage(event);
      case 'tool_call_started':
        _upsertToolCall(event, 'started');
      case 'tool_call_updated':
        _upsertToolCall(event, event.status ?? 'updated');
      case 'tool_call_finished':
        _upsertToolCall(event, event.status ?? 'finished');
      case 'safety_warning':
        _putSafetyWarning(event);
      case 'approval_required':
        _putApprovalRequest(event);
      case 'profile_contact_update':
        final contact = event.contact;
        if (contact != null) {
          _upsertProfileContact(navivoxProfileContactFromJson(contact));
        }
      case 'error':
        _appendSystemMessage(event.message ?? 'Gateway error');
      case 'done':
        return;
      default:
        return;
    }
  }

  void _appendAssistantDelta(NavivoxGatewayEvent event) {
    final messageId = navivoxGatewayAssistantMessageId(
      event: event,
      fallbackRequestId: _uuid.v4,
    );
    _putMessage(
      navivoxGatewayAssistantTextMessage(
        id: messageId,
        event: event,
        existing: _state.messages[messageId],
        createdAt: _clock(),
        scope: _messageScopeFromEvent(event),
        appendText: true,
      ),
    );
  }

  void _upsertAssistantMessage(NavivoxGatewayEvent event) {
    final messageId = navivoxGatewayAssistantMessageId(
      event: event,
      fallbackRequestId: _uuid.v4,
    );
    _putMessage(
      navivoxGatewayAssistantTextMessage(
        id: messageId,
        event: event,
        existing: _state.messages[messageId],
        createdAt: _clock(),
        scope: _messageScopeFromEvent(event),
        appendText: false,
      ),
    );
  }

  void _upsertToolCall(NavivoxGatewayEvent event, String status) {
    final toolCallId = event.toolCallId ?? 'tool-${_uuid.v4()}';
    _putMessage(
      navivoxGatewayToolCallMessage(
        id: toolCallId,
        event: event,
        status: status,
        priorMessage: _state.messages[toolCallId],
        createdAt: _clock(),
        scope: _messageScopeFromEvent(event),
      ),
    );
  }

  NavivoxMessageScope _messageScopeFromEvent(NavivoxGatewayEvent event) {
    return navivoxGatewayMessageScopeFromEvent(
      event: event,
      messages: _state.messages,
    );
  }

  void _putSafetyWarning(NavivoxGatewayEvent event) {
    final id = event.safetyId ?? 'safety-${_uuid.v4()}';
    _putMessage(
      navivoxGatewaySafetyWarningMessage(
        event: event,
        id: id,
        createdAt: _clock(),
        scope: _messageScopeFromEvent(event),
      ),
    );
  }

  void _putApprovalRequest(NavivoxGatewayEvent event) {
    final notice = navivoxGatewayApprovalNotice(
      event: event,
      fallbackApprovalId: () => 'approval-${_uuid.v4()}',
    );
    final scope = _messageScopeFromEvent(event);
    final priorMessage = _state.messages[notice.toolCallId];
    final toolApprovalMessage = navivoxGatewayToolApprovalMessage(
      id: notice.toolCallId,
      event: event,
      priorMessage: priorMessage,
      notice: notice,
      createdAt: _clock(),
      scope: scope,
    );
    if (toolApprovalMessage != null) _putMessage(toolApprovalMessage);
    _putMessage(
      navivoxGatewayApprovalRequestMessage(
        event: event,
        notice: notice,
        createdAt: _clock(),
        scope: scope,
      ),
    );
    _approvals.add(notice.toChannelRequest());
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
    final sessionId = _activeSessionId;
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
