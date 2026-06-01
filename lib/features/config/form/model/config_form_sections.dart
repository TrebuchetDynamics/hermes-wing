import 'config_form_model.dart';
import 'config_form_schema_wire.dart';

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
  ConfigFormSection({
    required this.id,
    required this.label,
    required List<ConfigFormRow> rows,
    this.description,
  }) : rows = List.unmodifiable(rows);

  ConfigFormSection.general({required List<ConfigFormRow> rows})
    : id = 'general',
      label = 'General config',
      description = null,
      rows = List.unmodifiable(rows);

  ConfigFormSection.other({required List<ConfigFormRow> rows})
    : id = 'other',
      label = 'Other config',
      description = null,
      rows = List.unmodifiable(rows);

  final String id;
  final String label;
  final String? description;
  final List<ConfigFormRow> rows;
}

List<ConfigFormSection> buildConfigFormSections({
  required Object? rawSections,
  required List<ConfigFormRow> rows,
}) {
  return configFormSectionBuildPlan(
    rawSections: rawSections,
    rows: rows,
  ).sections;
}

enum ConfigFormSectionRejectionReason { invalid, empty }

class ConfigFormSectionRejection {
  const ConfigFormSectionRejection({required this.index, required this.reason});

  final int index;
  final ConfigFormSectionRejectionReason reason;
}

class ConfigFormSectionBuildPlan {
  ConfigFormSectionBuildPlan({
    required List<ConfigFormSection> sections,
    required List<ConfigFormSectionRejection> rejections,
  }) : sections = List.unmodifiable(sections),
       rejections = List.unmodifiable(rejections);

  final List<ConfigFormSection> sections;
  final List<ConfigFormSectionRejection> rejections;

  int get skippedInvalidSections =>
      _skippedSections(ConfigFormSectionRejectionReason.invalid);

  int get skippedEmptySections =>
      _skippedSections(ConfigFormSectionRejectionReason.empty);

  int _skippedSections(ConfigFormSectionRejectionReason reason) {
    return rejections.where((rejection) => rejection.reason == reason).length;
  }
}

/// Builds sections with visibility into server-provided section candidates that
/// were ignored before the unsectioned fallback is appended.
///
/// Production callers consume only [ConfigFormSectionBuildPlan.sections], while
/// tests and diagnostics can replay invalid section maps and section maps whose
/// field references were empty, stale, duplicated, or otherwise unusable.
ConfigFormSectionBuildPlan configFormSectionBuildPlan({
  required Object? rawSections,
  required List<ConfigFormRow> rows,
}) {
  if (rows.isEmpty) {
    return ConfigFormSectionBuildPlan(sections: const [], rejections: const []);
  }
  if (rawSections is! List) {
    return ConfigFormSectionBuildPlan(
      sections: [ConfigFormSection.general(rows: rows)],
      rejections: const [],
    );
  }

  final rowsByField = {for (final row in rows) row.field: row};
  final usedFields = <String>{};
  final usedSectionIds = <String>{};
  final sections = <ConfigFormSection>[];
  final rejections = <ConfigFormSectionRejection>[];

  for (final indexedRaw in rawSections.indexed) {
    final index = indexedRaw.$1;
    final raw = indexedRaw.$2;
    if (raw is! Map) {
      rejections.add(
        ConfigFormSectionRejection(
          index: index,
          reason: ConfigFormSectionRejectionReason.invalid,
        ),
      );
      continue;
    }
    final sectionRows = _sectionRowsFromFirstUsefulFieldRefCandidate(
      rawSection: raw,
      rowsByField: rowsByField,
      usedFields: usedFields,
    );
    if (sectionRows.isEmpty) {
      rejections.add(
        ConfigFormSectionRejection(
          index: index,
          reason: ConfigFormSectionRejectionReason.empty,
        ),
      );
      continue;
    }
    final fallbackId = 'section-${sections.length + 1}';
    final requestedId = configFormSectionIdFromSchema(raw, fallbackId);
    final id = _uniqueSectionId(requestedId, usedSectionIds);
    sections.add(
      ConfigFormSection(
        id: id,
        label: configFormSectionLabelFromSchema(raw, id),
        description: configFormSectionDescriptionFromSchema(raw),
        rows: sectionRows,
      ),
    );
  }

  final otherRows = rows
      .where((row) => !usedFields.contains(row.field))
      .toList(growable: false);
  if (otherRows.isNotEmpty) {
    sections.add(
      _unsectionedRowsSection(
        rows: otherRows,
        hasServerSections: sections.isNotEmpty,
        usedSectionIds: usedSectionIds,
      ),
    );
  }
  return ConfigFormSectionBuildPlan(sections: sections, rejections: rejections);
}

