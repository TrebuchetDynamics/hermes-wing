import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local presentation only; contains no Agent, profile or connection identity.
class WingShellPreferencesController extends Notifier<bool> {
  WingShellPreferencesController({
    Future<SharedPreferences> Function()? loadPreferences,
  }) : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance;

  static const _sidebarExpandedKey = 'wing.shell.sidebar_expanded';

  final Future<SharedPreferences> Function() _loadPreferences;
  late Future<void> loaded;
  SharedPreferences? _preferences;
  bool _changedSinceLoad = false;
  Future<void> _pendingWrite = Future<void>.value();

  @override
  bool build() {
    loaded = _load();
    return true;
  }

  Future<void> _load() async {
    try {
      _preferences = await _loadPreferences();
      if (ref.mounted && !_changedSinceLoad) {
        state = _preferences!.getBool(_sidebarExpandedKey) ?? true;
      }
    } catch (_) {
      // Unavailable storage leaves the in-memory choice usable.
    }
  }

  Future<void> setSidebarExpanded(bool expanded) async {
    _changedSinceLoad = true;
    state = expanded;
    await loaded;
    // Preserve interaction order even when platform writes finish slowly.
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await _preferences?.setBool(_sidebarExpandedKey, expanded);
      } catch (_) {
        // Persistence is best-effort, never an Agent mutation.
      }
    });
    await _pendingWrite;
  }
}

enum WingSessionListDensity { compact, comfortable, detailed }

/// Install-local sidebar context only; never reads or mutates Agent state.
class WingSessionListDensityController
    extends Notifier<WingSessionListDensity> {
  WingSessionListDensityController({
    Future<SharedPreferences> Function()? loadPreferences,
  }) : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance;

  static const _key = 'wing.shell.session_list_density';
  final Future<SharedPreferences> Function() _loadPreferences;
  late Future<void> loaded;
  SharedPreferences? _preferences;
  bool _changedSinceLoad = false;
  Future<void> _pendingWrite = Future<void>.value();

  @override
  WingSessionListDensity build() {
    loaded = _load();
    return WingSessionListDensity.compact;
  }

  Future<void> _load() async {
    try {
      final preferences = await _loadPreferences();
      if (!ref.mounted) return;
      _preferences = preferences;
      if (!_changedSinceLoad) {
        final stored = preferences.get(_key);
        state =
            WingSessionListDensity.values
                .where((density) => density.name == stored)
                .firstOrNull ??
            WingSessionListDensity.compact;
      }
    } catch (_) {
      // Storage is best-effort; hydration never normalizes saved values.
    }
  }

  Future<void> setDensity(WingSessionListDensity density) {
    if (!ref.mounted) return Future<void>.value();
    _changedSinceLoad = true;
    state = density;
    // Queue before awaiting hydration so intent order also covers cold storage.
    _pendingWrite = _pendingWrite.then((_) async {
      await loaded;
      if (!ref.mounted) return;
      try {
        if (density == WingSessionListDensity.compact) {
          await _preferences?.remove(_key);
        } else {
          await _preferences?.setString(_key, density.name);
        }
      } catch (_) {
        // A failed save must not break subsequent saves or the local choice.
      }
    });
    return _pendingWrite;
  }
}

final wingSessionListDensityProvider =
    NotifierProvider<WingSessionListDensityController, WingSessionListDensity>(
      WingSessionListDensityController.new,
    );

final wingSidebarExpandedProvider =
    NotifierProvider<WingShellPreferencesController, bool>(
      WingShellPreferencesController.new,
    );
