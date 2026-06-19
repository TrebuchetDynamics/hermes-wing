import '../../protocol/navivox_json.dart';
import '../shared/navivox_gateway_json.dart';

/// Typed result of issuing an interim Navivox device credential.
///
/// The [secret] is the one-time durable-reconnect bearer returned by the
/// gateway. Callers must hand it straight to secure storage and never log it or
/// surface it in normal UI.
class NavivoxDeviceCredentialIssueResult {
  const NavivoxDeviceCredentialIssueResult({
    required this.credentialId,
    required this.secret,
    required this.authMethod,
    required this.scopes,
    required this.gatewayId,
    required this.appInstallId,
    required this.interim,
    this.expiresAt,
  });

  factory NavivoxDeviceCredentialIssueResult.fromJson(
    Map<String, Object?> json,
  ) {
    final expiresAtRaw = json['expires_at'];
    return NavivoxDeviceCredentialIssueResult(
      credentialId: navivoxStringFieldFromJson(json, 'credential_id'),
      secret: navivoxStringFieldFromJson(json, 'secret'),
      authMethod: navivoxStringFieldFromJson(json, 'auth_method'),
      scopes: navivoxStringListFromJson(json['scopes']),
      gatewayId: navivoxStringFieldFromJson(json, 'gateway_id'),
      appInstallId: navivoxStringFieldFromJson(json, 'app_install_id'),
      interim: navivoxGatewayBoolField(json, 'interim'),
      expiresAt:
          expiresAtRaw is String ? DateTime.tryParse(expiresAtRaw) : null,
    );
  }

  final String credentialId;
  final String secret;
  final String authMethod;
  final List<String> scopes;
  final String gatewayId;
  final String appInstallId;
  final bool interim;
  final DateTime? expiresAt;

  /// A credential is only usable when the gateway returned both an id and the
  /// one-time secret.
  bool get isUsable => credentialId.isNotEmpty && secret.isNotEmpty;
}
