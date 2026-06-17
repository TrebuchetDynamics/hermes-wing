import '../../gateway/client/navivox_gateway_client.dart';
import '../credentials/durable_credential_store.dart';
import '../identity/app_install_identity_service.dart';
import '../readiness/reconnect_readiness.dart';

/// Orchestrates interim durable-reconnect credential issuance after a connect.
///
/// When the gateway advertises durable reconnect as available, this resolves the
/// App install identity, issues an interim device credential, persists it behind
/// the injected secure store, and reports the resulting [ReconnectReadiness].
///
/// Readiness only becomes `saved` when the store actually persisted the secret
/// (`containsCredential` is true). With the default no-op store nothing is
/// stored, so readiness honestly stays session-only rather than claiming a
/// reconnect that cannot happen. Issuance failures never undo the live
/// connection — chat continues for the app session.
class DurableReconnectIssuanceCoordinator {
  DurableReconnectIssuanceCoordinator({
    required AppInstallIdentityService appInstallIdentity,
    required DurableCredentialStore credentialStore,
    DateTime Function()? clock,
    int maxAttempts = 2,
  }) : _appInstallIdentity = appInstallIdentity,
       _credentialStore = credentialStore,
       _clock = clock ?? DateTime.now,
       _maxAttempts = maxAttempts;

  final AppInstallIdentityService _appInstallIdentity;
  final DurableCredentialStore _credentialStore;
  final DateTime Function() _clock;
  final int _maxAttempts;

  static const ReconnectReadiness saved = ReconnectReadiness(
    kind: ReconnectReadinessKind.saved,
    message: 'Reconnect saved for this gateway.',
  );

  static const ReconnectReadiness sessionOnly = ReconnectReadiness(
    kind: ReconnectReadinessKind.available,
    message: 'Connected for this session; reconnect not saved.',
  );

  Future<ReconnectReadiness> persist({
    required NavivoxGatewayClient client,
    required String gatewayId,
    required ReconnectReadiness currentReadiness,
  }) async {
    // Only act when the gateway advertised durable reconnect as available and
    // we have a stable gateway identity to bind the credential to.
    if (currentReadiness.kind != ReconnectReadinessKind.available ||
        gatewayId.trim().isEmpty) {
      return currentReadiness;
    }

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final appInstallId = await _appInstallIdentity.getOrCreate();
        final result = await client.issueDeviceCredential(
          appInstallId: appInstallId,
        );
        if (!result.isUsable) {
          // A malformed/unusable result is not retryable; stay session-only.
          return sessionOnly;
        }
        await _credentialStore.saveCredential(
          metadata: GatewayCredentialMetadata(
            gatewayId: gatewayId,
            appInstallIdentity: appInstallId,
            credentialLabel: result.credentialId,
            createdAt: _clock(),
          ),
          secret: result.secret,
        );
        final persisted = await _credentialStore.containsCredential(
          gatewayId: gatewayId,
        );
        return persisted ? saved : sessionOnly;
      } catch (_) {
        // One bounded retry for transient issuance failures, then stop and
        // leave the operator session-only without undoing the connection.
        if (attempt >= _maxAttempts) return sessionOnly;
      }
    }
    return sessionOnly;
  }
}
