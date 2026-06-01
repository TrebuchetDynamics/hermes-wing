import 'config_form_field_type.dart';
import 'config_form_schema_wire.dart';
import 'config_risk_level.dart';

class ConfigFormSchemaRowCandidate {
  const ConfigFormSchemaRowCandidate._({
    required this.field,
    required this.label,
    required this.type,
    required this.required,
    required this.restartRequired,
    required this.riskLevel,
    required this.requiresConfirmation,
    required this.rawValue,
    required this.allowedValues,
    required this.actions,
    required this.reloadMode,
  });

  static ConfigFormSchemaRowCandidate? fromRaw({
    required Object? raw,
    required Map<String, Object?> values,
  }) {
    if (raw is! Map) return null;
    final field = configFormFieldPathFromSchema(raw);
    if (field == null || field.isEmpty) return null;

    final declaredType = ConfigFormFieldType.fromWire(raw['type']?.toString());
    final secret =
        configFormBoolFromSchema(raw, const ['secret']) ||
        declaredType == ConfigFormFieldType.secret;
    final riskLevel = configFormRiskLevelFromSchema(raw);
    final reloadMode = configFormReloadModeFromSchema(raw);

    return ConfigFormSchemaRowCandidate._(
      field: field,
      label: configFormFieldLabelFromSchema(raw, field),
      type: secret ? ConfigFormFieldType.secret : declaredType,
      required: configFormBoolFromSchema(raw, const ['required']),
      restartRequired:
          configFormBoolFromSchema(raw, const ['restart_required']) ||
          configFormReloadModeRequiresRestart(reloadMode),
      riskLevel: riskLevel,
      requiresConfirmation: configRequiresConfirmation(
        explicitRequiresConfirmation: configFormBoolFromSchema(raw, const [
          'requires_confirmation',
        ]),
        riskLevel: riskLevel,
      ),
      rawValue: values[field],
      allowedValues: configFormAllowedValuesFromSchema(raw),
      actions: configFormActionsFromSchema(raw),
      reloadMode: reloadMode,
    );
  }

  final String field;
  final String label;
  final ConfigFormFieldType type;
  final bool required;
  final bool restartRequired;
  final String riskLevel;
  final bool requiresConfirmation;
  final Object? rawValue;
  final List<String> allowedValues;
  final List<String> actions;
  final String reloadMode;
}

bool configFormReloadModeRequiresRestart(String reloadMode) {
  final tokens = configFormReloadModeTokens(reloadMode);
  if (tokens.isEmpty) return false;
  if (tokens.contains('no') || tokens.contains('without')) return false;
  return tokens.contains('restart');
}

List<String> configFormReloadModeTokens(String reloadMode) {
  return reloadMode
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}
