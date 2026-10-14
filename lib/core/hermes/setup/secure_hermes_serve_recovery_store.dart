import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/hermes_web_reads.dart';

/// A connection pointer and uncertainty fence, never cached content or a write queue.
class HermesServeRecoverySelection {
  const HermesServeRecoverySelection(this.checkpoint, this.credential);
  final HermesWebRecovery checkpoint;
  final String credential;
}

abstract interface class HermesServeRecoveryStore {
  Future<HermesServeRecoverySelection?> load();
  Future<void> save(HermesServeRecoverySelection selection);
  Future<void> clear();
}

class SecureHermesServeRecoveryStore implements HermesServeRecoveryStore {
  SecureHermesServeRecoveryStore({FlutterSecureStorage? secureStorage})
    : _storage = secureStorage ?? const FlutterSecureStorage();
  static const key = 'wing.hermes.serve_recovery.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<HermesServeRecoverySelection?> load() async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    if (raw.length > 32768) webMalformed();
    final row = webObject(jsonDecode(raw));
    webIdentity(row['version'], 1);
    final origin = Uri.parse(webString(row['origin'], maximum: 2048));
    if (!{'127.0.0.1', '::1'}.contains(origin.host) ||
        origin.scheme != 'http' ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      webMalformed();
    }
    String identity(String key) {
      final value = webString(row[key], maximum: 128);
      if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(value)) {
        webMalformed();
      }
      return value;
    }

    if (row['uncertain'] is! bool) webMalformed();
    return HermesServeRecoverySelection(
      HermesWebRecovery(
        origin: origin,
        profile: identity('profile'),
        storedSessionId: identity('stored'),
        runtimeSessionId: identity('runtime'),
        epoch: webString(row['epoch'], maximum: 128),
        sequence: webInteger(row['sequence'], maximum: 9007199254740991),
        uncertain: row['uncertain'] as bool,
      ),
      webString(row['credential'], maximum: 16384),
    );
  }

  @override
  Future<void> save(HermesServeRecoverySelection selection) async {
    final c = selection.checkpoint;
    await _storage.write(
      key: key,
      value: jsonEncode({
        'version': 1,
        'origin': c.origin.toString(),
        'profile': c.profile,
        'stored': c.storedSessionId,
        'runtime': c.runtimeSessionId,
        'epoch': c.epoch,
        'sequence': c.sequence,
        'uncertain': c.uncertain,
        'credential': selection.credential,
      }),
    );
  }

  @override
  Future<void> clear() => _storage.delete(key: key);
}
