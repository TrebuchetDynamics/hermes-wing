import 'local_hermes_home_types.dart';
import 'local_hermes_home_platform_unsupported.dart'
    if (dart.library.io) 'local_hermes_home_platform_io.dart'
    as native;

export 'local_hermes_home_types.dart';

/// Inspects only the default Linux user-home/.hermes or an explicitly selected
/// Hermes home. This is neither a Hermes Project nor a working directory grant.
class LocalHermesHomeDiscovery {
  LocalHermesHomeDiscovery({LocalHermesHomePlatform? platform})
    : _platform = platform ?? native.createLocalHermesHomePlatform();

  final LocalHermesHomePlatform _platform;

  Future<LocalHermesHomeInspection> inspectDefault() async {
    if (!_platform.isSupported) return _unsupported;
    try {
      final home = _platform.userHome;
      if (home == null || !home.startsWith('/')) return _unreadable;
      return inspectSelected('$home/.hermes');
    } catch (_) {
      return _unreadable;
    }
  }

  /// Call only with a local, owner-selected folder; never a remote host path.
  /// Each call re-inspects metadata. No previous choice or result is retained.
  Future<LocalHermesHomeInspection> inspectSelected(String directory) async {
    if (!_platform.isSupported) return _unsupported;
    if (!directory.startsWith('/') ||
        directory.length > 4096 ||
        directory.codeUnits.any((unit) => unit < 32 || unit == 127)) {
      return _unreadable;
    }
    try {
      return await _platform.inspectDirectory(directory);
    } catch (_) {
      // Do not surface platform exception text, which can contain private paths.
      return _unreadable;
    }
  }

  static const _unsupported = LocalHermesHomeInspection.unavailable(
    LocalHermesHomeStatus.unsupported,
  );
  static const _unreadable = LocalHermesHomeInspection.unavailable(
    LocalHermesHomeStatus.unreadable,
  );
}
