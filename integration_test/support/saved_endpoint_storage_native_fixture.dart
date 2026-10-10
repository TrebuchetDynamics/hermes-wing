import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Non-authorizing discriminators exist only in memory and platform secure storage.
String storageMarker() {
  final random = Random.secure();
  return base64UrlEncode(List.generate(32, (_) => random.nextInt(256)));
}

Future<void> storageControl(String root, String mode) async {
  final request = File('$root/cache/control-request');
  final ready = File('$root/cache/control-ready');
  if (ready.existsSync()) ready.deleteSync();
  request.writeAsStringSync(mode);
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!ready.existsSync()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Owned service control did not acknowledge');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  if (ready.readAsStringSync() != mode) {
    throw StateError('Owned service control mismatch');
  }
}

void storageCheck(bool condition, String invariant) {
  // Do not let test matchers print credential-bearing objects on failure.
  if (!condition) throw StateError(invariant);
}
