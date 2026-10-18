import 'package:flutter/foundation.dart';

/// Deliberate protocol selection; an SSH login never selects or grants an API.
enum SshAgentTransport { advertisedApi, serve }

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
    this.agentProfile,
    required this.agentBearerToken,
    this.transport = SshAgentTransport.advertisedApi,
  });
  final String host;
  final int sshPort;
  final String username;
  final String password;
  final String? privateKey, passphrase;
  final int agentPort;
  final String? agentProfile;
  final String? agentBearerToken;
  final SshAgentTransport transport;

  @override
  String toString() => 'SshConnectionRequest(<redacted>)';
}
