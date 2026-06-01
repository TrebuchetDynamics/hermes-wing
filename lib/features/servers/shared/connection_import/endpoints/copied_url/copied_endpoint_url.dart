part of '../../parser.dart';

String _trimCopiedEndpointUrl(String url) {
  final start = _copiedEndpointUrlStart(url);
  final end = _copiedEndpointUrlEnd(url, start: start);
  return url.substring(start, end);
}

int _copiedEndpointUrlStart(String url) {
  var start = 0;
  while (start < url.length &&
      _copiedUrlLeadingDelimiters.contains(url[start])) {
    start++;
  }
  return start;
}

int _copiedEndpointUrlEnd(String url, {required int start}) {
  var end = url.length;
  while (end > start &&
      _shouldTrimCopiedEndpointTrailingChar(url, start, end)) {
    end--;
  }
  return end;
}

bool _shouldTrimCopiedEndpointTrailingChar(String url, int start, int end) {
  final char = url[end - 1];
  if (!_copiedUrlTrailingPunctuation.contains(char)) return false;
  return switch (char) {
    ')' => _hasUnmatchedClosingDelimiterAtEnd(
      url,
      start: start,
      end: end,
      open: '(',
      close: ')',
    ),
    ']' => _hasUnmatchedClosingDelimiterAtEnd(
      url,
      start: start,
      end: end,
      open: '[',
      close: ']',
    ),
    '}' => _hasUnmatchedClosingDelimiterAtEnd(
      url,
      start: start,
      end: end,
      open: '{',
      close: '}',
    ),
    _ => true,
  };
}

bool _hasUnmatchedClosingDelimiterAtEnd(
  String text, {
  required int start,
  required int end,
  required String open,
  required String close,
}) {
  var balance = 0;
  for (var index = start; index < end; index++) {
    final char = text[index];
    if (char == open) balance++;
    if (char == close) balance--;
  }
  return balance < 0;
}

// Plain-text shares often wrap or end a copied URL with sentence/list
// punctuation or markdown/code delimiters. Keep these lists explicit because
// these characters otherwise become part of the parsed origin when the shared
// URL has no path, or part of a query token when the URL carries connection
// credentials.
const _copiedUrlLeadingDelimiters = '<"\'`';
const _copiedUrlTrailingPunctuation = '.,;:!?)]}>"\'`';
// Token labels can be glued to copied URLs by punctuation from prose,
// markdown, or wrapper delimiters, e.g. `connect:Token:x` or
// `connect(Token: x)`. Treat both closing and opening wrappers as label
// boundaries so the URL candidate keeps its real path while the following token
// remains in the endpoint-local search window.
const _attachedTokenLabelPunctuation = [
  ',',
  ';',
  '.',
  '!',
  ':',
  '(',
  '[',
  '{',
  ')',
  ']',
  '}',
  '>',
  '"',
  "'",
  '`',
];
