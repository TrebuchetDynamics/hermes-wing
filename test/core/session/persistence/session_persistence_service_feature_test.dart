import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/session/session_persistence_service.dart';

import '../support/session_persistence_test_support.dart';

void main() {
  group('SessionPersistenceService', () {
    late SessionPersistenceService service;
    setUp(() async {
      resetSessionPreferences();
      service = await initializedSessionPersistenceService();
    });

    test('saveConnection saves non-secret gateway metadata', () async {
      await saveLocalGatewayConnection(service);
      final session = await service.loadSession();
      expect(session, isNotNull);
      expect(session!.baseUrl, localGatewayBaseUrl);
      expect(session.webSocketUrl, localGatewayWebSocketUrl);
      expect(session.gatewayId, localGatewayId);
      expect(session.lastConnectedAt, isNotNull);
      expect(session.canAttemptReconnect, isFalse);
    });

    test(
      'saveConnection without optional metadata saves partial session',
      () async {
        await service.saveConnection(
          baseUrl: localGatewayBaseUrl,
          webSocketUrl: null,
          gatewayId: null,
        );
        final session = await service.loadSession();
        expect(session, isNotNull);
        expect(session!.baseUrl, localGatewayBaseUrl);
        expect(session.webSocketUrl, isNull);
        expect(session.gatewayId, isNull);
        expect(session.canAttemptReconnect, isFalse);
      },
    );

    test('clearSession removes all saved data', () async {
      await saveLocalGatewayConnection(service);
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
      await saveLocalGatewayConnection(service);
      expect(await service.hasSession(), isTrue);
    });

    test('loadSession returns null when no session saved', () async {
      await service.clearSession();
      final session = await service.loadSession();
      expect(session, isNull);
    });
  });
}
