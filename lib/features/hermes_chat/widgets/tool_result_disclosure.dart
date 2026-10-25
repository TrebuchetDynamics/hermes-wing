import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/security/wing_redaction.dart';

/// Presentation only: the caller supplies one uniquely owned, already loaded turn.
/// No result is decoded until the user opens this mounted disclosure.
class HermesToolResultDisclosure extends StatefulWidget {
  const HermesToolResultDisclosure({
    super.key,
    required this.owner,
    required this.turnId,
    required this.result,
  });

  final Object owner;
  final String turnId;
  final String? result;

  @override
  State<HermesToolResultDisclosure> createState() =>
      _ToolResultDisclosureState();
}

class _ToolResultDisclosureState extends State<HermesToolResultDisclosure> {
  bool _open = false;
  ({String text, bool available})? _presentation;

  @override
  void didUpdateWidget(HermesToolResultDisclosure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owner != widget.owner || oldWidget.turnId != widget.turnId) {
      _open = false;
      _presentation = null;
    } else if (oldWidget.result != widget.result) {
      _presentation = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presentation = null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final presentation = _open
        ? _presentation ??= _safeLoadedResult(widget.result, strings)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: _open,
            child: TextButton.icon(
              key: ValueKey('hermes-tool-payload-${widget.turnId}'),
              onPressed: () => setState(() {
                _open = !_open;
                if (!_open) _presentation = null;
              }),
              icon: Icon(_open ? Icons.expand_less : Icons.expand_more),
              label: Text(strings.chatToolPayloadTitle),
            ),
          ),
          if (_open) ...[
            if (presentation!.available) ...[
              Text(
                strings.chatToolResultTitle,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
            ],
            // Deliberately not selectable, Markdown, media, a link or an export.
            Text(
              presentation.text,
              key: ValueKey('hermes-tool-result-${widget.turnId}'),
            ),
          ],
        ],
      ),
    );
  }
}

const _maxSource = 65536;
const _maxPaint = 20000;
const _maxDepth = 16;
const _maxValues = 1000;
final _credentialKey = RegExp(
  r'credential|auth|token|secret|password|passwd|pwd|cookie|apikey',
  caseSensitive: false,
);
final _uri = RegExp(
  r'''\b[a-z][a-z0-9+.-]*:[^\s"'<>]+|//[^\s"'<>]+|\bwww\.[^\s"'<>]+''',
  caseSensitive: false,
);
final _address = RegExp(
  r'\b(?:\d{1,3}\.){3}\d{1,3}\b|[a-f0-9]*:[a-f0-9:.%]*:[a-f0-9:.%]*',
  caseSensitive: false,
);
final _absolutePath = RegExp(r'''(^|[\s(\[{<"'`=:])/(?!/)[^\s,;"'`<>]+''');
final _ansi = RegExp(r'\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|$))');
final _controls = RegExp(r'[\x00-\x08\x0b-\x1f\x7f\u202a-\u202e\u2066-\u2069]');

final _quotedAssignment = RegExp(r'''["']([^"'\n]+)["']\s*[:=]''');
final _scalarCredential = RegExp(
  r'''(?:credential|auth|token|secret|password|passwd|pwd|cookie|api[-_ ]?key)[a-z0-9_-]*["'`]?\s*[:=]|\b(?:Bearer|Basic)\s+''',
  caseSensitive: false,
);
final _keySeparators = RegExp('[^a-zA-Z0-9]');

String _redact(String value) {
  // Normalize invisible formatting first: it must not split a sensitive token
  // during redaction and then reassemble the secret in the painted output.
  final normalized = value.replaceAll(_ansi, '').replaceAll(_controls, '');
  // Scalar credential values may contain spaces, quotes, escapes or newlines.
  // Drop the whole leaf instead of trusting a whitespace-bounded substitution
  // to consume the full secret. Encoded structures are not a second decoder.
  final trimmed = normalized.trimLeft();
  if (trimmed.startsWith('{') ||
      trimmed.startsWith('[') ||
      _scalarCredential.hasMatch(normalized) ||
      _quotedAssignment
          .allMatches(normalized)
          .any(
            (m) =>
                _credentialKey.hasMatch(m[1]!.replaceAll(_keySeparators, '')),
          )) {
    return '[redacted]';
  }
  final safe = wingRedactSensitiveText(normalized)
      .replaceAll(_uri, '[redacted-address]')
      .replaceAll(_address, '[redacted-address]')
      .replaceAllMapped(_absolutePath, (m) => '${m[1]}[redacted-path]');
  // A path may contain whitespace with no delimiter left after JSON decoding.
  // Once detected, suppress the entire leaf rather than leak its trailing parts.
  return safe.contains('[redacted-path]') ? '[redacted-path]' : safe;
}

({String text, bool available}) _safeLoadedResult(
  String? source,
  AppLocalizations strings,
) {
  final unavailable = (
    text: strings.chatToolResultUnavailable,
    available: false,
  );
  if (source == null) return unavailable;
  // String.length is UTF-16 units. Reject before trim, parsing or redaction.
  if (source.length > _maxSource) {
    return (text: strings.chatToolResultOversized, available: false);
  }
  final trimmed = source.trim();
  if (trimmed.isEmpty) return unavailable;
  String safe;
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    // Reject excessive nesting before jsonDecode can allocate a deep tree.
    var depth = 0;
    var quoted = false;
    var escaped = false;
    for (final unit in trimmed.codeUnits) {
      if (quoted) {
        if (escaped) {
          escaped = false;
        } else if (unit == 92) {
          escaped = true;
        } else if (unit == 34) {
          quoted = false;
        }
      } else if (unit == 34) {
        quoted = true;
      } else if (unit == 123 || unit == 91) {
        if (++depth > _maxDepth) return unavailable;
      } else if (unit == 125 || unit == 93) {
        depth--;
      }
    }
    var values = 0;
    Object? sanitize(Object? value, int depth) {
      if (++values > _maxValues || depth > _maxDepth) {
        throw const FormatException('Result bounds exceeded');
      }
      if (value is Map<String, dynamic>) {
        final safeMap = <String, Object?>{};
        for (final entry in value.entries) {
          // Traverse even excluded values so secrets cannot bypass work limits.
          final child = sanitize(entry.value, depth + 1);
          if (!_credentialKey.hasMatch(
            entry.key.replaceAll(_keySeparators, ''),
          )) {
            safeMap[_redact(entry.key)] = child;
          }
        }
        return safeMap;
      }
      if (value is List) {
        return [for (final item in value) sanitize(item, depth + 1)];
      }
      // JSON exponents can decode to infinity, which cannot be formatted as JSON.
      if (value is num && !value.isFinite) {
        throw const FormatException('Non-finite result');
      }
      return value is String ? _redact(value) : value;
    }

    try {
      safe = const JsonEncoder.withIndent(
        '  ',
      ).convert(sanitize(jsonDecode(trimmed), 0));
    } on FormatException {
      return unavailable;
    }
  } else {
    var scalar = trimmed;
    if (trimmed.startsWith('"')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is String) scalar = decoded;
      } on FormatException {
        return unavailable;
      }
    }
    safe = _redact(scalar);
  }
  if (safe.length <= _maxPaint) return (text: safe, available: true);
  final marker = strings.chatToolResultTruncated;
  var end = _maxPaint - marker.length;
  // Do not cut a surrogate pair at the paint boundary.
  if (end > 0 &&
      safe.codeUnitAt(end - 1) >= 0xd800 &&
      safe.codeUnitAt(end - 1) <= 0xdbff) {
    end--;
  }
  return (text: '${safe.substring(0, end)}$marker', available: true);
}
