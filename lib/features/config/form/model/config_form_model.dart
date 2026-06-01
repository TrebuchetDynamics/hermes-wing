import '../../shared/config_value_display.dart';
import '../editing/config_edit_text.dart';
import 'config_edit_value_coercion.dart';
import 'config_form_field_type.dart';
import 'config_form_schema_row.dart';
import 'config_form_sections.dart';

export 'config_form_field_type.dart';
export 'config_form_sections.dart'
    show ConfigFormSection, ConfigSectionSelection;

class ConfigFormModel {
  ConfigFormModel({
    required List<ConfigFormRow> rows,
    required List<ConfigFormSection> sections,
  }) : rows = List.unmodifiable(rows),
       sections = List.unmodifiable(sections);

  factory ConfigFormModel.fromSchema({
    required Map<String, Object?>? schema,
    required Map<String, Object?> values,
  }) {
    final rawFields = schema?['fields'];
    if (rawFields is! List) {
      return ConfigFormModel(rows: const [], sections: const []);
    }

    final rows = _buildRowsFromSchemaFields(
      rawFields: rawFields,
      values: values,
    );
    return ConfigFormModel(
      rows: rows,
      sections: buildConfigFormSections(
        rawSections: schema?['sections'],
        rows: rows,
      ),
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
}

List<ConfigFormRow> _buildRowsFromSchemaFields({
  required List rawFields,
  required Map<String, Object?> values,
}) {
  final rows = <ConfigFormRow>[];
  final seenFields = <String>{};
  for (final raw in rawFields) {
    final candidate = ConfigFormSchemaRowCandidate.fromRaw(
      raw: raw,
      values: values,
    );
    if (candidate == null || !seenFields.add(candidate.field)) continue;
    rows.add(ConfigFormRow.fromSchemaCandidate(candidate));
  }
  return rows;
}

class ConfigFormRow {
  factory ConfigFormRow.fromSchemaCandidate(
    ConfigFormSchemaRowCandidate candidate,
  ) {
    return ConfigFormRow(
      field: candidate.field,
      label: candidate.label,
      type: candidate.type,
      required: candidate.required,
      restartRequired: candidate.restartRequired,
      riskLevel: candidate.riskLevel,
      requiresConfirmation: candidate.requiresConfirmation,
      rawValue: candidate.rawValue,
      allowedValues: candidate.allowedValues,
      actions: candidate.actions,
      reloadMode: candidate.reloadMode,
    );
  }

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
    return configEditTextFromValue(_plainValue(rawValue));
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
