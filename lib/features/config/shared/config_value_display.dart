import 'config_secret_wire_contract.dart';

const configBlankDisplayValue = '—';
const configSecretNotSetLabel = 'Secret not set';
const configSecretConfiguredLabel = 'Secret configured';
const configSecretStatusUnknownLabel = 'Secret status unknown';
const configSecretWillBeUpdatedLabel = 'Secret will be updated';

String configDisplayValue(Object? value) {
  if (value == null) return configBlankDisplayValue;
  if (value is Iterable) return value.join(', ');
  return '$value';
}

String configSecretDisplayValue(Object? rawValue) {
  if (rawValue == null) return configSecretNotSetLabel;
  if (rawValue is Map) {
    final status = configSecretStatusFromWire(rawValue)?.toLowerCase();
    return switch (status) {
      'configured' || 'external' || 'set' => _secretConfiguredLabel(rawValue),
      'unset' => configSecretNotSetLabel,
      'unknown' => configSecretStatusUnknownLabel,
      _ => configSecretConfiguredLabel,
    };
  }
  return configSecretConfiguredLabel;
}

String _secretConfiguredLabel(Map rawValue) {
  final source = configSecretSourceFromWire(rawValue);
  if (source == null) return configSecretConfiguredLabel;
  return '$configSecretConfiguredLabel ($source)';
}
