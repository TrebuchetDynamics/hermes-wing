import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/presentation/chat_screen_presentation.dart';

import '../shared/profiles/profile_scope_test_contracts.dart';
import '../shared/protocol/chat_message_test_fixtures.dart';
import '../shared/voice/voice_recovery_test_fixtures.dart';
import '../shared/protocol/voice_run_test_fixtures.dart';
import '../shared/voice/voice_settings_test_fixtures.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 5, 23, 9);

  const local = NavivoxServer(id: 'srv1', name: 'Local', status: 'ready');
  const activeScope = (serverId: 'srv1', profileId: chatMineruProfileId);
  final activeProfile = mineruBuilderProfile(
    serverId: activeScope.serverId,
    serverLabel: 'Local',
    latestPreview: 'Ready',
    workspaceRootCount: 3,
    workspaceRootsWarning: 1,
    activeTurnState: 'streaming',
  );
  final otherProfile = supportTriageProfile(
    serverId: activeScope.serverId,
    serverLabel: 'Local',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Watching tickets',
    micAvailable: true,
  );
  const architect = NavivoxAgent(
    id: 'arch',
    name: 'Architect',
    status: 'ready',
  );

  test('keeps transcript surface scoped to active Profile contact', () {
    final state = NavivoxChannelState(
      servers: const [local],
      activeServerId: activeScope.serverId,
      profileContacts: [activeProfile, otherProfile],
      selectedProfileContactKey: chatProfileScopeKey(activeScope),
      messages: {
        'mineru': chatProfileTextMessage(
          id: 'mineru',
          scope: activeScope,
          text: 'mineru turn',
          createdAt: now,
        ),
        'support': chatProfileTextMessage(
          id: 'support',
          scope: (serverId: activeScope.serverId, profileId: 'support'),
          text: 'support turn',
          createdAt: now,
        ),
        'system': chatTextMessage(
          id: 'system',
          author: NavivoxMessageAuthor.system,
          text: 'gateway connected',
          createdAt: now,
        ),
      },
    );

    final presentation = ChatScreenPresentation.fromState(
      state: state,
      voiceSettings: trustedVoiceSettingsForScope(activeScope),
      localVoiceCaptureAvailable: true,
    );

    expect(presentation.transcriptMessages.map((message) => message.text), [
      'mineru turn',
      'gateway connected',
    ]);
  });

  test('summarizes active profile scope and transcript surface inputs', () {
    final pendingRun = chatProfileVoiceRun(
      id: 'voice-1',
      scope: activeScope,
      transcript: 'ship this safely',
      duration: const Duration(seconds: 3),
      confidence: 0.82,
      createdAt: now,
    );
    final state = NavivoxChannelState(
      servers: const [local],
      activeServerId: activeScope.serverId,
      agents: const [architect],
      selectedAgentId: 'arch',
      profileContacts: [activeProfile, otherProfile],
      selectedProfileContactKey: chatProfileScopeKey(activeScope),
      messages: {
        'm1': chatProfileTextMessage(
          id: 'm1',
          scope: activeScope,
          text: 'hello',
          createdAt: now,
        ),
      },
      voiceRuns: {'voice-1': pendingRun},
      activeVoiceRunId: 'voice-1',
    );

    final presentation = ChatScreenPresentation.fromState(
      state: state,
      voiceSettings: trustedVoiceSettingsForScope(activeScope),
      localVoiceCaptureAvailable: true,
    );

    expect(presentation.appBarTitle, 'Mineru Builder');
    expect(
      presentation.appBarSubtitle,
      'Local • online • 3 projects • 1 warning',
    );
    expect(presentation.chatInfoTooltip, 'Chat info');
    expect(presentation.chatInfoTitle, 'Chat info');
    expect(presentation.activeProfile, activeProfile);
    expect(presentation.selectedAgent, architect);
    expect(presentation.assistantTypingLabel, 'Mineru Builder is typing…');
    expect(presentation.forwardTargets, [otherProfile]);
    expect(presentation.transcriptMessages, hasLength(2));
    expect(presentation.transcriptMessages.last.id, 'pending-voice-1');
    expect(presentation.transcriptMessages.last.kind, NavivoxMessageKind.voice);
    expect(
      presentation.transcriptMessages.last.voice?.transcript,
      'ship this safely',
    );
    expect(
      presentation.transcriptMessages.last.voice?.duration,
      const Duration(seconds: 3),
    );
    expect(presentation.transcriptMessages.last.voice?.confidence, 0.82);
    expect(
      presentation.infoRows.map((row) => '${row.label}:${row.value}'),
      containsAll([
        'Profile:Mineru Builder',
        'Profile ID:mineru',
        'Server:Local',
        'Server ID:srv1',
        'Status:online',
        'Projects:3 projects • 1 warning',
        'Agent:Architect',
      ]),
    );
    expect(
      presentation.infoActions.map(
        (action) => '${action.kind.name}:${action.title}:${action.subtitle}',
      ),
      [
        'openAgents:Open profile contacts:Select or manage Gormes profiles.',
        'openWorkspace:Workspace and memory:Inspect workspace-scoped memory and references.',
        'openConfig:Profile config:Review profile-scoped config and voice settings.',
        'openSettings:Navivox settings:Voice, trust, and local app controls.',
        'manageGateways:Gateway details:Manage Gormes gateway connections.',
      ],
    );
    expect(
      presentation.voiceMode.controlsSemanticsHint,
      'Open continuous voice controls',
    );
    expect(presentation.voiceMode.sheetTitle, 'Continuous voice');
    expect(presentation.voiceMode.cancelPendingButtonLabel, 'Cancel');
    expect(presentation.voiceMode.trustServerButtonLabel, 'Trust server');
    expect(_voiceRows(presentation.voiceMode), [
      'status:Pending voice turn:ship this safely:none',
      'cancelPending:Cancel pending voice::cancelPending',
      'commandWord:Command word:navi:none',
      'howItWorks:How it works:Tap once to capture a turn. Use command mode for local actions like switching profiles, stop, cancel, help, or settings.:none',
    ]);
  });

  test('summarizes project errors before warnings in status copy', () {
    final profile = NavivoxProfileContact(
      serverId: activeScope.serverId,
      profileId: activeScope.profileId,
      displayName: 'Mineru Builder',
      serverLabel: 'Local',
      health: NavivoxProfileHealth.warning,
      latestPreview: 'Ready',
      workspaceRootCount: 4,
      workspaceRootsWarning: 2,
      workspaceRootsError: 1,
      micAvailable: true,
    );

    final presentation = ChatScreenPresentation.fromState(
      state: NavivoxChannelState(
        servers: const [local],
        activeServerId: activeScope.serverId,
        profileContacts: [profile],
        selectedProfileContactKey: chatProfileScopeKey(activeScope),
      ),
      voiceSettings: trustedVoiceSettingsForScope(activeScope),
      localVoiceCaptureAvailable: true,
    );

    expect(
      presentation.appBarSubtitle,
      'Local • warning • 4 projects • 1 error • 2 warnings',
    );
    expect(
      presentation.infoRows.map((row) => '${row.label}:${row.value}'),
      contains('Projects:4 projects • 1 error • 2 warnings'),
    );
  });

  test('derives continuous voice availability and recovery copy', () {
    final profile = NavivoxProfileContact(
      serverId: activeScope.serverId,
      profileId: activeScope.profileId,
      displayName: 'Mineru Builder',
      serverLabel: 'Local',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Ready',
      micAvailable: true,
      voiceCapability: const NavivoxVoiceCapability(
        disabledReason: deviceSttUnavailableReason,
        recoveryAction: 'Enable speech recognition on the Android device.',
      ),
    );
    final state = NavivoxChannelState(
      servers: const [local],
      activeServerId: activeScope.serverId,
      profileContacts: [profile],
      selectedProfileContactKey: chatProfileScopeKey(activeScope),
    );

    final presentation = ChatScreenPresentation.fromState(
      state: state,
      voiceSettings: trustedVoiceSettingsForScope(activeScope),
      localVoiceCaptureAvailable: true,
    );

    expect(presentation.voiceMode.disabledReason, deviceSttUnavailableReason);
    expect(
      presentation.voiceMode.recoveryAction,
      'Enable speech recognition on the Android device.',
    );
    expect(
      presentation.voiceMode.bannerText,
      'Continuous voice unavailable: $deviceSttUnavailableReason',
    );
    expect(
      presentation.voiceMode.voiceSettingsSubtitle,
      deviceSttSettingsReviewCopy,
    );
    expect(presentation.voiceMode.showSttDiagnostics, isTrue);
    expect(
      presentation.voiceMode.gatewayProfileSttStatus,
      gatewayProfileSttUnavailableCopy,
    );
    expect(_voiceRows(presentation.voiceMode), [
      'status:Continuous voice unavailable:$deviceSttUnavailableReason:none',
      'recoveryAction:Recovery action:Enable speech recognition on the Android device.:none',
      'openVoiceSettings:Open voice settings:$deviceSttSettingsReviewCopy:openVoiceSettings',
      'diagnostics:Voice diagnostics:Android recognizer, microphone permission, and gateway profile STT are separate checks.:none',
      'androidRecognizer:Android recognizer:Ready in Navivox; gateway STT status is separate.:none',
      'microphonePermission:Microphone permission:Not denied by Android in this session; checked when capture starts.:none',
      'gatewayProfileStt:Gateway profile STT:$gatewayProfileSttUnavailableCopy:none',
      'commandWord:Command word:navi:none',
      'howItWorks:How it works:Reason: $deviceSttUnavailableReason. Continuous voice stays off until resolved.:none',
    ]);
  });

  test('separates local recognizer unavailability from gateway STT', () {
    final presentation = ChatScreenPresentation.fromState(
      state: NavivoxChannelState(
        servers: const [local],
        activeServerId: activeScope.serverId,
        profileContacts: [activeProfile],
        selectedProfileContactKey: chatProfileScopeKey(activeScope),
      ),
      voiceSettings: trustedVoiceSettingsForScope(activeScope),
      localVoiceCaptureAvailable: false,
    );

    expect(presentation.voiceMode.disabledReason, deviceSttUnavailableReason);
    expect(
      presentation.voiceMode.androidRecognizerStatus,
      'No local speech recognizer is active in Navivox.',
    );
    expect(
      presentation.voiceMode.gatewayProfileSttStatus,
      gatewayProfileSttBlockedByDeviceCopy,
    );
    expect(
      _voiceRows(presentation.voiceMode),
      contains(
        'gatewayProfileStt:Gateway profile STT:$gatewayProfileSttBlockedByDeviceCopy:none',
      ),
    );
  });

  test('offers a trust action for untrusted Profile contact voice mode', () {
    final presentation = ChatScreenPresentation.fromState(
      state: NavivoxChannelState(
        servers: const [local],
        activeServerId: activeScope.serverId,
        profileContacts: [activeProfile],
        selectedProfileContactKey: chatProfileScopeKey(activeScope),
      ),
      voiceSettings: untrustedVoiceSettings,
      localVoiceCaptureAvailable: true,
    );

    expect(presentation.voiceMode.disabledReason, 'trust Local');
    expect(presentation.voiceMode.canTrustServer, isTrue);
    expect(
      _voiceRows(presentation.voiceMode),
      contains('trustServer:Trust server::trustServer'),
    );
  });

  test(
    'uses server scope and profile-selection voice copy without a profile',
    () {
      final presentation = ChatScreenPresentation.fromState(
        state: NavivoxChannelState(
          servers: const [local],
          activeServerId: activeScope.serverId,
        ),
        voiceSettings: trustedVoiceSettingsForScope(activeScope),
        localVoiceCaptureAvailable: true,
      );

      expect(presentation.appBarTitle, 'Local');
      expect(presentation.appBarSubtitle, 'ready');
      expect(
        presentation.infoRows.map((row) => '${row.label}:${row.value}'),
        containsAll(['Server:Local', 'Status:ready']),
      );
      expect(presentation.voiceMode.disabledReason, 'select a profile contact');
      expect(
        presentation.voiceMode.voiceSettingsSubtitle,
        'Select a profile contact before reviewing continuous voice settings.',
      );
    },
  );
}

List<String> _voiceRows(VoiceModePresentation presentation) {
  return presentation.sheetRows
      .map(
        (row) =>
            '${row.kind.name}:${row.title}:${row.subtitle ?? ''}:${row.action.name}',
      )
      .toList();
}
