import 'dart:convert';

import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_health.dart';
import 'package:wing/core/hermes/models/hermes_job.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';

import '../../../test/features/hermes_chat/support/fake_hermes_channel.dart';
import 'interaction_fixture.dart';

HermesCapabilityDocument featureCapabilities({
  bool writes = true,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'features': {'session_chat_streaming': true, 'run_approval_response': true},
  'profile_context': {
    'type': 'query',
    'name': 'profile',
    'required': true,
    'default_profile_id': 'default',
  },
  'auth': {
    'type': 'bearer',
    'required': true,
    'granted_scopes': [
      'profiles:read',
      'providers:read',
      'models:read',
      'tasks:read',
      'gateway:read',
      'sessions:read',
      'sessions:write',
      if (writes) ...['profiles:write', 'providers:write', 'models:write'],
    ],
  },
  'endpoints': {
    for (final entry in <String, (String, String, String)>{
      'providers': ('GET', '/api/providers', 'providers:read'),
      'provider_credential_set': (
        'PUT',
        '/api/providers/{slug}/credential',
        'providers:write',
      ),
      'provider_credential_remove': (
        'DELETE',
        '/api/providers/{slug}/credential',
        'providers:write',
      ),
      'provider_credential_validate': (
        'POST',
        '/api/providers/{slug}/validate',
        'providers:write',
      ),
      'models': ('GET', '/api/models', 'models:read'),
      'models_assignment': ('PUT', '/api/models/assignment', 'models:write'),
      'profile_soul': ('GET', '/api/profiles/{name}/soul', 'profiles:read'),
      'profile_soul_update': (
        'PUT',
        '/api/profiles/{name}/soul',
        'profiles:write',
      ),
      'jobs': ('GET', '/api/jobs', 'tasks:read'),
      'health_detailed': ('GET', '/health/detailed', 'gateway:read'),
      'sessions': ('GET', '/api/sessions', 'sessions:read'),
      'session_create': ('POST', '/api/sessions', 'sessions:write'),
      'session_chat_stream': (
        'POST',
        '/api/sessions/{session_id}/chat/stream',
        'sessions:write',
      ),
      'run_approval': ('POST', '/v1/runs/{run_id}/approval', 'sessions:write'),
      'session_delete': (
        'DELETE',
        '/api/sessions/{session_id}',
        'sessions:write',
      ),
    }.entries)
      entry.key: {
        'method': entry.value.$1,
        'path': entry.value.$2,
        'required_scopes': [entry.value.$3],
      },
  },
});

const fixtureHealth = HermesHealthStatus(
  status: 'ok',
  platform: 'hermes-agent',
);

class FixtureStatusException implements HermesApiStatusException {
  const FixtureStatusException(this.statusCode);
  @override
  final int statusCode;
}

/// Deterministic service behavior only. These receipts prove UI dispatch, never
/// provider authentication, transport pinning, or live Agent compatibility.
class MaestroFeatureChannel extends FakeHermesChannel {
  MaestroFeatureChannel()
    : super(
        capabilities: featureCapabilities(),
        selectedProfileId: 'default',
        connectedBaseUrl: 'https://fixture.example',
        connectedWithApiKey: false,
        profiles: const [
          HermesProfile(
            id: 'default',
            displayName: 'Fixture profile',
            revision: 'p1',
          ),
        ],
        providers: const [
          HermesProvider(
            slug: 'fixture',
            label: 'Fixture provider',
            authType: 'api_key',
            envVars: ['FIXTURE_KEY'],
          ),
        ],
        modelInventory: HermesModelInventory(
          catalog: HermesModelCatalog.fromJson(const {
            'providers': {
              'fixture': {
                'models': [
                  {'id': 'fixture-small'},
                  {'id': 'fixture-large'},
                ],
              },
            },
          }),
          assignment: const HermesModelAssignment(
            activeProvider: 'fixture',
            activeModel: 'fixture-small',
            revision: 'm1',
          ),
        ),
        basicHealth: fixtureHealth,
        detailedHealth: fixtureHealth,
        jobs: const [
          HermesJob(
            id: 'daily',
            name: 'Fixture daily check',
            enabled: true,
            state: 'active',
            scheduleDisplay: 'Daily at 09:00',
          ),
        ],
        sessions: const [
          HermesSession(
            id: 'sess_1',
            title: 'Fixture first',
            source: 'fixture',
          ),
          HermesSession(
            id: 'sess_2',
            title: 'Fixture second',
            source: 'fixture',
          ),
        ],
      );

  bool conflictNext = false;
  bool failJobs = false;
  bool offline = false;
  String origin = 'https://fixture.example';
  int modelAttempts = 0;
  int soulWrites = 0;
  int submittedTurns = 0;
  bool textAttachmentSent = false;
  bool imageAttachmentSent = false;
  bool emojiSubmitted = false;
  String? concurrentModelRevision;
  bool earlierAvailable = false;
  bool earlierLoaded = false;
  HermesProfileSoul soul = const HermesProfileSoul(
    soul: 'Fixture initial persona',
    revision: 's1',
  );

