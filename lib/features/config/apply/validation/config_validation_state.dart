import '../../form/config_wire_fields.dart';
import '../../form/wire/config_form_wire_contract.dart';
import 'config_validation_snapshot_wire.dart';

class ConfigValidationState {
  const ConfigValidationState(this._messagesByPath);

  factory ConfigValidationState.fromSnapshot(Map<String, Object?>? snapshot) {
    final messages = <String, List<String>>{};
    if (snapshot == null) return ConfigValidationState(messages);
    final wire = ConfigValidationSnapshotWire(snapshot);
    _addValidationErrorList(messages, wire.validationErrors);
    _addValidationErrorList(messages, wire.genericErrors);
    _addFieldErrorMap(messages, wire.fieldErrors);
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
      final path = configFormValidationPathFromWire(raw);
      final message = configFormValidationMessageFromWire(raw);
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
      final path = configWireString(entry.key);
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

  static String? _messageFrom(Object? raw) {
    if (raw is Map) return configFormValidationMessageFromWire(raw);
    return configWireString(raw);
  }
}
