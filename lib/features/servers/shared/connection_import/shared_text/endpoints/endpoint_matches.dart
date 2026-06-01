part of '../../parser.dart';

Iterable<_SharedTextEndpoint> _endpointUrls(String text) =>
    _sharedTextEndpoints(text);

Iterable<_SharedTextEndpointMatch> _endpointUrlMatches(String text) sync* {
  for (final match in _endpointUrlPattern.allMatches(text)) {
    final matchedText = match.group(0);
    if (matchedText == null) continue;
    final trimmedUrlStart = _copiedEndpointUrlStart(matchedText);
    final rawUrlEnd = _matchedEndpointUrlEndBeforeAttachedTokenLabel(
      matchedText,
      start: trimmedUrlStart,
    );
    final trimmedUrlEnd = _copiedEndpointUrlEnd(
      matchedText.substring(0, rawUrlEnd),
      start: trimmedUrlStart,
    );
    if (trimmedUrlEnd <= trimmedUrlStart) continue;

    yield _SharedTextEndpointMatch(
      url: matchedText.substring(trimmedUrlStart, trimmedUrlEnd),
      sourceWindow: _TextWindow(start: match.start, end: match.end),
      trailingPunctuationWindow: _TextWindow(
        start: match.start + trimmedUrlEnd,
        end: match.end,
      ),
    );
  }
}

int _matchedEndpointUrlEndBeforeAttachedTokenLabel(
  String matchedText, {
  required int start,
}) {
  final punctuationAlternation = _attachedTokenLabelPunctuation
      .map(RegExp.escape)
      .join('|');
  int? earliestTokenLabelStart;
  for (final label in _tokenLabels) {
    final labelPattern = RegExp(
      '(?:$punctuationAlternation)\\s*${RegExp.escape(label)}\\s*[:=]',
      caseSensitive: false,
    );
    final match = labelPattern.firstMatch(matchedText.substring(start));
    if (match == null) continue;
    final labelStart = start + match.start;
    if (earliestTokenLabelStart == null ||
        labelStart < earliestTokenLabelStart) {
      earliestTokenLabelStart = labelStart;
    }
  }
  return earliestTokenLabelStart ?? matchedText.length;
}

bool _hasConnectionPath(Uri uri) {
  return uri.pathSegments.any(
    (segment) => _connectionPathSegments.contains(segment.toLowerCase()),
  );
}

const _connectionPathSegments = {'connect', 'connection', 'pair', 'pairing'};
