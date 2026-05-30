import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retires the legacy SimpleChatAdapter pass-through file', () {
    final legacyAdapter = File(
      'lib/features/chat/widgets/simple_chat_adapter.dart',
    );

    expect(
      legacyAdapter.existsSync(),
      isFalse,
      reason:
          'The active Transcript surface Adapter and TranscriptSurfaceFrame '
          'own this seam; keep voice behavior covered through those modules.',
    );
  });

  test('retires private Transcript widget fragment tombstones', () {
    const retiredFragments = [
      'lib/features/chat/widgets/src/transcript_bubble.dart',
      'lib/features/chat/widgets/src/transcript_composer.dart',
      'lib/features/chat/widgets/src/transcript_message_actions.dart',
      'lib/features/chat/widgets/src/transcript_message_bodies.dart',
    ];

    for (final path in retiredFragments) {
      expect(
        File(path).existsSync(),
        isFalse,
        reason:
            '$path is a retired private fragment; active Transcript widget '
            'Modules live directly under lib/features/chat/widgets/.',
      );
    }
  });
}
