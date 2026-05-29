import '../form/config_form_model.dart';

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

enum ConfigDraftValidationState { unknown, valid, invalid }

class ConfigDraftChange {
  const ConfigDraftChange({
    required this.path,
    required this.label,
    required this.oldDisplayValue,
    required this.newDisplayValue,
    required this.applyValue,
    required this.isSecret,
    required this.requiresConfirmation,
    required this.restartRequired,
    this.validationMessages = const [],
  });

  static ConfigDraftChange? fromRow(
    ConfigFormRow row,
    Object? draftValue,
    List<String> validationMessages,
  ) {
    if (row.isSecret) {
      final secret = draftValue?.toString().trim() ?? '';
      if (secret.isEmpty) return null;
      return ConfigDraftChange(
        path: row.field,
        label: row.label,
        oldDisplayValue: row.displayValue,
        newDisplayValue: 'Secret will be updated',
        applyValue: secret,
        isSecret: true,
        requiresConfirmation: row.requiresConfirmation,
        restartRequired: row.restartRequired,
        validationMessages: validationMessages,
      );
    }

    if (_sameValue(row.plainValue, draftValue)) return null;
    return ConfigDraftChange(
      path: row.field,
      label: row.label,
      oldDisplayValue: _displayValue(row.plainValue),
      newDisplayValue: _displayValue(draftValue),
      applyValue: draftValue,
      isSecret: false,
      requiresConfirmation: row.requiresConfirmation,
      restartRequired: row.restartRequired,
      validationMessages: validationMessages,
    );
  }

  final String path;
  final String label;
  final String oldDisplayValue;
  final String newDisplayValue;
  final Object? applyValue;
  final bool isSecret;
  final bool requiresConfirmation;
  final bool restartRequired;
  final List<String> validationMessages;

  String get summaryLabel => '$label: $oldDisplayValue -> $newDisplayValue';

  ConfigDraftValidationState get validationState => validationMessages.isEmpty
      ? ConfigDraftValidationState.unknown
      : ConfigDraftValidationState.invalid;

  bool get isInvalid => validationState == ConfigDraftValidationState.invalid;

  static bool _sameValue(Object? left, Object? right) => left == right;

  static String _displayValue(Object? value) => value == null ? '—' : '$value';
}

class ConfigValidationState {
  const ConfigValidationState(this._messagesByPath);

  factory ConfigValidationState.fromSnapshot(Map<String, Object?>? snapshot) {
    final messages = <String, List<String>>{};
    if (snapshot == null) return ConfigValidationState(messages);
    _addValidationErrorList(messages, snapshot['validation_errors']);
    _addValidationErrorList(messages, snapshot['errors']);
    _addFieldErrorMap(messages, snapshot['field_errors']);
    return ConfigValidationState(messages);
  }

  final Map<String, List<String>> _messagesByPath;

  List<String> messagesFor(String path) {
    return List.unmodifiable(_messagesByPath[path] ?? const []);
  }

  static void _addValidationErrorList(
    Map<String, List<String>> target,
    Object? rawErrors,
  ) {
    if (rawErrors is! List) return;
    for (final raw in rawErrors) {
      if (raw is! Map) continue;
      final path = _pathFrom(
        raw['path'] ?? raw['key'] ?? raw['field'] ?? raw['name'],
      );
      final message = _messageFrom(raw['message'] ?? raw['error']);
      if (path == null || message == null) continue;
      target.putIfAbsent(path, () => []).add(message);
    }
  }

  static void _addFieldErrorMap(
    Map<String, List<String>> target,
    Object? rawErrors,
  ) {
    if (rawErrors is! Map) return;
    for (final entry in rawErrors.entries) {
      final path = _pathFrom(entry.key);
      if (path == null) continue;
      final messages = _messagesFrom(entry.value);
      if (messages.isEmpty) continue;
      target.putIfAbsent(path, () => []).addAll(messages);
    }
  }

  static List<String> _messagesFrom(Object? raw) {
    if (raw is List) {
      return raw.map(_messageFrom).nonNulls.toList(growable: false);
    }
    final message = _messageFrom(raw);
    return message == null ? const [] : [message];
  }

  static String? _pathFrom(Object? raw) {
    final text = raw?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? _messageFrom(Object? raw) {
    final text = raw?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
