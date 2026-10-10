import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';

void main() {
  test('attempt request formatting is wholly redacted', () {
    const request = SshConnectionRequest(
      host: 'example.invalid',
      sshPort: 2222,
      username: 'synthetic-user',
      password: 'synthetic-password',
      privateKey: 'synthetic-private-key',
      passphrase: 'synthetic-passphrase',
      agentPort: 8643,
      agentBearerToken: 'synthetic-agent-token',
    );
    expect(request.toString(), 'SshConnectionRequest(<redacted>)');
    for (final value in [
      request.host,
      request.username,
      request.password,
      request.privateKey!,
      request.passphrase!,
      request.agentBearerToken!,
      '${request.sshPort}',
      '${request.agentPort}',
    ]) {
      expect(request.toString(), isNot(contains(value)));
    }
  });
}
