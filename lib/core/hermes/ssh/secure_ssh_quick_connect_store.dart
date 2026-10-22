import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ssh_connection_request.dart';
import 'ssh_types.dart';

/// Device-local authentication, never an Agent inventory or forwarded origin.
class SshQuickConnection {
  SshQuickConnection({required this.request, required this.hostKey}) {
    final r = request;
    ManagedSshConfig(
      host: r.host,
      username: r.username,
      sshPort: r.sshPort,
      agentPort: r.agentPort,
      agentProfile: r.agentProfile,
    );
    bool secret(String? value, int limit) =>
        value != null &&
        value.isNotEmpty &&
        value.length <= limit &&
        !value.contains('\u0000');
    if (r.transport != SshAgentTransport.advertisedApi ||
        !secret(r.agentBearerToken, 4096) ||
        !RegExp(r'^[\x21-\x7e]+$').hasMatch(r.agentBearerToken!) ||
        (r.privateKey == null
            ? !secret(r.password, 4096) || r.passphrase != null
            : r.password.isNotEmpty ||
                  !secret(r.privateKey, 131072) ||
                  (r.passphrase != null && !secret(r.passphrase, 4096))) ||
        !RegExp(r'^[a-zA-Z0-9@._+-]{1,128}$').hasMatch(hostKey.algorithm) ||
        hostKey.sha256.length != 32 ||
        hostKey.sha256.any((v) => v < 0 || v > 255)) {
      throw const FormatException('Saved SSH access unavailable');
    }
  }

  final SshConnectionRequest request;
  final ManagedSshHostKey hostKey;

  bool accepts(ManagedSshConfig config, ManagedSshHostKey key) =>
      config.host == request.host &&
      config.sshPort == request.sshPort &&
      config.username == request.username &&
      config.agentPort == request.agentPort &&
      config.agentProfile == request.agentProfile &&
      key.algorithm == hostKey.algorithm &&
      listEquals(key.sha256, hostKey.sha256);

  Map<String, Object?> _json() => {
    'host': request.host,
    'sshPort': request.sshPort,
    'username': request.username,
    'agentPort': request.agentPort,
    'profile': request.agentProfile,
    'password': request.password,
    'privateKey': request.privateKey,
    'passphrase': request.passphrase,
    'token': request.agentBearerToken,
    'algorithm': hostKey.algorithm,
    'fingerprint': base64Encode(hostKey.sha256),
  };

  static SshQuickConnection _decode(String raw) {
    if (raw.length > 196608) throw const FormatException();
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) throw const FormatException();
    return SshQuickConnection(
      request: SshConnectionRequest(
        host: data['host'] as String,
        sshPort: data['sshPort'] as int,
        username: data['username'] as String,
        agentPort: data['agentPort'] as int,
        agentProfile: data['profile'] as String?,
        password: data['password'] as String,
        privateKey: data['privateKey'] as String?,
        passphrase: data['passphrase'] as String?,
        agentBearerToken: data['token'] as String,
      ),
      hostKey: ManagedSshHostKey(
        data['algorithm'] as String,
        base64Decode(data['fingerprint'] as String),
      ),
    );
  }

  @override
  String toString() => 'SshQuickConnection(redacted)';
}

/// One opt-in encrypted slot, separate from legacy targets and recovery pointers.
/// No preference projection, automatic dialing, or fallback to another owner.
class SecureSshQuickConnectStore {
  SecureSshQuickConnectStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const slot = 'wing.hermes.ssh_quick_connect.v1';
  final FlutterSecureStorage _storage;
  static Future<void>? _pending;

  Future<SshQuickConnection?> load() => _serialized(() async {
    if (kIsWeb) throw const FormatException();
    final raw = await _storage.read(key: slot);
    return raw == null ? null : SshQuickConnection._decode(raw);
  });

  Future<void> save(
    SshQuickConnection connection, {
    required bool Function() isCurrent,
  }) => _serialized(() async {
    if (kIsWeb) throw const FormatException();
    final raw = jsonEncode(connection._json());
    SshQuickConnection._decode(raw);
    if (!isCurrent()) return;
    final previous = await _storage.read(key: slot);
    if (!isCurrent()) return;
    try {
      await _storage.write(key: slot, value: raw);
      if (await _storage.read(key: slot) != raw) throw const FormatException();
    } finally {
      // Keep rollback inside the lock so it cannot erase a newer owner's save.
      if (!isCurrent()) {
        if (previous == null) {
          await _storage.delete(key: slot);
        } else {
          await _storage.write(key: slot, value: previous);
        }
        if (await _storage.read(key: slot) != previous) {
          throw const FormatException();
        }
      }
    }
  });

  Future<void> forget() => _serialized(() async {
    if (kIsWeb) throw const FormatException();
    await _storage.delete(key: slot);
    if (await _storage.read(key: slot) != null) throw const FormatException();
  });

  Future<T> _serialized<T>(Future<T> Function() operation) async {
    while (_pending != null) {
      await _pending;
    }
    final release = Completer<void>();
    _pending = release.future;
    try {
      return await operation();
    } catch (_) {
      throw const FormatException('Saved SSH access unavailable');
    } finally {
      // No completed Future survives into another test/event-loop zone.
      _pending = null;
      release.complete();
    }
  }
}
