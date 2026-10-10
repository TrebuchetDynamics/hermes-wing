import 'package:flutter/foundation.dart';

/// Ephemeral submission; callers must not log or persist this value. Dart strings
/// cannot be zeroized; drop references after the attempt completes.
@immutable
class SshConnectionRequest {
  const SshConnectionRequest({
    required this.host,
    required this.sshPort,
    required this.username,
    this.password = '',
    this.privateKey,
    this.passphrase,
    required this.agentPort,
    required this.agentBearerToken,
  });
  final String host;
  final int sshPort;
  final String username;
  final String password;
  final String? privateKey, passphrase;
  final int agentPort;
  final String? agentBearerToken;

  @override
  String toString() => 'SshConnectionRequest(<redacted>)';
}
