import '../../form/config_wire_fields.dart';
import '../../form/wire/config_form_wire_contract.dart';

class ConfigValidationIssues {
  ConfigValidationIssues({
    Map<String, List<String>> messagesByPath = const {},
    List<String> globalMessages = const [],
  }) : messagesByPath = Map<String, List<String>>.unmodifiable(
         messagesByPath.map(
           (path, messages) =>
               MapEntry(path, List<String>.unmodifiable(messages)),
         ),
       ),
       globalMessages = List.unmodifiable(globalMessages);

  factory ConfigValidationIssues.fromSnapshotParts({
    required Object? validationErrors,
    required Object? genericErrors,
    required Object? fieldErrors,
  }) {
    final builder = _ConfigValidationIssuesBuilder();
    builder.addValidationErrorList(validationErrors);
    builder.addGenericErrors(genericErrors);
    builder.addFieldErrorMap(fieldErrors);
    return builder.build();
  }

  final Map<String, List<String>> messagesByPath;
  final List<String> globalMessages;

  bool get hasGlobalErrors => globalMessages.isNotEmpty;

  List<String> messagesFor(String path) {
    return List.unmodifiable(messagesByPath[path] ?? const []);
  }
}

class _ConfigValidationIssuesBuilder {
  final Map<String, List<String>> _messagesByPath = {};
  final List<String> _globalMessages = [];

  void addValidationErrorList(Object? rawErrors) {
    if (rawErrors is! List) return;
    for (final raw in rawErrors) {
      if (raw is! Map) continue;
      final path = configFormValidationPathFromWire(raw);
      final message = configFormValidationMessageFromWire(raw);
      if (message == null) continue;
      if (path == null) {
        _appendGlobalMessage(message);
      } else {
        _appendPathMessage(path: path, message: message);
      }
    }
  }

  void addGenericErrors(Object? rawErrors) {
    if (rawErrors is List) {
      for (final raw in rawErrors) {
        _appendGenericError(raw);
      }
      return;
    }
    _appendGenericError(rawErrors);
  }

  void addFieldErrorMap(Object? rawErrors) {
    if (rawErrors is! Map) return;
    for (final entry in rawErrors.entries) {
      final path = configWireString(entry.key);
      if (path == null) continue;
      final messages = _messagesFrom(entry.value);
      if (messages.isEmpty) continue;
      for (final message in messages) {
        _appendPathMessage(path: path, message: message);
      }
    }
  }

  ConfigValidationIssues build() {
    return ConfigValidationIssues(
      messagesByPath: _messagesByPath,
      globalMessages: _globalMessages,
    );
  }

  void _appendPathMessage({required String path, required String message}) {
    final pathMessages = _messagesByPath.putIfAbsent(path, () => []);
    if (pathMessages.contains(message)) return;
    pathMessages.add(message);
  }

  void _appendGlobalMessage(String message) {
    if (_globalMessages.contains(message)) return;
    _globalMessages.add(message);
  }

  void _appendGenericError(Object? raw) {
    if (raw is Map) {
      final message = configFormValidationMessageFromWire(raw);
      if (message == null) return;
      final path = configFormValidationPathFromWire(raw);
      if (path == null) {
        _appendGlobalMessage(message);
      } else {
        _appendPathMessage(path: path, message: message);
      }
      return;
    }

    final message = _messageFrom(raw);
    if (message != null) _appendGlobalMessage(message);
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
