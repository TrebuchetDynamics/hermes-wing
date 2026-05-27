import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:navivox/core/session/session_persistence_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionPersistenceService', () {
    test('saves and loads a complete session', () async {
      final service = SessionPersistenceService();
      await service.saveConnection(
        baseUrl: 'http://192.168.1.100:8765',
        token: 'nvbx_test_token_abc123',
        webSocketUrl: 'ws://192.168.1.100:8765/v1/navivox/stream',
        gatewayId: 'gw-abc-123',
      );

      final session = await service.loadSession();
      expect(session, isNotNull);
      expect(session!.baseUrl, 'http://192.168.1.100:8765');
      expect(session.token, 'nvbx_test_token_abc123');
      expect(session.webSocketUrl, 'ws://192.168.1.100:8765/v1/navivox/stream');
      expect(session.gatewayId, 'gw-abc-123');
      expect(session.lastConnectedAt, isNotNull);
      expect(session.hasAuthToken, isTrue);
      expect(session.isStale, isFalse);
    });

    test('loadSession returns null when no session saved', () async {
      final service = SessionPersistenceService();
      final session = await service.loadSession();
      expect(session, isNull);
    });

    test('clearSession removes all saved data', () async {
      final service = SessionPersistenceService();
      await service.saveConnection(
        baseUrl: 'http://localhost:8765',
        token: 'nvbx_test',
      );
      expect(await service.hasSession(), isTrue);

      await service.clearSession();
      expect(await service.loadSession(), isNull);
      expect(await service.hasSession(), isFalse);
    });

    test('saveConnection without optional fields', () async {
      final service = SessionPersistenceService();
      await service.saveConnection(baseUrl: 'http://localhost:8765');

      final session = await service.loadSession();
      expect(session, isNotNull);
      expect(session!.baseUrl, 'http://localhost:8765');
      expect(session.token, isNull);
      expect(session.webSocketUrl, isNull);
      expect(session.gatewayId, isNull);
      expect(session.hasAuthToken, isFalse);
    });

    test('isStale detects old sessions', () async {
      SharedPreferences.setMockInitialValues({
        'navivox.session.base_url': 'http://localhost:8765',
        'navivox.session.last_connected_at': DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
      });

      final service = SessionPersistenceService();
      final session = await service.loadSession();
      expect(session, isNotNull);
      expect(session!.isStale, isTrue);
    });

    test('persists without QR token leakage', () async {
      // Simulate storing a connection that used QR pairing — the token
      // should NOT contain QR-specific or raw QR payload content.
      final service = SessionPersistenceService();
      await service.saveConnection(
        baseUrl: 'http://192.168.1.100:8765',
        token: 'nvbx_session_token_valid',
      );

      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('navivox.session.token');
      expect(savedToken, 'nvbx_session_token_valid');
      // Verify no QR payload strings leaked into storage
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        final value = prefs.getString(key);
        if (value != null) {
          expect(
            value.contains('navivox://connect'),
            isFalse,
            reason: 'QR descriptor leaked into $key',
          );
        }
      }
    });
  });
}
