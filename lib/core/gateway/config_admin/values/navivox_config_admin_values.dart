import '../../../protocol/config_wire_fields.dart';
import '../../../protocol/navivox_json.dart';
import '../../shared/navivox_gateway_json.dart';
import '../status/config_admin_status_fields.dart';

class NavivoxConfigAdminValue {
  const NavivoxConfigAdminValue({
    required this.key,
    required this.type,
    this.value,
    this.secret = false,
    this.secretStatus = '',
    this.source = '',
  });

  factory NavivoxConfigAdminValue.fromJson(Map<String, Object?> json) {
    final secret = navivoxGatewayBoolField(json, 'secret');
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
  final Object? value;
  final bool secret;
  final String secretStatus;
  final String source;

  Object? get formValue {
    if (!secret) return value;
    return {
      'secret_status': secretStatus,
      if (source.isNotEmpty) 'source': source,
    };
  }
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
