import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'managed_ssh_generated_key.dart';

enum ManagedSshGeneratedKeyFailure {
  storageUnavailable,
  invalidStoredKey,
  persistenceMismatch,
  generationFailed,
  unsupportedPlatform,
}

class ManagedSshGeneratedKeyException implements Exception {
  const ManagedSshGeneratedKeyException(this.failure);
  final ManagedSshGeneratedKeyFailure failure;
  @override
  String toString() => 'Managed SSH generated key: ${failure.name}';
}

abstract interface class ManagedSshGeneratedKeyStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class FlutterSecureManagedSshGeneratedKeyStorage
    implements ManagedSshGeneratedKeyStorage {
  const FlutterSecureManagedSshGeneratedKeyStorage({
    this.storage = const FlutterSecureStorage(),
  });

  static const storageKey = 'hermes_wing.managed_ssh.generated_ed25519.v1';
  final FlutterSecureStorage storage;

  @override
  Future<String?> read() => storage.read(key: storageKey);
  @override
  Future<void> write(String value) =>
      storage.write(key: storageKey, value: value);
  @override
  Future<void> delete() => storage.delete(key: storageKey);
}

class ManagedSshGeneratedKeyStore {
  ManagedSshGeneratedKeyStore({
    ManagedSshGeneratedKeyStorage? storage,
    bool supported = true,
  }) : _storage = storage ?? const FlutterSecureManagedSshGeneratedKeyStorage(),
       _supported = !kIsWeb && supported;

  final ManagedSshGeneratedKeyStorage _storage;
  final bool _supported;

  // One app-isolate lane across instances: secure storage has no compare-and-set.
  // Callers must keep this store on the app isolate, not concurrent isolates.
  static Future<void> _pending = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() operation) async {
    final previous = _pending;
    final release = Completer<void>();
    _pending = release.future;
    await previous;
    try {
      return await operation();
    } finally {
      release.complete();
    }
  }

  void _checkSupported() {
    if (!_supported) {
      throw const ManagedSshGeneratedKeyException(
        ManagedSshGeneratedKeyFailure.unsupportedPlatform,
      );
    }
  }

  Future<void> remove() => _serialized(_remove);

  Future<void> _remove() async {
    _checkSupported();
    try {
      await _storage.delete();
      if (await _storage.read() != null) {
        throw const ManagedSshGeneratedKeyException(
          ManagedSshGeneratedKeyFailure.persistenceMismatch,
        );
      }
    } on ManagedSshGeneratedKeyException {
      rethrow;
    } catch (_) {
      throw const ManagedSshGeneratedKeyException(
        ManagedSshGeneratedKeyFailure.storageUnavailable,
      );
    }
  }

  Future<ManagedSshGeneratedKey?> load() => _serialized(_load);

  Future<ManagedSshGeneratedKey?> _load() async {
    _checkSupported();
    String? pem;
    try {
      pem = await _storage.read();
    } catch (_) {
      throw const ManagedSshGeneratedKeyException(
        ManagedSshGeneratedKeyFailure.storageUnavailable,
      );
    }
    if (pem == null) return null;
    try {
      return ManagedSshGeneratedKey.fromPrivatePem(pem);
    } catch (_) {
      throw const ManagedSshGeneratedKeyException(
        ManagedSshGeneratedKeyFailure.invalidStoredKey,
      );
    }
  }

  Future<ManagedSshGeneratedKey> generate() => _serialized(_generate);

  Future<ManagedSshGeneratedKey> _generate() async {
    final existing = await _load();
    if (existing != null) return existing;
    late ManagedSshGeneratedKey generated;
    try {
      generated = ManagedSshGeneratedKey.generate();
    } catch (_) {
      throw const ManagedSshGeneratedKeyException(
        ManagedSshGeneratedKeyFailure.generationFailed,
      );
    }
    try {
      await _storage.write(generated.privatePem);
    } catch (_) {
      throw const ManagedSshGeneratedKeyException(
        ManagedSshGeneratedKeyFailure.storageUnavailable,
      );
    }
    final persisted = await _load();
    if (persisted == null || persisted.privatePem != generated.privatePem) {
      throw const ManagedSshGeneratedKeyException(
        ManagedSshGeneratedKeyFailure.persistenceMismatch,
      );
    }
    return persisted;
  }

  @override
  String toString() => 'ManagedSshGeneratedKeyStore(redacted)';
}
