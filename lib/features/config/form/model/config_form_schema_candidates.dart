import 'config_form_schema_row.dart';

enum ConfigFormSchemaRowRejectionReason { invalid, duplicateField }

class ConfigFormSchemaRowRejection {
  const ConfigFormSchemaRowRejection({
    required this.index,
    required this.reason,
    this.field,
  });

  final int index;
  final ConfigFormSchemaRowRejectionReason reason;
  final String? field;
}

class ConfigFormSchemaRowCandidatePlan {
  ConfigFormSchemaRowCandidatePlan({
    required List<ConfigFormSchemaRowCandidate> candidates,
    required List<ConfigFormSchemaRowRejection> rejections,
  }) : candidates = List.unmodifiable(candidates),
       rejections = List.unmodifiable(rejections);

  final List<ConfigFormSchemaRowCandidate> candidates;
  final List<ConfigFormSchemaRowRejection> rejections;

  int get acceptedRows => candidates.length;

  int get skippedInvalidRows =>
      _skippedRows(ConfigFormSchemaRowRejectionReason.invalid);

  int get skippedDuplicateRows =>
      _skippedRows(ConfigFormSchemaRowRejectionReason.duplicateField);

  int _skippedRows(ConfigFormSchemaRowRejectionReason reason) {
    return rejections.where((rejection) => rejection.reason == reason).length;
  }
}

/// Builds validated schema row candidates in the exact order they should appear
/// in the form model.
///
/// This keeps the schema ingestion decision points explicit: non-map/blank rows
/// are dropped, the first candidate for a field path wins, and values are
/// attached from the same path used for de-duplication.
List<ConfigFormSchemaRowCandidate> configFormSchemaRowCandidatesFromFields({
  required List rawFields,
  required Map<String, Object?> values,
}) {
  return configFormSchemaRowCandidatePlanFromFields(
    rawFields: rawFields,
    values: values,
  ).candidates;
}

/// Replays schema row ingestion with visibility into skipped candidates.
///
/// The form still consumes only [candidates], but tests and diagnostics can now
/// assert that invalid rows and duplicate field paths are intentionally dropped
/// instead of disappearing inside the model constructor.
ConfigFormSchemaRowCandidatePlan configFormSchemaRowCandidatePlanFromFields({
  required List rawFields,
  required Map<String, Object?> values,
}) {
  final candidates = <ConfigFormSchemaRowCandidate>[];
  final rejections = <ConfigFormSchemaRowRejection>[];
  final seenFields = <String>{};

  for (final indexedRaw in rawFields.indexed) {
    final index = indexedRaw.$1;
    final raw = indexedRaw.$2;
    final candidate = ConfigFormSchemaRowCandidate.fromRaw(
      raw: raw,
      values: values,
    );
    if (candidate == null) {
      rejections.add(
        ConfigFormSchemaRowRejection(
          index: index,
          reason: ConfigFormSchemaRowRejectionReason.invalid,
        ),
      );
      continue;
    }
    if (!seenFields.add(candidate.field)) {
      rejections.add(
        ConfigFormSchemaRowRejection(
          index: index,
          reason: ConfigFormSchemaRowRejectionReason.duplicateField,
          field: candidate.field,
        ),
      );
      continue;
    }
    candidates.add(candidate);
  }

  return ConfigFormSchemaRowCandidatePlan(
    candidates: candidates,
    rejections: rejections,
  );
}
