bool transcriptHasDisplayText(String? value) => value?.isNotEmpty == true;

String? transcriptTrimmedTextOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

bool transcriptHasNonBlankText(String? value) {
  return transcriptTrimmedTextOrNull(value) != null;
}

String transcriptJoinNonEmptyLines(Iterable<String?> parts) {
  return parts.whereType<String>().where(transcriptHasDisplayText).join('\n');
}
