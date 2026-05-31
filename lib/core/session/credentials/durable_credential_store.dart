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

  Future<void> deleteCredential({required String gatewayId});
}

class EmptyDurableCredentialStore implements DurableCredentialStore {
  const EmptyDurableCredentialStore();

  @override
  Future<bool> containsCredential({required String gatewayId}) async => false;

  @override
  Future<GatewayCredentialMetadata?> metadata({
    required String gatewayId,
  }) async => null;

  @override
  Future<void> deleteCredential({required String gatewayId}) async {}
}
