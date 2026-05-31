import '../models/connection_import.dart';
import 'navivox_connect_intent_payload.dart';

void main() {
  parsesPlainStringPayloadAsManualImport();
  preservesMapPayloadSourceProvenance();
  trimsPlatformSourceTokenBeforeMappingProvenance();
  mapsPlatformSourceTokenCaseInsensitively();
  rejectsStructuredMapPayloadValuesInsteadOfParsingObjectStrings();
  rejectsStructuredSourceValuesInsteadOfParsingObjectStrings();
}

void parsesPlainStringPayloadAsManualImport() {
  final result = parseNavivoxConnectIntentPayload(
    ' https://gateway.example/connect?token=nvbx_token ',
  );

  _expect(result != null, 'plain string payload should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'plain string base URL should be derived from URL origin',
  );
  _expect(result.token == 'nvbx_token', 'plain string token should parse');
  _expect(
    result.source == PairingHandoffSource.manual,
    'plain string payloads have no platform provenance metadata',
  );
}

void preservesMapPayloadSourceProvenance() {
  final result = parseNavivoxConnectIntentPayload({
    'payload': 'https://gateway.example/connect?token=nvbx_token',
    'source': 'shared_text',
  });

  _expect(result != null, 'map payload should parse');
  _expect(
    result!.source == PairingHandoffSource.sharedText,
    'shared_text source should be preserved',
  );
}

void trimsPlatformSourceTokenBeforeMappingProvenance() {
  final result = parseNavivoxConnectIntentPayload({
    'payload': 'https://gateway.example/connect?token=nvbx_token',
    'source': ' shared_text ',
  });

  _expect(result != null, 'map payload with padded source should parse');
  _expect(
    result!.source == PairingHandoffSource.sharedText,
    'platform source token should be trimmed before source mapping',
  );
}

void mapsPlatformSourceTokenCaseInsensitively() {
  final result = parseNavivoxConnectIntentPayload({
    'payload': 'https://gateway.example/connect?token=nvbx_token',
    'source': ' SHARED_TEXT ',
  });

  _expect(result != null, 'map payload with uppercase source should parse');
  _expect(
    result!.source == PairingHandoffSource.sharedText,
    'platform source tokens should be case-insensitive after trimming',
  );
}

void rejectsStructuredMapPayloadValuesInsteadOfParsingObjectStrings() {
  final result = parseNavivoxConnectIntentPayload({
    'payload': {'url': 'https://gateway.example/connect?token=nvbx_token'},
    'source': 'shared_text',
  });

  _expect(
    result == null,
    'platform map payload field must be a string, not Object.toString() text',
  );
}

void rejectsStructuredSourceValuesInsteadOfParsingObjectStrings() {
  final result = parseNavivoxConnectIntentPayload({
    'payload': 'https://gateway.example/connect?token=nvbx_token',
    'source': _StringLikePlatformSource(),
  });

  _expect(result != null, 'map payload with structured source should parse');
  _expect(
    result!.source == PairingHandoffSource.manual,
    'platform source field must be a string, not Object.toString() text',
  );
}

class _StringLikePlatformSource {
  @override
  String toString() => 'shared_text';
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
