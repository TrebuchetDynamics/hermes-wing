import '../../../../core/channel/navivox_channel.dart';
import '../../../settings/providers/voice_settings_provider.dart';

enum VoiceReadinessStatus { ready, checking, blocked }

enum VoiceReadinessBlockerKind {
  disabledInSettings,
  selectProfileContact,
  trustGateway,
  deviceSpeechUnavailable,
  microphonePermissionDenied,
  gatewayProfileSttUnavailable,
  profileContactNotOnline,
  profileMicUnavailable,
}

class VoiceReadinessPresentation {
  const VoiceReadinessPresentation._({
    required this.status,
    required this.blockerKind,
    required this.disabledReason,
    required this.recoveryAction,
    required this.localVoiceCaptureAvailable,
    required this.localMicrophonePermissionGranted,
    required this.canTrustServer,
  });

  factory VoiceReadinessPresentation.fromState({
    required NavivoxVoiceSettings settings,
    required NavivoxProfileContact? activeProfile,
    required bool localVoiceCaptureAvailable,
    bool localVoiceCaptureChecking = false,
    String? localVoiceCaptureUnavailableReason,
    bool? localMicrophonePermissionGranted,
    String? runtimeVoiceDisabledReason,
  }) {
    if (!settings.continuousVoiceEnabled) {
      return _blocked(
        VoiceReadinessBlockerKind.disabledInSettings,
        'disabled in Settings',
        localVoiceCaptureAvailable: localVoiceCaptureAvailable,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      );
    }
    if (activeProfile == null) {
      return _blocked(
        VoiceReadinessBlockerKind.selectProfileContact,
        'select a profile contact',
        localVoiceCaptureAvailable: localVoiceCaptureAvailable,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      );
    }
    if (!settings.isTrusted(activeProfile.serverId)) {
      return _blocked(
        VoiceReadinessBlockerKind.trustGateway,
        'trust ${activeProfile.serverLabel}',
        localVoiceCaptureAvailable: localVoiceCaptureAvailable,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
        canTrustServer: true,
      );
    }
    if (localVoiceCaptureChecking) {
      return VoiceReadinessPresentation._(
        status: VoiceReadinessStatus.checking,
        blockerKind: null,
        disabledReason: null,
        recoveryAction: null,
        localVoiceCaptureAvailable: false,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
        canTrustServer: false,
      );
    }

    final runtimeReason = _canonicalReason(runtimeVoiceDisabledReason);
    final localReason = _canonicalReason(localVoiceCaptureUnavailableReason);
    final localBlockerReason = runtimeReason ?? localReason;
    if (!localVoiceCaptureAvailable || localBlockerReason != null) {
      final reason = localBlockerReason ?? 'device STT unavailable';
      return _blocked(
        _deviceBlockerKind(reason),
        reason,
        localVoiceCaptureAvailable: false,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
        recoveryAction: _deviceRecoveryAction(activeProfile, reason),
      );
    }

    final profileVoiceReason = _canonicalReason(
      activeProfile.voiceCapability.captureUnavailableReason,
    );
    if (profileVoiceReason != null) {
      return _blocked(
        VoiceReadinessBlockerKind.gatewayProfileSttUnavailable,
        profileVoiceReason,
        localVoiceCaptureAvailable: true,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
        recoveryAction: _profileRecoveryAction(
          activeProfile,
          profileVoiceReason,
        ),
      );
    }
    if (activeProfile.health != NavivoxProfileHealth.online) {
      return _blocked(
        VoiceReadinessBlockerKind.profileContactNotOnline,
        _profileHealthLabel(activeProfile.health),
        localVoiceCaptureAvailable: true,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      );
    }
    if (!activeProfile.micAvailable) {
      return _blocked(
        VoiceReadinessBlockerKind.profileMicUnavailable,
        'mic unavailable',
        localVoiceCaptureAvailable: true,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      );
    }

    return VoiceReadinessPresentation._(
      status: VoiceReadinessStatus.ready,
      blockerKind: null,
      disabledReason: null,
      recoveryAction: null,
      localVoiceCaptureAvailable: true,
      localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      canTrustServer: false,
    );
  }

  final VoiceReadinessStatus status;
  final VoiceReadinessBlockerKind? blockerKind;
  final String? disabledReason;
  final String? recoveryAction;
  final bool localVoiceCaptureAvailable;
  final bool? localMicrophonePermissionGranted;
  final bool canTrustServer;

  bool get ready => status == VoiceReadinessStatus.ready;
  bool get checking => status == VoiceReadinessStatus.checking;
  bool get blocked => status == VoiceReadinessStatus.blocked;
  bool get canStartVoiceRun => ready;

