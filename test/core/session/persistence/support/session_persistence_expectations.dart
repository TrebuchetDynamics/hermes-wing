import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/session/session_persistence_service.dart';

import '../../support/session_persistence_test_support.dart';

void expectLocalGatewaySession(SavedSession session) {
  expect(session.baseUrl, localGatewayBaseUrl);
  expect(session.webSocketUrl, localGatewayWebSocketUrl);
  expect(session.gatewayId, localGatewayId);
  expect(session.lastConnectedAt, isNotNull);
  expect(session.canAttemptReconnect, isFalse);
}

void expectPartialLocalGatewaySession(SavedSession session) {
  expect(session.baseUrl, localGatewayBaseUrl);
  expect(session.webSocketUrl, isNull);
  expect(session.gatewayId, isNull);
  expect(session.canAttemptReconnect, isFalse);
}

Future<void> expectNoSavedSession(SessionPersistenceService service) async {
  expect(await service.hasSession(), isFalse);
  expect(await service.loadSession(), isNull);
}
