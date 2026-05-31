import 'dart:convert';

import '../shared/navivox_gateway_json.dart';
import 'navivox_gateway_event.dart';

/// Decodes one raw WebSocket event payload into the typed gateway event model.
///
/// The gateway stream can deliver already-decoded objects in tests/adapters or
/// JSON strings from real sockets. Invalid payloads are normalized to the same
/// typed error event so clients do not duplicate wire-shape checks.
NavivoxGatewayEvent navivoxGatewayEventFromWire(Object? event) {
  final candidate = navivoxGatewayEventCandidateFromWire(event);
  if (!candidate.isValid) return navivoxInvalidGatewayEvent();
  return NavivoxGatewayEvent.fromJson(candidate.object!);
}

/// Validated decoded event candidate before typed event construction.
///
/// The candidate makes the wire invariant explicit: a gateway event must decode
/// to a JSON object and its `type` field must be a non-empty literal string.
class NavivoxGatewayEventCandidate {
  const NavivoxGatewayEventCandidate({required this.object, this.eventType});

  final Map<String, Object?>? object;
  final String? eventType;

  bool get isValid => object != null && eventType != null;
}

NavivoxGatewayEventCandidate navivoxGatewayEventCandidateFromWire(
  Object? event,
) {
  final object = navivoxGatewayObjectFromWireEvent(event);
  return NavivoxGatewayEventCandidate(
    object: object,
    eventType: _gatewayEventTypeFromObject(object),
  );
}

/// Converts one loose WebSocket payload into a decoded event object.
///
/// This intentionally returns `null` for malformed JSON, non-object JSON, and
/// non-map adapter payloads so callers can preserve the gateway client's
/// bad-response event contract without leaking parser exceptions.
Map<String, Object?>? navivoxGatewayObjectFromWireEvent(Object? event) {
  final decoded = _navivoxDecodedWireEvent(event);
  return navivoxGatewayOptionalObjectFromJson(decoded);
}

String? _gatewayEventTypeFromObject(Map<String, Object?>? object) {
  final type = object?['type'];
  if (type is! String || !navivoxGatewayHasText(type)) return null;
  return type;
}

NavivoxGatewayEvent navivoxInvalidGatewayEvent() {
  return const NavivoxGatewayEvent(
    type: 'error',
    code: 'bad_response',
    message: 'Invalid gateway event',
  );
}

Object? _navivoxDecodedWireEvent(Object? event) {
  if (event is! String) return event;
  try {
    return jsonDecode(event);
  } on FormatException {
    return null;
  }
}
