import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/setup/secure_managed_ssh_recovery_store.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'API prefix isolates recovery and run fences while legacy root stays stable',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = const FlutterSecureStorage();
      final store = SecureManagedSshRecoveryStore(storage: storage);
      ManagedSshConfig target([String? profile]) => ManagedSshConfig(
        host: 'example.invalid',
        username: 'tester',
        agentPort: 8642,
        agentProfile: profile,
      );
      final key = ManagedSshHostKey('ssh-ed25519', List.filled(32, 7));
      ManagedSshRecovery pointer(String? prefix) => ManagedSshRecovery(
        configuration: target(prefix),
        transport: SshAgentTransport.advertisedApi,
        hostKey: key,
        profile: prefix ?? 'default',
        session: 'exact-session',
        uncertain: true,
      );
      final legacy = pointer(null).toJson()..remove('agentProfile');
      await storage.write(
        key: SecureManagedSshRecoveryStore.key,
        value: jsonEncode([legacy]),
      );
      final rootPointer = await store.load(
        target(),
        SshAgentTransport.advertisedApi,
      );
      expect(rootPointer!.session, 'exact-session');
      expect(
        await store.load(target('demo'), SshAgentTransport.advertisedApi),
        isNull,
      );
      final rootOwner = ManagedSshRecovery.runOwner(target(), key);
      expect(
        rootOwner,
        'ssh-forward:${sha256.convert(utf8.encode(jsonEncode(['example.invalid', 22, 'tester', 8642, key.algorithm, base64.encode(key.sha256)])))}',
      );
      for (final prefix in ['demo', 'other']) {
        await store.save(pointer(prefix));
        expect(
          ManagedSshRecovery.runOwner(target(prefix), key),
          isNot(rootOwner),
        );
      }
      expect(
        ManagedSshRecovery.runOwner(target('demo'), key),
        isNot(ManagedSshRecovery.runOwner(target('other'), key)),
      );
      for (final prefix in [null, 'demo', 'other']) {
        final loaded = await store.load(
          target(prefix),
          SshAgentTransport.advertisedApi,
        );
        expect(loaded!.configuration.agentProfile, prefix);
        expect(loaded.profile, prefix ?? 'default');
        expect(loaded.unresolvedSessions, {
          (prefix ?? 'default', 'exact-session'),
        });
      }
      expect(
        ManagedSshRecovery.runOwner(rootPointer.configuration, key),
        rootOwner,
      );
      expect(
        jsonDecode(
          (await storage.read(key: SecureManagedSshRecoveryStore.key))!,
        ),
        hasLength(3),
      );
      expect(
        () => ManagedSshRecovery.fromJson({
          ...legacy,
          'agentProfile': 'demo',
          'transport': 'serve',
        }),
        throwsFormatException,
      );
    },
  );
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
