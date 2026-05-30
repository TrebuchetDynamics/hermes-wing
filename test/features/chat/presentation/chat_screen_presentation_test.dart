import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';
import 'package:navivox/features/chat/presentation/chat_screen_presentation.dart';
import 'package:navivox/features/settings/providers/voice_settings_provider.dart';

import '../../shared/fixtures/profile_contact_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 5, 23, 9);

  const local = NavivoxServer(id: 'srv1', name: 'Local', status: 'ready');
  final activeProfile = mineruBuilderProfile(
    serverId: 'srv1',
    serverLabel: 'Local',
    latestPreview: 'Ready',
    workspaceRootCount: 3,
    workspaceRootsWarning: 1,
    activeTurnState: 'streaming',
  );
  final otherProfile = supportTriageProfile(
    serverId: 'srv1',
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
      activeServerId: 'srv1',
      profileContacts: [activeProfile, otherProfile],
      selectedProfileContactKey: 'srv1::mineru',
      messages: {
        'mineru': NavivoxChatMessage(
          id: 'mineru',
          author: NavivoxMessageAuthor.user,
          kind: NavivoxMessageKind.text,
          text: 'mineru turn',
          serverId: 'srv1',
          profileId: 'mineru',
          createdAt: now,
        ),
        'support': NavivoxChatMessage(
          id: 'support',
          author: NavivoxMessageAuthor.user,
          kind: NavivoxMessageKind.text,
          text: 'support turn',
          serverId: 'srv1',
          profileId: 'support',
          createdAt: now,
        ),
        'system': NavivoxChatMessage(
          id: 'system',
          author: NavivoxMessageAuthor.system,
          kind: NavivoxMessageKind.text,
          text: 'gateway connected',
          createdAt: now,
        ),
      },
    );

    final presentation = ChatScreenPresentation.fromState(
      state: state,
      voiceSettings: const NavivoxVoiceSettings(trustedServerIds: {'srv1'}),
      localVoiceCaptureAvailable: true,
    );

    expect(presentation.transcriptMessages.map((message) => message.text), [
      'mineru turn',
      'gateway connected',
    ]);
  });

  test('summarizes active profile scope and transcript surface inputs', () {
    final pendingRun = NavivoxVoiceRun(
      id: 'voice-1',
      serverId: 'srv1',
      profileId: 'mineru',
      status: NavivoxVoiceRunStatus.pendingSend,
      transcriptSource: NavivoxTranscriptSource.device,
      ttsStatus: NavivoxTtsStatus.unavailable,
      transcript: 'ship this safely',
      duration: const Duration(seconds: 3),
      confidence: 0.82,
      createdAt: now,
      updatedAt: now,
    );
    final state = NavivoxChannelState(
      servers: const [local],
      activeServerId: 'srv1',
      agents: const [architect],
      selectedAgentId: 'arch',
      profileContacts: [activeProfile, otherProfile],
      selectedProfileContactKey: 'srv1::mineru',
      messages: {
        'm1': NavivoxChatMessage(
          id: 'm1',
          author: NavivoxMessageAuthor.user,
          kind: NavivoxMessageKind.text,
          text: 'hello',
          serverId: 'srv1',
          profileId: 'mineru',
          createdAt: now,
        ),
      },
      voiceRuns: {'voice-1': pendingRun},
      activeVoiceRunId: 'voice-1',
    );

    final presentation = ChatScreenPresentation.fromState(
      state: state,
      voiceSettings: const NavivoxVoiceSettings(trustedServerIds: {'srv1'}),
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
    const profile = NavivoxProfileContact(
      serverId: 'srv1',
      profileId: 'mineru',
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
      state: const NavivoxChannelState(
        servers: [local],
        activeServerId: 'srv1',
        profileContacts: [profile],
        selectedProfileContactKey: 'srv1::mineru',
      ),
      voiceSettings: const NavivoxVoiceSettings(trustedServerIds: {'srv1'}),
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
    const profile = NavivoxProfileContact(
      serverId: 'srv1',
      profileId: 'mineru',
      displayName: 'Mineru Builder',
      serverLabel: 'Local',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Ready',
      micAvailable: true,
      voiceCapability: NavivoxVoiceCapability(
        disabledReason: 'device STT unavailable',
        recoveryAction: 'Enable speech recognition on the Android device.',
      ),
    );
    final state = const NavivoxChannelState(
      servers: [local],
      activeServerId: 'srv1',
      profileContacts: [profile],
      selectedProfileContactKey: 'srv1::mineru',
    );

    final presentation = ChatScreenPresentation.fromState(
      state: state,
      voiceSettings: const NavivoxVoiceSettings(trustedServerIds: {'srv1'}),
      localVoiceCaptureAvailable: true,
    );

    expect(presentation.voiceMode.disabledReason, 'device STT unavailable');
    expect(
      presentation.voiceMode.recoveryAction,
      'Enable speech recognition on the Android device.',
    );
    expect(
      presentation.voiceMode.bannerText,
      'Continuous voice unavailable: device STT unavailable',
    );
    expect(
      presentation.voiceMode.voiceSettingsSubtitle,
      'Review continuous voice after enabling device speech recognition.',
    );
    expect(presentation.voiceMode.showSttDiagnostics, isTrue);
    expect(
      presentation.voiceMode.gatewayProfileSttStatus,
      'Gateway reported device STT unavailable for this profile.',
    );
    expect(_voiceRows(presentation.voiceMode), [
      'status:Continuous voice unavailable:device STT unavailable:none',
      'recoveryAction:Recovery action:Enable speech recognition on the Android device.:none',
      'openVoiceSettings:Open voice settings:Review continuous voice after enabling device speech recognition.:openVoiceSettings',
      'diagnostics:Voice diagnostics:Android recognizer, microphone permission, and gateway profile STT are separate checks.:none',
      'androidRecognizer:Android recognizer:Ready in Navivox; gateway STT status is separate.:none',
      'microphonePermission:Microphone permission:Not denied by Android in this session; checked when capture starts.:none',
      'gatewayProfileStt:Gateway profile STT:Gateway reported device STT unavailable for this profile.:none',
      'commandWord:Command word:navi:none',
      'howItWorks:How it works:Reason: device STT unavailable. Continuous voice stays off until resolved.:none',
    ]);
  });

  test('separates local recognizer unavailability from gateway STT', () {
    final presentation = ChatScreenPresentation.fromState(
      state: NavivoxChannelState(
        servers: const [local],
        activeServerId: 'srv1',
        profileContacts: [activeProfile],
        selectedProfileContactKey: 'srv1::mineru',
      ),
      voiceSettings: const NavivoxVoiceSettings(trustedServerIds: {'srv1'}),
      localVoiceCaptureAvailable: false,
    );

    expect(presentation.voiceMode.disabledReason, 'device STT unavailable');
    expect(
      presentation.voiceMode.androidRecognizerStatus,
      'No local speech recognizer is active in Navivox.',
    );
    expect(
      presentation.voiceMode.gatewayProfileSttStatus,
      'Gateway profile STT is not checked because Android speech recognition is unavailable.',
    );
    expect(
      _voiceRows(presentation.voiceMode),
      contains(
        'gatewayProfileStt:Gateway profile STT:Gateway profile STT is not checked because Android speech recognition is unavailable.:none',
      ),
    );
  });

  test('offers a trust action for untrusted Profile contact voice mode', () {
    final presentation = ChatScreenPresentation.fromState(
      state: NavivoxChannelState(
        servers: const [local],
        activeServerId: 'srv1',
        profileContacts: [activeProfile],
        selectedProfileContactKey: 'srv1::mineru',
      ),
      voiceSettings: const NavivoxVoiceSettings(),
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
        state: const NavivoxChannelState(
          servers: [local],
          activeServerId: 'srv1',
        ),
        voiceSettings: const NavivoxVoiceSettings(trustedServerIds: {'srv1'}),
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
