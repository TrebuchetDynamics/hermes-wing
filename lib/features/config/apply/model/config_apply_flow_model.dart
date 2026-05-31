import '../../form/config_form_model.dart';
import '../validation/config_validation_state.dart';
import 'config_draft_change.dart';

class ConfigApplyFlowModel {
  const ConfigApplyFlowModel({required this.changes});

  factory ConfigApplyFlowModel.fromDraft({
    required ConfigFormModel form,
    required Map<String, Object?> draftValues,
    Map<String, Object?>? validationSnapshot,
  }) {
    final validation = ConfigValidationState.fromSnapshot(validationSnapshot);
    final changes = <ConfigDraftChange>[];
    for (final row in form.rows) {
      if (!draftValues.containsKey(row.field)) continue;
      final change = ConfigDraftChange.fromRow(
        row,
        draftValues[row.field],
        validation.messagesFor(row.field),
      );
      if (change != null) changes.add(change);
    }
    return ConfigApplyFlowModel(changes: changes);
  }

  final List<ConfigDraftChange> changes;

  bool get hasPendingChanges => changes.isNotEmpty;

  bool get hasInvalidChanges => changes.any((change) => change.isInvalid);

  bool get canApply => hasPendingChanges && !hasInvalidChanges;

  bool get requiresConfirmation =>
      changes.any((change) => change.requiresConfirmation);

  List<String> validationMessagesFor(String path) {
    return changes
        .where((change) => change.path == path)
        .expand((change) => change.validationMessages)
        .toList(growable: false);
  }
}
