import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/hermes_web_reads.dart';
import 'hermes_gateway_invite.dart';

/// Durable exact-session pointer; no token, transcript or mutation queue.
class SecureGatewayRecoveryStore {
  SecureGatewayRecoveryStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _slot = 'wing.hermes.gateway_selection.v1';

  Future<HermesWebRecovery?> load(HermesGatewayInvite invite) async {
    final raw = await _storage.read(key: _slot);
    if (raw == null) return null;
    if (raw.length > 4096) {
      throw const FormatException('Gateway recovery unavailable');
    }
    final row = jsonDecode(raw) as Map<String, dynamic>;
    if (row['origin'] != invite.origin.replace(path: '').toString() ||
        row['profile'] != invite.profile) {
      return null;
    }
    String identity(String key) {
      final value = row[key];
      if (value is! String ||
          !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(value)) {
        throw const FormatException('Gateway recovery unavailable');
      }
      return value;
    }

    if (row['uncertain'] is! bool ||
        row['sequence'] is! int ||
        (row['sequence'] as int) < 0 ||
        row['epoch'] is! String ||
        (row['epoch'] as String).length > 128) {
      throw const FormatException('Gateway recovery unavailable');
    }
    return HermesWebRecovery(
      origin: invite.origin,
      profile: identity('profile'),
      runtimeSessionId: identity('runtime'),
      storedSessionId: identity('stored'),
      epoch: row['epoch'] as String,
      sequence: row['sequence'] as int,
      uncertain: row['uncertain'] as bool,
    );
  }

  Future<void> save(HermesWebRecovery c) async {
    HermesGatewayInvite(origin: c.origin, profile: c.profile);
    await _storage.write(
      key: _slot,
      value: jsonEncode({
        'origin': c.origin.replace(path: '').toString(),
        'profile': c.profile,
        'runtime': c.runtimeSessionId,
        'stored': c.storedSessionId,
        'epoch': c.epoch,
        'sequence': c.sequence,
        'uncertain': c.uncertain,
      }),
    );
  }
}
