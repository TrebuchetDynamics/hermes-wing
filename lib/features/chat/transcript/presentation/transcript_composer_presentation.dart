import '../../../../../shared/presentation/voice_unavailable_presentation.dart'
    as voice_unavailable_policy;

enum TranscriptComposerVoiceButtonState { capture, stop, unavailable }

enum TranscriptComposerVoiceSheetRowKind {
  status,
  recoveryAction,
  openVoiceSettings,
}

enum TranscriptComposerVoiceSheetActionKind { openVoiceSettings }

class TranscriptComposerVoiceSheetRowPresentation {
  const TranscriptComposerVoiceSheetRowPresentation({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.actionKind,
  });

  final TranscriptComposerVoiceSheetRowKind kind;
  final String title;
  final String subtitle;
  final TranscriptComposerVoiceSheetActionKind? actionKind;
}

enum TranscriptComposerShareOptionKind {
  uploadFile,
  photoOrVideo,
  workspaceFile,
}

class TranscriptComposerShareOption {
  const TranscriptComposerShareOption({
    required this.kind,
    required this.title,
    required this.subtitle,
  });

  final TranscriptComposerShareOptionKind kind;
  final String title;
  final String subtitle;
}

class TranscriptComposerPresentation {
  const TranscriptComposerPresentation({
    required this.showEmoji,
    required this.voiceAvailable,
    required this.voiceButtonState,
    required this.voiceUnavailableReason,
    required this.voiceRecoveryAction,
    required this.showVoiceSettings,
    required this.shareOptions,
  });

  factory TranscriptComposerPresentation.fromState({
    required bool voiceCaptureAvailable,
    required String? voiceUnavailableReason,
    required String? voiceRecoveryAction,
    required bool canOpenVoiceSettings,
    required bool capturing,
    required bool emojiOpen,
  }) {
    final reason = voice_unavailable_policy.canonicalVoiceUnavailableReason(
      voiceUnavailableReason,
    );
    final voiceAvailable = voiceCaptureAvailable && reason?.isNotEmpty != true;
    return TranscriptComposerPresentation(
      showEmoji: emojiOpen,
      voiceAvailable: voiceAvailable,
      voiceButtonState: voiceAvailable
          ? capturing
                ? TranscriptComposerVoiceButtonState.stop
                : TranscriptComposerVoiceButtonState.capture
          : TranscriptComposerVoiceButtonState.unavailable,
      voiceUnavailableReason: reason,
      voiceRecoveryAction: trimmedOrNull(voiceRecoveryAction),
      showVoiceSettings: canOpenVoiceSettings,
      shareOptions: defaultShareOptions,
    );
  }

  static const defaultMessageHint = 'Message Gormes';
  static const defaultEmojiTooltip = 'Emoji';
  static const defaultAttachTooltip = 'Attach';
  static const defaultShareTitle = 'Share';
  static const defaultVoiceSheetTitle = 'Voice unavailable';
  static const defaultQuickEmoji = ['😀', '👍', '🙏', '🔥', '✅', '👀'];
  static const defaultShareOptions = [
    TranscriptComposerShareOption(
      kind: TranscriptComposerShareOptionKind.uploadFile,
      title: 'Upload file',
      subtitle: 'Attach a local file after upload support is enabled.',
    ),
    TranscriptComposerShareOption(
      kind: TranscriptComposerShareOptionKind.photoOrVideo,
      title: 'Photo or video',
      subtitle: 'Pick media after upload support is enabled.',
    ),
    TranscriptComposerShareOption(
      kind: TranscriptComposerShareOptionKind.workspaceFile,
      title: 'Workspace file',
      subtitle: 'Share a file from the active Gormes workspace.',
    ),
  ];

  final bool showEmoji;
  final bool voiceAvailable;
  final TranscriptComposerVoiceButtonState voiceButtonState;
  final String? voiceUnavailableReason;
  final String? voiceRecoveryAction;
  final bool showVoiceSettings;
  final List<TranscriptComposerShareOption> shareOptions;

  String get messageHint => TranscriptComposerPresentation.defaultMessageHint;
  String get emojiTooltip => TranscriptComposerPresentation.defaultEmojiTooltip;
  String get attachTooltip =>
      TranscriptComposerPresentation.defaultAttachTooltip;
  String get shareTitle => TranscriptComposerPresentation.defaultShareTitle;
  String get voiceSheetTitle =>
      TranscriptComposerPresentation.defaultVoiceSheetTitle;
  List<String> get quickEmoji =>
      TranscriptComposerPresentation.defaultQuickEmoji;

  String? get voiceTooltip {
    if (voiceAvailable) return null;
    final reason = voiceUnavailableReason;
    return reason?.isNotEmpty == true
        ? 'Voice unavailable: $reason'
        : 'Voice unavailable';
  }

  String get voiceUnavailableTitle {
    final reason = voiceUnavailableReason;
    return reason?.isNotEmpty == true
        ? reason!
        : voice_unavailable_policy.deviceSttUnavailableReason;
  }

  String get voiceUnavailableHelpText {
    return voice_unavailable_policy.voiceUnavailableHelpText(
      voiceUnavailableReason,
    );
  }

  String get voiceSettingsSubtitle {
    return voice_unavailable_policy.voiceSettingsSubtitleForUnavailableReason(
      voiceUnavailableReason,
    );
  }

  List<TranscriptComposerVoiceSheetRowPresentation> get voiceSheetRows {
    final rows = <TranscriptComposerVoiceSheetRowPresentation>[
      TranscriptComposerVoiceSheetRowPresentation(
        kind: TranscriptComposerVoiceSheetRowKind.status,
        title: voiceUnavailableTitle,
        subtitle: voiceUnavailableHelpText,
      ),
    ];
    final recoveryAction = voiceRecoveryAction;
    if (recoveryAction != null) {
      rows.add(
        TranscriptComposerVoiceSheetRowPresentation(
          kind: TranscriptComposerVoiceSheetRowKind.recoveryAction,
          title: 'Recovery action',
          subtitle: recoveryAction,
        ),
      );
    }
    if (showVoiceSettings) {
      rows.add(
        TranscriptComposerVoiceSheetRowPresentation(
          kind: TranscriptComposerVoiceSheetRowKind.openVoiceSettings,
          title: 'Open voice settings',
          subtitle: voiceSettingsSubtitle,
          actionKind: TranscriptComposerVoiceSheetActionKind.openVoiceSettings,
        ),
      );
    }
    return rows;
  }

  static String? trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed?.isNotEmpty == true ? trimmed : null;
  }
}
