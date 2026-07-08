part of '../hermes_api_channel.dart';

String _safeHermesError(Object error) {
  var text = error.toString();
  text = text.replaceAllMapped(
    RegExp(r'Bearer\s+[^\s,;]+', caseSensitive: false),
    (_) => 'Bearer [redacted]',
  );
  text = text.replaceAllMapped(
    RegExp(r'Basic\s+[^\s,;]+', caseSensitive: false),
    (_) => 'Basic [redacted]',
  );
  text = text.replaceAllMapped(
    RegExp(
      r'((?:Cookie|Set-Cookie|X-API-Key|X-Auth-Token)\s*[:=]\s*)[^\n\r,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}[redacted]',
  );
  text = text.replaceAllMapped(
    RegExp(r'([a-z][a-z0-9+.-]*://)([^/\s@]+@)', caseSensitive: false),
    (match) => '${match[1]}[redacted]@',
  );
  text = text.replaceAllMapped(
    RegExp(
      r'(api[-_ ]?key|token|secret|password|passwd|pwd|credential|credentials|auth)(\s*(?:=|:)\s*)[^\s,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}${match[2]}[redacted]',
  );
  text = text
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
  if (text.length <= 240) return text;
  return '${text.substring(0, 240).trimRight()}…';
}
