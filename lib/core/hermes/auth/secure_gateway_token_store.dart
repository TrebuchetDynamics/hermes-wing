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

  Future<void> save(GatewayTokenSet tokens) async {
    final origin = validateGatewayOrigin(tokens.origin);
    try {
      await _storage.write(
        key: _key(origin),
        value: jsonEncode({
          'origin': origin.toString(),
          'tokens': tokens.toSecureJson(),
        }),
      );
    } catch (_) {
      throw const GatewayAuthException('secure_storage_failed');
    }
  }

  Future<GatewayTokenSet?> load(Uri origin) async {
    final scope = validateGatewayOrigin(origin);
    try {
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
      await _storage.delete(key: _key(scope));
    } catch (_) {
      throw const GatewayAuthException('secure_storage_failed');
    }
  }
}
