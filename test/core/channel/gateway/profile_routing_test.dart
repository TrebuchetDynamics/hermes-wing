import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway_navivox_channel.dart';

import '../support/gateway_routing_test_support.dart';

void main() {
  test(
    'connect loads Gormes profile routing choices when advertised',
    () async {
      final server = await _ProfileRoutingGateway.start();
      addTearDown(server.close);

      final channel = GatewayNavivoxChannel();
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

      expect(channel.state.profileRouting.profiles, hasLength(1));
      final route = channel.state.profileRouting.profiles.single;
      expect(route.profileId, 'mineru');
      expect(route.displayName, 'Mineru Ops');
      expect(route.workspaces, ['/srv/gormes', '/srv/navivox']);
      expect(route.providers, ['openai-codex', 'ollama']);
      expect(route.channels, ['navivox', 'telegram']);
      expect(channel.state.activeProfileRoute?.profileId, 'mineru');
    },
  );
}

class _ProfileRoutingGateway {
  _ProfileRoutingGateway._(this._server, this.port);

  final HttpServer _server;
  final int port;

  String get baseUrl => 'http://127.0.0.1:$port';

  static Future<_ProfileRoutingGateway> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = _ProfileRoutingGateway._(server, server.port);
    server.listen(fake._handle);
    return fake;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    if (!isAuthorizedGatewayRequest(request)) {
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
      return;
    }
    if (request.uri.path == '/v1/navivox/status') {
      writeGatewayJson(request.response, {
        'enabled': true,
        'protocol_version': 'navivox.v1',
        'websocket_protocols': ['navivox.v1'],
        'capabilities': ['profile_contacts', 'profile_routing'],
        'capabilities_url': '/v1/navivox/capabilities',
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/capabilities') {
      writeGatewayJson(request.response, gatewayRoutingCapabilityDocument());
      return;
    }
    if (request.uri.path == '/v1/navivox/profile-contacts') {
      writeGatewayJson(request.response, {
        'contacts': [gormesProfileContact],
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/profile-routing') {
      writeGatewayJson(request.response, {
        'profiles': [gormesProfileRoute],
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/stream') {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((_) {});
      return;
    }
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }
}
