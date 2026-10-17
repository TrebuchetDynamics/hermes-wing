import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

import '../ssh/managed_ssh.dart';
import '../ssh/ssh_connection_request.dart';

/// Navigation and an uncertainty fence, not Agent state or a mutation queue.
/// No forwarding origin, SSH authentication or Agent credential is retained.
class ManagedSshRecovery {
  const ManagedSshRecovery({
    required this.configuration,
    required this.transport,
    required this.hostKey,
    required this.profile,
    required this.session,
    required this.uncertain,
    this.uncertainSessions = const {},
  });
  final ManagedSshConfig configuration;
  final SshAgentTransport transport;
  final ManagedSshHostKey hostKey;
  final String profile;
  final String? session;
  final bool uncertain;
  final Set<(String, String)> uncertainSessions;

  Set<(String, String)> get unresolvedSessions => {
    ...uncertainSessions,
    if (uncertain && session != null) (profile, session!),
  };

  static String runOwner(ManagedSshConfig config, ManagedSshHostKey key) =>
      'ssh-forward:${sha256.convert(utf8.encode(jsonEncode([config.host, config.sshPort, config.username, config.agentPort, key.algorithm, base64.encode(key.sha256)])))}';

  bool matches(ManagedSshConfig other, SshAgentTransport protocol) =>
      configuration.host == other.host &&
      configuration.sshPort == other.sshPort &&
      configuration.username == other.username &&
      configuration.agentPort == other.agentPort &&
      transport == protocol;

  Map<String, Object> toJson() => {
    'host': configuration.host,
    'sshPort': configuration.sshPort,
    'username': configuration.username,
    'agentPort': configuration.agentPort,
    'transport': transport.name,
    'algorithm': hostKey.algorithm,
    'fingerprint': base64.encode(hostKey.sha256),
    'profile': profile,
    'session': ?session,
    'uncertain': uncertain,
    'uncertainSessions': [
      for (final (profile, session) in unresolvedSessions)
        {'profile': profile, 'session': session},
    ],
  };

  static ManagedSshRecovery fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) throw const FormatException();
    String text(String key, int limit) {
      final text = value[key];
      if (text is! String || text.isEmpty || text.length > limit) {
        throw const FormatException();
      }
      return text;
    }

    String identity(String key) {
      final id = text(key, 128);
      if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(id)) {
        throw const FormatException();
      }
      return id;
    }

    final unresolved = <(String, String)>{};
    final fences = value['uncertainSessions'] ?? [];
    if (fences is! List || fences.length > 32) throw const FormatException();
    for (final row in fences) {
      if (row is! Map ||
          row['profile'] is! String ||
          row['session'] is! String ||
          !RegExp(
            r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$',
          ).hasMatch(row['profile'] as String) ||
          !RegExp(
            r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$',
          ).hasMatch(row['session'] as String)) {
        throw const FormatException();
      }
      unresolved.add((row['profile'] as String, row['session'] as String));
    }
    final fingerprint = base64.decode(text('fingerprint', 44));
    if (fingerprint.length != 32 ||
        value['uncertain'] is! bool ||
        value['sshPort'] is! int ||
        value['agentPort'] is! int) {
      throw const FormatException();
    }
    return ManagedSshRecovery(
      configuration: ManagedSshConfig(
        host: text('host', 253),
        username: text('username', 128),
        sshPort: value['sshPort'] as int,
        agentPort: value['agentPort'] as int,
      ),
      transport: SshAgentTransport.values.singleWhere(
        (p) => p.name == text('transport', 32),
      ),
      hostKey: ManagedSshHostKey(text('algorithm', 128), fingerprint),
      profile: identity('profile'),
      session: value.containsKey('session') ? identity('session') : null,
      uncertain: value['uncertain'] as bool,
      uncertainSessions: unresolved,
    );
  }

  @override
  String toString() => 'ManagedSshRecovery(redacted)';
}

abstract interface class ManagedSshRecoveryStore {
  Future<ManagedSshRecovery?> load(
    ManagedSshConfig target,
    SshAgentTransport transport,
  );
  Future<void> save(ManagedSshRecovery selection);
}

/// A bounded secure pointer set, separate from direct endpoints/legacy slots.
/// The app-scoped controller serializes writes and keeps failed saves explicit.
class SecureManagedSshRecoveryStore implements ManagedSshRecoveryStore {
  SecureManagedSshRecoveryStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  static const key = 'wing.hermes.ssh_recovery.v1';
  final FlutterSecureStorage _storage;

  Future<List<ManagedSshRecovery>> _load() async {
    final encoded = await _storage.read(key: key);
    if (encoded == null) return [];
    if (encoded.length > 65536) throw const FormatException();
    final rows = jsonDecode(encoded);
    if (rows is! List || rows.length > 32) throw const FormatException();
    return rows.map(ManagedSshRecovery.fromJson).toList();
  }

  @override
  Future<ManagedSshRecovery?> load(
    ManagedSshConfig target,
    SshAgentTransport transport,
  ) async => (await _load())
      .where((row) => row.matches(target, transport))
      .firstOrNull;

  @override
  Future<void> save(ManagedSshRecovery selection) async {
    // Apply the same bounds before writing as on subsequent reads.
    ManagedSshRecovery.fromJson(selection.toJson());
    final rows = await _load();
    rows.removeWhere(
      (r) => r.matches(selection.configuration, selection.transport),
    );
    if (rows.length >= 32) throw StateError('SSH recovery storage is full.');
    rows.add(selection);
    final encoded = jsonEncode(rows.map((r) => r.toJson()).toList());
    if (encoded.length > 65536) throw const FormatException();
    await _storage.write(key: key, value: encoded);
  }
}
