import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/wing_theme.dart';

/// The user's local appearance selection: theme mode plus color palette.
@immutable
class WingThemeSettings {
  const WingThemeSettings({
    this.mode = ThemeMode.system,
    this.palette = WingThemePalette.wing,
  });

  final ThemeMode mode;
  final WingThemePalette palette;

  WingThemeSettings copyWith({ThemeMode? mode, WingThemePalette? palette}) =>
      WingThemeSettings(
        mode: mode ?? this.mode,
        palette: palette ?? this.palette,
      );
}

class WingThemeSettingsController extends Notifier<WingThemeSettings> {
  static const _keyMode = 'wing.theme.mode';
  static const _keyPalette = 'wing.theme.palette';

  /// Completes when the persisted selection has been applied.
  late Future<void> loaded;
  int _mutationGeneration = 0;

  @override
  WingThemeSettings build() {
    loaded = _loadPrefs();
    return const WingThemeSettings();
  }

  Future<void> _loadPrefs() async {
    final loadGeneration = _mutationGeneration;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (loadGeneration != _mutationGeneration) return;
      final storedMode = prefs.getString(_keyMode);
      final storedPalette = prefs.getString(_keyPalette);
      state = WingThemeSettings(
        mode: ThemeMode.values.firstWhere(
          (mode) => mode.name == storedMode,
          orElse: () => ThemeMode.system,
        ),
        palette: WingThemePalette.values.firstWhere(
          (palette) => palette.name == storedPalette,
          orElse: () => WingThemePalette.wing,
        ),
      );
    } catch (_) {
      // Unreadable preferences keep the defaults.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _mutationGeneration += 1;
    state = state.copyWith(mode: mode);
    await _save();
  }

  Future<void> setPalette(WingThemePalette palette) async {
    _mutationGeneration += 1;
    state = state.copyWith(palette: palette);
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyMode, state.mode.name);
      await prefs.setString(_keyPalette, state.palette.name);
    } catch (_) {
      // Persistence is best-effort; the in-memory selection still applies.
    }
  }
}

final wingThemeSettingsProvider =
    NotifierProvider<WingThemeSettingsController, WingThemeSettings>(
      WingThemeSettingsController.new,
    );
