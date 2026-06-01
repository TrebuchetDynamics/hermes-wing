import '../../apply/config_apply_flow_model.dart';
import '../../apply/model/config_draft_value_equality.dart';
import '../presentation/config_field_presentation.dart';
import 'config_draft_edit_value.dart';
import 'config_draft_stage_decision.dart';
import 'config_draft_values.dart';

class ConfigDraftSession {
  ConfigDraftSession({
    Map<String, Object?> draftValues = const {},
    this.editingField,
  }) : draftValues = configDraftValuesSnapshot(draftValues);

  final Map<String, Object?> draftValues;
  final String? editingField;

  bool isEditing(ConfigFieldPresentation field) => editingField == field.path;

  String editInitialValueFor(ConfigFieldPresentation field) {
    if (field.obscureText || !draftValues.containsKey(field.path)) {
      return field.editInitialValue;
    }
    return configDraftEditInitialValue(draftValues[field.path]);
  }

  ConfigDraftSession beginEditing(ConfigFieldPresentation field) {
    return ConfigDraftSession(
      draftValues: draftValues,
      editingField: field.path,
    );
  }

  ConfigDraftSession cancelEditing() {
    return ConfigDraftSession(draftValues: draftValues);
  }

  ConfigDraftSession stageEdit(ConfigFieldPresentation field, String rawText) {
    final value = field.coerceEditValue(rawText);
    final decision = stageConfigDraftEdit(
      draftValues: draftValues,
      editingField: editingField,
      fieldPath: field.path,
      value: value,
      clearsDraft: field.clearsDraftFor(value),
    );
    return ConfigDraftSession(
      draftValues: decision.draftValues,
      editingField: decision.editingField,
    );
  }

  ConfigDraftSession clearApplied(ConfigApplyFlowModel flow) {
    if (!flow.hasPendingChanges) return this;
    final nextDraft = Map<String, Object?>.from(draftValues);
    for (final change in flow.changes) {
      if (_draftValueStillMatchesApplied(
        draftValues: draftValues,
        path: change.path,
        appliedValue: change.applyValue,
      )) {
        nextDraft.remove(change.path);
      }
    }
    return ConfigDraftSession(
      draftValues: nextDraft,
      editingField: editingField,
    );
  }
}

bool _draftValueStillMatchesApplied({
  required Map<String, Object?> draftValues,
  required String path,
  required Object? appliedValue,
}) {
  return configDraftValuesContainsSameEntry(
    draftValues: draftValues,
    path: path,
    appliedValue: appliedValue,
    valuesEqual: configDraftValuesEqual,
  );
}
