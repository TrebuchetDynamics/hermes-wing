import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/session/persistence/contracts/saved_session.dart';

void main() {
  group('SavedSession', () {
    test('uses freshness contract for deterministic staleness checks', () {
      final connectedAt = DateTime.utc(2026);
      final session = SavedSession(
        baseUrl: 'http://gateway.local',
        lastConnectedAt: connectedAt,
      );

      expect(session.isStaleAt(connectedAt.add(const Duration(days: 7))), isFalse);
      expect(
        session.isStaleAt(connectedAt.add(const Duration(days: 7, seconds: 1))),
        isTrue,
      );
    });

    test('does not allow reconnect attempts without durable credentials', () {
      const session = SavedSession(baseUrl: 'http://gateway.local');

      expect(session.canAttemptReconnect, isFalse);
    });
  });
}
