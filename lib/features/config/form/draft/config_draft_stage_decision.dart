import 'config_draft_values.dart';

class ConfigDraftStageDecision {
  const ConfigDraftStageDecision({
    required this.draftValues,
    required this.editingField,
  });

  final Map<String, Object?> draftValues;
  final String? editingField;
}

ConfigDraftStageDecision stageConfigDraftEdit({
  required Map<String, Object?> draftValues,
  required String? editingField,
  required String fieldPath,
  required Object? value,
  required bool clearsDraft,
}) {
  final nextDraft = Map<String, Object?>.from(draftValues);
  if (clearsDraft) {
    nextDraft.remove(fieldPath);
  } else {
    nextDraft[fieldPath] = value;
  }
  return ConfigDraftStageDecision(
    draftValues: configDraftValuesSnapshot(nextDraft),
    editingField: _nextEditingField(
      editingField: editingField,
      stagedFieldPath: fieldPath,
    ),
  );
}

String? _nextEditingField({
  required String? editingField,
  required String stagedFieldPath,
}) {
  if (editingField == stagedFieldPath) return null;
  return editingField;
}