List<ConfigFormRow> _sectionRowsFromFirstUsefulFieldRefCandidate({
  required Map rawSection,
  required Map<String, ConfigFormRow> rowsByField,
  required Set<String> usedFields,
}) {
  for (final candidate in configFormSectionFieldRefAliasCandidates(
    rawSection,
  )) {
    final plan = configFormSectionRowsCandidatePlan(
      rawFieldRefs: candidate,
      rowsByField: rowsByField,
      usedFields: usedFields,
    );
    if (plan.rows.isEmpty) continue;
    usedFields.addAll(plan.rows.map((row) => row.field));
    return plan.rows;
  }
  return const [];
}

enum ConfigFormSectionFieldRefRejectionReason {
  invalid,
  staleOrAlreadyUsed,
  duplicate,
}

class ConfigFormSectionFieldRefRejection {
  const ConfigFormSectionFieldRefRejection({
    required this.index,
    required this.reason,
    this.field,
  });

  final int index;
  final ConfigFormSectionFieldRefRejectionReason reason;
  final String? field;
}

class ConfigFormSectionRowsCandidatePlan {
  ConfigFormSectionRowsCandidatePlan({
    required List<ConfigFormRow> rows,
    required List<ConfigFormSectionFieldRefRejection> rejections,
  }) : rows = List.unmodifiable(rows),
       rejections = List.unmodifiable(rejections);

  final List<ConfigFormRow> rows;
  final List<ConfigFormSectionFieldRefRejection> rejections;

  int get skippedInvalidRefs =>
      _skippedRefs(ConfigFormSectionFieldRefRejectionReason.invalid);

  int get skippedStaleRefs =>
      _skippedRefs(ConfigFormSectionFieldRefRejectionReason.staleOrAlreadyUsed);

  int get skippedDuplicateRefs =>
      _skippedRefs(ConfigFormSectionFieldRefRejectionReason.duplicate);

  int _skippedRefs(ConfigFormSectionFieldRefRejectionReason reason) {
    return rejections.where((rejection) => rejection.reason == reason).length;
  }
}

ConfigFormSectionRowsCandidatePlan configFormSectionRowsCandidatePlan({
  required Object? rawFieldRefs,
  required Map<String, ConfigFormRow> rowsByField,
  required Set<String> usedFields,
}) {
  final candidateRows = <ConfigFormRow>[];
  final rejections = <ConfigFormSectionFieldRefRejection>[];
  final seenCandidateFields = <String>{};

  for (final indexedRef in _configFormSectionFieldRefDecisions(rawFieldRefs)) {
    final index = indexedRef.index;
    final field = indexedRef.field;
    if (field == null) {
      rejections.add(
        ConfigFormSectionFieldRefRejection(
          index: index,
          reason: ConfigFormSectionFieldRefRejectionReason.invalid,
        ),
      );
      continue;
    }
    final row = rowsByField[field];
    if (row == null || usedFields.contains(row.field)) {
      rejections.add(
        ConfigFormSectionFieldRefRejection(
          index: index,
          reason: ConfigFormSectionFieldRefRejectionReason.staleOrAlreadyUsed,
          field: field,
        ),
      );
      continue;
    }
    if (!seenCandidateFields.add(row.field)) {
      rejections.add(
        ConfigFormSectionFieldRefRejection(
          index: index,
          reason: ConfigFormSectionFieldRefRejectionReason.duplicate,
          field: field,
        ),
      );
      continue;
    }
    candidateRows.add(row);
  }

  return ConfigFormSectionRowsCandidatePlan(
    rows: candidateRows,
    rejections: rejections,
  );
}

Iterable<({int index, String? field})> _configFormSectionFieldRefDecisions(
  Object? rawFieldRefs,
) sync* {
  if (rawFieldRefs is! List) return;
  for (final indexedRaw in rawFieldRefs.indexed) {
    final raw = indexedRaw.$2;
    yield (
      index: indexedRaw.$1,
      field: configFormSectionFieldRefFromSchemaValue(raw),
    );
  }
}

ConfigFormSection _unsectionedRowsSection({
  required List<ConfigFormRow> rows,
  required bool hasServerSections,
  required Set<String> usedSectionIds,
}) {
  final fallbackId = hasServerSections ? 'other' : 'general';
  return ConfigFormSection(
    id: _uniqueSectionId(fallbackId, usedSectionIds),
    label: hasServerSections ? 'Other config' : 'General config',
    rows: rows,
  );
}

String _uniqueSectionId(String requestedId, Set<String> usedSectionIds) {
  if (usedSectionIds.add(requestedId)) return requestedId;
  var suffix = 2;
  while (true) {
    final candidate = '$requestedId-$suffix';
    if (usedSectionIds.add(candidate)) return candidate;
    suffix += 1;
  }
}
