class SettingsScreenPresentation {
  const SettingsScreenPresentation();

  String get title => 'Settings';

  String get localSettingsTitle => 'Local settings';

  String get localSettingsSubtitle =>
      'Preferences for this Hermes companion install.';

  String get localVoiceSectionTitle => 'Local voice preferences';

  String get localVoiceSectionSubtitle =>
      'On-device recognition, a local command word, and spoken replies for the foreground Hermes voice loop.';

  String get continuousVoiceTitle => 'Continuous voice';

  String get continuousVoiceSubtitle =>
      'Allow on-device STT transcripts to be sent to Hermes';

  String get speakRepliesTitle => 'Speak replies aloud';

  String get speakRepliesSubtitle =>
      'Remember the foreground chat loop preference';

  String get commandWordTitle => 'Command word';
}
