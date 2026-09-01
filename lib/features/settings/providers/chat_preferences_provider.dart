import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class WingChatPreferences {
  const WingChatPreferences({
    this.spellcheckEnabled = true,
    this.transcriptTextScale = 1,
  });

  final bool spellcheckEnabled;
  final double transcriptTextScale;

  WingChatPreferences copyWith({
    bool? spellcheckEnabled,
    double? transcriptTextScale,
  }) => WingChatPreferences(
    spellcheckEnabled: spellcheckEnabled ?? this.spellcheckEnabled,
    transcriptTextScale: transcriptTextScale ?? this.transcriptTextScale,
  );
}

class WingChatPreferencesController extends Notifier<WingChatPreferences> {
  static const _keySpellcheckEnabled = 'wing.chat.spellcheck_enabled';
  static const _keyTranscriptTextScale = 'wing.chat.transcript_text_scale';
  static const minTranscriptTextScale = 0.5;
  static const maxTranscriptTextScale = 2.5;

  SharedPreferences? _prefs;
  int _mutationGeneration = 0;

  @override
  WingChatPreferences build() {
    _loadPrefs();
    return const WingChatPreferences();
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
      state = WingChatPreferences(
        spellcheckEnabled: _prefs?.getBool(_keySpellcheckEnabled) ?? true,
        transcriptTextScale: _boundedTranscriptTextScale(
          _prefs?.getDouble(_keyTranscriptTextScale) ?? 1,
        ),
      );
    } catch (_) {
      if (ref.mounted) state = const WingChatPreferences();
    }
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setBool(_keySpellcheckEnabled, state.spellcheckEnabled);
      await prefs.setDouble(_keyTranscriptTextScale, state.transcriptTextScale);
    } catch (_) {
      // The in-memory preference remains usable if persistence is unavailable.
    }
  }

  void setSpellcheckEnabled(bool enabled) {
    _mutationGeneration += 1;
    state = state.copyWith(spellcheckEnabled: enabled);
    _save();
  }

  void setTranscriptTextScale(double scale) {
    _mutationGeneration += 1;
    state = state.copyWith(
      transcriptTextScale: _boundedTranscriptTextScale(scale),
    );
    _save();
  }

  static double _boundedTranscriptTextScale(double scale) =>
      scale.clamp(minTranscriptTextScale, maxTranscriptTextScale).toDouble();
}

final wingChatPreferencesProvider =
    NotifierProvider<WingChatPreferencesController, WingChatPreferences>(
      WingChatPreferencesController.new,
    );
