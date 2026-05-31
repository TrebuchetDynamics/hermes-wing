import 'navivox_gateway_event_decoder.dart';

void main() {
  invalidJsonStringBecomesBadResponseEvent();
  nonObjectJsonStringBecomesBadResponseEvent();
  decodedObjectEventStillParses();
  decodedObjectMissingEventTypeBecomesBadResponseEvent();
  decodedObjectWithBlankEventTypeBecomesBadResponseEvent();
  decodedMapWithNonStringKeyBecomesBadResponseEvent();
}

void invalidJsonStringBecomesBadResponseEvent() {
  final event = navivoxGatewayEventFromWire('{not json');

  _expect(event.isError, 'invalid JSON string should decode to error event');
  _expect(
    event.code == 'bad_response',
    'invalid JSON code should be bad_response',
  );
  _expect(
    event.message == 'Invalid gateway event',
    'invalid JSON message should describe invalid gateway event',
  );
}

void nonObjectJsonStringBecomesBadResponseEvent() {
  final event = navivoxGatewayEventFromWire('[1, 2, 3]');

  _expect(event.isError, 'non-object JSON string should decode to error event');
  _expect(
    event.code == 'bad_response',
    'non-object JSON code should be bad_response',
  );
}

void decodedObjectEventStillParses() {
  final event = navivoxGatewayEventFromWire({
    'type': 'message',
    'text': 'hello',
  });

  _expect(event.type == 'message', 'decoded map event type should parse');
  _expect(event.text == 'hello', 'decoded map event text should parse');
}

void decodedObjectMissingEventTypeBecomesBadResponseEvent() {
  final event = navivoxGatewayEventFromWire({'text': 'hello'});

  _expect(
    event.isError,
    'decoded object without an event type should decode to error event',
  );
  _expect(
    event.code == 'bad_response',
    'missing event type should be bad_response',
  );
}

void decodedObjectWithBlankEventTypeBecomesBadResponseEvent() {
  final event = navivoxGatewayEventFromWire({'type': ' ', 'text': 'hello'});

  _expect(
    event.isError,
    'decoded object with a blank event type should decode to error event',
  );
  _expect(
    event.code == 'bad_response',
    'blank event type should be bad_response',
  );
}

void decodedMapWithNonStringKeyBecomesBadResponseEvent() {
  final event = navivoxGatewayEventFromWire({1: 'message', 'text': 'hello'});

  _expect(
    event.isError,
    'adapter maps with non-string keys should decode to error event',
  );
  _expect(
    event.code == 'bad_response',
    'adapter maps with non-string keys should be bad_response',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
