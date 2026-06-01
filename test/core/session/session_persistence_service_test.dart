import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/session/persistence/contracts/saved_session.dart';
import 'package:navivox/core/session/persistence/service/session_persistence_service.dart';
import 'package:navivox/core/session/persistence/storage/session_preference_keys.dart';
import 'package:navivox/core/session/persistence/storage/session_preference_write_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('write plan strips bootstrap-only URL state before persistence', () {
    final writes = sessionPreferenceWritesForConnection(
      baseUrl: ' https://gateway.example.test/setup?pairing_token=secret#frag ',
      webSocketUrl:
          ' wss://user:secret@gateway.example.test/stream?token=secret#frag ',
      gatewayId: ' gateway-1 ',
      connectedAt: DateTime.parse('2026-05-31T12:34:56+02:00'),
    );

    expect(_writeMap(writes), {
      SessionPreferenceKeys.baseUrl: 'https://gateway.example.test',
      SessionPreferenceKeys.webSocketUrl: 'wss://gateway.example.test/stream',
      SessionPreferenceKeys.gatewayId: 'gateway-1',
      SessionPreferenceKeys.lastConnectedAt: '2026-05-31T10:34:56.000Z',
    });
    expect(
      writes.where((write) => write.isRemove).map((write) => write.key),
      contains(SessionPreferenceKeys.legacyToken),
    );
  });

  test('write plan removes optional fields when input is blank', () {
    final writes = sessionPreferenceWritesForConnection(
      baseUrl: 'http://127.0.0.1:8765',
      webSocketUrl: ' ',
      gatewayId: '\t',
      connectedAt: DateTime.utc(2026, 5, 31),
    );

    expect(
      writes.where((write) => write.isRemove).map((write) => write.key),
      containsAll([
        SessionPreferenceKeys.legacyToken,
        SessionPreferenceKeys.webSocketUrl,
        SessionPreferenceKeys.gatewayId,
      ]),
    );
  });

  test('write plan drops unsafe websocket-shaped metadata', () {
    final writes = sessionPreferenceWritesForConnection(
      baseUrl: 'https://gateway.example.test',
      webSocketUrl: ' https://gateway.example.test/stream?token=secret#frag ',
      gatewayId: 'gateway-1',
      connectedAt: DateTime.utc(2026, 5, 31),
    );

    expect(
      writes.where((write) => write.isRemove).map((write) => write.key),
      contains(SessionPreferenceKeys.webSocketUrl),
    );
    expect(
      _writeMap(writes),
      isNot(contains(SessionPreferenceKeys.webSocketUrl)),
    );
  });

  test('save, load, and clear apply the same preference write plan', () async {
    SharedPreferences.setMockInitialValues({
      SessionPreferenceKeys.legacyToken: 'bootstrap-secret',
      SessionPreferenceKeys.webSocketUrl: 'wss://old.example.test/stream',
      SessionPreferenceKeys.gatewayId: 'old-gateway',
    });
    final service = SessionPersistenceService(
      clock: () => DateTime.parse('2026-05-31T12:34:56+02:00'),
    );

    await service.saveConnection(
      baseUrl: ' https://gateway.example.test/setup?pairing_token=secret ',
      webSocketUrl: ' ',
      gatewayId: ' gateway-1 ',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SessionPreferenceKeys.legacyToken), isNull);
    expect(prefs.getString(SessionPreferenceKeys.webSocketUrl), isNull);
    expect(
      prefs.getString(SessionPreferenceKeys.baseUrl),
      'https://gateway.example.test',
    );
    expect(prefs.getString(SessionPreferenceKeys.gatewayId), 'gateway-1');
    expect(
      prefs.getString(SessionPreferenceKeys.lastConnectedAt),
      '2026-05-31T10:34:56.000Z',
    );

    final SavedSession? session = await service.loadSession();
    expect(session?.baseUrl, 'https://gateway.example.test');
    expect(session?.webSocketUrl, isNull);
    expect(session?.gatewayId, 'gateway-1');

    await service.clearSession();

    expect(await service.hasSession(), isFalse);
    expect(await service.loadSession(), isNull);
    expect(prefs.getString(SessionPreferenceKeys.gatewayId), isNull);
    expect(prefs.getString(SessionPreferenceKeys.lastConnectedAt), isNull);
  });
}

Map<String, String> _writeMap(Iterable<SessionPreferenceWrite> writes) {
  final values = <String, String>{};
  for (final write in writes) {
    final value = write.value;
    if (value != null) values[write.key] = value;
  }
  return values;
}
