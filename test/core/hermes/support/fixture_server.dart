import 'dart:io';

// Autowork reserves a bounded port range per worker. Outside that harness retain
// OS-assigned ports. Suites using this helper run sequentially within a worker.
int _nextPort = 20;

Future<HttpServer> bindHermesFixtureServer() {
  final value = Platform.environment['AUTOWORK_PORT_BASE'];
  if (value == null) return HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final base = int.parse(value);
  if (base < 1024 || base > 65436) {
    throw StateError('Invalid reserved fixture port range.');
  }
  final port = base + _nextPort;
  _nextPort = _nextPort == 79 ? 20 : _nextPort + 1;
  return HttpServer.bind(InternetAddress.loopbackIPv4, port);
}
