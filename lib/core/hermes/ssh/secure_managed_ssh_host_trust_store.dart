import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ssh_types.dart';

/// App-isolate host pins, separate from Agent authorization and forwarded ports.
class SecureManagedSshHostTrustStore {
  const SecureManagedSshHostTrustStore({
    this.storage = const FlutterSecureStorage(),
  });

  final FlutterSecureStorage storage;
  static Future<void>? _pending;

  Future<bool> verify(
    ManagedSshConfig config,
    ManagedSshHostKey key, {
    required Future<bool> Function() review,
    required bool Function() isCurrent,
  }) async {
    if (kIsWeb ||
        !RegExp(r'^[a-zA-Z0-9@._+-]{1,128}$').hasMatch(key.algorithm) ||
        key.sha256.length != 32 ||
        key.sha256.any((byte) => byte < 0 || byte > 255)) {
      throw const ManagedSshException(ManagedSshFailure.hostKeyRejected);
    }
    // Exact host text and port are the trust scope; usernames/Agent ports aren't.
    final slot =
        'hermes_wing.managed_ssh.host_pin.v1.${sha256.convert(utf8.encode(jsonEncode([config.host, config.sshPort])))}';
    final value = jsonEncode([key.algorithm, base64Encode(key.sha256)]);
    Future<String?> read() async {
      final stored = await storage.read(key: slot);
      if (stored == null) return null;
      if (stored.length > 256) throw const FormatException();
      final decoded = jsonDecode(stored);
      if (decoded is! List ||
          decoded.length != 2 ||
          decoded[0] is! String ||
          !RegExp(
            r'^[a-zA-Z0-9@._+-]{1,128}$',
          ).hasMatch(decoded[0] as String) ||
          decoded[1] is! String ||
          base64Decode(decoded[1] as String).length != 32) {
        throw const FormatException();
      }
      if (stored != value) {
        throw const ManagedSshException(ManagedSshFailure.hostKeyChanged);
      }
      return stored;
    }

    try {
      final known = await read();
      if (!isCurrent()) return false;
      if (known != null) return true;
      if (!await review() || !isCurrent()) return false;

      // Secure storage has no CAS. Serialize commits, not interactive reviews.
      final previous = _pending;
      final release = Completer<void>();
      _pending = release.future;
      if (previous != null) await previous;
      try {
        if (!isCurrent()) return false;
        final existing = await read();
        if (!isCurrent()) return false;
        if (existing == null) {
          await storage.write(key: slot, value: value);
          if (await read() != value) throw const FormatException();
        }
        return isCurrent();
      } finally {
        if (identical(_pending, release.future)) _pending = null;
        release.complete();
      }
    } on ManagedSshException {
      rethrow;
    } catch (_) {
      throw const ManagedSshException(ManagedSshFailure.hostTrustUnavailable);
    }
  }
}
