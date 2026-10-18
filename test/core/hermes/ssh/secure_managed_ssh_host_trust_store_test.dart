import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/ssh/secure_managed_ssh_host_trust_store.dart';
import 'package:wing/core/hermes/ssh/ssh_types.dart';

class _Storage extends Fake implements FlutterSecureStorage {
  final values = <String, String>{'inert-legacy': 'preserved'};
  bool failRead = false;
  bool failWrite = false;
  bool dropWrite = false;
  Completer<void>? writeEntered;
  Completer<void>? releaseWrite;
  int writes = 0;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failRead) throw StateError('sensitive storage error');
    return values[key];
  }

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
    writes++;
    writeEntered?.complete();
    if (releaseWrite != null) await releaseWrite!.future;
    if (failWrite) throw StateError('sensitive storage error');
    if (!dropWrite) values[key] = value!;
  }
}

ManagedSshConfig config({
  String host = 'example.invalid',
  int port = 22,
  String user = 'tester',
  int agentPort = 8642,
  String? agentProfile,
}) => ManagedSshConfig(
  host: host,
  username: user,
  sshPort: port,
  agentPort: agentPort,
  agentProfile: agentProfile,
);
ManagedSshHostKey key([int byte = 0, String algorithm = 'ssh-ed25519']) =>
    ManagedSshHostKey(algorithm, List.filled(32, byte));
Matcher failure(ManagedSshFailure expected) => throwsA(
  isA<ManagedSshException>().having((e) => e.failure, 'failure', expected),
);

