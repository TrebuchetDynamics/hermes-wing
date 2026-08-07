import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../protocol/wing_json.dart';
import '../../protocol/voice/models/wing_voice_run.dart';
import '../client/hermes_api_client.dart';
import '../client/hermes_api_config.dart';
import '../models/hermes_capabilities.dart';
import '../models/hermes_chat_turn.dart';
import '../models/hermes_health.dart';
import '../models/hermes_job.dart';
import '../models/hermes_run.dart';
import '../models/hermes_runtime_model.dart';
import '../models/hermes_skill.dart';
import '../models/hermes_toolset.dart';
import '../policy/hermes_transport_policy.dart';
import '../../../shared/async/fire_and_forget.dart';
import '../../../shared/security/wing_redaction.dart';
import '../setup/hermes_endpoint_store.dart';
import '../sse/hermes_sse_event_decoder.dart';
import 'hermes_channel.dart';
import 'hermes_detached_run_store.dart';

part 'api_channel/hermes_api_channel_connection.dart';
part 'api_channel/hermes_api_channel_sessions.dart';
part 'api_channel/hermes_api_channel_profiles.dart';
part 'api_channel/hermes_api_channel_providers.dart';
part 'api_channel/hermes_api_channel_messaging.dart';
part 'api_channel/hermes_api_channel_approvals.dart';
part 'api_channel/hermes_api_channel_voice.dart';
part 'api_channel/hermes_api_channel_errors.dart';

/// [HermesChannel] backed by [HermesApiClient] against a live Hermes Agent
/// API server. See docs/adr/0007-native-hermes-channel-not-wing-channel-adapter.md.
class HermesApiChannel extends ChangeNotifier implements HermesChannel {
  HermesApiChannel({
    HermesApiClient Function(HermesApiConfig config)? clientBuilder,
    String Function()? sessionIdFactory,
    Uuid? uuid,
    HermesDetachedRunStore? detachedRunStore,
    this.streamIdleTimeout = const Duration(minutes: 5),
  }) : _clientBuilder =
           clientBuilder ?? ((config) => HermesApiClient(config: config)),
       _uuid = uuid ?? const Uuid(),
       // Named public injection cannot use a private initializing formal.
       // ignore: prefer_initializing_formals
       _detachedRunStore = detachedRunStore,
       _sessionIdFactory =
           sessionIdFactory ??
           (() =>
               'navi-${DateTime.now().microsecondsSinceEpoch}-${(uuid ?? const Uuid()).v4()}');

  final HermesApiClient Function(HermesApiConfig) _clientBuilder;
  final String Function() _sessionIdFactory;
  final Uuid _uuid;
  final HermesDetachedRunStore? _detachedRunStore;
  final Duration streamIdleTimeout;

  HermesApiClient? _client;
  HermesChannelState _state = const HermesChannelState();
  final _activeStreams = <String, StreamSubscription<HermesStreamEvent>>{};
  final _activeStreamCompleters = <String, Completer<void>>{};
  final _activeRunIds = <String, String>{};
  final _approvalRunIds = <String, String>{};
  final _sessionStreamGenerations = <String, int>{};
  final _detachedRuns = <String, HermesDetachedRunLease>{};
  final _recentTurns = <String, List<HermesChatTurn>>{};
  bool _detachedRunsLoaded = false;
  int _nextStreamGeneration = 0;
  int _connectionGeneration = 0;
  final _approvalController =
      StreamController<HermesApprovalRequest>.broadcast();
  final _deletingSessionOperations = <String, Object>{};
  final _forkingSessionOperations = <String, Object>{};

  @override
  HermesChannelState get state => _state;

  @override
  Stream<HermesApprovalRequest> get approvalRequests =>
      _approvalController.stream;

  @override
  void dispose() {
    _client = null;
    _connectionGeneration += 1;
    _deletingSessionOperations.clear();
    _forkingSessionOperations.clear();
    _clearActiveRunTracking();
    _detachedRuns.clear();
    _approvalController.close();
    super.dispose();
  }

  String _recentTurnKey(
    HermesApiClient client,
    String sessionId, {
    String? profileId,
  }) {
    final credential = sha256.convert(utf8.encode(client.config.apiKey ?? ''));
    final profile = profileId ?? _state.selectedProfileId ?? 'default';
    return '${client.config.baseUri}|$credential|$profile|$sessionId';
  }

