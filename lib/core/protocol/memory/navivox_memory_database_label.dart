import '../serialization/navivox_json.dart';

/// Produces a safe operator-facing label for a gateway-supplied memory DB path.
///
/// The Gormes home suffix is intentionally recognizable, while filesystem
/// paths outside that allowed suffix are reduced to a redacted basename.
String navivoxMemorySafeDatabaseLabel(Object? value) {
  final text = navivoxOptionalStringFromJson(value);
  if (text == null) return 'redacted';

  final gormesSuffix = _gormesPathSuffix(text);
  if (gormesSuffix != null) return '~/.gormes/$gormesSuffix';

  if (_hasDirectoryProvenance(text)) return 'redacted/${_pathBasename(text)}';

  return text;
}

String? _gormesPathSuffix(String value) {
  final normalized = value.replaceAll(r'\', '/');
  const gormesMarker = '/.gormes/';
  final markerIndex = normalized.indexOf(gormesMarker);
  if (markerIndex < 0) return null;

  final suffix = normalized.substring(markerIndex + gormesMarker.length);
  if (!_isSafeGormesSuffix(suffix)) return null;
  return suffix;
}

bool _isSafeGormesSuffix(String suffix) {
  final parts = suffix.split('/');
  if (parts.isEmpty) return false;
  return parts.every((part) => part.isNotEmpty && part != '.' && part != '..');
}

bool _hasDirectoryProvenance(String value) {
  return value.contains('/') ||
      value.contains(r'\') ||
      RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
}

String _pathBasename(String value) {
  final parts = value.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty);
  return parts.isEmpty ? 'memory.db' : parts.last;
}