  bool get showSttDiagnostics {
    return (ready && localMicrophonePermissionGranted == false) ||
        blockerKind == VoiceReadinessBlockerKind.deviceSpeechUnavailable ||
        blockerKind == VoiceReadinessBlockerKind.microphonePermissionDenied ||
        blockerKind == VoiceReadinessBlockerKind.gatewayProfileSttUnavailable;
  }

  String get voiceSettingsSubtitle {
    return blockerKind == VoiceReadinessBlockerKind.deviceSpeechUnavailable ||
            (blockerKind ==
                    VoiceReadinessBlockerKind.gatewayProfileSttUnavailable &&
                disabledReason == 'device STT unavailable')
        ? 'Review continuous voice after enabling device speech recognition.'
        : blockerKind == VoiceReadinessBlockerKind.microphonePermissionDenied
        ? 'Review continuous voice after granting microphone permission.'
        : blockerKind == VoiceReadinessBlockerKind.selectProfileContact
        ? 'Select a profile contact before reviewing continuous voice settings.'
        : 'Review continuous voice and trust settings';
  }

  String get androidRecognizerStatus {
    if (checking) return 'Checking Android speech recognition.';
    return localVoiceCaptureAvailable
        ? 'Ready in Navivox; gateway STT status is separate.'
        : 'No local speech recognizer is active in Navivox.';
  }

  String get microphonePermissionStatus {
    if (blockerKind == VoiceReadinessBlockerKind.microphonePermissionDenied) {
      return 'Denied by Android. Grant microphone permission in App info.';
    }
    if (localMicrophonePermissionGranted == false) {
      return 'Not granted yet. Android may prompt when voice capture starts.';
    }
    return 'Not denied by Android in this session; checked when capture starts.';
  }

  String get gatewayProfileSttStatus {
    if (blockerKind == VoiceReadinessBlockerKind.gatewayProfileSttUnavailable) {
      return 'Gateway reported device STT unavailable for this profile.';
    }
    if (blockerKind == VoiceReadinessBlockerKind.deviceSpeechUnavailable) {
      return 'Gateway profile STT is not checked because Android speech recognition is unavailable.';
    }
    return 'Gateway profile STT is not the current blocker.';
  }

  static VoiceReadinessPresentation _blocked(
    VoiceReadinessBlockerKind blockerKind,
    String disabledReason, {
    required bool localVoiceCaptureAvailable,
    bool? localMicrophonePermissionGranted,
    String? recoveryAction,
    bool canTrustServer = false,
  }) {
    return VoiceReadinessPresentation._(
      status: VoiceReadinessStatus.blocked,
      blockerKind: blockerKind,
      disabledReason: disabledReason,
      recoveryAction: recoveryAction,
      localVoiceCaptureAvailable: localVoiceCaptureAvailable,
      localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      canTrustServer: canTrustServer,
    );
  }

  static VoiceReadinessBlockerKind _deviceBlockerKind(String reason) {
    return reason == 'microphone permission denied'
        ? VoiceReadinessBlockerKind.microphonePermissionDenied
        : VoiceReadinessBlockerKind.deviceSpeechUnavailable;
  }

  static String? _deviceRecoveryAction(
    NavivoxProfileContact profile,
    String reason,
  ) {
    final recoveryAction = profile.voiceCapability.recoveryAction.trim();
    if (reason == 'device STT unavailable' && recoveryAction.isNotEmpty) {
      return recoveryAction;
    }
    return _defaultRecoveryAction(reason);
  }

  static String? _profileRecoveryAction(
    NavivoxProfileContact profile,
    String reason,
  ) {
    final recoveryAction = profile.voiceCapability.recoveryAction.trim();
    if (recoveryAction.isNotEmpty) return recoveryAction;
    return _defaultRecoveryAction(reason);
  }

  static String? _defaultRecoveryAction(String reason) {
    if (reason == 'device STT unavailable') {
      return 'Install or enable device speech recognition, then return to Navivox.';
    }
    if (reason == 'microphone permission denied') {
      return 'Grant microphone permission in Android App info, then return to Navivox.';
    }
    return null;
  }

  static String? _canonicalReason(String? reason) {
    final trimmed = reason?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final normalized = trimmed.toLowerCase();
    if (normalized == 'device stt unavailable') return 'device STT unavailable';
    if (normalized == 'microphone permission denied') {
      return 'microphone permission denied';
    }
    return trimmed;
  }

  static String _profileHealthLabel(NavivoxProfileHealth health) {
    return switch (health) {
      NavivoxProfileHealth.online => 'online',
      NavivoxProfileHealth.offline => 'offline',
      NavivoxProfileHealth.needsAuth => 'auth required',
      NavivoxProfileHealth.warning => 'warning',
    };
  }
}