void main() {
  test(
    'explicit trust persists across stores; exact host/port scope only',
    () async {
      final storage = _Storage();
      var reviews = 0;
      Future<bool> verify(ManagedSshConfig target) =>
          SecureManagedSshHostTrustStore(storage: storage).verify(
            target,
            key(),
            review: () async {
              reviews++;
              return true;
            },
            isCurrent: () => true,
          );
      expect(await verify(config()), isTrue);
      expect(await verify(config(user: 'other', agentPort: 9999)), isTrue);
      expect(await verify(config(agentProfile: 'demo')), isTrue);
      await expectLater(
        SecureManagedSshHostTrustStore(storage: storage).verify(
          config(agentProfile: 'demo'),
          key(1),
          review: () async =>
              throw StateError('Changed host must not ask again'),
          isCurrent: () => true,
        ),
        failure(ManagedSshFailure.hostKeyChanged),
      );
      expect(reviews, 1);
      expect(await verify(config(port: 2222)), isTrue);
      expect(await verify(config(host: 'other.invalid')), isTrue);
      expect(reviews, 3);
      expect(storage.writes, 3);
      expect(storage.values['inert-legacy'], 'preserved');
      expect(
        storage.values.keys.any((slot) => slot.contains('example.invalid')),
        isFalse,
      );
      expect(
        storage.values.values
            .where((value) => value != 'preserved')
            .every((value) => (jsonDecode(value) as List).length == 2),
        isTrue,
      );
    },
  );

  test(
    'changed digest or algorithm rejects without review or replacement',
    () async {
      final storage = _Storage();
      final store = SecureManagedSshHostTrustStore(storage: storage);
      await store.verify(
        config(),
        key(),
        review: () async => true,
        isCurrent: () => true,
      );
      final before = Map.of(storage.values);
      for (final changed in [key(1), key(0, 'rsa-sha2-512')]) {
        await expectLater(
          store.verify(
            config(),
            changed,
            review: () async => fail('Changed keys must not offer trust'),
            isCurrent: () => true,
          ),
          failure(ManagedSshFailure.hostKeyChanged),
        );
      }
      expect(storage.values, before);
      expect(storage.writes, 1);
    },
  );

  test('decline and obsolete review save nothing', () async {
    final storage = _Storage();
    final store = SecureManagedSshHostTrustStore(storage: storage);
    expect(
      await store.verify(
        config(),
        key(),
        review: () async => false,
        isCurrent: () => true,
      ),
      isFalse,
    );
    var current = true;
    expect(
      await store.verify(
        config(),
        key(),
        review: () async {
          current = false;
          return true;
        },
        isCurrent: () => current,
      ),
      isFalse,
    );
    expect(storage.writes, 0);
    expect(storage.values, {'inert-legacy': 'preserved'});
  });

  test(
    'storage read, write and readback failure block without leaking errors',
    () async {
      for (final mode in ['read', 'write', 'readback']) {
        final storage = _Storage()
          ..failRead = mode == 'read'
          ..failWrite = mode == 'write'
          ..dropWrite = mode == 'readback';
        final store = SecureManagedSshHostTrustStore(storage: storage);
        try {
          await store.verify(
            config(),
            key(),
            review: () async => true,
            isCurrent: () => true,
          );
          fail('Storage failure must block');
        } on ManagedSshException catch (error) {
          expect(error.failure, ManagedSshFailure.hostTrustUnavailable);
          expect(error.toString(), isNot(contains('sensitive')));
        }
        expect(storage.values, {'inert-legacy': 'preserved'});
      }
    },
  );

  test('malformed stored pins fail closed and remain untouched', () async {
    final storage = _Storage();
    final store = SecureManagedSshHostTrustStore(storage: storage);
    await store.verify(
      config(),
      key(),
      review: () async => true,
      isCurrent: () => true,
    );
    final slot = storage.values.keys.singleWhere((k) => k != 'inert-legacy');
    for (final malformed in [
      'garbage',
      '[]',
      '["ssh-ed25519","AA=="]',
      'x' * 257,
    ]) {
      storage.values[slot] = malformed;
      await expectLater(
        store.verify(
          config(),
          key(),
          review: () async => fail('Malformed pins must not offer trust'),
          isCurrent: () => true,
        ),
        failure(ManagedSshFailure.hostTrustUnavailable),
      );
      expect(storage.values[slot], malformed);
    }
    expect(storage.writes, 1);
  });

  test('invalid presented key never reads storage or asks for trust', () async {
    final storage = _Storage()..failRead = true;
    final store = SecureManagedSshHostTrustStore(storage: storage);
    for (final malformed in [
      ManagedSshHostKey('ssh-ed25519', [0]),
      key(-1),
      key(256),
      key(0, 'bad\nkey'),
    ]) {
      await expectLater(
        store.verify(
          config(),
          malformed,
          review: () async => fail('Malformed key'),
          isCurrent: () => true,
        ),
        failure(ManagedSshFailure.hostKeyRejected),
      );
    }
    expect(storage.writes, 0);
  });

  test(
    'concurrent different reviewed keys cannot overwrite the winning pin',
    () async {
      final storage = _Storage();
      final reviewsEntered = Completer<void>();
      final releaseReviews = Completer<bool>();
      var reviews = 0;
      Future<bool> review() {
        if (++reviews == 2) reviewsEntered.complete();
        return releaseReviews.future;
      }

      Future<ManagedSshFailure?> verify(int byte) async {
        try {
          expect(
            await SecureManagedSshHostTrustStore(storage: storage).verify(
              config(),
              key(byte),
              review: review,
              isCurrent: () => true,
            ),
            isTrue,
          );
          return null;
        } on ManagedSshException catch (error) {
          return error.failure;
        }
      }

      final results = Future.wait([verify(0), verify(1)]);
      await reviewsEntered.future;
      releaseReviews.complete(true);
      expect(await results, [null, ManagedSshFailure.hostKeyChanged]);
      expect(storage.writes, 1);
    },
  );

  test(
    'cancellation during committed review never admits the expired attempt',
    () async {
      final storage = _Storage()
        ..writeEntered = Completer<void>()
        ..releaseWrite = Completer<void>();
      var current = true;
      final result = SecureManagedSshHostTrustStore(storage: storage).verify(
        config(),
        key(),
        review: () async => true,
        isCurrent: () => current,
      );
      await storage.writeEntered!.future;
      current = false;
      storage.releaseWrite!.complete();
      expect(await result, isFalse);
      // The explicitly reviewed pin may finish saving; no connection is authorized.
      expect(storage.writes, 1);
      expect(
        await SecureManagedSshHostTrustStore(storage: storage).verify(
          config(),
          key(),
          review: () async => fail('Already reviewed'),
          isCurrent: () => true,
        ),
        isTrue,
      );
    },
  );
}
