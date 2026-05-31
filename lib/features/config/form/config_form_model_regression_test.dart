import 'config_form_model.dart';

void main() {
  preservesUnrecognizedBooleanEditTextForValidation();
  coercesRecognizedBooleanEditTextCaseInsensitively();
}

void preservesUnrecognizedBooleanEditTextForValidation() {
  final row = _row(type: ConfigFormFieldType.boolean, rawValue: false);

  final result = row.coerceEditValue('maybe');

  _expect(
    result == 'maybe',
    'invalid boolean edit text should be preserved for validation instead of silently becoming false',
  );
}

void coercesRecognizedBooleanEditTextCaseInsensitively() {
  final row = _row(type: ConfigFormFieldType.boolean, rawValue: false);

  _expect(row.coerceEditValue(' TRUE ') == true, 'TRUE should coerce to true');
  _expect(
    row.coerceEditValue(' false ') == false,
    'false should coerce to false',
  );
}

ConfigFormRow _row({required ConfigFormFieldType type, Object? rawValue}) {
  return ConfigFormRow(
    field: 'feature.enabled',
    label: 'Feature enabled',
    type: type,
    required: false,
    restartRequired: false,
    riskLevel: 'low',
    requiresConfirmation: false,
    rawValue: rawValue,
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
