enum PocketSpeechModel {
  kitten('Kitten', '≈26 MB'),
  kokoro('Kokoro', '≈365 MB');

  const PocketSpeechModel(this.label, this.downloadSize);

  final String label;
  final String downloadSize;
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
    this.commandWord = 'navi',
    this.voiceCommandsEnabled = false,
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
  bool get pocketSpeechVoicePackReady =>
      pocketSpeechVoicePack?.model == pocketSpeechModel;
  final String commandWord;

  /// Opt-in on-device voice-command router (Needle). Off by default so
  /// today's Hermes-only voice path is unchanged unless the operator enables
  /// it explicitly.
  final bool voiceCommandsEnabled;

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
    bool clearPocketSpeechVoicePack = false,
    String? commandWord,
    bool? voiceCommandsEnabled,
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
      commandWord: commandWord ?? this.commandWord,
      voiceCommandsEnabled: voiceCommandsEnabled ?? this.voiceCommandsEnabled,
      speechRate: speechRate ?? this.speechRate,
      ttsVoiceName: clearTtsVoiceName
          ? null
          : ttsVoiceName ?? this.ttsVoiceName,
    );
  }
}
