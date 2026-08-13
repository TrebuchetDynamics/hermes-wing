import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message flow lives in the chat composer package', () {
    expect(
      File(
        'lib/features/hermes_chat/composer/hermes_chat_message_flow.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'lib/features/hermes_chat/screens/state/hermes_chat_message_flow.dart',
      ).existsSync(),
      isFalse,
    );
  });
}
