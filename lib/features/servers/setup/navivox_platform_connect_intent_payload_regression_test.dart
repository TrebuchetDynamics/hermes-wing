import '../models/connection_import.dart';
import 'navivox_platform_connect_intent_payload.dart';

void main() {
  normalizesPlainStringPayloadAsManualSource();
  normalizesStructuredPayloadAndSourceToken();
  fallsBackToManualForUnknownPlatformSourceToken();
  rejectsNonStringPayloadFields();
}

void normalizesPlainStringPayloadAsManualSource() {
  final result = NavivoxPlatformConnectIntentPayload.from(
    ' https://gateway.example/connect?token=nvbx_token ',
  );

  _expect(result != null, 'plain string payload should normalize');
  _expect(
    result!.text == 'https://gateway.example/connect?token=nvbx_token',
    'plain string payload text should be trimmed',
  );
  _expect(
    result.source == PairingHandoffSource.manual,
    'plain string payloads have no platform provenance metadata',
  );
}

void normalizesStructuredPayloadAndSourceToken() {
  final result = NavivoxPlatformConnectIntentPayload.from({
    'payload': ' https://gateway.example/connect?token=nvbx_token ',
    'source': directAppOpenPairingHandoffPlatformSource.toUpperCase(),
  });

  _expect(result != null, 'structured payload should normalize');
  _expect(
    result!.text == 'https://gateway.example/connect?token=nvbx_token',
    'structured payload text should be trimmed',
  );
  _expect(
    result.source == PairingHandoffSource.directAppOpen,
    'platform source tokens should be trimmed and case-insensitive',
  );
}

void fallsBackToManualForUnknownPlatformSourceToken() {
  final result = NavivoxPlatformConnectIntentPayload.from({
    'payload': 'https://gateway.example/connect?token=nvbx_token',
    'source': 'clipboard',
  });

  _expect(result != null, 'payload with unknown source should still normalize');
  _expect(
    result!.source == PairingHandoffSource.manual,
    'unknown platform source tokens should not fabricate trusted provenance',
  );
}

void rejectsNonStringPayloadFields() {
  final result = NavivoxPlatformConnectIntentPayload.from({
    'payload': {'url': 'https://gateway.example/connect?token=nvbx_token'},
    'source': sharedTextPairingHandoffPlatformSource,
  });

  _expect(
    result == null,
    'structured payload field must be a string, not Object.toString() text',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
