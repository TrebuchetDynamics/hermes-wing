import '../../../core/protocol/config_wire_fields.dart';

/// Wire aliases accepted for secret status payloads.
///
/// Server and local config payloads may drift between snake_case and camelCase;
/// keep that normalization explicit at the display boundary so secret-state
/// labels are replayable from captured payloads.
String? configSecretStatusFromWire(Map rawValue) {
  return configWireStringFromAliases(rawValue, const ['secret_status']);
}

String? configSecretSourceFromWire(Map rawValue) {
  return configWireStringFromAliases(rawValue, const ['source']);
}
