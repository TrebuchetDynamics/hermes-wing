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

final wingSidebarExpandedProvider =
    NotifierProvider<WingShellPreferencesController, bool>(
      WingShellPreferencesController.new,
    );
