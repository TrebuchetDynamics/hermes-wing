import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wing/core/hermes/setup/secure_hermes_serve_recovery_store.dart';

/// Test-only synthetic credential persistence; not OS keyring qualification.
class ServeFixtureStorage extends FlutterSecureStorage {
  ServeFixtureStorage(this.file);
  final File file;
  void check(String key) {
    if (key != SecureHermesServeRecoveryStore.key) {
      throw StateError('Unexpected fixture key');
    }
  }

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
    check(key);
    return await file.exists() ? file.readAsString() : null;
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
    check(key);
    if (value == null) throw StateError('Missing fixture value');
    final temporary = File('${file.path}.pending');
    await temporary.writeAsString(value, flush: true);
    await temporary.rename(file.path);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    check(key);
    if (await file.exists()) await file.delete();
  }
}
