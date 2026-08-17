enum VoiceLanguageMode {
  autoEnglishSpanish('Auto · English + Español', null),
  english('English', 'en-US'),
  spanish('Español', 'es-US');

  const VoiceLanguageMode(this.label, this.localeId);

  final String label;
  final String? localeId;
}

class WingVoiceSettings {
  const WingVoiceSettings({
    this.continuousVoiceEnabled = true,
    this.speakRepliesEnabled = false,
    this.languageMode = VoiceLanguageMode.autoEnglishSpanish,
    this.commandWord = 'navi',
    this.speechRate = 1.0,
    this.ttsVoiceName,
  });

  final bool continuousVoiceEnabled;

  /// Opt-in for hands-free continuous voice: when on, assistant replies are
  /// spoken aloud and the next capture re-arms automatically. Off by default so
  /// the app never speaks or re-listens without explicit operator consent.
  final bool speakRepliesEnabled;
  final VoiceLanguageMode languageMode;
  final String commandWord;
  final double speechRate;
  final String? ttsVoiceName;

  WingVoiceSettings copyWith({
    bool? continuousVoiceEnabled,
    bool? speakRepliesEnabled,
    VoiceLanguageMode? languageMode,
    String? commandWord,
    double? speechRate,
    String? ttsVoiceName,
    bool clearTtsVoiceName = false,
  }) {
    return WingVoiceSettings(
      continuousVoiceEnabled:
          continuousVoiceEnabled ?? this.continuousVoiceEnabled,
      speakRepliesEnabled: speakRepliesEnabled ?? this.speakRepliesEnabled,
      languageMode: languageMode ?? this.languageMode,
      commandWord: commandWord ?? this.commandWord,
      speechRate: speechRate ?? this.speechRate,
      ttsVoiceName: clearTtsVoiceName
          ? null
          : ttsVoiceName ?? this.ttsVoiceName,
    );
  }
}
