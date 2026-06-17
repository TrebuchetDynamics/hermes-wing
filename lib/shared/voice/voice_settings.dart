class NavivoxVoiceSettings {
  const NavivoxVoiceSettings({
    this.continuousVoiceEnabled = true,
    this.profileSwitchingEnabled = true,
    this.speakRepliesEnabled = false,
    this.commandWord = 'navi',
    this.trustedServerIds = const {},
  });

  final bool continuousVoiceEnabled;
  final bool profileSwitchingEnabled;

  /// Opt-in for hands-free continuous voice: when on, assistant replies are
  /// spoken aloud and the next capture re-arms automatically. Off by default so
  /// the app never speaks or re-listens without explicit operator consent.
  final bool speakRepliesEnabled;
  final String commandWord;
  final Set<String> trustedServerIds;

  bool isTrusted(String serverId) => trustedServerIds.contains(serverId);

  NavivoxVoiceSettings copyWith({
    bool? continuousVoiceEnabled,
    bool? profileSwitchingEnabled,
    bool? speakRepliesEnabled,
    String? commandWord,
    Set<String>? trustedServerIds,
  }) {
    return NavivoxVoiceSettings(
      continuousVoiceEnabled:
          continuousVoiceEnabled ?? this.continuousVoiceEnabled,
      profileSwitchingEnabled:
          profileSwitchingEnabled ?? this.profileSwitchingEnabled,
      speakRepliesEnabled: speakRepliesEnabled ?? this.speakRepliesEnabled,
      commandWord: commandWord ?? this.commandWord,
      trustedServerIds: trustedServerIds ?? this.trustedServerIds,
    );
  }
}
