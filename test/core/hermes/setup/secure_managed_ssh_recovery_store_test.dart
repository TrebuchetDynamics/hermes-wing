import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/setup/secure_managed_ssh_recovery_store.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'SSH pointers roundtrip exact owners without a forwarding origin or secrets',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = const FlutterSecureStorage();
      final store = SecureManagedSshRecoveryStore(storage: storage);
      ManagedSshConfig target(String host) =>
          ManagedSshConfig(host: host, username: 'synthetic', agentPort: 8642);
      for (final host in ['a.invalid', 'b.invalid']) {
        await store.save(
          ManagedSshRecovery(
            configuration: target(host),
            transport: SshAgentTransport.serve,
            hostKey: ManagedSshHostKey(
              'ssh-ed25519',
              List.filled(32, host.codeUnitAt(0)),
            ),
            profile: 'demo',
            session: '$host-session',
            uncertain: true,
          ),
        );
      }
      final reopened = SecureManagedSshRecoveryStore(storage: storage);
      final saved = await reopened.load(
        target('a.invalid'),
        SshAgentTransport.serve,
      );
      expect(saved?.session, 'a.invalid-session');
      expect(saved?.uncertain, true);
      expect(saved?.profile, 'demo');
      expect(saved?.hostKey.sha256, List.filled(32, 'a'.codeUnitAt(0)));
      expect(
        await reopened.load(
          target('a.invalid'),
          SshAgentTransport.advertisedApi,
        ),
        isNull,
      );
      final encoded = (await storage.readAll()).values.single;
      expect(encoded, isNot(contains('127.0.0.1')));
      expect(encoded, isNot(contains('credential')));
      expect(encoded, isNot(contains('password')));
      // A malformed pointer never falls back to a default session/trust record.
      final rows = jsonDecode(encoded) as List<dynamic>;
      (rows.first as Map<String, dynamic>)['session'] = '../other';
      await storage.write(
        key: SecureManagedSshRecoveryStore.key,
        value: jsonEncode(rows),
      );
      await expectLater(
        reopened.load(target('a.invalid'), SshAgentTransport.serve),
        throwsFormatException,
      );
    },
  );
}
