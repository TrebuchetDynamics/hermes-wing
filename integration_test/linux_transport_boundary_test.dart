import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/core/hermes/client/platform/hermes_api_transport_io_test.dart'
    as agent_transport;
import '../test/core/wing_link/wing_link_transport_io_test.dart'
    as link_transport;
import '../test/core/hermes/sse/hermes_sse_event_decoder_test.dart' as sse;

// Exercise native sockets/TLS in the Linux engine, not only the host test VM.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('native Agent transport', agent_transport.main);
  group('native Wing Link transport', link_transport.main);
  group('native SSE framing', sse.main);
}
