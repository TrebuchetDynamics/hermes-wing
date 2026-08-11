String _normalizeWhitespace(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Returns whether [partial] is plausibly an ordered concatenation of
/// contiguous runs dropped from [full]. Scattered character subsequences are
/// deliberately rejected so distinct assistant prose is never erased.
bool isLossyChunkCopy(
  String partial,
  String full, {
  int minRun = 3,
  int minLength = 12,
  double minCoverage = 0.3,
}) {
  if (partial.isEmpty || full.isEmpty) return false;
  if (partial.length < minLength || partial.length >= full.length) return false;
  if (partial.length < minCoverage * full.length) return false;

  var partialIndex = 0;
  var fullIndex = 0;
  while (partialIndex < partial.length) {
    final remaining = partial.length - partialIndex;
    final probeLength = remaining < minRun ? remaining : minRun;
    final probe = partial.substring(partialIndex, partialIndex + probeLength);
    final matchAt = full.indexOf(probe, fullIndex);
    if (matchAt < 0) return false;
    if (probeLength < minRun && remaining > probeLength) return false;

    var runLength = probeLength;
    while (partialIndex + runLength < partial.length &&
        matchAt + runLength < full.length &&
        partial.codeUnitAt(partialIndex + runLength) ==
            full.codeUnitAt(matchAt + runLength)) {
      runLength++;
    }
    partialIndex += runLength;
    fullIndex = matchAt + runLength;
  }
  return true;
}

/// Reconciles one generation-owned assistant stream with its canonical final.
/// This function must never receive reasoning, tool, or another turn's text.
String reconcileAssistantText({
  required String streamed,
  required String canonical,
  bool segmentStart = false,
}) {
  final streamedText = streamed.trim();
  final canonicalText = canonical.trim();
  if (streamedText.isEmpty) return canonicalText;
  if (canonicalText.isEmpty) return streamedText;

  final normalizedStreamed = _normalizeWhitespace(streamedText);
  final normalizedCanonical = _normalizeWhitespace(canonicalText);
  if (normalizedStreamed == normalizedCanonical) return canonicalText;
  if (normalizedCanonical.contains(normalizedStreamed)) return canonicalText;
  if (normalizedStreamed.contains(normalizedCanonical)) return streamedText;
  if (isLossyChunkCopy(normalizedStreamed, normalizedCanonical)) {
    return canonicalText;
  }
  return segmentStart ? '$streamedText\n\n$canonicalText' : canonicalText;
}
