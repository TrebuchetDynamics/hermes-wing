class SettingsScreenPresentation {
  const SettingsScreenPresentation();

  String get title => 'Settings';

  String get localSettingsTitle => 'Local settings';

  String get localSettingsSubtitle =>
      'Preferences for this Hermes companion install.';

  String get localVoiceSectionTitle => 'Local voice preferences';

  String get localVoiceSectionSubtitle =>
      'Command word, local capture, and spoken replies stay on this device.';

  String get continuousVoiceTitle => 'Continuous voice';

  String get continuousVoiceSubtitle =>
      'Use local device STT to send transcripts to Hermes';

  String get speakRepliesTitle => 'Speak replies aloud';

  String get speakRepliesSubtitle =>
      'Hands-free: speak each reply, then listen again';

  String get commandWordTitle => 'Command word';

  String get profileSwitchingTitle => 'Voice profile switching';

  String get profileSwitchingSubtitle =>
      'Allow local command-word mode switches when available';
}
