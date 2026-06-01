part of '../../parser.dart';

List<_SharedTextEndpoint> _sharedTextEndpoints(String text) {
  final matches = _endpointUrlMatches(text).toList(growable: false);
  return _sharedTextEndpointsFromMatches(
    textLength: text.length,
    matches: matches,
  );
}

List<_SharedTextEndpoint> _sharedTextEndpointsFromMatches({
  required int textLength,
  required List<_SharedTextEndpointMatch> matches,
}) {
  assert(textLength >= 0);
  final endpoints = <_SharedTextEndpoint>[];
  for (var index = 0; index < matches.length; index++) {
    final match = matches[index];
    final nextEndpointStart = index + 1 < matches.length
        ? matches[index + 1].sourceWindow.start
        : textLength;
    assert(match.sourceWindow.start <= match.trailingPunctuationWindow.start);
    assert(match.trailingPunctuationWindow.start <= match.sourceWindow.end);
    assert(match.sourceWindow.end <= textLength);
    assert(
      match.trailingPunctuationWindow.end >=
          match.trailingPunctuationWindow.start,
    );
    assert(match.trailingPunctuationWindow.end <= textLength);
    final endpoint = _SharedTextEndpoint(
      url: match.url,
      sourceWindow: match.sourceWindow,
      tokenWindow: _TextWindow(
        start: match.trailingPunctuationWindow.start,
        end: nextEndpointStart,
      ),
      hasPriorEndpoint: index > 0,
    );
    assert(endpoint.tokenWindow.start >= endpoint.sourceWindow.start);
    assert(endpoint.tokenWindow.end >= endpoint.tokenWindow.start);
    assert(endpoint.tokenWindow.end <= textLength);
    endpoints.add(endpoint);
  }
  return List.unmodifiable(endpoints);
}

class _SharedTextEndpointMatch {
  const _SharedTextEndpointMatch({
    required this.url,
    required this.sourceWindow,
    required this.trailingPunctuationWindow,
  }) : assert(url.length > 0);

  final String url;
  final _TextWindow sourceWindow;
  final _TextWindow trailingPunctuationWindow;
}

class _SharedTextEndpoint {
  const _SharedTextEndpoint({
    required this.url,
    required this.sourceWindow,
    required this.tokenWindow,
    required this.hasPriorEndpoint,
  }) : assert(url.length > 0);

  final String url;
  final _TextWindow sourceWindow;
  final _TextWindow tokenWindow;
  final bool hasPriorEndpoint;

  String? followingToken(String text) {
    return _firstToken(text, start: tokenWindow.start, end: tokenWindow.end);
  }
}

class _TextWindow {
  const _TextWindow({required this.start, required this.end})
    : assert(start >= 0),
      assert(end >= start);

  final int start;
  final int end;
}
