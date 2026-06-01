part of '../../parser.dart';

String? _firstToken(String text, {int start = 0, int? end}) {
  return _tokenInWindow(
    text,
    start: start,
    end: end ?? text.length,
    preferLatest: false,
  );
}

String? _lastToken(String text, {int start = 0, int? end}) {
  return _tokenInWindow(
    text,
    start: start,
    end: end ?? text.length,
    preferLatest: true,
  );
}

String? _tokenInWindow(
  String text, {
  required int start,
  required int end,
  required bool preferLatest,
}) {
  final labeledToken = _labeledTokenInWindow(
    text,
    start: start,
    end: end,
    preferLatest: preferLatest,
  );
  if (labeledToken != null) return labeledToken;

  return preferLatest
      ? _lastNavivoxToken(text, start: start, end: end)
      : _firstNavivoxToken(text, start: start, end: end);
}

String? _labeledTokenInWindow(
  String text, {
  required int start,
  required int end,
  required bool preferLatest,
}) {
  _TokenMatch? selectedMatch;
  for (final label in _tokenLabels) {
    final matches = _tokenLabelPattern(
      label,
    ).allMatches(text, start).where((match) => match.start < end);
    for (final match in matches) {
      final token = _readLabeledTokenAt(text, match.end, end: end);
      if (token == null) continue;
      final candidate = _TokenMatch(start: match.start, token: token);
      if (candidate.isPreferredOver(
        selectedMatch,
        preferLatest: preferLatest,
      )) {
        selectedMatch = candidate;
      }
    }
  }
  return selectedMatch?.token;
}

String? _firstNavivoxToken(
  String text, {
  required int start,
  required int end,
}) {
  final index = _firstNavivoxTokenStart(text, start: start, end: end);
  if (index == null) return null;
  return _readTokenAt(text, index, end: end);
}

String? _lastNavivoxToken(String text, {required int start, required int end}) {
  final index = _lastNavivoxTokenStart(text, start: start, end: end);
  if (index == null) return null;
  return _readTokenAt(text, index, end: end);
}

int? _firstNavivoxTokenStart(
  String text, {
  required int start,
  required int end,
}) {
  return _navivoxTokenStart(text, start: start, end: end, preferLatest: false);
}

int? _lastNavivoxTokenStart(
  String text, {
  required int start,
  required int end,
}) {
  return _navivoxTokenStart(text, start: start, end: end, preferLatest: true);
}

int? _navivoxTokenStart(
  String text, {
  required int start,
  required int end,
  required bool preferLatest,
}) {
  var searchStart = start;
  int? selectedIndex;
  final lower = text.toLowerCase();
  while (searchStart < end) {
    final navivoxIndex = lower.indexOf('nvbx_', searchStart);
    if (navivoxIndex < 0 || navivoxIndex >= end) break;
    if (_hasTokenStartBoundary(text, navivoxIndex, windowStart: start)) {
      selectedIndex = navivoxIndex;
      if (!preferLatest) break;
    }
    searchStart = navivoxIndex + 1;
  }
  return selectedIndex;
}

bool _hasTokenStartBoundary(
  String text,
  int tokenStart, {
  required int windowStart,
}) {
  if (tokenStart <= windowStart) return true;
  return !_isTokenChar(text.codeUnitAt(tokenStart - 1));
}

class _TokenMatch {
  const _TokenMatch({required this.start, required this.token});

  final int start;
  final String token;

  bool isPreferredOver(_TokenMatch? other, {required bool preferLatest}) {
    if (other == null) return true;
    return preferLatest ? start > other.start : start < other.start;
  }
}

const _tokenLabels = [
  'pairing token',
  'pairing_token',
  'pairing-token',
  'auth token',
  'auth_token',
  'auth-token',
  'token',
];

RegExp _tokenLabelPattern(String label) {
  // Field labels are provenance, not substring searches. Without an explicit
  // left boundary, a copied field such as "notoken:" or "server-token:" can
  // accidentally satisfy the generic "token:" label and attach unrelated data
  // to the selected endpoint.
  return RegExp(
    '(^|[^A-Za-z0-9_-])${RegExp.escape(label)}\\s*[:=]',
    caseSensitive: false,
  );
}

