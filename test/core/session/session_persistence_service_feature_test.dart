import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:navivox/core/session/session_persistence_service.dart';

void main() {
  group('SessionPersistenceService', () {
    late SessionPersistenceService service;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = SessionPersistenceService();
      await service.ensureInitialized();
    });

    test('saveConnection saves non-secret gateway metadata', () async {
      await service.saveConnection(
        baseUrl: 'http://192.168.1.100:8765',
        webSocketUrl: 'ws://192.168.1.100:8765/v1/navivox/stream',
        gatewayId: 'gw-abc-123',
      );
      final session = await service.loadSession();
      expect(session, isNotNull);
      expect(session!.baseUrl, 'http://192.168.1.100:8765');
      expect(session.webSocketUrl, 'ws://192.168.1.100:8765/v1/navivox/stream');
      expect(session.gatewayId, 'gw-abc-123');
      expect(session.lastConnectedAt, isNotNull);
      expect(session.canAttemptReconnect, isFalse);
    });

    test(
      'saveConnection without optional metadata saves partial session',
      () async {
        await service.saveConnection(
          baseUrl: 'http://192.168.1.100:8765',
          webSocketUrl: null,
          gatewayId: null,
        );
        final session = await service.loadSession();
        expect(session, isNotNull);
        expect(session!.baseUrl, 'http://192.168.1.100:8765');
        expect(session.webSocketUrl, isNull);
        expect(session.gatewayId, isNull);
        expect(session.canAttemptReconnect, isFalse);
      },
    );

    test('clearSession removes all saved data', () async {
      await service.saveConnection(
        baseUrl: 'http://192.168.1.100:8765',
        webSocketUrl: 'ws://192.168.1.100:8765/v1/navivox/stream',
        gatewayId: 'gw-abc-123',
      );
      expect(await service.hasSession(), isTrue);
      await service.clearSession();
      expect(await service.hasSession(), isFalse);
      final session = await service.loadSession();
      expect(session, isNull);
    });

    test('hasSession returns false when no session saved', () async {
      await service.clearSession();
      expect(await service.hasSession(), isFalse);
    });

    test('hasSession returns true after saveConnection', () async {
      await service.saveConnection(
        baseUrl: 'http://192.168.1.100:8765',
        webSocketUrl: 'ws://192.168.1.100:8765/v1/navivox/stream',
        gatewayId: 'gw-abc-123',
      );
      expect(await service.hasSession(), isTrue);
    });

    test('loadSession returns null when no session saved', () async {
      await service.clearSession();
      final session = await service.loadSession();
      expect(session, isNull);
    });
  });
}