  @override
  HermesChannelState get state => super.state.copyWith(
    connectedBaseUrl: origin,
    status: offline
        ? HermesConnectionStatus.disconnected
        : HermesConnectionStatus.connected,
    modelInventory: concurrentModelRevision == null
        ? null
        : super.state.modelInventory!.withAssignment(
            HermesModelAssignment(
              activeProvider:
                  super.state.modelInventory!.assignment.activeProvider,
              activeModel: super.state.modelInventory!.assignment.activeModel,
              revision: concurrentModelRevision!,
            ),
          ),
    sessionsWithEarlierMessages: earlierAvailable
        ? {super.state.activeSessionId!}
        : {},
    messages: earlierLoaded
        ? {
            ...super.state.messages,
            super.state.activeSessionId!: [
              HermesChatTurn(
                id: 'earlier',
                sessionId: super.state.activeSessionId!,
                author: HermesTurnAuthor.assistant,
                createdAt: DateTime.utc(2026),
                text: 'Fixture earlier history',
              ),
              ...super.state.activeMessages,
            ],
          }
        : null,
  );

  @override
  Future<void> loadEarlierMessages() async {
    await super.loadEarlierMessages();
    earlierAvailable = false;
    earlierLoaded = true;
    notifyListeners();
  }

  @override
  Future<void> loadMoreSessions() async {
    await super.loadMoreSessions();
    replaceSessions([
      ...state.sessions,
      const HermesSession(
        id: 'sess_3',
        title: 'Fixture third',
        source: 'fixture',
      ),
    ], activeSessionId: state.activeSessionId);
  }

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) async {
    connectCalls.add(FakeHermesConnectCall(baseUrl: baseUrl, apiKey: apiKey));
    origin = baseUrl;
    setOffline(false);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    setOffline(true);
  }

  void revokeWrites() => replaceCapabilitiesAndProfiles(
    featureCapabilities(writes: false),
    state.profiles,
  );

  void setOffline(bool value) {
    offline = value;
    notifyListeners();
  }

  @override
  Future<void> loadJobs() async {
    await super.loadJobs();
    if (failJobs) throw StateError('fixture inventory failure');
  }

  @override
  Future<HermesProfileSoul> readProfileSoul(String profileId) async => soul;

  @override
  Future<void> writeProfileSoul({
    required String profileId,
    required String soul,
    required String revision,
  }) async {
    if (conflictNext) {
      conflictNext = false;
      this.soul = const HermesProfileSoul(
        soul: 'Fixture concurrent persona',
        revision: 's-concurrent',
      );
      throw const FixtureStatusException(412);
    }
    if (revision != this.soul.revision) throw const FixtureStatusException(412);
    soulWrites++;
    this.soul = HermesProfileSoul(soul: soul, revision: 's${soulWrites + 1}');
  }

  @override
  Future<void> assignModel({
    required String scope,
    String? task,
    required String provider,
    required String model,
    required String revision,
  }) async {
    modelAttempts++;
    if (conflictNext) {
      conflictNext = false;
      concurrentModelRevision = 'concurrent-revision';
      throw const FixtureStatusException(412);
    }
    if (revision != state.modelInventory!.assignment.revision) {
      throw const FixtureStatusException(412);
    }
    concurrentModelRevision = null;
    await super.assignModel(
      scope: scope,
      task: task,
      provider: provider,
      model: model,
      revision: revision,
    );
  }

  @override
  Future<void> sendText(
    String text, {
    String? imageDataUrl,
    String? textAttachment,
    String? attachmentName,
  }) async {
    textAttachmentSent =
        textAttachment == 'Fixture attachment content' &&
        attachmentName == 'fixture-note.txt' &&
        imageDataUrl == null;
    imageAttachmentSent =
        imageDataUrl ==
            'data:image/png;base64,${base64Encode(InteractionFixture.imageBytes)}' &&
        attachmentName == 'fixture-image.png' &&
        textAttachment == null;
    emojiSubmitted = text == '😀';
    submittedTurns++;
    beginStreamingTurn(text);
    final target = activeTurnInterruptionTarget!;
    emitApprovalRequest(
      HermesApprovalRequest(
        id: 'approval-$submittedTurns',
        toolCallId: 'tool-$submittedTurns',
        prompt: 'Fixture approval $submittedTurns',
        choices: {HermesApprovalDecision.once, HermesApprovalDecision.deny},
        runId: target.runId,
        sessionId: target.sessionId,
        profileId: target.profileId,
        connectionGeneration: target.connectionGeneration,
      ),
    );
  }

  @override
  Future<void> respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
    String? runId,
    HermesApprovalRequest? origin,
  }) async {
    await super.respondToApproval(
      approvalId: approvalId,
      decision: decision,
      runId: runId,
      origin: origin,
    );
    completeStreamingTurn(text: 'Fixture decision ${decision.name}');
  }
}
