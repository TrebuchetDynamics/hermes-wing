import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/reconciliation/hermes_text_reconciliation.dart';

void main() {
  group('reconcileAssistantText', () {
    test('repairs a meaningful dropped-chunk copy', () {
      expect(
        reconcileAssistantText(
          streamed: '! What are we working on?',
          canonical: 'Hey! What are we working on today?',
        ),
        'Hey! What are we working on today?',
      );
    });

    test('preserves distinct pre-tool prose before a canonical final', () {
      expect(
        reconcileAssistantText(
          streamed: 'I will inspect that now.',
          canonical: 'The inspection completed successfully.',
          segmentStart: true,
        ),
        'I will inspect that now.\n\nThe inspection completed successfully.',
      );
    });

    test('does not erase scattered one-character similarities', () {
      expect(
        isLossyChunkCopy(
          'abcdefghijklm',
          'a long body where b then c then d appear far apart from each other',
        ),
        isFalse,
      );
    });

    test('rejects tiny and low-coverage fragments', () {
      expect(
        isLossyChunkCopy('short', 'a much longer canonical response'),
        false,
      );
      expect(
        isLossyChunkCopy('shared phrase', '${'prefix ' * 20}shared phrase'),
        false,
      );
    });

    test('retains a stream that already contains the canonical final', () {
      expect(
        reconcileAssistantText(
          streamed: 'Before the tool.\n\nFinal answer.',
          canonical: 'Final answer.',
        ),
        'Before the tool.\n\nFinal answer.',
      );
    });

    test('uses canonical text for whitespace-only differences', () {
      expect(
        reconcileAssistantText(
          streamed: 'Hello   world',
          canonical: 'Hello world',
        ),
        'Hello world',
      );
    });
  });
}
