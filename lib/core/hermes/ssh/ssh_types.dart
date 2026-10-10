import 'dart:async';
import 'package:dartssh2/dartssh2.dart';

typedef ManagedSshDial =
    Future<SSHSocket> Function(String host, int port, {Duration? timeout});

enum ManagedSshFailure {
  invalidConfiguration,
  unsupportedPlatform,
  busy,
  disposed,
  cancelled,
  timeout,
  hostKeyRejected,
  authentication,
  connection,
}

/// Contains no raw upstream exception, endpoint or credential.
class ManagedSshException implements Exception {
  const ManagedSshException(this.failure);
  final ManagedSshFailure failure;
  @override
  String toString() => 'Managed SSH: ${failure.name}';
}

/// A single direct TCP destination; the remote host is always 127.0.0.1.
/// This object is not a persistence or trust record.
class ManagedSshConfig {
  ManagedSshConfig({
    required this.host,
    required this.username,
    this.sshPort = 22,
    required this.agentPort,
  }) {
    if (host.isEmpty ||
        host.length > 253 ||
        !RegExp(r'^[a-zA-Z0-9.:_-]+$').hasMatch(host) ||
        username.isEmpty ||
        username.length > 128 ||
        !RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username) ||
        sshPort < 1 ||
        sshPort > 65535 ||
        agentPort < 1 ||
        agentPort > 65535) {
      throw const ManagedSshException(ManagedSshFailure.invalidConfiguration);
    }
  }
  final String host;
  final String username;
  final int sshPort;
  final int agentPort;
  @override
  String toString() => 'ManagedSshConfig(redacted)';
}

/// SHA-256 of the SSH wire-format public key, not a TLS SPKI fingerprint.
/// The caller must bind its explicit trust decision to config.host/sshPort.
class ManagedSshHostKey {
  ManagedSshHostKey(this.algorithm, List<int> fingerprint)
    : sha256 = List.unmodifiable(fingerprint);
  final String algorithm;
  final List<int> sha256;
  @override
  String toString() => 'ManagedSshHostKey(redacted)';
}

typedef ManagedSshHostKeyVerifier =
    FutureOr<bool> Function(ManagedSshConfig config, ManagedSshHostKey key);

/// Ephemeral forwarding lease. Never persist agentUri as the SSH target identity.
/// Agent bearer authentication remains mandatory on the forwarded connection.
class ManagedSshTunnel {
  ManagedSshTunnel({
    required this.agentUri,
    required this.done,
    required Future<void> Function() close,
    // Keep the disposal callback private while exposing a public named input.
    // ignore: prefer_initializing_formals
  }) : _close = close;
  final Uri agentUri;
  final Future<void> done;
  final Future<void> Function() _close;
  Future<void> dispose() => _close();
  @override
  String toString() => 'ManagedSshTunnel(ephemeral)';
}

/// Inputs are obtained only for this attempt, never discovered or persisted.
/// Dart strings cannot be securely zeroized; callers must drop their own copies.
class ManagedSshCredentials {
  const ManagedSshCredentials({
    this.password,
    this.privateKey,
    this.passphrase,
  });
  final FutureOr<String?> Function()? password;
  final FutureOr<String?> Function()? privateKey;
  final FutureOr<String?> Function()? passphrase;
  @override
  String toString() => 'ManagedSshCredentials(redacted)';
}
