import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/voice/voice_settings.dart';

export '../../../shared/voice/voice_settings.dart';

class WingVoiceSettingsController extends Notifier<WingVoiceSettings> {
  static const _keyVoiceEnabled = 'wing.voice.continuous_enabled';
  static const _keySpeakReplies = 'wing.voice.speak_replies_enabled';
  // Keep legacy key values so existing Kokoro installs migrate in place.
  static const _keyPocketSpeechEnabled = 'wing.voice.kokoro_tts_enabled';
  static const _keyPocketSpeechModel = 'wing.voice.pocket_speech_model';
  static const _keyModelPath = 'wing.voice.kokoro_model_path';
  static const _keyVoicesPath = 'wing.voice.kokoro_voices_path';
  static const _keyCommandWord = 'wing.voice.command_word';
  static const _keyVoiceCommandsEnabled = 'voice_commands_enabled';
  static const _keySpeechRate = 'tts_speech_rate';
  static const _keyTtsVoiceName = 'tts_voice_name';

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
      if (loadGeneration != _mutationGeneration) {
        await _save();
        return;
      }
      final enabled = _prefs?.getBool(_keyVoiceEnabled) ?? true;
      final speakReplies = _prefs?.getBool(_keySpeakReplies) ?? false;
      final pocketSpeechEnabled =
          _prefs?.getBool(_keyPocketSpeechEnabled) ?? false;
      final modelPath = _prefs?.getString(_keyModelPath);
      final voicesPath = _prefs?.getString(_keyVoicesPath);
      final savedModel = _prefs?.getString(_keyPocketSpeechModel);
      final model = PocketSpeechModel.values.firstWhere(
        (candidate) => candidate.name == savedModel,
        // Existing path-only settings came from the Kokoro-only integration.
        orElse: () => modelPath?.isNotEmpty == true
            ? PocketSpeechModel.kokoro
            : PocketSpeechModel.kitten,
      );
      final voicePack =
          modelPath?.isNotEmpty == true && voicesPath?.isNotEmpty == true
          ? PocketSpeechVoicePack(
              model: model,
              modelPath: modelPath!,
              voicesPath: voicesPath!,
            )
          : null;
      final commandWord = _prefs?.getString(_keyCommandWord) ?? 'navi';
      final voiceCommandsEnabled =
          _prefs?.getBool(_keyVoiceCommandsEnabled) ?? false;
      final speechRate = _prefs?.getDouble(_keySpeechRate) ?? 1.0;
      final ttsVoiceName = _prefs?.getString(_keyTtsVoiceName);
      state = WingVoiceSettings(
        continuousVoiceEnabled: enabled,
        speakRepliesEnabled: speakReplies,
        pocketSpeechTtsEnabled: pocketSpeechEnabled,
        pocketSpeechModel: model,
        pocketSpeechVoicePack: voicePack,
        commandWord: commandWord,
        voiceCommandsEnabled: voiceCommandsEnabled,
        speechRate: speechRate,
        ttsVoiceName: ttsVoiceName,
      );
    } catch (_) {
      state = const WingVoiceSettings();
    }
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_keyVoiceEnabled, state.continuousVoiceEnabled);
    await prefs.setBool(_keySpeakReplies, state.speakRepliesEnabled);
    await prefs.setBool(_keyPocketSpeechEnabled, state.pocketSpeechTtsEnabled);
    await prefs.setString(_keyPocketSpeechModel, state.pocketSpeechModel.name);
    final voicePack = state.pocketSpeechVoicePack;
    if (voicePack == null) {
      await prefs.remove(_keyModelPath);
      await prefs.remove(_keyVoicesPath);
    } else {
      await prefs.setString(_keyModelPath, voicePack.modelPath);
      await prefs.setString(_keyVoicesPath, voicePack.voicesPath);
    }
    await prefs.setString(_keyCommandWord, state.commandWord);
    await prefs.setBool(_keyVoiceCommandsEnabled, state.voiceCommandsEnabled);
    await prefs.setDouble(_keySpeechRate, state.speechRate);
    final ttsVoiceName = state.ttsVoiceName;
    if (ttsVoiceName == null) {
      await prefs.remove(_keyTtsVoiceName);
    } else {
      await prefs.setString(_keyTtsVoiceName, ttsVoiceName);
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

  void setPocketSpeechTtsEnabled(bool enabled) {
    if (enabled && !state.pocketSpeechVoicePackReady) return;
    _mutationGeneration += 1;
    state = state.copyWith(pocketSpeechTtsEnabled: enabled);
    _save();
  }

  void setPocketSpeechModel(PocketSpeechModel model) {
    if (model == state.pocketSpeechModel) return;
    _mutationGeneration += 1;
    state = state.copyWith(
      pocketSpeechModel: model,
      pocketSpeechTtsEnabled: false,
      clearPocketSpeechVoicePack: true,
    );
    _save();
  }

  void setPocketSpeechVoicePack(PocketSpeechVoicePack voicePack) {
    _mutationGeneration += 1;
    state = state.copyWith(
      pocketSpeechModel: voicePack.model,
      pocketSpeechVoicePack: voicePack,
    );
    _save();
  }

  void clearPocketSpeechVoicePack() {
    _mutationGeneration += 1;
    state = state.copyWith(
      pocketSpeechTtsEnabled: false,
      clearPocketSpeechVoicePack: true,
    );
    _save();
  }

  void setCommandWord(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty || normalized.contains(RegExp(r'\s'))) return;
    _mutationGeneration += 1;
    state = state.copyWith(commandWord: normalized);
    _save();
  }

  void setVoiceCommandsEnabled(bool enabled) {
    _mutationGeneration += 1;
    state = state.copyWith(voiceCommandsEnabled: enabled);
    _save();
  }

  void setSpeechRate(double rate) {
    _mutationGeneration += 1;
    state = state.copyWith(speechRate: rate.clamp(0.25, 3.0));
    _save();
  }

  void setTtsVoiceName(String? name) {
    _mutationGeneration += 1;
    state = state.copyWith(ttsVoiceName: name, clearTtsVoiceName: name == null);
    _save();
  }
}

final wingVoiceSettingsProvider =
    NotifierProvider<WingVoiceSettingsController, WingVoiceSettings>(
      WingVoiceSettingsController.new,
    );
