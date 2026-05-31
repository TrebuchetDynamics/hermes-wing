import 'config_value_display.dart';

void main() {
  displaysCamelCaseUnsetSecretStatusAsNotSet();
}

void displaysCamelCaseUnsetSecretStatusAsNotSet() {
  final displayValue = configSecretDisplayValue({'secretStatus': 'unset'});

  _expect(
    displayValue == configSecretNotSetLabel,
    'camelCase secretStatus should be treated the same as secret_status',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
