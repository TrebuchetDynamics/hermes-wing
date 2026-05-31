import '../../form/config_form_model.dart';
import '../../form/config_wire_fields.dart';
import '../../shared/config_value_display.dart';

const configApplyChangeSummarySeparator = ' -> ';

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
      final secret = configWireString(draftValue) ?? '';
      if (secret.isEmpty) return null;
      return ConfigDraftChange(
        path: row.field,
        label: row.label,
        oldDisplayValue: row.displayValue,
        newDisplayValue: configSecretWillBeUpdatedLabel,
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

  String get summaryLabel =>
      '$label: $oldDisplayValue$configApplyChangeSummarySeparator$newDisplayValue';

  ConfigDraftValidationState get validationState => validationMessages.isEmpty
      ? ConfigDraftValidationState.unknown
      : ConfigDraftValidationState.invalid;

  bool get isInvalid => validationState == ConfigDraftValidationState.invalid;

  static bool _sameValue(Object? left, Object? right) => left == right;

  static String _displayValue(Object? value) => configDisplayValue(value);
}
