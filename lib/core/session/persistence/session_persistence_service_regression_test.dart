import 'saved_connection_fields.dart';

void main() {
  saveConnectionFieldsClearBlankOptionalValues();
}

void saveConnectionFieldsClearBlankOptionalValues() {
  final fields = SavedConnectionFields.fromInput(
    baseUrl: ' https://gateway.example/api ',
    webSocketUrl: '   ',
    gatewayId: null,
  );

  _expect(
    fields.baseUrl == 'https://gateway.example/api',
    'base URL is trimmed',
  );
  _expect(
    fields.webSocketUrl == null,
    'blank websocket URL must clear stale persisted websocket metadata',
  );
  _expect(
    fields.gatewayId == null,
    'absent gateway id must clear stale persisted gateway metadata',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
