import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:integration_test/integration_test.dart';

import 'support/local_serve_chat_journey.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
  });
  testWidgets('isolated Linux authenticated serve chat production journey', (
    tester,
  ) async {
    final root = Platform.environment['WING_LOCAL_ROOT'];
    if (root == null ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null) {
      throw StateError('Use the task-owned isolated serve-chat runner.');
    }
    await binding.setSurfaceSize(const Size(1280, 1000));
    final receipt = await runLocalServeChatJourney(tester);
    File(
      '$root/cache/serve-chat-receipt.json',
    ).writeAsStringSync(jsonEncode({...receipt, 'native_pid': pid}));
  });
}
