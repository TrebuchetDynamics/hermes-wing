/// Normalizes and bounds display metadata; does not validate identifiers or redact secrets.
String boundedHermesMetadataText(String value, int limit) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.length <= limit) return normalized;
  return '${normalized.substring(0, limit - 1)}…';
}
