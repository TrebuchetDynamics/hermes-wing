import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';
import 'package:navivox/features/settings/providers/voice_settings_provider.dart';
import 'package:navivox/features/voice/services/capture/voice_capture_service.dart';
import 'package:navivox/features/voice/services/platform/default_voice_capture_service.dart';
import 'package:navivox/features/voice/services/speech/speech_to_text_voice_capture_service.dart';

import '../../../support/test_navivox_channel.dart';
import '../../shared/app/test_material_app.dart';
import '../../shared/app/test_router_app.dart';
import '../../shared/fakes/voice_capture_service_fakes.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';

const _servers = [localGormesServer, officeOnlineServer];

final _contacts = [
  mineruBuilderProfile(
    displayName: 'Mineru',
    latestPreview: 'Ready',
    workspaceRootCount: 1,
  ),
  supportTriageProfile(
    displayName: 'Support',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready',
    micAvailable: true,
  ),
];

void main() {
  testWidgets('typed command switches profile locally and is not sent', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'office::support');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: const ChatScreen(serverId: 'office', profileId: 'support'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Gormes'),
      'navi mineru',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(channel.selectedProfileScope, (
      serverId: 'local',
      profileId: 'mineru',
    ));
    expect(channel.sentTexts, isEmpty);
    expect(channel.state.voiceRuns, isEmpty);
  });

  testWidgets('duplicate profile voice command asks for disambiguation', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts([
        ..._contacts,
        const NavivoxProfileContact(
          serverId: 'office',
          profileId: 'mineru',
          displayName: 'Mineru',
          serverLabel: 'office',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
          workspaceRootCount: 1,
          micAvailable: true,
        ),
      ], selectedKey: 'local::mineru');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: const ChatScreen(serverId: 'local', profileId: 'mineru'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Gormes'),
      'navi mineru',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(channel.sentTexts, isEmpty);
    expect(
      find.textContaining('Choose one profile named mineru'),
      findsOneWidget,
    );
  });

  testWidgets('voice command mode accepts one bare command', (tester) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = QueueVoiceCaptureService([
      testVoiceCapture('navi'),
      testVoiceCapture('support'),
    ]);

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
    );

    await _tapMic(tester);
    expect(find.text('Command mode'), findsOneWidget);

    await _tapMic(tester);
    expect(channel.selectedProfileScope, (
      serverId: 'office',
      profileId: 'support',
    ));
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets('voice command mode timeout treats later bare voice as chat', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = QueueVoiceCaptureService([
      testVoiceCapture('navi'),
      testVoiceCapture('support'),
    ]);

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
      voiceAutoSendGrace: const Duration(milliseconds: 100),
      voiceCommandTimeout: const Duration(milliseconds: 50),
    );

    await _tapMic(tester);
    expect(find.text('Command mode'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));

    await _tapMic(tester);
    await tester.pump(const Duration(milliseconds: 120));

    expect(channel.sentVoiceTranscripts, hasLength(1));
    expect(channel.sentVoiceTranscripts.single, 'support');
    expect(channel.selectedProfileScope, isNull);
  });

  testWidgets('local cancel stop and help commands stay out of chat', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: const ChatScreen(serverId: 'local', profileId: 'mineru'),
      ),
    );
    await tester.pumpAndSettle();

    await _submitText(tester, 'navi help');
    expect(find.textContaining('Voice commands:'), findsOneWidget);

    await _submitText(tester, 'navi cancel');
    await _submitText(tester, 'navi stop');

    expect(channel.cancelRequests, 1);
    expect(channel.stopRequests, 1);
    expect(channel.sentTexts, isEmpty);
  });

  testWidgets('navi cancel discards pending voice before server commit', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = successfulVoiceCaptureService(
      audio: [7, 8, 9],
      transcript: 'before commit',
      duration: const Duration(milliseconds: 800),
      confidence: 0.91,
    );

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
      voiceAutoSendGrace: const Duration(milliseconds: 300),
    );

    await _tapMic(tester);
    expect(find.text('Sending...'), findsOneWidget);

    await _submitText(tester, 'navi cancel');
    await tester.pump(const Duration(milliseconds: 350));

    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(channel.cancelRequests, 0);
    expect(find.textContaining('before commit'), findsNothing);
  });

  testWidgets(
    'disabled voice profile switching rejects local profile command',
    (tester) async {
      final channel = _seedChannel(selectedKey: 'local::mineru');

      await tester.pumpWidget(
        TestNavivoxMaterialApp(
          channel: channel,
          home: const ChatScreen(serverId: 'local', profileId: 'mineru'),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChatScreen)),
      );
      container
          .read(navivoxVoiceSettingsProvider.notifier)
          .setProfileSwitchingEnabled(false);
      await tester.pump();

      await _submitText(tester, 'navi support');

      expect(channel.selectedProfileScope, isNull);
      expect(channel.sentTexts, isEmpty);
      expect(
        find.textContaining('Voice profile switching is disabled'),
        findsOneWidget,
      );
    },
  );

  testWidgets('continuous voice explains unavailable device STT', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: const ChatScreen(serverId: 'local', profileId: 'mineru'),
      ),
    );
    await tester.pumpAndSettle();
    _trustLocalServer(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Continuous voice unavailable: device STT unavailable'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.mic), findsNothing);
    expect(find.byIcon(Icons.mic_off), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pumpAndSettle();

    expect(find.text('Continuous voice'), findsOneWidget);
    expect(find.text('Continuous voice unavailable'), findsOneWidget);
    expect(find.text('device STT unavailable'), findsOneWidget);
  });

  testWidgets('missing profile selection beats unavailable STT', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts(_contacts);

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: ChatScreen(serverId: 'local'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Continuous voice unavailable: select a profile contact'),
      findsOneWidget,
    );
    expect(
      find.text('Continuous voice unavailable: device STT unavailable'),
      findsNothing,
    );
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets('missing profile sheet points to profile selection first', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts(_contacts);

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: ChatScreen(serverId: 'local'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pumpAndSettle();

    expect(find.text('Open voice settings'), findsOneWidget);
    expect(
      find.text(
        'Select a profile contact before reviewing continuous voice settings.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Review continuous voice after enabling device speech recognition.',
      ),
      findsNothing,
    );
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets('disabled continuous voice setting beats unavailable STT', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: const ChatScreen(serverId: 'local', profileId: 'mineru'),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChatScreen)),
    );
    container
        .read(navivoxVoiceSettingsProvider.notifier)
        .setContinuousVoiceEnabled(false);
    await tester.pump();

    expect(
      find.text('Continuous voice unavailable: disabled in Settings'),
      findsOneWidget,
    );
    expect(
      find.text('Continuous voice unavailable: device STT unavailable'),
      findsNothing,
    );
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets('continuous voice unavailable sheet gives STT recovery action', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: const ChatScreen(serverId: 'local', profileId: 'mineru'),
      ),
    );
    await tester.pumpAndSettle();
    _trustLocalServer(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pumpAndSettle();

    expect(find.text('Recovery action'), findsOneWidget);
    expect(
      find.text(
        'Install or enable device speech recognition, then return to Navivox.',
      ),
      findsOneWidget,
    );
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets('continuous voice unavailable sheet avoids capture instructions', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: const ChatScreen(serverId: 'local', profileId: 'mineru'),
      ),
    );
    await tester.pumpAndSettle();
    _trustLocalServer(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('How it works'), findsOneWidget);
    expect(
      find.text(
        'Reason: device STT unavailable. Continuous voice stays off until resolved.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Tap once to capture a turn'), findsNothing);
  });

  testWidgets('continuous voice unavailable banner announces controls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final channel = _seedChannel(selectedKey: 'local::mineru');

      await tester.pumpWidget(
        TestNavivoxMaterialApp(
          channel: channel,
          home: const ChatScreen(serverId: 'local', profileId: 'mineru'),
        ),
      );
      await tester.pumpAndSettle();
      _trustLocalServer(tester);
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(
          find.byKey(const ValueKey('continuous-voice-banner')),
        ),
        matchesSemantics(
          label: 'Continuous voice unavailable: device STT unavailable',
          hint: 'Open continuous voice controls',
          textDirection: TextDirection.ltr,
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('profile-reported STT unavailability blocks capture', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts([
        mineruBuilderProfile(
          displayName: 'Mineru',
          latestPreview: 'Ready',
          workspaceRootCount: 1,
          voiceCapability: const NavivoxVoiceCapability(
            deviceStt: 'unavailable',
            disabledReason: 'device STT unavailable',
          ),
        ),
      ], selectedKey: 'local::mineru');
    final voiceService = successfulVoiceCaptureService(
      transcript: 'should not capture',
      duration: const Duration(milliseconds: 500),
      confidence: 0.9,
    );

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
    );

    expect(
      find.text('Continuous voice unavailable: device STT unavailable'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.mic), findsNothing);
    expect(find.byIcon(Icons.mic_off), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pumpAndSettle();

    expect(find.text('device STT unavailable'), findsOneWidget);
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets(
    'STT unavailable sheet separates Android recognizer and microphone permission diagnostics',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(_servers, activeServerId: 'local')
        ..seedProfileContacts([
          mineruBuilderProfile(
            displayName: 'Mineru',
            latestPreview: 'Ready',
            workspaceRootCount: 1,
            voiceCapability: const NavivoxVoiceCapability(
              deviceStt: 'unavailable',
              disabledReason: 'device STT unavailable',
            ),
          ),
        ], selectedKey: 'local::mineru');
      final voiceService = successfulVoiceCaptureService(
        transcript: 'should not capture',
        duration: const Duration(milliseconds: 500),
        confidence: 0.9,
      );

      await _pumpTrustedChat(
        tester,
        channel: channel,
        voiceService: voiceService,
      );

      await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
      await tester.pumpAndSettle();

      expect(find.text('Voice diagnostics'), findsOneWidget);
      expect(
        find.text('Android recognizer', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(
          'Ready in Navivox; gateway STT status is separate.',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.text('Microphone permission', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(
          'Not denied by Android in this session; checked when capture starts.',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.text('Gateway profile STT', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(
          'Gateway reported device STT unavailable for this profile.',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(channel.sentVoiceTranscripts, isEmpty);
    },
  );

  testWidgets('profile STT disabled reason is canonicalized', (tester) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts([
        mineruBuilderProfile(
          displayName: 'Mineru',
          latestPreview: 'Ready',
          workspaceRootCount: 1,
          voiceCapability: const NavivoxVoiceCapability(
            deviceStt: 'unavailable',
            disabledReason: ' Device STT unavailable ',
            recoveryAction: 'Enable device speech recognition',
          ),
        ),
      ], selectedKey: 'local::mineru');
    final voiceService = successfulVoiceCaptureService(
      transcript: 'should not capture',
      duration: const Duration(milliseconds: 500),
      confidence: 0.9,
    );

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
    );

    expect(
      find.text('Continuous voice unavailable: device STT unavailable'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Continuous voice unavailable: Device STT unavailable',
      ),
      findsNothing,
    );
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets('profile STT canonical reason keeps recovery action', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts([
        mineruBuilderProfile(
          displayName: 'Mineru',
          latestPreview: 'Ready',
          workspaceRootCount: 1,
          voiceCapability: const NavivoxVoiceCapability(
            deviceStt: 'available',
            disabledReason: ' Device STT unavailable ',
            recoveryAction: 'Enable device speech recognition',
          ),
        ),
      ], selectedKey: 'local::mineru');
    final voiceService = successfulVoiceCaptureService(
      transcript: 'should not capture',
      duration: const Duration(milliseconds: 500),
      confidence: 0.9,
    );

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
    );

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pumpAndSettle();

    expect(find.text('Recovery action'), findsOneWidget);
    expect(find.text('Enable device speech recognition'), findsOneWidget);
    expect(
      find.text(
        'Install or enable device speech recognition, then return to Navivox.',
      ),
      findsNothing,
    );
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets(
    'profile STT recovery guidance leaves trust prompt as next blocker',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(_servers, activeServerId: 'local')
        ..seedProfileContacts([
          mineruBuilderProfile(
            displayName: 'Mineru',
            latestPreview: 'Ready',
            workspaceRootCount: 1,
            voiceCapability: const NavivoxVoiceCapability(
              deviceStt: 'unavailable',
              recoveryAction: 'Enable device speech recognition',
            ),
          ),
        ], selectedKey: 'local::mineru');
      final voiceService = successfulVoiceCaptureService(
        transcript: 'capture after trust',
        duration: const Duration(milliseconds: 500),
        confidence: 0.9,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: MaterialApp(
            home: ChatScreen(
              serverId: 'local',
              profileId: 'mineru',
              voiceCaptureServiceOverride: voiceService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Continuous voice unavailable: device STT unavailable'),
        findsNothing,
      );
      expect(
        find.textContaining('Continuous voice unavailable: trust local'),
        findsOneWidget,
      );
      expect(find.text('Trust server'), findsOneWidget);
      expect(channel.sentVoiceTranscripts, isEmpty);
    },
  );

  testWidgets(
    'profile STT unavailable without recovery stays local-STT ready',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(_servers, activeServerId: 'local')
        ..seedProfileContacts([
          mineruBuilderProfile(
            displayName: 'Mineru',
            latestPreview: 'Ready',
            workspaceRootCount: 1,
            voiceCapability: const NavivoxVoiceCapability(
              deviceStt: 'unavailable',
              isReported: true,
            ),
          ),
        ], selectedKey: 'local::mineru');
      final voiceService = successfulVoiceCaptureService(
        transcript: 'local android stt works',
        duration: const Duration(milliseconds: 500),
        confidence: 0.9,
      );

      await _pumpTrustedChat(
        tester,
        channel: channel,
        voiceService: voiceService,
      );

      expect(find.text('Continuous voice ready'), findsOneWidget);
      expect(
        find.text('Continuous voice unavailable: device STT unavailable'),
        findsNothing,
      );
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.mic_off), findsNothing);
      expect(channel.sentVoiceTranscripts, isEmpty);
    },
  );

  testWidgets(
    'profile STT recovery guidance without disabled reason stays local-STT ready',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(_servers, activeServerId: 'local')
        ..seedProfileContacts([
          mineruBuilderProfile(
            displayName: 'Mineru',
            latestPreview: 'Ready',
            workspaceRootCount: 1,
            voiceCapability: const NavivoxVoiceCapability(
              deviceStt: 'unavailable',
              recoveryAction: 'Enable device speech recognition',
            ),
          ),
        ], selectedKey: 'local::mineru');
      final voiceService = successfulVoiceCaptureService(
        transcript: 'local android stt works',
        duration: const Duration(milliseconds: 500),
        confidence: 0.9,
      );

      await _pumpTrustedChat(
        tester,
        channel: channel,
        voiceService: voiceService,
        voiceAutoSendGrace: const Duration(seconds: 5),
      );

      expect(find.text('Continuous voice ready'), findsOneWidget);
      expect(
        find.text('Continuous voice unavailable: device STT unavailable'),
        findsNothing,
      );
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.mic_off), findsNothing);

      await _tapMic(tester);

      expect(
        channel.state.activeVoiceRun?.status,
        NavivoxVoiceRunStatus.pendingSend,
      );
      expect(
        channel.state.activeVoiceRun?.transcript,
        'local android stt works',
      );
      expect(channel.sentVoiceTranscripts, isEmpty);
    },
  );

  testWidgets(
    'profile STT recovery action without disabled reason stays out of ready sheet',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(_servers, activeServerId: 'local')
        ..seedProfileContacts([
          mineruBuilderProfile(
            displayName: 'Mineru',
            latestPreview: 'Ready',
            workspaceRootCount: 1,
            voiceCapability: const NavivoxVoiceCapability(
              deviceStt: 'unavailable',
              recoveryAction: 'Enable device speech recognition',
            ),
          ),
        ], selectedKey: 'local::mineru');
      final voiceService = successfulVoiceCaptureService(
        transcript: 'local android stt works',
        duration: const Duration(milliseconds: 500),
        confidence: 0.9,
      );

      await _pumpTrustedChat(
        tester,
        channel: channel,
        voiceService: voiceService,
      );

      await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
      await tester.pumpAndSettle();

      expect(find.text('Ready for Mineru'), findsOneWidget);
      expect(find.text('Recovery action'), findsNothing);
      expect(find.text('Enable device speech recognition'), findsNothing);
      expect(channel.sentVoiceTranscripts, isEmpty);
    },
  );

  testWidgets('profile STT recovery action appears in unavailable sheet', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts([
        mineruBuilderProfile(
          displayName: 'Mineru',
          latestPreview: 'Ready',
          workspaceRootCount: 1,
          voiceCapability: const NavivoxVoiceCapability(
            deviceStt: 'unavailable',
            disabledReason: 'device STT unavailable',
            recoveryAction: 'Enable device speech recognition',
          ),
        ),
      ], selectedKey: 'local::mineru');
    final voiceService = successfulVoiceCaptureService(
      transcript: 'should not capture',
      duration: const Duration(milliseconds: 500),
      confidence: 0.9,
    );

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
    );

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pumpAndSettle();

    expect(find.text('Recovery action'), findsOneWidget);
    expect(find.text('Enable device speech recognition'), findsOneWidget);
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets('continuous voice unavailable sheet opens voice settings', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const TestRouterApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mineru'));
    await tester.pumpAndSettle();
    _trustLocalServer(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pumpAndSettle();

    expect(find.text('Open voice settings'), findsOneWidget);
    expect(
      find.text(
        'Review continuous voice after enabling device speech recognition.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Open voice settings'));
    await tester.pumpAndSettle();

    expect(find.text('Voice settings'), findsOneWidget);
    expect(find.text('Continuous voice'), findsOneWidget);
    expect(channel.sentTexts, isEmpty);
  });

  testWidgets('STT unavailable mic sheet opens voice settings', (tester) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const TestRouterApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mineru'));
    await tester.pumpAndSettle();
    _trustLocalServer(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byTooltip('Voice unavailable: device STT unavailable'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Voice unavailable'), findsOneWidget);
    expect(find.text('device STT unavailable'), findsOneWidget);
    expect(find.text('Open voice settings'), findsOneWidget);
    expect(
      find.text(
        'Review continuous voice after enabling device speech recognition.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Open voice settings'));
    await tester.pumpAndSettle();

    expect(find.text('Voice settings'), findsOneWidget);
    expect(find.text('Continuous voice'), findsOneWidget);
    expect(channel.sentTexts, isEmpty);
  });

  testWidgets('STT unavailable mic sheet shows profile recovery action', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts([
        mineruBuilderProfile(
          displayName: 'Mineru',
          latestPreview: 'Ready',
          workspaceRootCount: 1,
          voiceCapability: const NavivoxVoiceCapability(
            deviceStt: 'unavailable',
            recoveryAction: 'Enable device speech recognition',
          ),
        ),
      ], selectedKey: 'local::mineru');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const TestRouterApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mineru'));
    await tester.pumpAndSettle();
    _trustLocalServer(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byTooltip('Voice unavailable: device STT unavailable'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recovery action'), findsOneWidget);
    expect(find.text('Enable device speech recognition'), findsOneWidget);
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets('continuous voice ready banner shows live voice affordance', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = successfulVoiceCaptureService(
      transcript: 'hello',
      duration: const Duration(milliseconds: 500),
      confidence: 0.9,
    );

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
    );

    expect(find.text('Continuous voice ready'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('continuous-voice-live-indicator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('continuous-voice-live-dot')),
      findsOneWidget,
    );
    expect(find.text('Slide to cancel'), findsNothing);
  });

  testWidgets('continuous voice banner opens a control sheet', (tester) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = successfulVoiceCaptureService(
      transcript: 'hello',
      duration: const Duration(milliseconds: 500),
      confidence: 0.9,
    );

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
    );

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pumpAndSettle();

    expect(find.text('Continuous voice'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('continuous-voice-control-sheet')),
      findsOneWidget,
    );
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Ready for Mineru'), findsOneWidget);
    expect(
      find.text('Tap the mic to speak. Say “navi” for command mode.'),
      findsOneWidget,
    );
    expect(find.text('Command word'), findsOneWidget);
    expect(find.text('navi'), findsOneWidget);
  });

  testWidgets('continuous voice control sheet exposes pending cancel', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = successfulVoiceCaptureService(
      audio: [1, 2, 3],
      transcript: 'check status',
      duration: const Duration(milliseconds: 900),
      confidence: 0.9,
    );

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
      voiceAutoSendGrace: const Duration(seconds: 5),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Pending voice turn'), findsOneWidget);
    expect(find.textContaining('check status'), findsWidgets);

    await tester.tap(find.text('Cancel pending voice'));
    await tester.pumpAndSettle();

    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(find.textContaining('check status'), findsNothing);
  });

  testWidgets('trusted healthy voice capture shows grace and can cancel', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = successfulVoiceCaptureService(
      audio: [1, 2, 3],
      transcript: 'check status',
      duration: const Duration(milliseconds: 900),
      confidence: 0.9,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          home: ChatScreen(
            serverId: 'local',
            profileId: 'mineru',
            voiceCaptureServiceOverride: voiceService,
            voiceAutoSendGrace: const Duration(milliseconds: 300),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Continuous voice unavailable: trust local'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.mic), findsNothing);

    await tester.tap(find.text('Trust server'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.mic), findsOneWidget);

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Sending...'), findsOneWidget);
    expect(find.textContaining('check status'), findsOneWidget);
    expect(
      channel.state.activeVoiceRun?.status,
      NavivoxVoiceRunStatus.pendingSend,
    );
    expect(channel.state.activeVoiceRun?.transcript, 'check status');
    expect(channel.sentVoiceTranscripts, isEmpty);

    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(
      channel.state.activeVoiceRun?.status,
      NavivoxVoiceRunStatus.cancelled,
    );
    expect(find.textContaining('check status'), findsNothing);
  });

  testWidgets('voice capture timeout records failed Voice run reason', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = ThrowingVoiceCaptureService(
      const VoiceCaptureTimeout(),
    );

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
    );

    await _tapMic(tester);
    await tester.pumpAndSettle();

    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(channel.state.activeVoiceRun?.status, NavivoxVoiceRunStatus.failed);
    expect(channel.state.activeVoiceRun?.reason, 'Voice capture timed out.');
    expect(find.text('Voice capture timed out.'), findsOneWidget);
  });

  testWidgets(
    'default voice readiness disables ready banner when Android has no recognizer',
    (tester) async {
      final channel = _seedChannel(selectedKey: 'local::mineru');
      final voiceService = successfulVoiceCaptureService(
        transcript: 'should not capture',
        duration: const Duration(milliseconds: 500),
        confidence: 0.9,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navivoxChannelProvider.overrideWithValue(channel),
            chatVoiceCaptureServiceProvider.overrideWithValue(voiceService),
            chatVoiceCaptureReadinessProvider.overrideWith(
              (_) async => const VoiceCaptureReadiness.unavailable(
                'device STT unavailable',
              ),
            ),
          ],
          child: const MaterialApp(
            home: ChatScreen(serverId: 'local', profileId: 'mineru'),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChatScreen)),
      );
      container
          .read(navivoxVoiceSettingsProvider.notifier)
          .setServerTrusted('local', true);
      await tester.pumpAndSettle();

      expect(channel.sentVoiceTranscripts, isEmpty);
      expect(
        find.text('Continuous voice unavailable: device STT unavailable'),
        findsOneWidget,
      );
      expect(find.text('Continuous voice ready'), findsNothing);
      expect(find.byIcon(Icons.mic), findsNothing);
      expect(find.byIcon(Icons.mic_off), findsWidgets);
    },
  );

  testWidgets(
    'ready voice diagnostics show microphone prompt before first capture',
    (tester) async {
      final channel = _seedChannel(selectedKey: 'local::mineru');
      final voiceService = successfulVoiceCaptureService(
        transcript: 'ready with prompt',
        duration: const Duration(milliseconds: 500),
        confidence: 0.9,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navivoxChannelProvider.overrideWithValue(channel),
            chatVoiceCaptureServiceProvider.overrideWithValue(voiceService),
            chatVoiceCaptureReadinessProvider.overrideWith(
              (_) async => const VoiceCaptureReadiness.available(
                diagnostics: DeviceSpeechRecognitionDiagnostics(
                  recognitionServiceCount: 1,
                  microphonePermissionGranted: false,
                  recognitionServices: [
                    'com.android.speech/.RecognitionService',
                  ],
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: ChatScreen(serverId: 'local', profileId: 'mineru'),
          ),
        ),
      );
      _trustLocalServer(tester);
      await tester.pumpAndSettle();

      expect(find.text('Continuous voice ready'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
      await tester.pumpAndSettle();

      expect(find.text('Voice diagnostics'), findsOneWidget);
      expect(find.text('Microphone permission'), findsOneWidget);
      expect(
        find.text(
          'Not granted yet. Android may prompt when voice capture starts.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('com.android.speech'), findsNothing);
      expect(find.textContaining('RecognitionService'), findsNothing);
    },
  );

  testWidgets('app resume rechecks default voice readiness', (tester) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = successfulVoiceCaptureService(
      transcript: 'ready after resume',
      duration: const Duration(milliseconds: 500),
      confidence: 0.9,
    );
    var readinessChecks = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          navivoxChannelProvider.overrideWithValue(channel),
          chatVoiceCaptureServiceProvider.overrideWithValue(voiceService),
          chatVoiceCaptureReadinessProvider.overrideWith((_) async {
            readinessChecks += 1;
            if (readinessChecks == 1) {
              return const VoiceCaptureReadiness.unavailable(
                'device STT unavailable',
              );
            }
            return const VoiceCaptureReadiness.available();
          }),
        ],
        child: const MaterialApp(
          home: ChatScreen(serverId: 'local', profileId: 'mineru'),
        ),
      ),
    );
    _trustLocalServer(tester);
    await tester.pumpAndSettle();

    expect(readinessChecks, 1);
    expect(
      find.text('Continuous voice unavailable: device STT unavailable'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.mic), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(readinessChecks, 2);
    expect(find.text('Continuous voice ready'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('runtime device STT failure disables continuous voice', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = ThrowingVoiceCaptureService(
      const DeviceSpeechUnavailable(),
    );

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
    );

    expect(find.text('Continuous voice ready'), findsOneWidget);

    await _tapMic(tester);
    await tester.pumpAndSettle();

    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(channel.state.activeVoiceRun?.status, NavivoxVoiceRunStatus.failed);
    expect(channel.state.activeVoiceRun?.reason, 'device STT unavailable');
    expect(
      find.text('Continuous voice unavailable: device STT unavailable'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.mic), findsNothing);
    expect(find.byIcon(Icons.mic_off), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pumpAndSettle();

    expect(find.text('Recovery action'), findsOneWidget);
    expect(
      find.text(
        'Install or enable device speech recognition, then return to Navivox.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('runtime microphone permission failure gives permission recovery', (
    tester,
  ) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = ThrowingVoiceCaptureService(
      const DeviceSpeechUnavailable('microphone permission denied'),
    );

    await _pumpTrustedChat(
      tester,
      channel: channel,
      voiceService: voiceService,
    );

    await _tapMic(tester);
    await tester.pumpAndSettle();

    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(channel.state.activeVoiceRun?.status, NavivoxVoiceRunStatus.failed);
    expect(
      channel.state.activeVoiceRun?.reason,
      'microphone permission denied',
    );
    expect(
      find.text('Continuous voice unavailable: microphone permission denied'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('continuous-voice-banner')));
    await tester.pumpAndSettle();

    expect(find.text('Recovery action'), findsOneWidget);
    expect(
      find.text(
        'Grant microphone permission in Android App info, then return to Navivox.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('trusted voice capture auto-sends after grace', (tester) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');
    final voiceService = successfulVoiceCaptureService(
      audio: [4, 5, 6],
      transcript: 'summarize workspace',
      duration: const Duration(milliseconds: 1200),
      confidence: 0.88,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          home: ChatScreen(
            serverId: 'local',
            profileId: 'mineru',
            voiceCaptureServiceOverride: voiceService,
            voiceAutoSendGrace: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trust server'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(channel.sentVoiceTranscripts, hasLength(1));
    expect(channel.sentVoiceTranscripts.single, 'summarize workspace');
    expect(
      channel.state.activeVoiceRun?.status,
      NavivoxVoiceRunStatus.submitted,
    );
    expect(channel.state.activeVoiceRun?.transcript, 'summarize workspace');
  });

  testWidgets('typed navi settings opens local voice settings', (tester) async {
    final channel = _seedChannel(selectedKey: 'local::mineru');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const TestRouterApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mineru'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Message Gormes'),
      'navi settings',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Voice settings'), findsOneWidget);
    expect(find.text('Command word'), findsOneWidget);
    expect(channel.sentTexts, isEmpty);
  });
}

TestNavivoxChannel _seedChannel({required String selectedKey}) {
  return TestNavivoxChannel()
    ..seedServers(_servers, activeServerId: selectedKey.split('::').first)
    ..seedProfileContacts(_contacts, selectedKey: selectedKey);
}

void _trustLocalServer(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChatScreen)),
  );
  container
      .read(navivoxVoiceSettingsProvider.notifier)
      .setServerTrusted('local', true);
}

Future<void> _pumpTrustedChat(
  WidgetTester tester, {
  required TestNavivoxChannel channel,
  required VoiceCaptureService voiceService,
  Duration voiceAutoSendGrace = const Duration(milliseconds: 800),
  Duration voiceCommandTimeout = const Duration(seconds: 5),
}) async {
  await tester.pumpWidget(
    TestNavivoxMaterialApp(
      channel: channel,
      home: ChatScreen(
        serverId: 'local',
        profileId: 'mineru',
        voiceCaptureServiceOverride: voiceService,
        voiceAutoSendGrace: voiceAutoSendGrace,
        voiceCommandTimeout: voiceCommandTimeout,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final trustButton = find.text('Trust server');
  if (trustButton.evaluate().isNotEmpty) {
    await tester.tap(trustButton);
  } else {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChatScreen)),
    );
    container
        .read(navivoxVoiceSettingsProvider.notifier)
        .setServerTrusted('local', true);
  }
  await tester.pumpAndSettle();
}

Future<void> _tapMic(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.mic));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

Future<void> _submitText(WidgetTester tester, String text) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Message Gormes'),
    text,
  );
  await tester.tap(find.byIcon(Icons.send));
  await tester.pump();
}
