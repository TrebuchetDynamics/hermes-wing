import '../models/connection_import.dart';
import '../shared/connection_import_parser.dart';

/// Parses the platform-channel shape used by Android connect intents.
///
/// Native code may deliver either a plain payload string or a map containing
/// the payload plus handoff provenance metadata.
SetupQrImageImport? parseNavivoxConnectIntentPayload(Object? payload) {
  final normalized = _NavivoxPlatformConnectIntentPayload.from(payload);
  if (normalized == null) return null;

  final parsed = parseNavivoxConnectionImportPayload(normalized.text);
  if (parsed == null) return null;
  return parsed.withSource(normalized.source);
}

class _NavivoxPlatformConnectIntentPayload {
  const _NavivoxPlatformConnectIntentPayload({
    required this.text,
    required this.source,
  });

  final String text;
  final PairingHandoffSource source;

  static _NavivoxPlatformConnectIntentPayload? from(Object? payload) {
    if (payload is String) return _fromString(payload);
    if (payload is Map) return _fromMap(payload);
    return null;
  }

  static _NavivoxPlatformConnectIntentPayload? _fromString(String payload) {
    final text = payload.trim();
    if (text.isEmpty) return null;
    return _NavivoxPlatformConnectIntentPayload(
      text: text,
      source: PairingHandoffSource.manual,
    );
  }

  static _NavivoxPlatformConnectIntentPayload? _fromMap(Map payload) {
    final rawText = payload['payload'];
    if (rawText is! String) return null;
    final text = rawText.trim();
    if (text.isEmpty) return null;
    return _NavivoxPlatformConnectIntentPayload(
      text: text,
      source: pairingHandoffSourceFromPlatformPayload(payload['source']),
    );
  }
}

PairingHandoffSource pairingHandoffSourceFromPlatformPayload(Object? value) {
  return switch (_platformSourceTokenFromPayload(value)) {
    'direct_app_open' => PairingHandoffSource.directAppOpen,
    'shared_text' => PairingHandoffSource.sharedText,
    _ => PairingHandoffSource.manual,
  };
}

String? _platformSourceTokenFromPayload(Object? value) {
  if (value is! String) return null;
  return _normalizedPlatformSourceToken(value);
}

String? _normalizedPlatformSourceToken(String value) {
  final token = value.trim().toLowerCase();
  if (token.isEmpty) return null;
  return token;
}
