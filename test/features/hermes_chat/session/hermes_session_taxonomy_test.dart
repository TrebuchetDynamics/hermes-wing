import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session actions live in the chat session package', () {
    expect(
      File(
        'lib/features/hermes_chat/session/hermes_chat_session_actions.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'lib/features/hermes_chat/screens/state/hermes_chat_session_actions.dart',
      ).existsSync(),
      isFalse,
    );
  });
}
