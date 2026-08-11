enum PocketSpeechModel {
  kitten('Kitten', 'About 26 MB', 26453800, 'English · 1 voice'),
  kokoro('Kokoro', 'About 331 MB', 331147356, 'English + Spanish · 2 voices');

  const PocketSpeechModel(
    this.label,
    this.downloadSize,
    this.downloadBytes,
    this.voiceSummary,
  );

  final String label;
  final String downloadSize;
  final int downloadBytes;
  final String voiceSummary;

  String get downloadSummary => '$downloadSize · $voiceSummary';
}

enum VoiceLanguageMode {
  autoEnglishSpanish('Auto · English + Español', null),
  english('English', 'en-US'),
  spanish('Español', 'es-US');

  const VoiceLanguageMode(this.label, this.localeId);

  final String label;
  final String? localeId;
}

class PocketSpeechVoicePack {
  const PocketSpeechVoicePack({
    required this.model,
    required this.modelPath,
    required this.voicesPath,
  }) : assert(modelPath != ''),
       assert(voicesPath != '');

  final PocketSpeechModel model;
  final String modelPath;
  final String voicesPath;
}

class WingVoiceSettings {
  const WingVoiceSettings({
    this.continuousVoiceEnabled = true,
    this.speakRepliesEnabled = false,
    this.pocketSpeechTtsEnabled = false,
    this.pocketSpeechModel = PocketSpeechModel.kitten,
    this.pocketSpeechVoicePack,
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
  final bool pocketSpeechTtsEnabled;
  final PocketSpeechModel pocketSpeechModel;
  final PocketSpeechVoicePack? pocketSpeechVoicePack;
  final VoiceLanguageMode languageMode;
  bool get pocketSpeechVoicePackReady =>
      pocketSpeechVoicePack?.model == pocketSpeechModel;
  final String commandWord;

  /// Text-to-speech playback rate multiplier; 1.0 is normal speed.
  final double speechRate;

  /// Selected TTS voice name, or null to use the engine default.
  final String? ttsVoiceName;

  WingVoiceSettings copyWith({
    bool? continuousVoiceEnabled,
    bool? speakRepliesEnabled,
    bool? pocketSpeechTtsEnabled,
    PocketSpeechModel? pocketSpeechModel,
    PocketSpeechVoicePack? pocketSpeechVoicePack,
    VoiceLanguageMode? languageMode,
    bool clearPocketSpeechVoicePack = false,
    String? commandWord,
    double? speechRate,
    String? ttsVoiceName,
    bool clearTtsVoiceName = false,
  }) {
    return WingVoiceSettings(
      continuousVoiceEnabled:
          continuousVoiceEnabled ?? this.continuousVoiceEnabled,
      speakRepliesEnabled: speakRepliesEnabled ?? this.speakRepliesEnabled,
      pocketSpeechTtsEnabled:
          pocketSpeechTtsEnabled ?? this.pocketSpeechTtsEnabled,
      pocketSpeechModel: pocketSpeechModel ?? this.pocketSpeechModel,
      pocketSpeechVoicePack: clearPocketSpeechVoicePack
          ? null
          : pocketSpeechVoicePack ?? this.pocketSpeechVoicePack,
      languageMode: languageMode ?? this.languageMode,
      commandWord: commandWord ?? this.commandWord,
      speechRate: speechRate ?? this.speechRate,
      ttsVoiceName: clearTtsVoiceName
          ? null
          : ttsVoiceName ?? this.ttsVoiceName,
    );
  }
}
