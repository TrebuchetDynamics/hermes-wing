import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The context-aware first-run tips (ROADMAP 5.2). Each shows once on the
/// surface where it matters and never again after dismissal.
enum WingTip { moreDestinations, voice, approvals }

/// Which tips may currently be shown. Nothing shows before the persisted
/// dismissals have loaded, so a dismissed tip can never flash on screen.
@immutable
class WingTipsState {
  const WingTipsState({this.loaded = false, this.dismissed = const {}});

  final bool loaded;
  final Set<WingTip> dismissed;

  bool shouldShow(WingTip tip) => loaded && !dismissed.contains(tip);
}

class WingTipsController extends Notifier<WingTipsState> {
  static const _key = 'wing.tips.dismissed.v1';

  /// Completes when the persisted dismissals have been applied.
  late Future<void> loaded;

  @override
  WingTipsState build() {
    loaded = _loadPrefs();
    return const WingTipsState();
  }

  Future<void> _loadPrefs() async {
    var dismissed = const <WingTip>{};
    try {
      final stored =
          (await SharedPreferences.getInstance()).getStringList(_key) ??
          const [];
      dismissed = {
        for (final name in stored)
          for (final tip in WingTip.values)
            if (tip.name == name) tip,
      };
    } catch (_) {
      // Unreadable preferences show every tip again; dismissal re-persists.
    }
    state = WingTipsState(loaded: true, dismissed: dismissed);
  }

  Future<void> dismiss(WingTip tip) async {
    state = WingTipsState(
      loaded: state.loaded,
      dismissed: {...state.dismissed, tip},
    );
    try {
      await (await SharedPreferences.getInstance()).setStringList(_key, [
        for (final tip in state.dismissed) tip.name,
      ]);
    } catch (_) {
      // Best-effort; the in-memory dismissal still applies this session.
    }
  }
}

final wingTipsProvider = NotifierProvider<WingTipsController, WingTipsState>(
  WingTipsController.new,
);
