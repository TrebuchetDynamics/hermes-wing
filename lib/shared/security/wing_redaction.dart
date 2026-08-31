final RegExp _wingMediaDeliveryTokenPattern = RegExp(
  r'''MEDIA:[ \t]*(?:`[^`\n]+`|"[^"\n]+"|'[^'\n]+'|\S+)''',
  caseSensitive: false,
);

bool wingContainsMediaDeliveryToken(String text) =>
    _wingMediaDeliveryTokenPattern.hasMatch(text);

final RegExp _wingHostArtifactLabelPattern = RegExp(
  r'(?:^|\s)(?:\*{1,2})?(?:file|path|saved(?:\s+(?:to|at))?|output|result|image|location)\s*:\s*(?:\*{1,2})?\s*',
  caseSensitive: false,
);

final RegExp _wingHostArtifactPathPattern = RegExp(
  r'''(?:`|["'])?(?:~[\\/]|[A-Z]:[\\/]|\\\\|/(?:home|Users|var|private|mnt|Volumes|tmp|root|opt|srv|etc)/)[^\n]+?\.(?:png|jpe?g|gif|webp|svg|bmp|avif|pdf|txt|md|csv|json|docx?|xlsx?|pptx?|odt|rtf|zip|tar|gz|mp4|mov|webm|mkv|avi|mp3|wav|ogg|opus|m4a|flac)(?=[`"'*\s)]|$)''',
  caseSensitive: false,
);

final RegExp _wingFileArtifactUrlPattern = RegExp(
  r'''file://[^\s`"']*?\.(?:png|jpe?g|gif|webp|svg|bmp|avif|pdf|txt|md|csv|json|docx?|xlsx?|pptx?|odt|rtf|zip|tar|gz|mp4|mov|webm|mkv|avi|mp3|wav|ogg|opus|m4a|flac)\b''',
  caseSensitive: false,
);

Iterable<String> _wingUnfencedLines(String text) sync* {
  var fencedCode = false;
  for (final line in text.split(RegExp(r'[\r\n]+'))) {
    if (RegExp(r'^\s*(?:`{3,}|~{3,})').hasMatch(line)) {
      fencedCode = !fencedCode;
      continue;
    }
    if (!fencedCode) yield line;
  }
}

final RegExp _wingHostAudioPathPattern = RegExp(
  r'''(?:~[\\/]|[A-Z]:[\\/]|\\\\|/(?:home|Users|var|private|mnt|Volumes|tmp|root|opt|srv|etc)/)[^\n`"']*?\.(?:wav|mp3|m4a|aac|ogg|opus|flac)\b''',
  caseSensitive: false,
);

final RegExp _wingFileAudioUrlPattern = RegExp(
  r'''file://[^\s`"']*?\.(?:wav|mp3|m4a|aac|ogg|opus|flac)\b''',
  caseSensitive: false,
);

bool _wingHostPathMatchStartsInsideToken(String source, RegExpMatch match) {
  if (match.start == 0) return false;
  final prefix = source.substring(0, match.start);
  if (prefix.toLowerCase().endsWith('file://')) return false;
  return RegExp(
    r'[a-z0-9/\\.:]',
    caseSensitive: false,
  ).hasMatch(source.substring(match.start - 1, match.start));
}

bool wingContainsHostAudioReference(String text) {
  for (final line in _wingUnfencedLines(text)) {
    if (_wingFileAudioUrlPattern.hasMatch(line)) return true;
    for (final match in _wingHostAudioPathPattern.allMatches(line)) {
      if (!_wingHostPathMatchStartsInsideToken(line, match)) return true;
    }
  }
  return false;
}

bool wingContainsHostArtifactReference(String text) {
  for (final line in _wingUnfencedLines(text)) {
    final label = _wingHostArtifactLabelPattern.firstMatch(line);
    if (label == null) continue;
    final candidate = line.substring(label.end);
    if (_wingFileArtifactUrlPattern.hasMatch(candidate)) return true;
    for (final match in _wingHostArtifactPathPattern.allMatches(candidate)) {
      if (!_wingHostPathMatchStartsInsideToken(candidate, match)) return true;
    }
  }
  return false;
}

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
  // MEDIA: embeds a host path or URL in assistant text instead of transferring
  // an attachment. Keep the delivery failure visible without exposing its
  // source or encouraging Wing to fetch an untrusted remote resource.
  var safe = text.replaceAll(
    _wingMediaDeliveryTokenPattern,
    '[media not delivered]',
  );

  // Models can occasionally leak tool protocol wrappers into prose. Treat
  // snake_case tags as tool payloads, and fail closed on an unfinished wrapper
  // while a reply is still streaming.
  safe = safe.replaceAll(
    RegExp(
      r'<([a-z][a-z0-9]*_[a-z0-9_]*)\b[^>]*>[\s\S]*?</\1\s*>',
      caseSensitive: false,
    ),
    '[tool activity hidden]',
  );
  safe = safe.replaceAll(
    RegExp(r'<[a-z][a-z0-9]*_[a-z0-9_]*\b[^>]*>[\s\S]*$', caseSensitive: false),
    '[tool activity hidden]',
  );

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

  // file:// always addresses a local or mounted filesystem resource. Remove
  // the full URI before applying URL-safe POSIX path boundaries below.
  safe = safe.replaceAll(
    RegExp(r'file://[^\s,;]+', caseSensitive: false),
    '[redacted-path]',
  );

  // Quoted and Markdown-code paths can contain spaces. Remove the complete
  // delimited path before the whitespace-bounded fallbacks below.
  safe = safe.replaceAll(
    RegExp(
      r'''([`"'])(?:~[\\/]|[A-Z]:[\\/]|\\\\|/(?:home|Users|var|private|mnt|Volumes|tmp|root|opt|srv|etc)/)[^`"'\n]+\1''',
      caseSensitive: false,
    ),
    '[redacted-path]',
  );

  // Local paths are excluded data: tilde homes, Windows drive, UNC, then
  // POSIX homes.
  safe = safe.replaceAll(RegExp(r'~[\\/][^\s,;]+'), '[redacted-path]');
  safe = safe.replaceAll(
    RegExp(r'\b[A-Z]:[\\/][^\s,;]+', caseSensitive: false),
    '[redacted-path]',
  );
  safe = safe.replaceAll(RegExp(r'\\\\[^\s,;]+'), '[redacted-path]');
  safe = safe.replaceAllMapped(
    RegExp(
      r'''(^|[\s(\[{<"'`=:])(/(?:home|Users|var|private|mnt|Volumes|tmp|root|opt|srv|etc)/[^\s,;]+)''',
      caseSensitive: false,
      multiLine: true,
    ),
    (match) => '${match[1]}[redacted-path]',
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
