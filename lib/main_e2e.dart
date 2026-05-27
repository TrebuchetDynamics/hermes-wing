// E2E test entry point for Playwright testing.
// Uses a mock channel pre-seeded with gateway, profiles, and messages
// so Playwright tests can navigate all app screens without a real gateway.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/channel/navivox_channel.dart';
import 'core/channel/navivox_channel_provider.dart';
import 'core/gateway/navivox_gateway_protocol.dart';
import 'core/protocol/navivox_event.dart';
import 'core/protocol/navivox_memory.dart';
import 'core/protocol/navivox_voice_run.dart';
import 'router/app_router.dart';
import 'theme/navivox_theme.dart';

class E2EMockChannel extends ChangeNotifier implements NavivoxChannel {
  NavivoxChannelState _state = const NavivoxChannelState();
  final StreamController<NavivoxApprovalRequest> _approvals =
      StreamController<NavivoxApprovalRequest>.broadcast();

  @override
  NavivoxChannelState get state => _state;

  set state(NavivoxChannelState next) {
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
    _state = _state.copyWith(
      servers: const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
        NavivoxServer(id: 'office', name: 'Office Gormes', status: 'online'),
      ],
      activeServerId: 'local',
      profileContacts: [
        const NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready to work on mineru',
          micAvailable: true,
        ),
        const NavivoxProfileContact(
          serverId: 'office',
          profileId: 'support',
          displayName: 'Support Triage',
          serverLabel: 'office',
          health: NavivoxProfileHealth.needsAuth,
          latestPreview: 'Waiting for auth',
          attentionBadges: ['auth'],
        ),
        const NavivoxProfileContact(
          serverId: 'local',
          profileId: 'voice',
          displayName: 'Voice Agent',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Voice ready',
          micAvailable: true,
        ),
      ],
      selectedProfileContactKey: 'local::mineru',
    );
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {}

  @override
  void sendText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final messages = Map<String, NavivoxChatMessage>.from(_state.messages);
    final id = 'user-${messages.length + 1}';
    messages[id] = NavivoxChatMessage(
      id: id,
      author: NavivoxMessageAuthor.user,
      kind: NavivoxMessageKind.text,
      createdAt: DateTime.now(),
      text: trimmed,
    );
    final aid = 'assistant-${messages.length + 1}';
    messages[aid] = NavivoxChatMessage(
      id: aid,
      author: NavivoxMessageAuthor.assistant,
      kind: NavivoxMessageKind.text,
      createdAt: DateTime.now(),
      text: 'Echo: $trimmed',
    );
    _state = _state.copyWith(messages: messages);
    notifyListeners();
  }

  @override
  void sendVoice({required String transcript}) {}

  @override
  String startVoiceRun() => '';

  @override
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
    NavivoxTranscriptSource transcriptSource = NavivoxTranscriptSource.device,
  }) {}

  @override
  void cancelVoiceRun(String voiceRunId, {String reason = 'cancelled'}) {}

  @override
  void failVoiceRun(String voiceRunId, {required String reason}) {}

  @override
  void submitVoiceRun(String voiceRunId) {}

  @override
  void cancelActiveTurn() {}

  @override
  void stopActiveTurn() {}

  @override
  void respondToApproval({
    required String approvalId,
    required bool approved,
  }) {}

  @override
  void requestAgentList() {}

  @override
  Future<NavivoxProfileSeedResult> profileSeed({
    required String seed,
    bool apply = false,
    List<String> workspaceRoots = const [],
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxVoiceProfilesResponse> voiceProfiles() async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxVoiceProfileValidationResponse> validateVoiceProfile({
    required String profileId,
    required NavivoxProfileVoiceProfile voiceProfile,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxRunRecordSnapshot> runRecord(String runIdOrSessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxMemoryOverview> memoryOverview({
    String? serverId,
    String? profileId,
  }) async {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<NavivoxMemoryDetail> memoryDetail({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
  }) async {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  void selectAgent(String agentId) {}

  @override
  void selectProfileContact({
    required String serverId,
    required String profileId,
  }) {
    final contact = _state.profileContacts.where(
      (c) => c.serverId == serverId && c.profileId == profileId,
    ).firstOrNull;
    if (contact != null) {
      _state = _state.copyWith(
        activeServerId: serverId,
        selectedProfileContactKey: contact.key,
      );
      notifyListeners();
    }
  }

  @override
  void selectProfileRouting({
    String? workspace,
    String? provider,
    String? channel,
  }) {}

  @override
  bool get configAdminAvailable => false;

  @override
  Future<void> refreshConfigAdmin() async {}

  @override
  Future<NavivoxConfigAdminResponse> diffConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxConfigAdminResponse> validateConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxConfigAdminResponse> applyConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    throw UnimplementedError();
  }

  @override
  void sendConfigSet({required String field, required Object? value}) {}

  @override
  void sendConfigSecretSet({required String name, required String secret}) {}

  @override
  void dispose() {
    _approvals.close();
    super.dispose();
  }
}

void main() {
  final channel = E2EMockChannel();
  channel.connect(baseUrl: 'http://127.0.0.1:8765', token: 'nvbx_e2e_token');

  runApp(
    ProviderScope(
      overrides: [
        navivoxChannelProvider.overrideWithValue(channel),
      ],
      child: const _E2ETestApp(),
    ),
  );
}

class _E2ETestApp extends ConsumerWidget {
  const _E2ETestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Navivox',
      theme: navivoxLightTheme,
      darkTheme: navivoxDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}