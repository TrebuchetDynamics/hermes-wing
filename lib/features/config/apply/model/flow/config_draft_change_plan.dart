import '../../../form/config_form_model.dart';
import '../../validation/config_validation_state.dart';
import '../change/config_draft_change.dart';

/// Replayable projection from draft values onto visible config form rows.
///
/// The apply flow can only submit fields that are present in the current form
/// schema. Keeping the accepted changes and dropped draft paths together makes
/// that hidden data-flow boundary explicit for tests and diagnostics without
/// changing the public apply behavior.
class ConfigDraftChangePlan {
  ConfigDraftChangePlan({
    required List<ConfigDraftChange> changes,
    required List<String> droppedDraftPaths,
  }) : changes = List.unmodifiable(changes),
       droppedDraftPaths = List.unmodifiable(droppedDraftPaths);

  factory ConfigDraftChangePlan.fromRows({
    required Iterable<ConfigFormRow> rows,
    required Map<String, Object?> draftValues,
    required ConfigValidationState validation,
  }) {
    final changes = <ConfigDraftChange>[];
    final rowPaths = <String>{};

    for (final row in rows) {
      rowPaths.add(row.field);
      if (!draftValues.containsKey(row.field)) continue;
      final change = ConfigDraftChange.fromRow(
        row,
        draftValues[row.field],
        validation.messagesFor(row.field),
      );
      if (change != null) changes.add(change);
    }

    return ConfigDraftChangePlan(
      changes: changes,
      droppedDraftPaths: _draftPathsOutsideRows(
        draftValues: draftValues,
        rowPaths: rowPaths,
      ),
    );
  }

  final List<ConfigDraftChange> changes;

  /// Draft paths that were present in local edit state but absent from the
  /// current schema, in insertion order from the draft snapshot.
  final List<String> droppedDraftPaths;
}

List<String> _draftPathsOutsideRows({
  required Map<String, Object?> draftValues,
  required Set<String> rowPaths,
}) {
  final dropped = <String>[];
  for (final path in draftValues.keys) {
    if (!rowPaths.contains(path)) dropped.add(path);
  }
  return dropped;
}
