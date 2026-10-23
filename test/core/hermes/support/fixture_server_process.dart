import 'dart:io';

import 'fixture_server.dart';

/// A separate socket registry for the fixture allocator's overlap regression.
Future<void> main() async {
  final server = await bindHermesFixtureServer();
  stdout.writeln(server.port);
  try {
    await stdin.drain<void>();
  } finally {
    await server.close(force: true);
  }
}
