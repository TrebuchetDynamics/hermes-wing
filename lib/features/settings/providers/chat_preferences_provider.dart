import 'dart:ui' show TextDirection;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WingChatTextDirection {
  auto,
  rtl,
  ltr;

  TextDirection? get forcedDirection => switch (this) {
    auto => null,
    rtl => TextDirection.rtl,
    ltr => TextDirection.ltr,
  };
}

@immutable
class WingChatPreferences {
  const WingChatPreferences({
    this.spellcheckEnabled = true,
    this.transcriptTextScale = 1,
    this.textDirection = WingChatTextDirection.auto,
  });

  final bool spellcheckEnabled;
  final double transcriptTextScale;
  final WingChatTextDirection textDirection;

  WingChatPreferences copyWith({
    bool? spellcheckEnabled,
    double? transcriptTextScale,
    WingChatTextDirection? textDirection,
  }) => WingChatPreferences(
    spellcheckEnabled: spellcheckEnabled ?? this.spellcheckEnabled,
    transcriptTextScale: transcriptTextScale ?? this.transcriptTextScale,
    textDirection: textDirection ?? this.textDirection,
  );
}

class WingChatPreferencesController extends Notifier<WingChatPreferences> {
  static const _keySpellcheckEnabled = 'wing.chat.spellcheck_enabled';
  static const _keyTranscriptTextScale = 'wing.chat.transcript_text_scale';
  static const _keyTextDirection = 'wing.chat.text_direction';
  static const minTranscriptTextScale = 0.5;
  static const maxTranscriptTextScale = 2.5;

  SharedPreferences? _prefs;
  final _mutatedFields = <String>{};
  Future<void> _pendingSave = Future.value();

  @override
  WingChatPreferences build() {
    _loadPrefs();
    return const WingChatPreferences();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      _prefs = prefs;
      state = WingChatPreferences(
        spellcheckEnabled: _mutatedFields.contains(_keySpellcheckEnabled)
            ? state.spellcheckEnabled
            : prefs.getBool(_keySpellcheckEnabled) ?? true,
        transcriptTextScale: _mutatedFields.contains(_keyTranscriptTextScale)
            ? state.transcriptTextScale
            : _boundedTranscriptTextScale(
                prefs.getDouble(_keyTranscriptTextScale) ?? 1,
              ),
        textDirection: _mutatedFields.contains(_keyTextDirection)
            ? state.textDirection
            : switch (prefs.get(_keyTextDirection)) {
                'rtl' => WingChatTextDirection.rtl,
                'ltr' => WingChatTextDirection.ltr,
                _ => WingChatTextDirection.auto,
              },
      );
      if (_mutatedFields.isNotEmpty) _save();
    } catch (_) {
      // A late storage failure must not replace a newer in-memory choice.
    }
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    _pendingSave = _pendingSave.then((_) async {
      if (!ref.mounted) return;
      final snapshot = state;
      try {
        // Write only touched fields; loading or editing direction must preserve
        // unrelated saved values, including a pinch scale pending hydration.
        if (_mutatedFields.contains(_keySpellcheckEnabled)) {
          await prefs.setBool(
            _keySpellcheckEnabled,
            snapshot.spellcheckEnabled,
          );
        }
        if (!ref.mounted) return;
        if (_mutatedFields.contains(_keyTranscriptTextScale)) {
          await prefs.setDouble(
            _keyTranscriptTextScale,
            snapshot.transcriptTextScale,
          );
        }
        if (!ref.mounted) return;
        if (_mutatedFields.contains(_keyTextDirection)) {
          final direction = snapshot.textDirection;
          if (direction == WingChatTextDirection.auto) {
            await prefs.remove(_keyTextDirection);
          } else {
            await prefs.setString(_keyTextDirection, direction.name);
          }
        }
      } catch (_) {
        // The in-memory preference remains usable if persistence is unavailable.
      }
    });
  }

  void setSpellcheckEnabled(bool enabled) {
    _mutatedFields.add(_keySpellcheckEnabled);
    state = state.copyWith(spellcheckEnabled: enabled);
    _save();
  }

  void setTranscriptTextScale(double scale) {
    _mutatedFields.add(_keyTranscriptTextScale);
    state = state.copyWith(
      transcriptTextScale: _boundedTranscriptTextScale(scale),
    );
    _save();
  }

  void setTextDirection(WingChatTextDirection direction) {
    _mutatedFields.add(_keyTextDirection);
    state = state.copyWith(textDirection: direction);
    _save();
  }

  static double _boundedTranscriptTextScale(double scale) =>
      scale.clamp(minTranscriptTextScale, maxTranscriptTextScale).toDouble();
}

final wingChatPreferencesProvider =
    NotifierProvider<WingChatPreferencesController, WingChatPreferences>(
      WingChatPreferencesController.new,
    );
