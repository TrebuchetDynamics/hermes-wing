import '../config_wire_fields.dart';

/// Wire aliases accepted for field-scoped config validation errors.
///
/// Keep these helpers near the config form because apply flow and presentation
/// both need the same path/message contract when replaying server validation
/// snapshots against draft edits.
String? configFormValidationPathFromWire(Map raw) {
  return configWireStringFromAliases(raw, const [
    'path',
    'field',
    'key',
    'name',
  ]);
}

String? configFormValidationMessageFromWire(Map raw) {
  return configWireStringFromAliases(raw, const ['message', 'detail', 'error']);
}
