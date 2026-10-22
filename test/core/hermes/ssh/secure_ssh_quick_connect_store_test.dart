import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/ssh/secure_ssh_quick_connect_store.dart';
import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';
import 'package:wing/core/hermes/ssh/ssh_types.dart';

SshQuickConnection entry({String? profile = 'demo', String? privateKey}) =>
    SshQuickConnection(
      request: SshConnectionRequest(
        host: 'example.invalid',
        sshPort: 22,
        username: 'tester',
        password: privateKey == null ? 'synthetic-password' : '',
        privateKey: privateKey,
        agentPort: 8642,
        agentProfile: profile,
        agentBearerToken: 'synthetic-token',
      ),
      hostKey: ManagedSshHostKey('ssh-ed25519', List.filled(32, 3)),
    );

class HeldWriteStorage extends FlutterSecureStorage {
  final written = Completer<void>();
  final release = Completer<void>();
  bool holdNextWrite = false;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    await super.write(key: key, value: value);
    if (holdNextWrite) {
      holdNextWrite = false;
      written.complete();
      await release.future;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'encrypted slot roundtrip across store instances preserves exact owner',
    () async {
      final original = entry();
      await SecureSshQuickConnectStore().save(original, isCurrent: () => true);
      final restored = (await SecureSshQuickConnectStore().load())!;
      expect(restored.request.agentProfile, 'demo');
      expect(restored.request.password, 'synthetic-password');
      expect(restored.request.agentBearerToken, 'synthetic-token');
      expect(restored.toString(), isNot(contains('synthetic')));
      for (final profile in ['demo', 'other', null]) {
        expect(
          restored.accepts(
            ManagedSshConfig(
              host: 'example.invalid',
              username: 'tester',
              agentPort: 8642,
              agentProfile: profile,
            ),
            original.hostKey,
          ),
          profile == 'demo',
        );
      }
      expect(
        restored.accepts(
          ManagedSshConfig(
            host: 'example.invalid',
            username: 'tester',
            agentPort: 8642,
            agentProfile: 'demo',
          ),
          ManagedSshHostKey('ssh-ed25519', List.filled(32, 4)),
        ),
        isFalse,
      );
    },
  );

  test(
    'stale save is rejected, forget preserves unrelated secure slots',
    () async {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'inert-legacy', value: 'synthetic-preserved');
      final store = SecureSshQuickConnectStore(storage: storage);
      await store.save(entry(), isCurrent: () => false);
      expect(await store.load(), isNull);
      await store.save(
        entry(privateKey: 'synthetic-private-key'),
        isCurrent: () => true,
      );
      expect((await store.load())!.request.privateKey, 'synthetic-private-key');
      await store.forget();
      expect(await store.load(), isNull);
      expect(await storage.read(key: 'inert-legacy'), 'synthetic-preserved');
    },
  );

  for (final hasPrevious in [false, true]) {
    for (final next in ['load', 'save', 'forget']) {
      test(
        'cancelled write rolls back before cross-instance $next: previous=$hasPrevious',
        () async {
          final storage = HeldWriteStorage();
          final first = SecureSshQuickConnectStore(storage: storage);
          final second = SecureSshQuickConnectStore(storage: storage);
          if (hasPrevious) {
            await first.save(entry(profile: 'previous'), isCurrent: () => true);
          }
          storage.holdNextWrite = true;
          var current = true;
          final saving = first.save(
            entry(profile: 'cancelled'),
            isCurrent: () => current,
          );
          await storage.written.future;
          current = false;
          var finished = false;
          final following = switch (next) {
            'load' => second.load(),
            'save' => second.save(
              entry(profile: 'replacement'),
              isCurrent: () => true,
            ),
            _ => second.forget(),
          };
          final observed = following.then((value) {
            finished = true;
            return value;
          });
          // Let an unguarded operation finish while the original write is held.
          await Future<void>.delayed(Duration.zero);
          final overlapped = finished;
          storage.release.complete();
          await saving;
          final value = await observed;
          expect(overlapped, isFalse);
          final expected = hasPrevious ? 'previous' : null;
          if (next == 'load') {
            expect(
              (value as SshQuickConnection?)?.request.agentProfile,
              expected,
            );
          }
          expect(
            (await second.load())?.request.agentProfile,
            next == 'save'
                ? 'replacement'
                : next == 'forget'
                ? null
                : expected,
          );
        },
      );
    }
  }

  test('corrupt and oversized slots fail with redacted error', () async {
    const storage = FlutterSecureStorage();
    for (final raw in [
      'synthetic-private-token',
      jsonEncode({'token': 'synthetic-private-token'}),
      'x' * 196609,
    ]) {
      await storage.write(key: SecureSshQuickConnectStore.slot, value: raw);
      await expectLater(
        SecureSshQuickConnectStore(storage: storage).load(),
        throwsA(
          predicate(
            (Object e) =>
                e is FormatException &&
                !e.toString().contains('synthetic-private-token'),
          ),
        ),
      );
    }
  });

  test('missing Agent authentication cannot become a quick connection', () {
    expect(
      () => SshQuickConnection(
        request: const SshConnectionRequest(
          host: 'example.invalid',
          sshPort: 22,
          username: 'tester',
          password: 'synthetic-password',
          agentPort: 8642,
          agentBearerToken: '',
        ),
        hostKey: entry().hostKey,
      ),
      throwsFormatException,
    );
  });
}
