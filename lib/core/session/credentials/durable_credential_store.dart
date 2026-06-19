import '../shared/session_text.dart';

class GatewayCredentialMetadata {
  const GatewayCredentialMetadata({
    required this.gatewayId,
    required this.appInstallIdentity,
    required this.credentialLabel,
    required this.createdAt,
    this.lastUsedAt,
  });

  final String gatewayId;
  final String appInstallIdentity;
  final String credentialLabel;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  bool get isUsableMetadata {
    return isNonBlankSessionText(gatewayId) &&
        isNonBlankSessionText(appInstallIdentity) &&
        isNonBlankSessionText(credentialLabel);
  }
}

abstract interface class DurableCredentialStore {
  Future<bool> containsCredential({required String gatewayId});

  Future<GatewayCredentialMetadata?> metadata({required String gatewayId});

  /// Persists a durable reconnect [secret] for a gateway behind platform secure
  /// storage, alongside its non-secret [metadata]. Implementations must never
  /// write the secret to shared preferences, logs, or other non-secure storage.
  Future<void> saveCredential({
    required GatewayCredentialMetadata metadata,
    required String secret,
  });

  /// Returns the stored secret for [gatewayId], or null if not present.
  /// The caller must treat the returned value as a secret and never log it.
  Future<String?> loadSecret({required String gatewayId});

  Future<void> deleteCredential({required String gatewayId});
}

/// Default store that persists nothing. Production uses this until a platform
/// secure-storage implementation is injected, so no secret is ever written to
/// insecure storage; `containsCredential` stays false and reconnect readiness
/// therefore never claims "saved".
class EmptyDurableCredentialStore implements DurableCredentialStore {
  const EmptyDurableCredentialStore();

  @override
  Future<bool> containsCredential({required String gatewayId}) async => false;

  @override
  Future<GatewayCredentialMetadata?> metadata({
    required String gatewayId,
  }) async => null;

  @override
  Future<void> saveCredential({
    required GatewayCredentialMetadata metadata,
    required String secret,
  }) async {}

  @override
  Future<String?> loadSecret({required String gatewayId}) async => null;

  @override
  Future<void> deleteCredential({required String gatewayId}) async {}
}
