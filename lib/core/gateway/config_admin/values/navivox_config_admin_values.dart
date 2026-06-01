import '../../../protocol/config_wire_fields.dart';
import '../../../protocol/navivox_json.dart';
import '../../shared/navivox_gateway_json.dart';
import '../status/config_admin_status_fields.dart';
import 'config_admin_secret_policy.dart';

class NavivoxConfigAdminValue {
  const NavivoxConfigAdminValue({
    required this.key,
    required this.type,
    Object? value,
    this.secret = false,
    this.secretStatus = '',
    this.source = '',
  }) : _value = value;

  factory NavivoxConfigAdminValue.fromJson(Map<String, Object?> json) {
    final secret = configAdminIsSecret(json);
    return NavivoxConfigAdminValue(
      key: configWireStringFromAliases(json, const ['key', 'path']) ?? '',
      type: configWireString(json['type']) ?? 'string',
      value: configAdminStoredValue(value: json['value'], secret: secret),
      secret: secret,
      secretStatus: configAdminStatusStringFromAliases(
        json,
        configAdminSecretStatusAliases,
      ),
      source: configWireString(json['source']) ?? '',
    );
  }

  final String key;
  final String type;
  final Object? _value;
  final bool secret;
  final String secretStatus;
  final String source;

  bool get _isSecret => secret || configAdminTypeIsSecret(type);

  Object? get value {
    return configAdminStoredValue(value: _value, secret: _isSecret);
  }

  Object? get formValue {
    if (!_isSecret) return value;
    return configAdminSecretFormValue(
      secretStatus: secretStatus,
      source: source,
    );
  }
}

/// Returns non-secret form metadata for secret config values.
///
/// Constructed DTOs and parsed gateway values must expose the same trimmed
/// provenance shape so UI snapshots cannot diverge based on construction path.
Map<String, Object?> configAdminSecretFormValue({
  required String secretStatus,
  String source = '',
}) {
  final normalizedStatus = secretStatus.trim();
  final normalizedSource = source.trim();
  return {
    'secret_status': normalizedStatus,
    if (normalizedSource.isNotEmpty) 'source': normalizedSource,
  };
}

/// Returns the non-secret value payload that may be retained in app memory.
///
/// Gateway responses should already redact secrets, but this client-side guard
/// makes accidental raw secret echoing non-replayable through DTO fields,
/// snapshots, or debug output.
Object? configAdminStoredValue({required Object? value, required bool secret}) {
  if (secret) return null;
  return value;
}

class NavivoxConfigAdminGetResponse {
  const NavivoxConfigAdminGetResponse({
    required this.action,
    this.values = const [],
  });

  factory NavivoxConfigAdminGetResponse.fromJson(Map<String, Object?> json) {
    return NavivoxConfigAdminGetResponse(
      action: navivoxStringFieldFromJson(json, 'action'),
      values: navivoxGatewayObjectListWhereHasText(
        json['values'],
        NavivoxConfigAdminValue.fromJson,
        (value) => value.key,
      ),
    );
  }

  final String action;
  final List<NavivoxConfigAdminValue> values;

  Map<String, Object?> toConfigValues() {
    return {for (final value in values) value.key: value.formValue};
  }
}