String? _readLabeledTokenAt(String text, int start, {int? end}) {
  final token = _readTokenAt(text, start, end: end);
  if (token == null || _looksLikeUrlToken(token)) return null;
  return token;
}

bool _looksLikeUrlToken(String token) =>
    RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(token);

String? _readTokenAt(String text, int start, {int? end}) {
  final tokenSearchEnd = end ?? text.length;
  var index = start;
  index = _skipTokenLeadingIgnoredChars(text, index, end: tokenSearchEnd);
  final tokenStart = index;
  while (index < tokenSearchEnd &&
      index < text.length &&
      _isTokenChar(text.codeUnitAt(index))) {
    index++;
  }
  if (index == tokenStart) return null;
  if (_tokenContinuesPastWindow(text, index, tokenSearchEnd)) return null;
  return _trimTokenTrailingPunctuationOrNull(text.substring(tokenStart, index));
}

bool _tokenContinuesPastWindow(String text, int tokenEnd, int windowEnd) {
  return tokenEnd == windowEnd &&
      windowEnd < text.length &&
      _isTokenChar(text.codeUnitAt(windowEnd));
}

int _skipTokenLeadingIgnoredChars(String text, int start, {int? end}) {
  final tokenSearchEnd = end ?? text.length;
  var index = start;
  while (index < tokenSearchEnd && index < text.length) {
    if (_isTokenLeadingIgnoredChar(text, index)) {
      index++;
      continue;
    }
    break;
  }
  return index;
}

bool _isTokenLeadingIgnoredChar(String text, int index) {
  final codeUnit = text.codeUnitAt(index);
  return _isTokenSeparatorCodeUnit(codeUnit) ||
      _tokenLeadingDelimiters.contains(text[index]);
}

bool _isTokenSeparatorCodeUnit(int codeUnit) {
  // Copied setup guides often carry non-ASCII spacing from rich text. Keep the
  // accepted separator set explicit so token parsing does not depend on regex
  // engine whitespace tables or silently treat format characters as spaces.
  return codeUnit <= 0x20 || _unicodeTokenSeparatorCodeUnits.contains(codeUnit);
}

String? _trimTokenTrailingPunctuationOrNull(String token) {
  var end = token.length;
  while (end > 0 && _tokenTrailingPunctuation.contains(token[end - 1])) {
    end--;
  }
  final trimmed = token.substring(0, end);
  return trimmed.isEmpty ? null : trimmed;
}

// Shared-text tokens may be copied from prose, quoted strings, markdown code
// spans, or angle-bracket wrappers. Keep delimiter pairs explicit so broad
// human-entered token support does not silently diverge between wrapper styles.
const _tokenLeadingDelimiters = '"\'`<';
const _tokenTrailingPunctuation = '.,;:!?)]}>"\'`';
const _unicodeTokenSeparatorCodeUnits = {
  0x00a0, // no-break space
  0x1680, // ogham space mark
  0x2000, // en quad
  0x2001, // em quad
  0x2002, // en space
  0x2003, // em space
  0x2004, // three-per-em space
  0x2005, // four-per-em space
  0x2006, // six-per-em space
  0x2007, // figure space
  0x2008, // punctuation space
  0x2009, // thin space
  0x200a, // hair space
  0x2028, // line separator
  0x2029, // paragraph separator
  0x202f, // narrow no-break space
  0x205f, // medium mathematical space
  0x3000, // ideographic space
};

bool _isTokenChar(int codeUnit) {
  return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5a) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7a) ||
      codeUnit == 0x2d ||
      codeUnit == 0x2e ||
      codeUnit == 0x2f ||
      codeUnit == 0x3a ||
      codeUnit == 0x3d ||
      codeUnit == 0x5f ||
      codeUnit == 0x7e ||
      codeUnit == 0x2b;
}
