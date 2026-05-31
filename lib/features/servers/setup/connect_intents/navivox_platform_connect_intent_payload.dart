import '../../models/connection_import.dart';

/// Normalized platform-channel connect intent payload.
///
/// Android may deliver either a plain payload string or a structured map with
/// pairing handoff provenance. Keep normalization separate from connection
/// parsing so source/provenance assumptions are visible and testable.
class NavivoxPlatformConnectIntentPayload {
  const NavivoxPlatformConnectIntentPayload({
    required this.text,
    required this.source,
  });

  final String text;
  final PairingHandoffSource source;

  static NavivoxPlatformConnectIntentPayload? from(Object? payload) {
    if (payload is String) return _fromString(payload);
    if (payload is Map) return _fromMap(payload);
    return null;
  }

  static NavivoxPlatformConnectIntentPayload? _fromString(String payload) {
    final text = payload.trim();
    if (text.isEmpty) return null;
    return NavivoxPlatformConnectIntentPayload(
      text: text,
      source: PairingHandoffSource.manual,
    );
  }

  static NavivoxPlatformConnectIntentPayload? _fromMap(Map payload) {
    final rawText = payload['payload'];
    if (rawText is! String) return null;
    final text = rawText.trim();
    if (text.isEmpty) return null;
    return NavivoxPlatformConnectIntentPayload(
      text: text,
      source: pairingHandoffSourceFromPlatformPayload(payload['source']),
    );
  }
}

PairingHandoffSource pairingHandoffSourceFromPlatformPayload(Object? value) {
  return switch (_platformSourceTokenFromPayload(value)) {
    directAppOpenPairingHandoffPlatformSource =>
      PairingHandoffSource.directAppOpen,
    sharedTextPairingHandoffPlatformSource => PairingHandoffSource.sharedText,
    _ => PairingHandoffSource.manual,
  };
}

const directAppOpenPairingHandoffPlatformSource = 'direct_app_open';
const sharedTextPairingHandoffPlatformSource = 'shared_text';

String? _platformSourceTokenFromPayload(Object? value) {
  if (value is! String) return null;
  return _normalizedPlatformSourceToken(value);
}

String? _normalizedPlatformSourceToken(String value) {
  final token = value.trim().toLowerCase();
  if (token.isEmpty) return null;
  return token;
}
