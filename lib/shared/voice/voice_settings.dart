enum VoiceLanguageMode {
  // Keep the legacy enum name because settings persist enum.name.
  autoEnglishSpanish('Automatic · device recognizer', null),
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
    this.completionSoundEnabled = false,
    this.languageMode = VoiceLanguageMode.autoEnglishSpanish,
    this.commandWord = 'navi',
  });

  final bool continuousVoiceEnabled;

  /// Opt-in for hands-free continuous voice: when on, assistant replies are
  /// spoken aloud and the next capture re-arms automatically. Off by default so
  /// the app never speaks or re-listens without explicit operator consent.
  final bool speakRepliesEnabled;

  /// Opt-in alert after a reply finishes. Text and accessibility status remain
  /// authoritative because sound is never the only completion signal.
  final bool completionSoundEnabled;
  final VoiceLanguageMode languageMode;
  final String commandWord;

  WingVoiceSettings copyWith({
    bool? continuousVoiceEnabled,
    bool? speakRepliesEnabled,
    bool? completionSoundEnabled,
    VoiceLanguageMode? languageMode,
    String? commandWord,
  }) {
    return WingVoiceSettings(
      continuousVoiceEnabled:
          continuousVoiceEnabled ?? this.continuousVoiceEnabled,
      speakRepliesEnabled: speakRepliesEnabled ?? this.speakRepliesEnabled,
      completionSoundEnabled:
          completionSoundEnabled ?? this.completionSoundEnabled,
      languageMode: languageMode ?? this.languageMode,
      commandWord: commandWord ?? this.commandWord,
    );
  }
}
