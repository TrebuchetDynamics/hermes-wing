import '../shared/config_value_display.dart';
import 'config_edit_value_coercion.dart';
import 'config_form_field_type.dart';
import 'config_wire_fields.dart';

export 'config_form_field_type.dart';

class ConfigFormModel {
  const ConfigFormModel({required this.rows, required this.sections});

  factory ConfigFormModel.fromSchema({
    required Map<String, Object?>? schema,
    required Map<String, Object?> values,
  }) {
    final rawFields = schema?['fields'];
    if (rawFields is! List) {
      return const ConfigFormModel(rows: [], sections: []);
    }

    final rows = <ConfigFormRow>[];
    for (final raw in rawFields) {
      if (raw is! Map) continue;
      final field = configWireStringFromAliases(raw, const [
        'path',
        'key',
        'name',
      ]);
      if (field == null || field.isEmpty) continue;
      final type = ConfigFormFieldType.fromWire(raw['type']?.toString());
      final secret =
          raw['secret'] == true || type == ConfigFormFieldType.secret;
      final riskLevel = _fieldRiskLevel(raw);
      final reloadMode = _fieldReloadMode(raw);
      rows.add(
        ConfigFormRow(
          field: field,
          label: _fieldLabel(raw, field),
          type: secret ? ConfigFormFieldType.secret : type,
          required: _fieldBool(raw, const ['required']),
          restartRequired:
              _fieldBool(raw, const ['restart_required']) ||
              _reloadModeRequiresRestart(reloadMode),
          riskLevel: riskLevel,
          requiresConfirmation:
              _fieldBool(raw, const ['requires_confirmation']) ||
              riskLevel == 'high',
          rawValue: values[field],
          allowedValues: _fieldAllowedValues(raw),
          actions: _fieldActions(raw),
          reloadMode: reloadMode,
        ),
      );
    }
    return ConfigFormModel(
      rows: rows,
      sections: _buildSections(schema?['sections'], rows),
    );
  }

  final List<ConfigFormRow> rows;
  final List<ConfigFormSection> sections;

  ConfigSectionSelection selectSection(String? sectionId) {
    final id = sectionId?.trim();
    if (id == null || id.isEmpty) {
      return ConfigSectionSelection(sections: sections);
    }
    for (final section in sections) {
      if (section.id == id) {
        return ConfigSectionSelection(sections: [section], requestedId: id);
      }
    }
    return ConfigSectionSelection(
      sections: const [],
      requestedId: id,
      missingId: id,
    );
  }

  static List<ConfigFormSection> _buildSections(
    Object? rawSections,
    List<ConfigFormRow> rows,
  ) {
    if (rows.isEmpty) return const [];
    if (rawSections is! List) {
      return [ConfigFormSection.general(rows: rows)];
    }

    final rowsByField = {for (final row in rows) row.field: row};
    final usedFields = <String>{};
    final sections = <ConfigFormSection>[];

    for (final raw in rawSections) {
      if (raw is! Map) continue;
      final sectionRows = <ConfigFormRow>[];
      for (final field in _sectionFieldRefs(raw['fields'])) {
        final row = rowsByField[field];
        if (row == null || usedFields.contains(row.field)) continue;
        sectionRows.add(row);
        usedFields.add(row.field);
      }
      if (sectionRows.isEmpty) continue;
      final id =
          configWireString(raw['id']) ?? 'section-${sections.length + 1}';
      sections.add(
        ConfigFormSection(
          id: id,
          label: configWireString(raw['label']) ?? id,
          description: configWireString(raw['description']),
          rows: sectionRows,
        ),
      );
    }

    final otherRows = rows
        .where((row) => !usedFields.contains(row.field))
        .toList(growable: false);
    if (otherRows.isNotEmpty) {
      sections.add(
        sections.isEmpty
            ? ConfigFormSection.general(rows: otherRows)
            : ConfigFormSection.other(rows: otherRows),
      );
    }
    return sections;
  }

  static String _fieldLabel(Map raw, String fallback) {
    return configWireStringFromAliases(raw, const ['label', 'title']) ??
        fallback;
  }

  static bool _fieldBool(Map raw, Iterable<String> aliases) {
    return configWireValueFromAliases(raw, aliases) == true;
  }

  static String _fieldRiskLevel(Map raw) {
    return configWireStringFromAliases(raw, const ['risk_level'])
            ?.toLowerCase() ??
        'low';
  }

  static String _fieldReloadMode(Map raw) {
    return configWireStringFromAliases(raw, const ['reload', 'reload_mode']) ??
        '';
  }

  static bool _reloadModeRequiresRestart(String reloadMode) {
    return reloadMode.toLowerCase().contains('restart');
  }

  static List<String> _fieldAllowedValues(Map raw) {
    return configWireStringListFromAliases(raw, const [
      'allowed',
      'allowed_values',
      'choices',
      'options',
    ]);
  }

  static List<String> _fieldActions(Map raw) {
    return configWireStringListFromAliases(raw, const [
      'actions',
      'supported_actions',
    ]);
  }

  static List<String> _sectionFieldRefs(Object? rawFields) {
    if (rawFields is! List) return const [];
    final refs = <String>[];
    for (final raw in rawFields) {
      final text = raw is Map
          ? configWireStringFromAliases(raw, const ['path', 'key', 'name'])
          : configWireString(raw);
      if (text != null) refs.add(text);
    }
    return refs;
  }
}

class ConfigSectionSelection {
  const ConfigSectionSelection({
    required this.sections,
    this.requestedId,
    this.missingId,
  });

  final List<ConfigFormSection> sections;
  final String? requestedId;
  final String? missingId;

  bool get isFiltered => requestedId != null;

  bool get isMissing => missingId != null;
}

class ConfigFormSection {
  const ConfigFormSection({
    required this.id,
    required this.label,
    required this.rows,
    this.description,
  });

  const ConfigFormSection.general({required this.rows})
    : id = 'general',
      label = 'General config',
      description = null;

  const ConfigFormSection.other({required this.rows})
    : id = 'other',
      label = 'Other config',
      description = null;

  final String id;
  final String label;
  final String? description;
  final List<ConfigFormRow> rows;
}

class ConfigFormRow {
  const ConfigFormRow({
    required this.field,
    required this.label,
    required this.type,
    required this.required,
    required this.restartRequired,
    required this.riskLevel,
    required this.requiresConfirmation,
    required this.rawValue,
    this.allowedValues = const [],
    this.actions = const [],
    this.reloadMode = '',
  });

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

  bool get isSecret => type == ConfigFormFieldType.secret;

  Object? get plainValue => _plainValue(rawValue);

  String get displayValue {
    if (isSecret) return configSecretDisplayValue(rawValue);
    return configDisplayValue(_plainValue(rawValue));
  }

  String get editInitialValue {
    if (isSecret) return '';
    final value = _plainValue(rawValue);
    return value == null ? '' : '$value';
  }

  Object? coerceEditValue(String raw) =>
      coerceConfigEditValue(raw: raw, type: type, isSecret: isSecret);

  static Object? _plainValue(Object? rawValue) {
    if (rawValue is Map && rawValue.containsKey('value')) {
      return rawValue['value'];
    }
    return rawValue;
  }
}
