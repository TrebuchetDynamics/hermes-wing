import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavivoxVoiceSettings {
  const NavivoxVoiceSettings({
    this.continuousVoiceEnabled = true,
    this.profileSwitchingEnabled = true,
    this.commandWord = 'navi',
    this.trustedServerIds = const {},
  });

  final bool continuousVoiceEnabled;
  final bool profileSwitchingEnabled;
  final String commandWord;
  final Set<String> trustedServerIds;

  bool isTrusted(String serverId) => trustedServerIds.contains(serverId);

  NavivoxVoiceSettings copyWith({
    bool? continuousVoiceEnabled,
    bool? profileSwitchingEnabled,
    String? commandWord,
    Set<String>? trustedServerIds,
  }) {
    return NavivoxVoiceSettings(
      continuousVoiceEnabled:
          continuousVoiceEnabled ?? this.continuousVoiceEnabled,
      profileSwitchingEnabled:
          profileSwitchingEnabled ?? this.profileSwitchingEnabled,
      commandWord: commandWord ?? this.commandWord,
      trustedServerIds: trustedServerIds ?? this.trustedServerIds,
    );
  }
}

class NavivoxVoiceSettingsController extends Notifier<NavivoxVoiceSettings> {
  static const _keyVoiceEnabled = 'navivox.voice.continuous_enabled';
  static const _keyProfileSwitch = 'navivox.voice.profile_switching_enabled';
  static const _keyCommandWord = 'navivox.voice.command_word';
  static const _keyTrustedServers = 'navivox.voice.trusted_server_ids';

  SharedPreferences? _prefs;

  @override
  NavivoxVoiceSettings build() {
    _loadPrefs();
    return const NavivoxVoiceSettings();
  }

  Future<void> _loadPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final enabled = _prefs?.getBool(_keyVoiceEnabled) ?? true;
      final profileSwitch = _prefs?.getBool(_keyProfileSwitch) ?? true;
      final commandWord = _prefs?.getString(_keyCommandWord) ?? 'navi';
      final trustedList = _prefs?.getStringList(_keyTrustedServers) ?? [];
      state = NavivoxVoiceSettings(
        continuousVoiceEnabled: enabled,
        profileSwitchingEnabled: profileSwitch,
        commandWord: commandWord,
        trustedServerIds: trustedList.toSet(),
      );
    } catch (_) {
      state = const NavivoxVoiceSettings();
    }
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_keyVoiceEnabled, state.continuousVoiceEnabled);
    await prefs.setBool(_keyProfileSwitch, state.profileSwitchingEnabled);
    await prefs.setString(_keyCommandWord, state.commandWord);
    await prefs.setStringList(
      _keyTrustedServers,
      state.trustedServerIds.toList(),
    );
  }

  void setContinuousVoiceEnabled(bool enabled) {
    state = state.copyWith(continuousVoiceEnabled: enabled);
    _save();
  }

  void setProfileSwitchingEnabled(bool enabled) {
    state = state.copyWith(profileSwitchingEnabled: enabled);
    _save();
  }

  void setCommandWord(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty || normalized.contains(RegExp(r'\s'))) return;
    state = state.copyWith(commandWord: normalized);
    _save();
  }

  void setServerTrusted(String serverId, bool trusted) {
    final trimmed = serverId.trim();
    if (trimmed.isEmpty) return;
    final next = {...state.trustedServerIds};
    if (trusted) {
      next.add(trimmed);
    } else {
      next.remove(trimmed);
    }
    state = state.copyWith(trustedServerIds: next);
    _save();
  }
}

final navivoxVoiceSettingsProvider =
    NotifierProvider<NavivoxVoiceSettingsController, NavivoxVoiceSettings>(
      NavivoxVoiceSettingsController.new,
    );
