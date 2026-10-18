import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ssh_types.dart';

/// Durable destination and selection, never a forwarded origin or credential.
class ManagedSshTarget {
  const ManagedSshTarget({
    required this.config,
    required this.serveReads,
    this.selection,
  });

  final ManagedSshConfig config;
  final bool serveReads;
  final ({String profile, String? session})? selection;

  bool sameDestination(ManagedSshTarget other) =>
      config.host == other.config.host &&
      config.sshPort == other.config.sshPort &&
      config.username == other.config.username &&
      config.agentPort == other.config.agentPort &&
      config.agentProfile == other.config.agentProfile &&
      serveReads == other.serveReads;

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

  static bool _identity(dynamic value) =>
      value is String &&
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(value);

  Future<ManagedSshTarget?> load() async {
    try {
      if (kIsWeb) throw const FormatException();
      final raw = await storage.read(key: _slot);
      if (raw == null) return null;
      if (raw.length > 1024) throw const FormatException();
      final data = jsonDecode(raw);
      if (data is! List ||
          (data.length != 5 && data.length != 7 && data.length != 8) ||
          data[0] is! String ||
          data[1] is! int ||
          data[2] is! String ||
          data[3] is! int ||
          data[4] is! bool) {
        throw const FormatException();
      }
      if (data.length == 8 &&
          (data[7] is! String ||
              data[4] == true ||
              data[5] != null ||
              data[6] != null ||
              !ManagedSshConfig.validAgentProfile(data[7] as String))) {
        throw const FormatException();
      }
      // Five/seven fields are legacy root records; eight adds only an API ID.
      if (data.length == 7 &&
          (data[4] != true ||
              !_identity(data[5]) ||
              (data[6] != null && !_identity(data[6])))) {
        throw const FormatException();
      }
      return ManagedSshTarget(
        config: ManagedSshConfig(
          host: data[0] as String,
          sshPort: data[1] as int,
          username: data[2] as String,
          agentPort: data[3] as int,
          agentProfile: data.length == 8 ? data[7] as String : null,
        ),
        serveReads: data[4] as bool,
        selection: data.length >= 7 && data[5] != null
            ? (profile: data[5] as String, session: data[6] as String?)
            : null,
      );
    } catch (_) {
      throw const FormatException('Saved SSH settings unavailable');
    }
  }

  Future<void> save(ManagedSshTarget target) => _save(target);

  /// Never create or replace a destination without explicit Save settings.
  Future<void> rememberSelection(ManagedSshTarget target) =>
      _save(target, onlyMatching: true);

  Future<void> _save(
    ManagedSshTarget target, {
    bool onlyMatching = false,
  }) async {
    // Serialize app-isolate writes so cancelled older saves cannot finish last.
    final previous = _pending;
    final release = Completer<void>();
    _pending = release.future;
    if (previous != null) await previous;
    try {
      if (kIsWeb) throw const FormatException();
      if (onlyMatching) {
        final saved = await load();
        if (saved == null || !saved.sameDestination(target)) return;
      }
      final selection = target.selection;
      if (selection != null &&
          (!target.serveReads ||
              !_identity(selection.profile) ||
              (selection.session != null && !_identity(selection.session)))) {
        throw const FormatException();
      }
      final config = target.config;
      if (target.serveReads && config.agentProfile != null) {
        throw const FormatException();
      }
      final raw = jsonEncode([
        config.host,
        config.sshPort,
        config.username,
        config.agentPort,
        target.serveReads,
        if (selection != null) ...[
          selection.profile,
          selection.session,
        ] else if (config.agentProfile != null) ...[
          null,
          null,
        ],
        if (config.agentProfile != null) config.agentProfile,
      ]);
      if (raw.length > 1024) throw const FormatException();
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
