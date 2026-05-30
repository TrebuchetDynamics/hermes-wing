import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/chat/voice/presentation/voice_readiness_presentation.dart';
import 'package:navivox/features/settings/providers/voice_settings_provider.dart';

void main() {
  const profile = NavivoxProfileContact(
    serverId: 'local',
    profileId: 'mineru',
    displayName: 'Mineru',
    serverLabel: 'local',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready',
    micAvailable: true,
  );
  const trusted = NavivoxVoiceSettings(trustedServerIds: {'local'});

  test(
    'reports ready when settings, trust, device, and profile allow capture',
    () {
      final readiness = VoiceReadinessPresentation.fromState(
        settings: trusted,
        activeProfile: profile,
        localVoiceCaptureAvailable: true,
      );

      expect(readiness.status, VoiceReadinessStatus.ready);
      expect(readiness.canStartVoiceRun, isTrue);
      expect(readiness.disabledReason, isNull);
      expect(readiness.androidRecognizerStatus, contains('Ready'));
    },
  );

  test('prioritizes local intent and trust before device blockers', () {
    final disabled = VoiceReadinessPresentation.fromState(
      settings: const NavivoxVoiceSettings(
        continuousVoiceEnabled: false,
        trustedServerIds: {'local'},
      ),
      activeProfile: profile,
      localVoiceCaptureAvailable: false,
      localVoiceCaptureUnavailableReason: 'device STT unavailable',
    );
    final noProfile = VoiceReadinessPresentation.fromState(
      settings: trusted,
      activeProfile: null,
      localVoiceCaptureAvailable: false,
      localVoiceCaptureUnavailableReason: 'device STT unavailable',
    );
    final untrusted = VoiceReadinessPresentation.fromState(
      settings: const NavivoxVoiceSettings(),
      activeProfile: profile,
      localVoiceCaptureAvailable: false,
      localVoiceCaptureUnavailableReason: 'device STT unavailable',
    );

    expect(disabled.blockerKind, VoiceReadinessBlockerKind.disabledInSettings);
    expect(disabled.disabledReason, 'disabled in Settings');
    expect(
      noProfile.blockerKind,
      VoiceReadinessBlockerKind.selectProfileContact,
    );
    expect(noProfile.disabledReason, 'select a profile contact');
    expect(untrusted.blockerKind, VoiceReadinessBlockerKind.trustGateway);
    expect(untrusted.disabledReason, 'trust local');
    expect(untrusted.canTrustServer, isTrue);
  });

  test('uses checking state instead of a false unavailable blocker', () {
    final readiness = VoiceReadinessPresentation.fromState(
      settings: trusted,
      activeProfile: profile,
      localVoiceCaptureAvailable: false,
      localVoiceCaptureChecking: true,
    );

    expect(readiness.status, VoiceReadinessStatus.checking);
    expect(readiness.canStartVoiceRun, isFalse);
    expect(readiness.disabledReason, isNull);
    expect(
      readiness.androidRecognizerStatus,
      'Checking Android speech recognition.',
    );
  });

  test('separates device and gateway profile STT blockers', () {
    final device = VoiceReadinessPresentation.fromState(
      settings: trusted,
      activeProfile: profile,
      localVoiceCaptureAvailable: false,
      localVoiceCaptureUnavailableReason: 'device STT unavailable',
    );
    final gatewayProfile = VoiceReadinessPresentation.fromState(
      settings: trusted,
      activeProfile: const NavivoxProfileContact(
        serverId: 'local',
        profileId: 'mineru',
        displayName: 'Mineru',
        serverLabel: 'local',
        health: NavivoxProfileHealth.online,
        latestPreview: 'Ready',
        micAvailable: true,
        voiceCapability: NavivoxVoiceCapability(
          disabledReason: 'device STT unavailable',
          recoveryAction: 'Enable profile STT',
        ),
      ),
      localVoiceCaptureAvailable: true,
    );

    expect(
      device.blockerKind,
      VoiceReadinessBlockerKind.deviceSpeechUnavailable,
    );
    expect(
      device.gatewayProfileSttStatus,
      'Gateway profile STT is not checked because Android speech recognition is unavailable.',
    );
    expect(
      gatewayProfile.blockerKind,
      VoiceReadinessBlockerKind.gatewayProfileSttUnavailable,
    );
    expect(gatewayProfile.recoveryAction, 'Enable profile STT');
    expect(
      gatewayProfile.gatewayProfileSttStatus,
      'Gateway reported device STT unavailable for this profile.',
    );
  });

  test('pre-capture microphone diagnostic does not block readiness', () {
    final readiness = VoiceReadinessPresentation.fromState(
      settings: trusted,
      activeProfile: profile,
      localVoiceCaptureAvailable: true,
      localMicrophonePermissionGranted: false,
    );

    expect(readiness.status, VoiceReadinessStatus.ready);
    expect(readiness.canStartVoiceRun, isTrue);
    expect(readiness.disabledReason, isNull);
    expect(readiness.showSttDiagnostics, isTrue);
    expect(
      readiness.microphonePermissionStatus,
      'Not granted yet. Android may prompt when voice capture starts.',
    );
  });

  test('permission denial has its own recovery and diagnostics', () {
    final readiness = VoiceReadinessPresentation.fromState(
      settings: trusted,
      activeProfile: profile,
      localVoiceCaptureAvailable: true,
      runtimeVoiceDisabledReason: 'microphone permission denied',
    );

    expect(
      readiness.blockerKind,
      VoiceReadinessBlockerKind.microphonePermissionDenied,
    );
    expect(readiness.disabledReason, 'microphone permission denied');
    expect(
      readiness.recoveryAction,
      'Grant microphone permission in Android App info, then return to Navivox.',
    );
    expect(
      readiness.microphonePermissionStatus,
      'Denied by Android. Grant microphone permission in App info.',
    );
  });
}
