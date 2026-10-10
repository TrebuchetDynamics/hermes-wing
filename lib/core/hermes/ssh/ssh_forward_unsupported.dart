import 'ssh_types.dart';

/// Browsers have no raw TCP sockets. No proxy or insecure fallback is provided.
class ManagedSshForward {
  ManagedSshForward({ManagedSshDial? dial});
  ManagedSshTunnel? get activeTunnel => null;
  Future<ManagedSshTunnel> connect({
    required ManagedSshConfig configuration,
    required ManagedSshCredentials authentication,
    ManagedSshHostKeyVerifier? verifyHostKey,
    Duration timeout = const Duration(seconds: 20),
  }) async =>
      throw const ManagedSshException(ManagedSshFailure.unsupportedPlatform);
  Future<void> disconnect() async {}
  Future<void> dispose() async {}
}
