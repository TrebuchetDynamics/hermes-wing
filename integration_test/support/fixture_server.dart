import 'dart:io';

int _nextPort = 0;

/// Bind-and-retain is the ownership claim, including across isolates/processes.
/// Offsets 0–19 and 80–99 remain available to the harness/native fixtures.
Future<HttpServer> bindHermesFixtureServer({int portOffset = 0}) async {
  final value = Platform.environment['AUTOWORK_PORT_BASE'];
  if (value == null) return HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final base = int.tryParse(value);
  if (base == null || base < 1024 || base > 65436) {
    throw StateError('Invalid reserved fixture port range.');
  }
  final start = _nextPort++;
  for (var attempt = 0; attempt < 60; attempt++) {
    final port = base + 20 + ((portOffset + start + attempt) % 60);
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      // A sequential replacement should advance beyond skipped candidates too.
      final next = start + attempt + 1;
      if (_nextPort < next) _nextPort = next;
      return server;
    } on SocketException catch (error) {
      final code = error.osError?.errorCode;
      // Dart's socket registry reports same-VM ownership before an OS bind.
      final sameVmOwner =
          code == -1 &&
          error.osError?.message ==
              'The shared flag to bind() needs to be `true` if binding multiple times on the same (address, port) combination.';
      if (!sameVmOwner && !{48, 98, 10048}.contains(code)) rethrow;
    }
  }
  throw StateError('Reserved fixture port range exhausted.');
}
