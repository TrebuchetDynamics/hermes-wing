import 'local_hermes_home_types.dart';

LocalHermesHomePlatform createLocalHermesHomePlatform() =>
    const UnsupportedLocalHermesHomePlatform();

/// Browser platforms cannot inspect the host filesystem.
class UnsupportedLocalHermesHomePlatform implements LocalHermesHomePlatform {
  const UnsupportedLocalHermesHomePlatform();
  @override
  bool get isSupported => false;
  @override
  String? get userHome => null;
  @override
  Future<LocalHermesHomeInspection> inspectDirectory(String path) async =>
      const LocalHermesHomeInspection.unavailable(
        LocalHermesHomeStatus.unsupported,
      );
}
