import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/voice/voice_settings.dart';
import '../../../shared/voice/text_to_speech_service.dart';

export '../../../shared/voice/voice_settings.dart';

final class OfflineTtsRuntimeOwner {
  TextToSpeechService? _current;
  bool _currentOwnsOfflineModels = false;
  Future<void> _releaseBarrier = Future<void>.value();

  Future<void> adopt(
    TextToSpeechService service, {
    bool ownsOfflineModels = false,
  }) {
    if (identical(_current, service)) return _releaseBarrier;
    final previous = _current;
    _current = service;
    _currentOwnsOfflineModels = ownsOfflineModels;
    if (previous != null) _queueRelease(previous);
    return _releaseBarrier;
  }

  Future<void> release(TextToSpeechService service) {
    if (!identical(_current, service)) return _releaseBarrier;
    _current = null;
    _currentOwnsOfflineModels = false;
    _queueRelease(service);
    return _releaseBarrier;
  }

  Future<void> releaseAll() {
    final current = _current;
    _current = null;
    _currentOwnsOfflineModels = false;
    if (current != null) _queueRelease(current);
    return _releaseBarrier;
  }

  Future<void> releaseOfflineModels() {
    if (!_currentOwnsOfflineModels) return _releaseBarrier;
    return releaseAll();
  }

  void _queueRelease(TextToSpeechService service) {
    _releaseBarrier = _releaseBarrier.then(
      (_) => Future<void>.sync(service.dispose),
    );
  }
}

final offlineTtsRuntimeOwnerProvider = Provider<OfflineTtsRuntimeOwner>(
  (_) => OfflineTtsRuntimeOwner(),
);

final class ReleaseBarrierTextToSpeechService implements TextToSpeechService {
  ReleaseBarrierTextToSpeechService(this._delegate, this._predecessorRelease);

  final TextToSpeechService _delegate;
  final Future<void> _predecessorRelease;

  @override
  Future<void> speak(String text) async {
    await _predecessorRelease;
    await _delegate.speak(text);
  }

  @override
  Future<void> stop() async {
    await _predecessorRelease;
    await _delegate.stop();
  }

  @override
  Future<void> dispose() async {
    await _predecessorRelease;
    await _delegate.dispose();
  }
}

class WingVoiceSettingsController extends Notifier<WingVoiceSettings> {
  static const _keyVoiceEnabled = 'wing.voice.continuous_enabled';
  static const _keySpeakReplies = 'wing.voice.speak_replies_enabled';
  // Keep legacy key values so existing Kokoro installs migrate in place.
  static const _keyPocketSpeechEnabled = 'wing.voice.kokoro_tts_enabled';
  static const _keyPocketSpeechModel = 'wing.voice.pocket_speech_model';
  static const _keyModelPath = 'wing.voice.kokoro_model_path';
  static const _keyVoicesPath = 'wing.voice.kokoro_voices_path';
  static const _keyCommandWord = 'wing.voice.command_word';
  static const _keySpeechRate = 'tts_speech_rate';
  static const _keyTtsVoiceName = 'tts_voice_name';
  static const _keyLanguageMode = 'wing.voice.language_mode';

  SharedPreferences? _prefs;
  final _voicePacks = <PocketSpeechModel, PocketSpeechVoicePack>{};
  int _mutationGeneration = 0;

