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
    this.reasoningCollapsedByDefault = false,
    this.userBubbleTransparency = 0,
    this.isHydrated = true,
  });

  final bool spellcheckEnabled;
  final double transcriptTextScale;
  final WingChatTextDirection textDirection;
  final bool reasoningCollapsedByDefault;
  final int userBubbleTransparency;
  final bool isHydrated;

  WingChatPreferences copyWith({
    bool? spellcheckEnabled,
    double? transcriptTextScale,
    WingChatTextDirection? textDirection,
    bool? reasoningCollapsedByDefault,
    int? userBubbleTransparency,
    bool? isHydrated,
  }) => WingChatPreferences(
    spellcheckEnabled: spellcheckEnabled ?? this.spellcheckEnabled,
    transcriptTextScale: transcriptTextScale ?? this.transcriptTextScale,
    textDirection: textDirection ?? this.textDirection,
    userBubbleTransparency:
        userBubbleTransparency ?? this.userBubbleTransparency,
    isHydrated: isHydrated ?? this.isHydrated,
    reasoningCollapsedByDefault:
        reasoningCollapsedByDefault ?? this.reasoningCollapsedByDefault,
  );
}

class WingChatPreferencesController extends Notifier<WingChatPreferences> {
  static const _keySpellcheckEnabled = 'wing.chat.spellcheck_enabled';
  static const _keyTranscriptTextScale = 'wing.chat.transcript_text_scale';
  static const _keyTextDirection = 'wing.chat.text_direction';
  static const _keyReasoningCollapsed =
      'wing.chat.reasoning_collapsed_by_default';
  static const _keyUserBubbleTransparency =
      'wing.chat.user_bubble_transparency';
  static const minTranscriptTextScale = 0.5;
  static const maxTranscriptTextScale = 2.5;

  SharedPreferences? _prefs;
  final _mutatedFields = <String>{};
  Future<void> _pendingSave = Future.value();

  @override
  WingChatPreferences build() {
    _loadPrefs();
    return const WingChatPreferences(isHydrated: false);
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
        reasoningCollapsedByDefault:
            _mutatedFields.contains(_keyReasoningCollapsed)
            ? state.reasoningCollapsedByDefault
            : prefs.get(_keyReasoningCollapsed) == true,
        userBubbleTransparency:
            _mutatedFields.contains(_keyUserBubbleTransparency)
            ? state.userBubbleTransparency
            : _boundedUserBubbleTransparency(
                prefs.get(_keyUserBubbleTransparency),
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
      if (ref.mounted) state = state.copyWith(isHydrated: true);
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
        if (_mutatedFields.contains(_keyReasoningCollapsed)) {
          await prefs.setBool(
            _keyReasoningCollapsed,
            snapshot.reasoningCollapsedByDefault,
          );
        }
        if (!ref.mounted) return;
        if (_mutatedFields.contains(_keyUserBubbleTransparency)) {
          if (snapshot.userBubbleTransparency == 0) {
            await prefs.remove(_keyUserBubbleTransparency);
          } else {
            await prefs.setInt(
              _keyUserBubbleTransparency,
              snapshot.userBubbleTransparency,
            );
          }
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

  void setReasoningCollapsedByDefault(bool collapsed) {
    _mutatedFields.add(_keyReasoningCollapsed);
    state = state.copyWith(reasoningCollapsedByDefault: collapsed);
    _save();
  }

  void setUserBubbleTransparency(double value) {
    _mutatedFields.add(_keyUserBubbleTransparency);
    state = state.copyWith(
      userBubbleTransparency: _boundedUserBubbleTransparency(value),
    );
    _save();
  }

  static int _boundedUserBubbleTransparency(Object? value) =>
      value is num && value.isFinite ? value.round().clamp(0, 100) : 0;

  static double _boundedTranscriptTextScale(double scale) =>
      scale.clamp(minTranscriptTextScale, maxTranscriptTextScale).toDouble();
}

final wingChatPreferencesProvider =
    NotifierProvider<WingChatPreferencesController, WingChatPreferences>(
      WingChatPreferencesController.new,
    );
