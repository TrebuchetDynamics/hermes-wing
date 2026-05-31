import 'package:navivox/core/session/session_persistence_service.dart';

export 'session_shared_preferences_test_support.dart';
import 'session_shared_preferences_test_support.dart';

const localGatewayBaseUrl = 'http://192.168.1.100:8765';
const localGatewayWebSocketUrl = 'ws://192.168.1.100:8765/v1/navivox/stream';
const localGatewayId = 'gw-abc-123';

Future<SessionPersistenceService> initializedSessionPersistenceService() async {
  final service = SessionPersistenceService();
  await service.ensureInitialized();
  return service;
}

Future<void> saveLocalGatewayConnection(SessionPersistenceService service) {
  return service.saveConnection(
    baseUrl: localGatewayBaseUrl,
    webSocketUrl: localGatewayWebSocketUrl,
    gatewayId: localGatewayId,
  );
}