  void _setState(HermesChannelState next) {
    _state = next;
    notifyListeners();
  }

  void _clearActiveRunTracking() {
    for (final stream in _activeStreams.values) {
      unawaited(stream.cancel());
    }
    for (final completer in _activeStreamCompleters.values) {
      if (!completer.isCompleted) completer.complete();
    }
    _activeStreams.clear();
    _activeStreamCompleters.clear();
    _activeRunIds.clear();
    _approvalRunIds.clear();
    _sessionStreamGenerations.clear();
  }

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) =>
      _connect(baseUrl: baseUrl, apiKey: apiKey);

  @override
  Future<void> disconnect() => _disconnect();

  @override
  Future<void> selectSession(String sessionId) => _selectSession(sessionId);

  @override
  Future<void> createSession({String? title}) => _createSession(title: title);

  @override
  Future<void> renameSession({
    required String sessionId,
    required String title,
  }) => _renameSession(sessionId: sessionId, title: title);

  @override
  Future<void> deleteSession(String sessionId) => _deleteSession(sessionId);

  @override
  Future<void> forkSession(String sessionId, {String? title}) =>
      _forkSession(sessionId, title: title);

  @override
  Future<void> selectProfile(
    String profileId, {
    bool allowDiscovered = false,
  }) => _selectProfile(profileId, allowDiscovered: allowDiscovered);

  @override
  Future<void> createProfile({required String name, String? cloneFrom}) =>
      _createProfile(name: name, cloneFrom: cloneFrom);

  @override
  Future<void> renameProfile({
    required String profileId,
    required String name,
    required String revision,
  }) => _renameProfile(profileId: profileId, name: name, revision: revision);

  @override
  Future<void> deleteProfile({
    required String profileId,
    required String revision,
  }) => _deleteProfile(profileId: profileId, revision: revision);

  @override
  Future<HermesProfileSoul> readProfileSoul(String profileId) =>
      _readProfileSoul(profileId);

  @override
  Future<void> writeProfileSoul({
    required String profileId,
    required String soul,
    required String revision,
  }) => _writeProfileSoul(profileId: profileId, soul: soul, revision: revision);

  @override
  Future<void> loadDetailedHealth() => _reloadDetailedHealth();

  @override
  Future<void> loadJobs() => _reloadJobs();

  @override
  Future<void> loadProviders() => _loadProviders();

  @override
  Future<void> setProviderCredential({
    required String slug,
    required String envVar,
    required String value,
  }) => _setProviderCredential(slug: slug, envVar: envVar, value: value);

  @override
  Future<void> removeProviderCredential({
    required String slug,
    required String envVar,
  }) => _removeProviderCredential(slug: slug, envVar: envVar);

  @override
  Future<HermesCredentialProbe> validateProviderCredential({
    required String slug,
  }) => _validateProviderCredential(slug: slug);

  @override
  Future<void> loadModels() => _loadModels();

  @override
  Future<void> refreshModels() => _refreshModels();

  @override
  Future<void> assignModel({
    required String scope,
    String? task,
    required String provider,
    required String model,
    required String revision,
  }) => _assignModel(
    scope: scope,
    task: task,
    provider: provider,
    model: model,
    revision: revision,
  );

  @override
  Future<void> sendText(
    String text, {
    String? imageDataUrl,
    String? textAttachment,
    String? attachmentName,
  }) => _sendText(
    text,
    imageDataUrl: imageDataUrl,
    textAttachment: textAttachment,
    attachmentName: attachmentName,
  );

  @override
  void cancelActiveTurn() => _cancelActiveTurn();

  @override
  void stopActiveTurn() => _stopActiveTurn();

  @override
  Future<void> respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
  }) => _respondToApproval(approvalId: approvalId, decision: decision);

  @override
  String startVoiceRun() => _startVoiceRun();

  @override
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
  }) => _stageVoiceRunTranscript(
    voiceRunId: voiceRunId,
    transcript: transcript,
    duration: duration,
    confidence: confidence,
  );

  @override
  void submitVoiceRun(String voiceRunId) => _submitVoiceRun(voiceRunId);

  @override
  void cancelVoiceRun(String voiceRunId, {String reason = 'cancelled'}) =>
      _cancelVoiceRun(voiceRunId, reason: reason);

  @override
  void failVoiceRun(String voiceRunId, {required String reason}) =>
      _failVoiceRun(voiceRunId, reason: reason);
}
