import '../../../form/config_form_model.dart';
import '../../validation/config_validation_state.dart';
import '../change/config_draft_change.dart';
import 'config_draft_change_plan.dart';

class ConfigApplyFlowModel {
  ConfigApplyFlowModel({
    required List<ConfigDraftChange> changes,
    List<String> globalValidationMessages = const [],
    ConfigValidationState? validation,
    bool? hasVisibleFieldErrors,
  }) : changes = List.unmodifiable(changes),
       globalValidationMessages = List.unmodifiable(globalValidationMessages),
       _validation = validation ?? ConfigValidationState.fromSnapshot(null),
       _hasVisibleFieldErrors =
           hasVisibleFieldErrors ??
           (validation ?? ConfigValidationState.fromSnapshot(null))
               .hasFieldErrors;

  factory ConfigApplyFlowModel.fromDraft({
    required ConfigFormModel form,
    required Map<String, Object?> draftValues,
    Map<String, Object?>? validationSnapshot,
  }) {
    final validation = ConfigValidationState.fromSnapshot(validationSnapshot);
    final changePlan = ConfigDraftChangePlan.fromRows(
      rows: form.rows,
      draftValues: draftValues,
      validation: validation,
    );
    return ConfigApplyFlowModel(
      changes: changePlan.changes,
      globalValidationMessages: validation.globalMessages,
      validation: validation,
      hasVisibleFieldErrors: _hasValidationMessagesForRows(
        rows: form.rows,
        validation: validation,
      ),
    );
  }

  final List<ConfigDraftChange> changes;
  final List<String> globalValidationMessages;
  final ConfigValidationState _validation;
  final bool _hasVisibleFieldErrors;

  bool get hasPendingChanges => changes.isNotEmpty;

  bool get hasInvalidChanges =>
      globalValidationMessages.isNotEmpty ||
      _hasVisibleFieldErrors ||
      changes.any((change) => change.isInvalid);

  bool get canApply => hasPendingChanges && !hasInvalidChanges;

  bool get requiresConfirmation =>
      changes.any((change) => change.requiresConfirmation);

  List<String> validationMessagesFor(String path) {
    final validationMessages = _validation.messagesFor(path);
    if (validationMessages.isNotEmpty) return validationMessages;
    return changes
        .where((change) => change.path == path)
        .expand((change) => change.validationMessages)
        .toList(growable: false);
  }
}

bool _hasValidationMessagesForRows({
  required Iterable<ConfigFormRow> rows,
  required ConfigValidationState validation,
}) {
  return rows.any((row) => validation.messagesFor(row.field).isNotEmpty);
}
