import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/voice/voice_settings.dart';

export '../../../shared/voice/voice_settings.dart';

class WingVoiceSettingsController extends Notifier<WingVoiceSettings> {
  static const _keyVoiceEnabled = 'wing.voice.continuous_enabled';
  static const _keySpeakReplies = 'wing.voice.speak_replies_enabled';
  static const _keyCommandWord = 'wing.voice.command_word';
  static const _keyLanguageMode = 'wing.voice.language_mode';

  SharedPreferences? _prefs;
  int _mutationGeneration = 0;

  @override
  WingVoiceSettings build() {
    _loadPrefs();
    return const WingVoiceSettings();
  }

  Future<void> _loadPrefs() async {
    final loadGeneration = _mutationGeneration;
    try {
      _prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      if (loadGeneration != _mutationGeneration) {
        await _save();
        return;
      }
      final savedLanguageMode = _prefs?.getString(_keyLanguageMode);
      state = WingVoiceSettings(
        continuousVoiceEnabled: _prefs?.getBool(_keyVoiceEnabled) ?? true,
        speakRepliesEnabled: _prefs?.getBool(_keySpeakReplies) ?? false,
        commandWord: _prefs?.getString(_keyCommandWord) ?? 'navi',
        languageMode: VoiceLanguageMode.values.firstWhere(
          (candidate) => candidate.name == savedLanguageMode,
          orElse: () => VoiceLanguageMode.autoEnglishSpanish,
        ),
      );
    } catch (_) {
      if (ref.mounted) state = const WingVoiceSettings();
    }
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setBool(_keyVoiceEnabled, state.continuousVoiceEnabled);
      await prefs.setBool(_keySpeakReplies, state.speakRepliesEnabled);
      await prefs.setString(_keyCommandWord, state.commandWord);
      await prefs.setString(_keyLanguageMode, state.languageMode.name);
    } catch (_) {
      // Settings remain usable in memory when platform persistence is down.
    }
  }

  void setContinuousVoiceEnabled(bool enabled) {
    _mutationGeneration += 1;
    state = state.copyWith(continuousVoiceEnabled: enabled);
    _save();
  }

  void setSpeakRepliesEnabled(bool enabled) {
    _mutationGeneration += 1;
    state = state.copyWith(speakRepliesEnabled: enabled);
    _save();
  }

  void setCommandWord(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (normalized.isEmpty) return;
    _mutationGeneration += 1;
    state = state.copyWith(commandWord: normalized);
    _save();
  }

  void setLanguageMode(VoiceLanguageMode mode) {
    _mutationGeneration += 1;
    state = state.copyWith(languageMode: mode);
    _save();
  }
}

final wingVoiceSettingsProvider =
    NotifierProvider<WingVoiceSettingsController, WingVoiceSettings>(
      WingVoiceSettingsController.new,
    );
