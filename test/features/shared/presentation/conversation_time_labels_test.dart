import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/shared/presentation/conversation_time_labels.dart';

void main() {
  group('conversation time labels', () {
    test(
      'formats message bubble timestamps with the shared 24-hour policy',
      () {
        expect(
          conversationMessageTimeLabel(DateTime.utc(2026, 5, 23, 9, 7)),
          '09:07',
        );
      },
    );

    test(
      'formats date separators relative to the current conversation day',
      () {
        final now = DateTime.utc(2026, 5, 23, 12);

        expect(
          conversationDateSeparatorLabel(DateTime.utc(2026, 5, 23), now),
          'Today',
        );
        expect(
          conversationDateSeparatorLabel(DateTime.utc(2026, 5, 22), now),
          'Yesterday',
        );
        expect(
          conversationDateSeparatorLabel(DateTime.utc(2026, 5, 20), now),
          'May 20',
        );
      },
    );

    test('compares timestamps by calendar day for transcript grouping', () {
      expect(
        isSameConversationDay(
          DateTime.utc(2026, 5, 23, 9),
          DateTime.utc(2026, 5, 23, 20),
        ),
        isTrue,
      );
      expect(
        isSameConversationDay(
          DateTime.utc(2026, 5, 23, 23),
          DateTime.utc(2026, 5, 24),
        ),
        isFalse,
      );
    });
  });
}
