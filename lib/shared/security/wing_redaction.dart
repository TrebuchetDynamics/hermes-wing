/// Strips credentials, tokens, and local paths out of text that reaches an
/// operator's screen, clipboard, or diagnostics export.
///
/// This is the single implementation behind the Hermes channel's error text,
/// the chat surfaces, and the diagnostics export. Those three used to keep
/// hand-maintained copies, which drifted: the channel copy lost local-path
/// redaction while the other two kept it, and Agents, Providers, and
/// Diagnostics render channel error text verbatim. Adding a pattern here now
/// covers every path at once.
///
/// The rules run most-specific first so a header keeps its name while losing
/// its value.
String wingRedactSensitiveText(String text) {
  var safe = text;

  // Authorization headers, before the bare scheme rules below, so the header
  // name survives and only its value is replaced.
  safe = safe.replaceAllMapped(
    RegExp(
      r'(Authorization\s*[:=]\s*(?:Bearer|Basic)\s+)[^\s,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}[redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'(authorization\s*[:=]\s*basic\s+)\S+', caseSensitive: false),
    (match) => '${match[1]}[redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'(authorization\s*[:=]\s*)\S+', caseSensitive: false),
    (match) => '${match[1]}[redacted]',
  );

  // Bare credential schemes. The `\S+` form is deliberately greedier than the
  // `[^\s,;]+` one and runs after it, so a value containing a comma or
  // semicolon still loses its tail.
  safe = safe.replaceAllMapped(
    RegExp(r'Bearer\s+[^\s,;]+', caseSensitive: false),
    (_) => 'Bearer [redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'bearer\s+\S+', caseSensitive: false),
    (_) => 'Bearer [redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'Basic\s+[^\s,;]+', caseSensitive: false),
    (_) => 'Basic [redacted]',
  );

  safe = safe.replaceAllMapped(
    RegExp(
      r'((?:Cookie|Set-Cookie|X-API-Key|X-Auth-Token)\s*[:=]\s*)[^\n\r,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}[redacted]',
  );

  // Credentials embedded in a URL's userinfo section.
  safe = safe.replaceAllMapped(
    RegExp(r'([a-z][a-z0-9+.-]*://)([^/\s@]+@)', caseSensitive: false),
    (match) => '${match[1]}[redacted]@',
  );

  // Local paths are excluded data: Windows drive, UNC, then POSIX homes.
  safe = safe.replaceAll(
    RegExp(r'\b[A-Z]:\\[^\s,;]+', caseSensitive: false),
    '[redacted-path]',
  );
  safe = safe.replaceAll(RegExp(r'\\\\[^\s,;]+'), '[redacted-path]');
  safe = safe.replaceAll(
    RegExp(r'/(?:home|Users|var|private|mnt|Volumes)/[^\s,;]+'),
    '[redacted-path]',
  );

  // key=value and key: value pairs, keeping the key so the message still
  // explains itself.
  safe = safe.replaceAllMapped(
    RegExp(
      r'(api[-_ ]?key|auth[-_ ]?token|token|secret|password|passwd|pwd|credential|credentials|auth)(\s*(?:=|:)\s*)[^\s,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}${match[2]}[redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(
      r'((?:api[-_ ]?key|auth[-_ ]?token|token|secret|password|passwd|pwd|credential)\s*[:=]\s*)\S+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}[redacted]',
  );

  // Known provider token shapes, then anything still calling itself a secret.
  return safe
      .replaceAll(
        RegExp(r'sk-[a-z0-9_-]{12,}', caseSensitive: false),
        'sk-[redacted]',
      )
      .replaceAll(
        RegExp(r'gh[pousr]_[a-z0-9_]{20,}', caseSensitive: false),
        'ghp_[redacted]',
      )
      .replaceAll(
        RegExp(r'xox[abprs]-[a-z0-9-]{20,}', caseSensitive: false),
        'xox-[redacted]',
      )
      .replaceAll(
        RegExp(
          r'eyJ[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}',
          caseSensitive: false,
        ),
        '[redacted-jwt]',
      )
      .replaceAll(
        RegExp(r'secret[-_a-z0-9.]*', caseSensitive: false),
        '[redacted]',
      );
}

/// Redacts [text], then bounds it to [maxLength] with an ellipsis.
String wingRedactedPreview(String text, {required int maxLength}) {
  final safe = wingRedactSensitiveText(text);
  if (safe.length <= maxLength) return safe;
  return '${safe.substring(0, maxLength).trimRight()}…';
}
