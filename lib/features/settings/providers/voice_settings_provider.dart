import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/voice/voice_settings.dart';

export '../../../shared/voice/voice_settings.dart';

class NavivoxVoiceSettingsController extends Notifier<NavivoxVoiceSettings> {
  static const _keyVoiceEnabled = 'navivox.voice.continuous_enabled';
  static const _keyProfileSwitch = 'navivox.voice.profile_switching_enabled';
  static const _keySpeakReplies = 'navivox.voice.speak_replies_enabled';
  static const _keyKokoroEnabled = 'navivox.voice.kokoro_tts_enabled';
  static const _keyKokoroModelPath = 'navivox.voice.kokoro_model_path';
  static const _keyKokoroVoicesPath = 'navivox.voice.kokoro_voices_path';
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
      final speakReplies = _prefs?.getBool(_keySpeakReplies) ?? false;
      final kokoroEnabled = _prefs?.getBool(_keyKokoroEnabled) ?? false;
      final kokoroModelPath = _prefs?.getString(_keyKokoroModelPath);
      final kokoroVoicesPath = _prefs?.getString(_keyKokoroVoicesPath);
      final commandWord = _prefs?.getString(_keyCommandWord) ?? 'navi';
      final trustedList = _prefs?.getStringList(_keyTrustedServers) ?? [];
      state = NavivoxVoiceSettings(
        continuousVoiceEnabled: enabled,
        profileSwitchingEnabled: profileSwitch,
        speakRepliesEnabled: speakReplies,
        kokoroTtsEnabled: kokoroEnabled,
        kokoroModelPath: kokoroModelPath,
        kokoroVoicesPath: kokoroVoicesPath,
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
    await prefs.setBool(_keySpeakReplies, state.speakRepliesEnabled);
    await prefs.setBool(_keyKokoroEnabled, state.kokoroTtsEnabled);
    final modelPath = state.kokoroModelPath;
    final voicesPath = state.kokoroVoicesPath;
    if (modelPath == null || modelPath.isEmpty) {
      await prefs.remove(_keyKokoroModelPath);
    } else {
      await prefs.setString(_keyKokoroModelPath, modelPath);
    }
    if (voicesPath == null || voicesPath.isEmpty) {
      await prefs.remove(_keyKokoroVoicesPath);
    } else {
      await prefs.setString(_keyKokoroVoicesPath, voicesPath);
    }
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

  void setSpeakRepliesEnabled(bool enabled) {
    state = state.copyWith(speakRepliesEnabled: enabled);
    _save();
  }

  void setKokoroTtsEnabled(bool enabled) {
    if (enabled && !state.kokoroAssetsReady) return;
    state = state.copyWith(kokoroTtsEnabled: enabled);
    _save();
  }

  void setKokoroAssets({
    required String modelPath,
    required String voicesPath,
  }) {
    final trimmedModel = modelPath.trim();
    final trimmedVoices = voicesPath.trim();
    if (trimmedModel.isEmpty || trimmedVoices.isEmpty) return;
    state = state.copyWith(
      kokoroModelPath: trimmedModel,
      kokoroVoicesPath: trimmedVoices,
    );
    _save();
  }

  void clearKokoroAssets() {
    state = state.copyWith(
      kokoroTtsEnabled: false,
      kokoroModelPath: '',
      kokoroVoicesPath: '',
    );
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
