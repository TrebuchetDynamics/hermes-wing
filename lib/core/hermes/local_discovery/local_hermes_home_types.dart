/// Metadata inspection only; `supported` does not establish an Agent install,
/// authenticated connection, running service, or readiness.
enum LocalHermesHomeStatus {
  supported,
  unsupported,
  absent,
  notDirectory,
  unreadable,
}

/// Ephemeral, device-local result. Never serialize paths into remote requests,
/// preferences, logs, or diagnostics.
class LocalHermesHomeInspection {
  const LocalHermesHomeInspection.unavailable(this.status)
    : assert(status != LocalHermesHomeStatus.supported),
      canonicalPath = null;
  const LocalHermesHomeInspection.directory(String path)
    : status = LocalHermesHomeStatus.supported,
      canonicalPath = path;

  final LocalHermesHomeStatus status;
  final String? canonicalPath;
}

/// Injectable platform metadata boundary. No directory enumeration or content
/// reads are part of this contract.
abstract interface class LocalHermesHomePlatform {
  bool get isSupported;
  String? get userHome;
  Future<LocalHermesHomeInspection> inspectDirectory(String path);
}
