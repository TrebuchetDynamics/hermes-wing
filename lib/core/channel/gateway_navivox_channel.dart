import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../gateway/navivox_gateway_client.dart';
import '../gateway/navivox_gateway_protocol.dart';
import '../protocol/navivox_event.dart';
import '../protocol/navivox_memory.dart';
import '../protocol/navivox_voice_run.dart';
import '../session/session_persistence_service.dart';
import 'navivox_channel.dart';

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

    final contacts =
        _capabilityAllows(
          capabilities,
          'profile_contacts',
          'GET',
          '/v1/navivox/profile-contacts',
        )
        ? await _loadProfileContacts(client)
        : [_fallbackProfileContact()];
    final profileRouting =
        _capabilityAllows(
          capabilities,
          'profile_routing',
          'GET',
          '/v1/navivox/profile-routing',
        )
        ? await client.profileRouting()
        : const NavivoxProfileRoutingReport();
    final configAdminState = await _loadConfigAdminState(client, capabilities);
    _configAdminAvailable = configAdminState != null;
    final streamAvailable = _streamAvailable(capabilities);
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
    _state = _state.copyWith(
      servers: _serversFromProfileContacts(contacts, config),
      activeServerId: contacts.first.serverId,
      profileContacts: contacts,
      selectedProfileContactKey: contacts.first.key,
      profileRouting: profileRouting,
      runRecordInspectionAvailable: _runRecordsSupported(capabilities),
      configSchema: configAdminState?.schema ?? const {},
      configValues: configAdminState?.values ?? const {},
      configDiff: const {},
    );
    notifyListeners();
    // Persist connection parameters so the app can reconnect automatically.
    unawaited(
      _sessionService.saveConnection(
        baseUrl: baseUrl,
        token: token,
        webSocketUrl: webSocketUrl,
        gatewayId: status.capabilitiesUrl,
      ),
    );
    if (!streamAvailable) {
      _appendSystemMessage('Navivox stream is not advertised by this gateway.');
    }
  }

  @override
  Future<void> disconnect() async {
    await _closeConnection(clearSavedSession: true);
  }

  Future<void> _closeConnection({required bool clearSavedSession}) async {
    await _events?.cancel();
    _events = null;
    await _socket?.close();
    _socket = null;
    _client = null;
    _capabilities = null;
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
      return _capabilityDocumentValid(capabilities) ? capabilities : null;
    } catch (_) {
      return null;
    }
  }

  bool _capabilityDocumentValid(NavivoxCapabilityDocument capabilities) {
    return capabilities.object == 'gormes.navivox.capabilities' &&
        capabilities.protocolVersion == navivoxWebSocketProtocol &&
        capabilities.auth.mode.trim().isNotEmpty &&
        capabilities.advertisesEndpoint('GET', '/v1/navivox/capabilities') &&
        capabilities.streams.canonicalEndpoint.trim().isNotEmpty;
  }

  bool _capabilityAllows(
    NavivoxCapabilityDocument capabilities,
    String capability,
    String method,
    String path,
  ) {
    return capabilities.supports(capability) &&
        capabilities.advertisesEndpoint(method, path);
  }

  bool _streamAvailable(NavivoxCapabilityDocument capabilities) {
    return _capabilityAllows(
          capabilities,
          'stream_turns',
          'WS',
          '/v1/navivox/stream',
        ) &&
        capabilities.streams.canonicalEndpoint == '/v1/navivox/stream';
  }

  bool _runRecordsSupported(NavivoxCapabilityDocument capabilities) {
    return capabilities.voice.runRecordsEndpoint.trim().isNotEmpty;
  }

  bool _configAdminSupported(NavivoxCapabilityDocument capabilities) {
    return _capabilityAllows(
          capabilities,
          'config_admin',
          'GET',
          '/v1/navivox/config-admin/schema',
        ) &&
        capabilities.advertisesEndpoint('GET', '/v1/navivox/config-admin') &&
        capabilities.advertisesEndpoint(
          'POST',
          '/v1/navivox/config-admin/diff',
        ) &&
        capabilities.advertisesEndpoint(
          'POST',
          '/v1/navivox/config-admin/validate',
        ) &&
        capabilities.advertisesEndpoint(
          'POST',
          '/v1/navivox/config-admin/apply',
        );
  }

  Future<({Map<String, Object?> schema, Map<String, Object?> values})?>
  _loadConfigAdminState(
    NavivoxGatewayClient client,
    NavivoxCapabilityDocument capabilities,
  ) async {
    if (!_configAdminSupported(capabilities)) return null;
    try {
      final schema = await client.configAdminSchema();
      final values = await client.configAdminValues();
      return (schema: schema.toConfigSchema(), values: values.toConfigValues());
    } catch (_) {
      return null;
    }
  }

  Future<List<NavivoxProfileContact>> _loadProfileContacts(
    NavivoxGatewayClient client,
  ) async {
    final contactPayloads = await client.profileContacts();
    final profileContacts = contactPayloads
        .map(_profileContactFromJson)
        .toList(growable: false);
    return profileContacts.isEmpty
        ? [_fallbackProfileContact()]
        : profileContacts;
  }

  void _enterClosedCapabilityMode(
    NavivoxGatewayConfig config, {
    required String status,
  }) {
    final contact = _closedCapabilityProfileContact(status);
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
    final activeProfile = _state.activeProfileContact;
    _putMessage(
      NavivoxChatMessage(
        id: requestId,
        author: NavivoxMessageAuthor.user,
        kind: NavivoxMessageKind.text,
        createdAt: _clock(),
        text: trimmed,
      ),
    );
    socket.add(
      jsonEncode(
        NavivoxGatewayMessage.startTurn(
          requestId: requestId,
          sessionId: _activeSessionId,
          text: trimmed,
          metadata: _turnMetadata(activeProfile),
        ).body,
      ),
    );
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
    final activeProfile = _state.activeProfileContact;
    final id = 'voice-${_uuid.v4()}';
    final run = NavivoxVoiceRun.recording(
      id: id,
      serverId: activeProfile?.serverId ?? 'navivox-gateway',
      profileId: activeProfile?.profileId ?? 'default',
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
      run.copyWith(
        status: NavivoxVoiceRunStatus.pendingSend,
        transcriptSource: transcriptSource,
        transcript: transcript,
        duration: duration,
        confidence: confidence,
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
    final submitted = run.markSubmitted(
      requestId: requestId,
      sessionId: _activeSessionId,
    );
    _putVoiceRun(submitted, active: true);
    final activeProfile = _state.activeProfileContact;
    _putMessage(
      NavivoxChatMessage(
        id: requestId,
        author: NavivoxMessageAuthor.user,
        kind: NavivoxMessageKind.voice,
        createdAt: _clock(),
        text: trimmed,
        voice: NavivoxVoiceMessage(
          voiceRunId: voiceRunId,
          duration: submitted.duration ?? Duration.zero,
          transcript: trimmed,
          confidence: submitted.confidence ?? 1,
          status: submitted.status,
        ),
      ),
    );
    socket.add(
      jsonEncode(
        NavivoxGatewayMessage.startTurn(
          requestId: requestId,
          sessionId: _activeSessionId,
          text: trimmed,
          metadata: _turnMetadata(activeProfile),
        ).body,
      ),
    );
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
    final client = _client;
    if (client == null) {
      throw StateError('Connect to Gormes to create profiles from seed.');
    }
    final capabilities = _capabilities;
    if (capabilities == null ||
        !_capabilityAllows(
          capabilities,
          'profile_seed',
          'POST',
          '/v1/navivox/profile-seed',
        )) {
      throw StateError('Gormes profile seed is not advertised.');
    }
    final result = await client.profileSeed(
      seed: seed,
      apply: apply,
      workspaceRoots: workspaceRoots,
    );
    if (result.isApplied) {
      final contactPayload = result.contact;
      if (contactPayload.isNotEmpty) {
        final contact = _profileContactFromJson(contactPayload);
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
    final client = _client;
    if (client == null) {
      throw StateError('Connect to Gormes to load voice profiles.');
    }
    final capabilities = _capabilities;
    if (capabilities == null ||
        !_capabilityAllows(
          capabilities,
          'voice_profiles',
          'GET',
          '/v1/navivox/voice-profiles',
        )) {
      throw StateError('Gormes voice profiles are not advertised.');
    }
    return client.voiceProfiles();
  }

  @override
  Future<NavivoxVoiceProfileValidationResponse> validateVoiceProfile({
    required String profileId,
    required NavivoxProfileVoiceProfile voiceProfile,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Connect to Gormes to validate voice profiles.');
    }
    final capabilities = _capabilities;
    if (capabilities == null ||
        !_capabilityAllows(
          capabilities,
          'voice_profiles',
          'POST',
          '/v1/navivox/voice-profiles/validate',
        )) {
      throw StateError('Gormes voice profile validation is not advertised.');
    }
    return client.validateVoiceProfile(
      profileId: profileId,
      voiceProfile: voiceProfile,
    );
  }

  @override
  Future<NavivoxRunRecordSnapshot> runRecord(String runIdOrSessionId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Connect to Gormes to load run records.');
    }
    final capabilities = _capabilities;
    if (capabilities == null || !_runRecordsSupported(capabilities)) {
      throw StateError('Gormes run records are not advertised.');
    }
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
        !_capabilityAllows(
          capabilities,
          'profile_contacts',
          'GET',
          '/v1/navivox/profile-contacts',
        )) {
      _appendSystemMessage('Gormes profile contacts are not advertised.');
      return;
    }
    try {
      final contactPayloads = await client.profileContacts();
      final profileContacts = contactPayloads
          .map(_profileContactFromJson)
          .toList(growable: false);
      final contacts = profileContacts.isEmpty
          ? [_fallbackProfileContact()]
          : profileContacts;
      final selectedKey =
          contacts.any(
            (contact) => contact.key == _state.selectedProfileContactKey,
          )
          ? _state.selectedProfileContactKey
          : contacts.first.key;
      _state = _state.copyWith(
        servers: _serversFromProfileContacts(contacts, client.config),
        activeServerId: contacts.first.serverId,
        profileContacts: contacts,
        selectedProfileContactKey: selectedKey,
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
    final activeProfile = _state.activeProfileContact;
    final scopedServerId = serverId ?? activeProfile?.serverId;
    final scopedProfileId = profileId ?? activeProfile?.profileId ?? 'default';
    final client = _client;
    if (client == null) {
      return NavivoxMemoryOverview.degraded(
        profileId: scopedProfileId,
        reason: 'Connect to Gormes to load Goncho memory.',
      );
    }
    try {
      return await client.memoryOverview(
        serverId: scopedServerId,
        profileId: scopedProfileId,
      );
    } catch (_) {
      return NavivoxMemoryOverview.degraded(
        profileId: scopedProfileId,
        reason: 'Gormes memory API is unavailable.',
      );
    }
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
    final activeProfile = _state.activeProfileContact;
    final scopedServerId = serverId ?? activeProfile?.serverId;
    final scopedProfileId = profileId ?? activeProfile?.profileId ?? 'default';
    final client = _client;
    if (client == null) {
      return const NavivoxMemorySearchResult.degraded(
        reason: 'Connect to Gormes to search Goncho memory.',
      );
    }
    try {
      return await client.memorySearch(
        serverId: scopedServerId,
        profileId: scopedProfileId,
        query: query,
        type: type,
        limit: limit,
        pageToken: pageToken,
      );
    } catch (_) {
      return const NavivoxMemorySearchResult.degraded(
        reason: 'Gormes memory search API is unavailable.',
      );
    }
  }

  @override
  Future<NavivoxMemoryDetail> memoryDetail({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
  }) async {
    final activeProfile = _state.activeProfileContact;
    final scopedServerId = serverId ?? activeProfile?.serverId;
    final scopedProfileId = profileId ?? activeProfile?.profileId ?? 'default';
    final client = _client;
    if (client == null) {
      return NavivoxMemoryDetail.degraded(
        id: id,
        reason: 'Connect to Gormes to inspect Goncho memory.',
      );
    }
    try {
      return await client.memoryDetail(
        serverId: scopedServerId,
        profileId: scopedProfileId,
        id: id,
        type: type,
      );
    } catch (_) {
      return NavivoxMemoryDetail.degraded(
        id: id,
        reason: 'Gormes memory detail API is unavailable.',
      );
    }
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
    final activeProfile = _state.activeProfileContact;
    final scopedServerId = serverId ?? activeProfile?.serverId;
    final scopedProfileId = profileId ?? activeProfile?.profileId ?? 'default';
    final client = _client;
    if (client == null) {
      return NavivoxMemoryActionResult.degraded(
        action: action,
        reason: 'Connect to Gormes to manage Goncho memory.',
      );
    }
    try {
      return await client.memoryAction(
        serverId: scopedServerId,
        profileId: scopedProfileId,
        id: id,
        type: type,
        action: action,
        correction: correction,
      );
    } catch (_) {
      return NavivoxMemoryActionResult.degraded(
        action: action,
        reason: 'Gormes memory management API is unavailable.',
      );
    }
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
    final key = '$serverId::$profileId';
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
    final schema = await client.configAdminSchema();
    final values = await client.configAdminValues();
    _state = _state.copyWith(
      configSchema: schema.toConfigSchema(),
      configValues: values.toConfigValues(),
    );
    notifyListeners();
  }

  @override
  Future<NavivoxConfigAdminResponse> validateConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    final client = _requireConfigAdminClient('validate config');
    final response = await client.validateConfigAdmin(changes);
    _state = _state.copyWith(configDiff: response.snapshot);
    notifyListeners();
    return response;
  }

  @override
  Future<NavivoxConfigAdminResponse> diffConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    final client = _requireConfigAdminClient('diff config');
    final response = await client.diffConfigAdmin(changes);
    _state = _state.copyWith(configDiff: response.snapshot);
    notifyListeners();
    return response;
  }

  @override
  Future<NavivoxConfigAdminResponse> applyConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    final client = _requireConfigAdminClient('apply config');
    final response = await client.applyConfigAdmin(changes);
    Map<String, Object?>? nextValues;
    if (response.applied) {
      try {
        nextValues = (await client.configAdminValues()).toConfigValues();
      } catch (_) {
        nextValues = null;
      }
    }
    _state = _state.copyWith(
      configValues: nextValues,
      configDiff: response.snapshot,
    );
    notifyListeners();
    return response;
  }

  NavivoxGatewayClient _requireConfigAdminClient(String action) {
    final client = _client;
    if (client == null || !_configAdminAvailable) {
      throw StateError('Connect to Gormes to $action.');
    }
    return client;
  }

  @override
  void sendConfigSet({required String field, required Object? value}) {
    if (!_configAdminAvailable) {
      _appendSystemMessage(
        'Config editing is not available on this channel yet.',
      );
      return;
    }
    unawaited(_applyConfigSetInBackground(field: field, value: value));
  }

  @override
  void sendConfigSecretSet({required String name, required String secret}) {
    if (!_configAdminAvailable) {
      _appendSystemMessage(
        'Secret editing is not available on this channel yet.',
      );
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
    if (session == null) return false;
    try {
      await connect(
        baseUrl: session.baseUrl,
        token: session.token,
        webSocketUrl: session.webSocketUrl,
      );
      return true;
    } catch (_) {
      // Saved session expired or invalid — clear it so the user sees setup.
      await _sessionService.clearSession();
      _state = _state.copyWith(servers: [], activeServerId: null);
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
          _upsertProfileContact(_profileContactFromJson(contact));
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
    final requestId = event.requestId ?? _uuid.v4();
    final messageId = 'assistant-$requestId';
    final existing = _state.messages[messageId];
    if (existing == null) {
      _putMessage(
        NavivoxChatMessage(
          id: messageId,
          author: NavivoxMessageAuthor.assistant,
          kind: NavivoxMessageKind.text,
          createdAt: _clock(),
          text: event.text ?? '',
          runRecordReference: event.runRecordReference,
        ),
      );
      return;
    }
    _putMessage(
      NavivoxChatMessage(
        id: existing.id,
        author: existing.author,
        kind: existing.kind,
        createdAt: existing.createdAt,
        text: '${existing.text ?? ''}${event.text ?? ''}',
        runRecordReference:
            event.runRecordReference ?? existing.runRecordReference,
      ),
    );
  }

  void _upsertAssistantMessage(NavivoxGatewayEvent event) {
    final requestId = event.requestId ?? _uuid.v4();
    final messageId = 'assistant-$requestId';
    final existing = _state.messages[messageId];
    final message = NavivoxChatMessage(
      id: messageId,
      author: NavivoxMessageAuthor.assistant,
      kind: NavivoxMessageKind.text,
      createdAt: existing?.createdAt ?? _clock(),
      text: event.text ?? '',
      runRecordReference:
          event.runRecordReference ?? existing?.runRecordReference,
    );
    _putMessage(message);
  }

  void _upsertToolCall(NavivoxGatewayEvent event, String status) {
    final toolCallId = event.toolCallId ?? 'tool-${_uuid.v4()}';
    final priorMessage = _state.messages[toolCallId];
    final prior = priorMessage?.toolCall;
    final summary = _boundedToolText(
      event.message ?? event.text ?? prior?.summary ?? '',
    );
    _putMessage(
      NavivoxChatMessage(
        id: toolCallId,
        author: NavivoxMessageAuthor.assistant,
        kind: NavivoxMessageKind.toolCall,
        createdAt: _state.messages[toolCallId]?.createdAt ?? _clock(),
        toolCall: NavivoxToolCall(
          name: event.toolName ?? prior?.name ?? 'tool',
          status: status,
          summary: summary,
          approval: prior?.approval,
          artifacts: _toolArtifactsFromEvent(
            event,
            toolCallId: toolCallId,
            prior: prior?.artifacts ?? const [],
          ),
        ),
        runRecordReference:
            event.runRecordReference ?? priorMessage?.runRecordReference,
      ),
    );
  }

  List<NavivoxToolArtifact> _toolArtifactsFromEvent(
    NavivoxGatewayEvent event, {
    required String toolCallId,
    required List<NavivoxToolArtifact> prior,
  }) {
    final parsed = _structuredToolArtifacts(event.metadata, toolCallId);
    if (parsed.isEmpty) return prior;
    final byId = {for (final artifact in prior) artifact.id: artifact};
    for (final artifact in parsed) {
      byId[artifact.id] = artifact;
    }
    return byId.values.toList(growable: false);
  }

  List<NavivoxToolArtifact> _structuredToolArtifacts(
    Map<String, Object?> metadata,
    String toolCallId,
  ) {
    if (metadata.isEmpty) return const [];
    final artifacts = <NavivoxToolArtifact>[];
    final artifactList = metadata['artifacts'];
    if (artifactList is List) {
      for (final artifact in artifactList.whereType<Map>()) {
        final parsed = _toolArtifactFromMap(
          Map<String, Object?>.from(artifact),
        );
        if (parsed != null) artifacts.add(parsed);
      }
    }
    final single = _toolArtifactFromFlatMetadata(metadata);
    if (single != null) artifacts.add(single);
    if (artifacts.isNotEmpty) return artifacts;
    return [
      NavivoxToolArtifact(
        id: 'metadata-$toolCallId',
        kind: 'metadata',
        title: 'Tool metadata',
        summary: _boundedToolText(_safeMetadataSummary(metadata)),
      ),
    ];
  }

  NavivoxToolArtifact? _toolArtifactFromMap(Map<String, Object?> json) {
    final id = _trimmedString(json['id']);
    final kind = _trimmedString(json['kind']);
    final title = _trimmedString(json['title']);
    if (id == null || kind == null || title == null) return null;
    return NavivoxToolArtifact(
      id: id,
      kind: kind,
      title: title,
      summary: _trimmedString(json['summary']),
      ref: _trimmedString(json['ref']),
    );
  }

  NavivoxToolArtifact? _toolArtifactFromFlatMetadata(
    Map<String, Object?> metadata,
  ) {
    final id = _trimmedString(metadata['artifact_id']);
    final kind = _trimmedString(metadata['artifact_kind']);
    final title = _trimmedString(metadata['artifact_title']);
    if (id == null || kind == null || title == null) return null;
    return NavivoxToolArtifact(
      id: id,
      kind: kind,
      title: title,
      summary: _trimmedString(metadata['artifact_summary']),
      ref: _trimmedString(metadata['artifact_ref']),
    );
  }

  String? _trimmedString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String _safeMetadataSummary(Map<String, Object?> metadata) {
    final parts = <String>[];
    for (final entry in metadata.entries) {
      if (_isSensitiveMetadataKey(entry.key)) continue;
      parts.add('${entry.key}: ${_safeMetadataValue(entry.value)}');
    }
    return parts.isEmpty ? 'Metadata unavailable' : parts.join('; ');
  }

  String _safeMetadataValue(Object? value) {
    if (value is Map) return '[object]';
    if (value is List) return '[list]';
    return value?.toString() ?? '';
  }

  bool _isSensitiveMetadataKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('token') ||
        lower.contains('secret') ||
        lower.contains('password') ||
        lower.contains('api_key') ||
        lower.contains('apikey');
  }

  String _boundedToolText(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 240) return trimmed;
    return '${trimmed.substring(0, 237)}...';
  }

  void _putSafetyWarning(NavivoxGatewayEvent event) {
    final id = event.safetyId ?? 'safety-${_uuid.v4()}';
    _putMessage(
      NavivoxChatMessage(
        id: id,
        author: NavivoxMessageAuthor.system,
        kind: NavivoxMessageKind.safetyWarning,
        createdAt: _clock(),
        safetyNotice: NavivoxSafetyNotice(
          id: id,
          severity: event.severity ?? 'warning',
          message: event.message ?? 'Safety warning',
          risk: event.risk,
        ),
        runRecordReference: event.runRecordReference,
      ),
    );
  }

  void _putApprovalRequest(NavivoxGatewayEvent event) {
    final id = event.approvalId ?? 'approval-${_uuid.v4()}';
    final toolCallId = event.toolCallId ?? '';
    final prompt = event.message ?? 'Approval required';
    final risk = event.risk;
    final priorTool = _state.messages[toolCallId]?.toolCall;
    if (priorTool != null) {
      _putMessage(
        NavivoxChatMessage(
          id: toolCallId,
          author: NavivoxMessageAuthor.assistant,
          kind: NavivoxMessageKind.toolCall,
          createdAt: _state.messages[toolCallId]?.createdAt ?? _clock(),
          toolCall: priorTool.copyWith(
            approval: NavivoxToolApproval(
              id: id,
              status: 'approval_required',
              prompt: prompt,
              risk: risk,
            ),
          ),
          runRecordReference:
              event.runRecordReference ??
              _state.messages[toolCallId]?.runRecordReference,
        ),
      );
    }
    _putMessage(
      NavivoxChatMessage(
        id: id,
        author: NavivoxMessageAuthor.system,
        kind: NavivoxMessageKind.approvalRequest,
        createdAt: _clock(),
        safetyNotice: NavivoxSafetyNotice(
          id: id,
          approvalId: id,
          toolCallId: toolCallId,
          message: prompt,
          risk: risk,
        ),
        runRecordReference: event.runRecordReference,
      ),
    );
    _approvals.add(
      NavivoxApprovalRequest(
        id: id,
        toolCallId: toolCallId,
        prompt: prompt,
        risk: risk,
      ),
    );
  }

  void _appendSystemMessage(String text) {
    final messages = _state.messagesList;
    final lastMessage = messages.isEmpty ? null : messages.last;
    if (lastMessage?.author == NavivoxMessageAuthor.system &&
        lastMessage?.kind == NavivoxMessageKind.text &&
        lastMessage?.text == text) {
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
    final server = _state.servers.first;
    _state = _state.copyWith(
      servers: [
        NavivoxServer(id: server.id, name: server.name, status: status),
      ],
    );
    notifyListeners();
  }

  void _upsertProfileContact(NavivoxProfileContact contact) {
    final contacts = [..._state.profileContacts];
    final index = contacts.indexWhere(
      (existing) => existing.key == contact.key,
    );
    if (index >= 0) {
      contacts[index] = contact;
    } else {
      contacts.add(contact);
    }
    final servers = _upsertServer(_state.servers, contact);
    _state = _state.copyWith(
      servers: servers,
      activeServerId: _state.activeServerId ?? contact.serverId,
      profileContacts: contacts,
      selectedProfileContactKey:
          _state.selectedProfileContactKey ?? contact.key,
    );
    notifyListeners();
  }

  void _putMessage(NavivoxChatMessage message) {
    final messages = Map<String, NavivoxChatMessage>.from(_state.messages);
    messages[message.id] = message;
    _state = _state.copyWith(messages: messages);
    notifyListeners();
  }

  void _putVoiceRun(NavivoxVoiceRun run, {required bool active}) {
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[run.id] = run;
    _state = _state.copyWith(
      voiceRuns: runs,
      activeVoiceRunId: active ? run.id : _state.activeVoiceRunId,
    );
    notifyListeners();
  }

  void _sendTurnControl({required bool stop}) {
    final socket = _socket;
    final sessionId = _activeSessionId;
    if (socket == null || sessionId == null || sessionId.trim().isEmpty) {
      _appendSystemMessage(
        stop ? 'No active turn to stop.' : 'No active turn to cancel.',
      );
      return;
    }
    final requestId = _uuid.v4();
    final message = stop
        ? NavivoxGatewayMessage.stopTurn(
            requestId: requestId,
            sessionId: sessionId,
          )
        : NavivoxGatewayMessage.cancelTurn(
            requestId: requestId,
            sessionId: sessionId,
          );
    socket.add(jsonEncode(message.body));
    _appendSystemMessage(
      stop
          ? 'Stop requested. Started side effects may still exist.'
          : 'Cancel requested. Started side effects may still exist.',
    );
  }

  Map<String, Object?> _turnMetadata(NavivoxProfileContact? profile) {
    final routing = _state.activeProfileRoutingSelection;
    return {
      'client': 'navivox',
      'platform': 'flutter',
      if (profile != null) ...{
        'server_id': profile.serverId,
        'profile_id': profile.profileId,
      },
      if (routing?.workspace != null) 'workspace': routing!.workspace,
      if (routing?.provider != null) 'provider_id': routing!.provider,
      if (routing?.channel != null) 'channel_id': routing!.channel,
    };
  }

  NavivoxProfileContact _closedCapabilityProfileContact(String status) {
    return NavivoxProfileContact(
      serverId: 'navivox-gateway',
      profileId: 'default',
      displayName: 'Default profile',
      serverLabel: 'Gormes Gateway',
      health: NavivoxProfileHealth.warning,
      latestPreview: status,
      latestPreviewKind: 'status',
      workspaceRootCount: 0,
      workspaceRootsOk: false,
      micAvailable: false,
      voiceCapability: const NavivoxVoiceCapability(
        disabledReason: 'Navivox capabilities unavailable',
        isReported: true,
      ),
    );
  }

  NavivoxProfileContact _fallbackProfileContact() {
    return NavivoxProfileContact(
      serverId: 'navivox-gateway',
      profileId: 'default',
      displayName: 'Default profile',
      serverLabel: 'Gormes Gateway',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Gateway online',
      latestPreviewKind: 'status',
      workspaceRootCount: 1,
      workspaceRootsOk: true,
      micAvailable: true,
    );
  }

  List<NavivoxServer> _serversFromProfileContacts(
    List<NavivoxProfileContact> contacts,
    NavivoxGatewayConfig config,
  ) {
    final servers = <String, NavivoxServer>{};
    for (final contact in contacts) {
      servers.putIfAbsent(
        contact.serverId,
        () => NavivoxServer(
          id: contact.serverId,
          name: contact.serverLabel,
          status: _serverStatus(contact, config),
        ),
      );
    }
    return servers.values.toList(growable: false);
  }

  List<NavivoxServer> _upsertServer(
    List<NavivoxServer> servers,
    NavivoxProfileContact contact,
  ) {
    final index = servers.indexWhere((server) => server.id == contact.serverId);
    if (index >= 0) return servers;
    return [
      ...servers,
      NavivoxServer(
        id: contact.serverId,
        name: contact.serverLabel,
        status: _profileHealthStatus(contact),
      ),
    ];
  }

  String _serverStatus(
    NavivoxProfileContact contact,
    NavivoxGatewayConfig config,
  ) {
    if (contact.serverId == 'navivox-gateway') {
      return 'Gateway online - ${config.baseUri.host}:${config.baseUri.port}';
    }
    return _profileHealthStatus(contact);
  }

  String _profileHealthStatus(NavivoxProfileContact contact) {
    return switch (contact.health) {
      NavivoxProfileHealth.online => 'Gateway online',
      NavivoxProfileHealth.offline => 'Gateway offline',
      NavivoxProfileHealth.needsAuth => 'Provider auth required',
      NavivoxProfileHealth.warning => 'Profile warning',
    };
  }

  NavivoxProfileContact _profileContactFromJson(Map<String, Object?> json) {
    final serverId = _stringFromJson(
      json['server_id'],
      fallback: 'navivox-gateway',
    );
    final profileId = _stringFromJson(json['profile_id'], fallback: 'default');
    final serverLabel = _stringFromJson(
      json['server_label'],
      fallback: 'Gormes Gateway',
    );
    final micAvailable = _boolFromJson(json['mic_available']);
    return NavivoxProfileContact(
      serverId: serverId,
      profileId: profileId,
      displayName: _stringFromJson(
        json['display_name'],
        fallback: profileId == 'default' ? 'Default profile' : profileId,
      ),
      serverLabel: serverLabel,
      health: _profileHealthFromJson(json['health']),
      latestPreview: _stringFromJson(
        json['latest_preview'],
        fallback: 'Profile ready',
      ),
      latestPreviewKind: _stringFromJson(
        json['latest_preview_kind'],
        fallback: 'status',
      ),
      latestAt: _dateFromJson(json['latest_preview_at']),
      workspaceRootCount: _intFromJson(json['workspace_root_count']),
      workspaceRootsOk: _boolFromJson(
        json['workspace_roots_ok'],
        fallback: true,
      ),
      workspaceRootsWarning: _intFromJson(json['workspace_roots_warning']),
      workspaceRootsError: _intFromJson(json['workspace_roots_error']),
      attentionBadges: _stringListFromJson(json['attention_badges']),
      micAvailable: micAvailable,
      voiceCapability: _voiceCapabilityFromJson(
        json['voice_capability'],
        micAvailable: micAvailable,
      ),
      activeTurnState: _stringFromJson(
        json['active_turn_state'],
        fallback: 'idle',
      ),
      avatarSeed: _stringFromJson(
        json['avatar_seed'],
        fallback: '$serverId:$profileId',
      ),
    );
  }

  NavivoxVoiceCapability _voiceCapabilityFromJson(
    Object? value, {
    required bool micAvailable,
  }) {
    if (value is Map) {
      return NavivoxVoiceCapability(
        deviceStt: _stringFromJson(
          value['device_stt'],
          fallback: micAvailable ? 'available' : 'unavailable',
        ),
        serverStt: _stringFromJson(
          value['server_stt'],
          fallback: 'unavailable',
        ),
        serverTts: _stringFromJson(
          value['server_tts'],
          fallback: 'unavailable',
        ),
        disabledReason: _stringFromJson(
          value['disabled_reason'],
          fallback: micAvailable ? '' : 'mic unavailable',
        ),
        recoveryAction: _stringFromJson(value['recovery_action'], fallback: ''),
        isReported: true,
      );
    }
    return NavivoxVoiceCapability(
      deviceStt: micAvailable ? 'available' : 'unavailable',
      disabledReason: micAvailable ? '' : 'mic unavailable',
    );
  }

  NavivoxProfileHealth _profileHealthFromJson(Object? value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'offline' => NavivoxProfileHealth.offline,
      'needs_auth' ||
      'needsauth' ||
      'needs-auth' => NavivoxProfileHealth.needsAuth,
      'warning' => NavivoxProfileHealth.warning,
      _ => NavivoxProfileHealth.online,
    };
  }

  DateTime? _dateFromJson(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String _stringFromJson(Object? value, {required String fallback}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }

  int _intFromJson(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _boolFromJson(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return fallback;
  }

  List<String> _stringListFromJson(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
