import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ssh_types.dart';

/// Durable destination, never a forwarded origin, credential or trust decision.
class ManagedSshTarget {
  const ManagedSshTarget({required this.config, required this.serveReads});

  final ManagedSshConfig config;
  final bool serveReads;

  @override
  String toString() => 'ManagedSshTarget(<redacted>)';
}

class SecureManagedSshTargetStore {
  const SecureManagedSshTargetStore({
    this.storage = const FlutterSecureStorage(),
  });

  final FlutterSecureStorage storage;
  static const _slot = 'hermes_wing.managed_ssh.target.v1';
  static Future<void>? _pending;

  Future<ManagedSshTarget?> load() async {
    try {
      if (kIsWeb) throw const FormatException();
      final raw = await storage.read(key: _slot);
      if (raw == null) return null;
      if (raw.length > 1024) throw const FormatException();
      final data = jsonDecode(raw);
      if (data is! List ||
          data.length != 5 ||
          data[0] is! String ||
          data[1] is! int ||
          data[2] is! String ||
          data[3] is! int ||
          data[4] is! bool) {
        throw const FormatException();
      }
      return ManagedSshTarget(
        config: ManagedSshConfig(
          host: data[0] as String,
          sshPort: data[1] as int,
          username: data[2] as String,
          agentPort: data[3] as int,
        ),
        serveReads: data[4] as bool,
      );
    } catch (_) {
      throw const FormatException('Saved SSH settings unavailable');
    }
  }

  Future<void> save(ManagedSshTarget target) async {
    // Serialize app-isolate writes so cancelled older saves cannot finish last.
    final previous = _pending;
    final release = Completer<void>();
    _pending = release.future;
    if (previous != null) await previous;
    try {
      if (kIsWeb) throw const FormatException();
      final config = target.config;
      final raw = jsonEncode([
        config.host,
        config.sshPort,
        config.username,
        config.agentPort,
        target.serveReads,
      ]);
      await storage.write(key: _slot, value: raw);
      if (await storage.read(key: _slot) != raw) throw const FormatException();
    } catch (_) {
      throw const FormatException('Saved SSH settings unavailable');
    } finally {
      if (identical(_pending, release.future)) _pending = null;
      release.complete();
    }
  }
}
