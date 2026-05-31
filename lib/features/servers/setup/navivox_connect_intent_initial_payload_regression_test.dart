import 'navivox_connect_intent_initial_payload.dart';
import 'navivox_platform_connect_intent_payload.dart';

void main() {
  preservesPayloadObservedDuringAvailabilityProbe();
  remembersNullAvailabilityProbePayload();
  keepsFirstUnconsumedProbePayloadAcrossRepeatedAvailabilityChecks();
}

void preservesPayloadObservedDuringAvailabilityProbe() {
  final cache = NavivoxInitialConnectIntentPayloadCache();
  final payload = {
    'payload': 'https://gateway.example/connect?token=nvbx_token',
    'source': sharedTextPairingHandoffPlatformSource,
  };

  cache.remember(payload);

  _expect(
    cache.hasPayload,
    'availability probe payload should be marked cached',
  );
  _expect(
    identical(cache.take(), payload),
    'initial import should consume the payload returned by the availability probe',
  );
  _expect(
    !cache.hasPayload,
    'availability probe payload should be consumed only once',
  );
}

void remembersNullAvailabilityProbePayload() {
  final cache = NavivoxInitialConnectIntentPayloadCache();

  cache.remember(null);

  _expect(
    cache.hasPayload,
    'null availability probe result should still be treated as a completed probe',
  );
  _expect(
    cache.take() == null,
    'null availability probe result should be replayable without a second probe',
  );
  _expect(!cache.hasPayload, 'null probe result should be consumed only once');
}

void keepsFirstUnconsumedProbePayloadAcrossRepeatedAvailabilityChecks() {
  final cache = NavivoxInitialConnectIntentPayloadCache();
  final firstPayload = {
    'payload': 'https://gateway.example/connect?token=nvbx_token',
    'source': directAppOpenPairingHandoffPlatformSource,
  };

  cache.remember(firstPayload);
  cache.remember(null);

  _expect(
    identical(cache.take(), firstPayload),
    'repeated availability probes should not overwrite the first cached initial intent',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