  static String _modelPathKey(PocketSpeechModel model) =>
      'wing.voice.pocket_speech_${model.name}_model_path';
  static String _voicesPathKey(PocketSpeechModel model) =>
      'wing.voice.pocket_speech_${model.name}_voices_path';

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
      _voicePacks.clear();
      for (final candidate in PocketSpeechModel.values) {
        final savedModelPath = _prefs?.getString(_modelPathKey(candidate));
        final savedVoicesPath = _prefs?.getString(_voicesPathKey(candidate));
        if (savedModelPath?.isNotEmpty == true &&
            savedVoicesPath?.isNotEmpty == true) {
          _voicePacks[candidate] = PocketSpeechVoicePack(
            model: candidate,
            modelPath: savedModelPath!,
            voicesPath: savedVoicesPath!,
          );
        }
      }
      if (modelPath?.isNotEmpty == true && voicesPath?.isNotEmpty == true) {
        _voicePacks.putIfAbsent(
          model,
          () => PocketSpeechVoicePack(
            model: model,
            modelPath: modelPath!,
            voicesPath: voicesPath!,
          ),
        );
      }
      final commandWord = _prefs?.getString(_keyCommandWord) ?? 'navi';
      final speechRate = _prefs?.getDouble(_keySpeechRate) ?? 1.0;
      final ttsVoiceName = _prefs?.getString(_keyTtsVoiceName);
      final savedLanguageMode = _prefs?.getString(_keyLanguageMode);
      final languageMode = VoiceLanguageMode.values.firstWhere(
        (candidate) => candidate.name == savedLanguageMode,
        orElse: () => VoiceLanguageMode.autoEnglishSpanish,
      );
      state = WingVoiceSettings(
        continuousVoiceEnabled: enabled,
        speakRepliesEnabled: speakReplies,
        pocketSpeechTtsEnabled:
            pocketSpeechEnabled && _voicePacks.containsKey(model),
        pocketSpeechModel: model,
        pocketSpeechVoicePack: _voicePacks[model],
        commandWord: commandWord,
        speechRate: speechRate,
        ttsVoiceName: ttsVoiceName,
        languageMode: languageMode,
      );
    } catch (_) {
      if (ref.mounted) state = const WingVoiceSettings();
    }
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final settings = state;
    final voicePacks = Map.of(_voicePacks);
    try {
      await prefs.setBool(_keyVoiceEnabled, settings.continuousVoiceEnabled);
      await prefs.setBool(_keySpeakReplies, settings.speakRepliesEnabled);
      await prefs.setBool(
        _keyPocketSpeechEnabled,
        settings.pocketSpeechTtsEnabled,
      );
      await prefs.setString(
        _keyPocketSpeechModel,
        settings.pocketSpeechModel.name,
      );
      final voicePack = settings.pocketSpeechVoicePack;
      if (voicePack == null) {
        await prefs.remove(_keyModelPath);
        await prefs.remove(_keyVoicesPath);
      } else {
        await prefs.setString(_keyModelPath, voicePack.modelPath);
        await prefs.setString(_keyVoicesPath, voicePack.voicesPath);
      }
      for (final model in PocketSpeechModel.values) {
        final savedVoicePack = voicePacks[model];
        if (savedVoicePack == null) {
          await prefs.remove(_modelPathKey(model));
          await prefs.remove(_voicesPathKey(model));
        } else {
          await prefs.setString(_modelPathKey(model), savedVoicePack.modelPath);
          await prefs.setString(
            _voicesPathKey(model),
            savedVoicePack.voicesPath,
          );
        }
      }
      await prefs.setString(_keyCommandWord, settings.commandWord);
      await prefs.setDouble(_keySpeechRate, settings.speechRate);
      final ttsVoiceName = settings.ttsVoiceName;
      if (ttsVoiceName == null) {
        await prefs.remove(_keyTtsVoiceName);
      } else {
        await prefs.setString(_keyTtsVoiceName, ttsVoiceName);
      }
      await prefs.setString(_keyLanguageMode, settings.languageMode.name);
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

  void setPocketSpeechTtsEnabled(bool enabled) {
    if (enabled && !state.pocketSpeechVoicePackReady) return;
    _mutationGeneration += 1;
    state = state.copyWith(pocketSpeechTtsEnabled: enabled);
    _save();
  }

  void setPocketSpeechModel(PocketSpeechModel model) {
    if (model == state.pocketSpeechModel) return;
    _mutationGeneration += 1;
    final voicePack = _voicePacks[model];
    state = state.copyWith(
      pocketSpeechModel: model,
      pocketSpeechTtsEnabled: false,
      pocketSpeechVoicePack: voicePack,
      clearPocketSpeechVoicePack: voicePack == null,
      clearTtsVoiceName: true,
    );
    _save();
  }

  void setPocketSpeechVoicePack(PocketSpeechVoicePack voicePack) {
    _mutationGeneration += 1;
    _voicePacks[voicePack.model] = voicePack;
    final modelChanged = voicePack.model != state.pocketSpeechModel;
    state = state.copyWith(
      pocketSpeechModel: voicePack.model,
      pocketSpeechVoicePack: voicePack,
      clearTtsVoiceName: modelChanged,
    );
    _save();
  }

  void clearPocketSpeechVoicePack(PocketSpeechModel model) {
    _mutationGeneration += 1;
    _voicePacks.remove(model);
    if (model == state.pocketSpeechModel) {
      state = state.copyWith(
        pocketSpeechTtsEnabled: false,
        clearPocketSpeechVoicePack: true,
        clearTtsVoiceName: true,
      );
    }
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
