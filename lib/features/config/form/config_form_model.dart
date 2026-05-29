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
      final field = (raw['path'] ?? raw['key'] ?? raw['name'])
          ?.toString()
          .trim();
      if (field == null || field.isEmpty) continue;
      final type = ConfigFormFieldType.fromWire(raw['type']?.toString());
      final secret =
          raw['secret'] == true || type == ConfigFormFieldType.secret;
      rows.add(
        ConfigFormRow(
          field: field,
          label: _fieldLabel(raw, field),
          type: secret ? ConfigFormFieldType.secret : type,
          required: raw['required'] == true,
          restartRequired:
              raw['restart_required'] == true ||
              raw['reload']?.toString().contains('restart') == true,
          riskLevel:
              raw['risk_level']?.toString().trim().toLowerCase() ?? 'low',
          requiresConfirmation:
              raw['requires_confirmation'] == true ||
              raw['risk_level']?.toString().trim().toLowerCase() == 'high',
          rawValue: values[field],
          allowedValues: _stringList(raw['allowed']),
          actions: _stringList(raw['actions']),
          reloadMode: raw['reload']?.toString().trim() ?? '',
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
      final id = _sectionText(raw['id']) ?? 'section-${sections.length + 1}';
      sections.add(
        ConfigFormSection(
          id: id,
          label: _sectionText(raw['label']) ?? id,
          description: _sectionText(raw['description']),
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
    for (final key in const ['label', 'title']) {
      final text = raw[key]?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return fallback;
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _sectionFieldRefs(Object? rawFields) {
    if (rawFields is! List) return const [];
    final refs = <String>[];
    for (final raw in rawFields) {
      final field = raw is Map ? raw['path'] ?? raw['key'] ?? raw['name'] : raw;
      final text = field?.toString().trim();
      if (text != null && text.isNotEmpty) refs.add(text);
    }
    return refs;
  }

  static String? _sectionText(Object? raw) {
    final text = raw?.toString().trim();
    return text == null || text.isEmpty ? null : text;
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

enum ConfigFormFieldType {
  string,
  number,
  integer,
  boolean,
  secret;

  factory ConfigFormFieldType.fromWire(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'number' => ConfigFormFieldType.number,
      'integer' || 'int' => ConfigFormFieldType.integer,
      'boolean' || 'bool' => ConfigFormFieldType.boolean,
      'secret' => ConfigFormFieldType.secret,
      'enum' || 'string_list' => ConfigFormFieldType.string,
      _ => ConfigFormFieldType.string,
    };
  }

  bool get isNumeric =>
      this == ConfigFormFieldType.number || this == ConfigFormFieldType.integer;
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
    if (isSecret) return _secretDisplayValue(rawValue);
    final value = _plainValue(rawValue);
    if (value == null) return '—';
    if (value is Iterable) return value.join(', ');
    return '$value';
  }

  String get editInitialValue {
    if (isSecret) return '';
    final value = _plainValue(rawValue);
    return value == null ? '' : '$value';
  }

  Object? coerceEditValue(String raw) {
    final text = raw.trim();
    if (isSecret) return text;
    return switch (type) {
      ConfigFormFieldType.number => num.tryParse(text) ?? raw,
      ConfigFormFieldType.integer =>
        int.tryParse(text) ?? num.tryParse(text) ?? raw,
      ConfigFormFieldType.boolean => text.toLowerCase() == 'true',
      ConfigFormFieldType.string => raw,
      ConfigFormFieldType.secret => text,
    };
  }

  static Object? _plainValue(Object? rawValue) {
    if (rawValue is Map && rawValue.containsKey('value')) {
      return rawValue['value'];
    }
    return rawValue;
  }

  static String _secretDisplayValue(Object? rawValue) {
    if (rawValue == null) return 'Secret not set';
    if (rawValue is Map) {
      final status = rawValue['secret_status']?.toString().trim().toLowerCase();
      return switch (status) {
        'configured' || 'external' || 'set' => _secretConfiguredLabel(rawValue),
        'unset' => 'Secret not set',
        'unknown' => 'Secret status unknown',
        _ => 'Secret configured',
      };
    }
    return 'Secret configured';
  }

  static String _secretConfiguredLabel(Map rawValue) {
    final source = rawValue['source']?.toString().trim();
    if (source == null || source.isEmpty) return 'Secret configured';
    return 'Secret configured ($source)';
  }
}
