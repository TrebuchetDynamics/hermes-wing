import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'durable_credential_store.dart';

/// [DurableCredentialStore] backed by the platform secure enclave
/// (Android Keystore / iOS Keychain).
///
/// The raw device-credential secret never leaves secure storage after write.
/// It is loaded only to form a device-bearer reconnect token at startup.
///
/// Navivox never stores device credentials in `shared_preferences`.
class SecureStorageDurableCredentialStore implements DurableCredentialStore {
  const SecureStorageDurableCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _secretKeyPrefix = 'navivox.dc.secret.';
  static const _metaKeyPrefix = 'navivox.dc.meta.';

  String _secretKey(String gatewayId) => '$_secretKeyPrefix$gatewayId';
  String _metaKey(String gatewayId) => '$_metaKeyPrefix$gatewayId';

  @override
  Future<bool> containsCredential({required String gatewayId}) async {
    final value = await _storage.read(key: _secretKey(gatewayId));
    return value != null && value.isNotEmpty;
  }

  @override
  Future<GatewayCredentialMetadata?> metadata({required String gatewayId}) async {
    final raw = await _storage.read(key: _metaKey(gatewayId));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final createdAtRaw = json['created_at'] as String?;
      if (createdAtRaw == null) return null;
      return GatewayCredentialMetadata(
        gatewayId: json['gateway_id'] as String? ?? gatewayId,
        appInstallIdentity: json['app_install_identity'] as String? ?? '',
        credentialLabel: json['credential_label'] as String? ?? '',
        createdAt: DateTime.parse(createdAtRaw),
        lastUsedAt:
            json['last_used_at'] != null
                ? DateTime.tryParse(json['last_used_at'] as String)
                : null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> loadSecret({required String gatewayId}) async {
    return _storage.read(key: _secretKey(gatewayId));
  }

  @override
  Future<void> saveCredential({
    required GatewayCredentialMetadata metadata,
    required String secret,
  }) async {
    final metaJson = jsonEncode({
      'gateway_id': metadata.gatewayId,
      'app_install_identity': metadata.appInstallIdentity,
      'credential_label': metadata.credentialLabel,
      'created_at': metadata.createdAt.toIso8601String(),
      if (metadata.lastUsedAt != null)
        'last_used_at': metadata.lastUsedAt!.toIso8601String(),
    });
    // Write metadata first so that a crash between the two writes leaves
    // containsCredential returning false (no secret = not usable).
    await _storage.write(
      key: _metaKey(metadata.gatewayId),
      value: metaJson,
    );
    await _storage.write(
      key: _secretKey(metadata.gatewayId),
      value: secret,
    );
  }

  @override
  Future<void> deleteCredential({required String gatewayId}) async {
    await _storage.delete(key: _secretKey(gatewayId));
    await _storage.delete(key: _metaKey(gatewayId));
  }
}
