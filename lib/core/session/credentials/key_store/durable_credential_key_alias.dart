import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../shared/session_text.dart';

class DurableCredentialKeyAlias {
  const DurableCredentialKeyAlias.native(this.value);

  factory DurableCredentialKeyAlias.forGatewayInstall({
    required String gatewayId,
    required String appInstallIdentity,
  }) {
    final gateway = requiredSessionText(gatewayId, fieldName: 'gatewayId');
    final install = requiredSessionText(
      appInstallIdentity,
      fieldName: 'appInstallIdentity',
    );
    final digest = sha256.convert(utf8.encode('$gateway\u0000$install'));
    return DurableCredentialKeyAlias.native('navivox_durable_$digest');
  }

  final String value;

  @override
  String toString() => value;
}
