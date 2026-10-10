import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/ssh_keys/managed_ssh_generated_key.dart';
import 'package:wing/features/hermes_chat/ssh_keys/managed_ssh_generated_key_store.dart';

class FakeKeyStorage implements ManagedSshGeneratedKeyStorage {
  String? value;
  int writes = 0;
  int deletes = 0;
  bool failRead = false;
  bool failWrite = false;
  bool failDelete = false;
  bool dropWrite = false;
  String? substituteWrite;

  @override
  Future<String?> read() async {
    if (failRead) throw StateError('redacted storage error');
    return value;
  }

  @override
  Future<void> write(String value) async {
    writes++;
    if (failWrite) throw StateError('redacted storage error');
    if (!dropWrite) this.value = substituteWrite ?? value;
  }

  @override
  Future<void> delete() async {
    deletes++;
    if (failDelete) throw StateError('redacted storage error');
    value = null;
  }
}

Matcher failure(ManagedSshGeneratedKeyFailure reason) =>
    isA<ManagedSshGeneratedKeyException>()
        .having((error) => error.failure, 'reason', reason)
        .having(
          (error) => error.toString(),
          'redacted error',
          'Managed SSH generated key: ${reason.name}',
        );

void main() {
  test('concurrent stores serialize generation without overwriting', () async {
    final storage = FakeKeyStorage();
    final first = ManagedSshGeneratedKeyStore(storage: storage);
    final second = ManagedSshGeneratedKeyStore(storage: storage);
    final results = await Future.wait([
      first.generate(),
      second.generate(),
      first.generate(),
    ]);
    expect(
      results.every((key) => key.privatePem == results.first.privatePem),
      isTrue,
    );
    expect(storage.writes, 1);
  });
  test('remove is explicit and refuses storage failure', () async {
    final storage = FakeKeyStorage();
    final store = ManagedSshGeneratedKeyStore(storage: storage);
    await store.generate();
    storage.failDelete = true;
    await expectLater(
      store.remove(),
      throwsA(failure(ManagedSshGeneratedKeyFailure.storageUnavailable)),
    );
    expect(await store.load(), isNotNull);
    storage.failDelete = false;
    await store.remove();
    expect(await store.load(), isNull);
    expect(storage.deletes, 2);
  });
  test(
    'different readback identity is refused rather than silently adopted',
    () async {
      final storage = FakeKeyStorage()
        ..substituteWrite = ManagedSshGeneratedKey.generate().privatePem;
      final store = ManagedSshGeneratedKeyStore(storage: storage);
      await expectLater(
        store.generate(),
        throwsA(failure(ManagedSshGeneratedKeyFailure.persistenceMismatch)),
      );
      expect(storage.writes, 1);
    },
  );
  test('unsupported platform never reads or generates', () async {
    final storage = FakeKeyStorage();
    final store = ManagedSshGeneratedKeyStore(
      storage: storage,
      supported: false,
    );
    await expectLater(
      store.load(),
      throwsA(failure(ManagedSshGeneratedKeyFailure.unsupportedPlatform)),
    );
    await expectLater(
      store.generate(),
      throwsA(failure(ManagedSshGeneratedKeyFailure.unsupportedPlatform)),
    );
    await expectLater(
      store.remove(),
      throwsA(failure(ManagedSshGeneratedKeyFailure.unsupportedPlatform)),
    );
    expect(storage.writes, 0);
    expect(storage.deletes, 0);
  });
  test(
    'malformed entry refuses load and generation without overwriting',
    () async {
      final storage = FakeKeyStorage()..value = 'not a key';
      final store = ManagedSshGeneratedKeyStore(storage: storage);
      await expectLater(
        store.load(),
        throwsA(failure(ManagedSshGeneratedKeyFailure.invalidStoredKey)),
      );
      await expectLater(
        store.generate(),
        throwsA(failure(ManagedSshGeneratedKeyFailure.invalidStoredKey)),
      );
      expect(storage.writes, 0);
    },
  );
  test('storage failures never return an unpersisted fallback', () async {
    final storage = FakeKeyStorage()..failRead = true;
    final store = ManagedSshGeneratedKeyStore(storage: storage);
    await expectLater(
      store.load(),
      throwsA(failure(ManagedSshGeneratedKeyFailure.storageUnavailable)),
    );
    await expectLater(
      store.generate(),
      throwsA(failure(ManagedSshGeneratedKeyFailure.storageUnavailable)),
    );
    expect(storage.writes, 0);
    storage.failRead = false;
    storage.failWrite = true;
    await expectLater(
      store.generate(),
      throwsA(failure(ManagedSshGeneratedKeyFailure.storageUnavailable)),
    );
    expect(await store.load(), isNull);
  });
  test('dropped write fails closed on readback', () async {
    final store = ManagedSshGeneratedKeyStore(
      storage: FakeKeyStorage()..dropWrite = true,
    );
    await expectLater(
      store.generate(),
      throwsA(failure(ManagedSshGeneratedKeyFailure.persistenceMismatch)),
    );
  });
  test(
    'generate persists once and load reuses across store instances',
    () async {
      final storage = FakeKeyStorage();
      final store = ManagedSshGeneratedKeyStore(storage: storage);
      expect(await store.load(), isNull);
      final first = await store.generate();
      final loaded = await ManagedSshGeneratedKeyStore(storage: storage).load();
      expect(loaded?.publicKey == first.publicKey, isTrue);
      expect(loaded?.privatePem == first.privatePem, isTrue);
      expect((await store.generate()).publicKey == first.publicKey, isTrue);
      expect(storage.writes, 1);
      expect(store.toString(), 'ManagedSshGeneratedKeyStore(redacted)');
    },
  );
}
