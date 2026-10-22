import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'gateway_auth_models.dart';

/// Dedicated secure slots; never reads or migrates legacy credential files.
/// Call save only after the caller's owner/generation check. Login and refresh
/// return values without persisting so cancelled UI work cannot save implicitly.
class SecureGatewayTokenStore {
  SecureGatewayTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  String _key(Uri origin) =>
      'wing.gateway.native_tokens.v1.'
      '${sha256.convert(utf8.encode(origin.toString()))}';

  static final Map<String, Future<void>> _pending = {};

  Future<T> _serialized<T>(Uri origin, Future<T> Function() action) async {
    final key = _key(origin);
    final previous = _pending[key];
    final release = Completer<void>();
    _pending[key] = release.future;
    try {
      if (previous != null) await previous;
      return await action();
    } finally {
      release.complete();
      if (identical(_pending[key], release.future)) {
        final removed = _pending.remove(key);
        if (removed != null) unawaited(removed);
      }
    }
  }

  Future<void> save(
    GatewayTokenSet tokens, {
    bool Function()? isCurrent,
  }) async {
    final origin = validateGatewayOrigin(tokens.origin);
    try {
      await _serialized(origin, () async {
        final previous = await _storage.read(key: _key(origin));
        if (!(isCurrent?.call() ?? true)) return;
        await _storage.write(
          key: _key(origin),
          value: jsonEncode({
            'origin': origin.toString(),
            'tokens': tokens.toSecureJson(),
          }),
        );
        // The platform write is not cancellable. Roll back under the same lock
        // before another save/delete can run, never overwriting a newer owner.
        if (!(isCurrent?.call() ?? true)) {
          if (previous == null) {
            await _storage.delete(key: _key(origin));
          } else {
            await _storage.write(key: _key(origin), value: previous);
          }
        }
      });
    } catch (_) {
      throw const GatewayAuthException('secure_storage_failed');
    }
  }

  Future<GatewayTokenSet?> load(Uri origin) async {
    final scope = validateGatewayOrigin(origin);
    try {
      final pending = _pending[_key(scope)];
      if (pending != null) await pending;
      final raw = await _storage.read(key: _key(scope));
      if (raw == null) return null;
      if (utf8.encode(raw).length > 65536) {
        throw const GatewayAuthException('invalid_stored_tokens');
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['origin'] != scope.toString() ||
          decoded['tokens'] is! Map<String, dynamic>) {
        throw const GatewayAuthException('invalid_stored_tokens');
      }
      return GatewayTokenSet.fromJson(
        scope,
        decoded['tokens'] as Map<String, dynamic>,
      );
    } catch (_) {
      throw const GatewayAuthException('secure_storage_failed');
    }
  }

  Future<void> delete(Uri origin) async {
    final scope = validateGatewayOrigin(origin);
    try {
      await _serialized(scope, () => _storage.delete(key: _key(scope)));
    } catch (_) {
      throw const GatewayAuthException('secure_storage_failed');
    }
  }
}
