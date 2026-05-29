import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/presentation/transcript/transcript_thread_presentation.dart';

void main() {
  test('derives empty Transcript surface display state', () {
    final presentation = TranscriptThreadPresentation.fromMessages(
      const <NavivoxChatMessage>[],
      assistantTypingLabel: null,
    );

    expect(presentation.showEmptyState, isTrue);
    expect(presentation.emptyStateTitle, 'Start a conversation');
    expect(presentation.rows, isEmpty);
    expect(presentation.showTypingIndicator, isFalse);
    expect(presentation.itemCount, 0);
  });

  test('derives message rows, bubble tails, and active stream pause state', () {
    final presentation = TranscriptThreadPresentation.fromMessages([
      _message(id: 'assistant-1', author: NavivoxMessageAuthor.assistant),
      _message(id: 'assistant-2', author: NavivoxMessageAuthor.assistant),
      _message(id: 'user-1', author: NavivoxMessageAuthor.user),
      _message(id: 'user-2', author: NavivoxMessageAuthor.user),
      _message(id: 'assistant-3', author: NavivoxMessageAuthor.assistant),
    ], assistantTypingLabel: 'Mineru is typing…');

    expect(presentation.showEmptyState, isFalse);
    expect(presentation.showTypingIndicator, isTrue);
    expect(presentation.typingIndicatorLabel, 'Mineru is typing…');
    expect(presentation.itemCount, 6);
    expect(_rowSummary(presentation.rows), [
      'assistant-1:user=false:tail=false:cancel=true',
      'assistant-2:user=false:tail=true:cancel=true',
      'user-1:user=true:tail=false:cancel=false',
      'user-2:user=true:tail=true:cancel=false',
      'assistant-3:user=false:tail=true:cancel=true',
    ]);
  });

  test('omits typing indicator and pause state when no stream is active', () {
    final presentation = TranscriptThreadPresentation.fromMessages([
      _message(id: 'assistant-1', author: NavivoxMessageAuthor.assistant),
    ], assistantTypingLabel: null);

    expect(presentation.showEmptyState, isFalse);
    expect(presentation.showTypingIndicator, isFalse);
    expect(presentation.typingIndicatorLabel, isNull);
    expect(presentation.itemCount, 1);
    expect(presentation.rows.single.canCancelActiveTurn, isFalse);
  });
}

NavivoxChatMessage _message({
  required String id,
  required NavivoxMessageAuthor author,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: NavivoxMessageKind.text,
    createdAt: DateTime.utc(2026, 5, 23, 11, 15),
    text: id,
  );
}

List<String> _rowSummary(List<TranscriptThreadMessageRowPresentation> rows) {
  return rows
      .map(
        (row) =>
            '${row.message.id}:user=${row.isUser}:tail=${row.showTail}:cancel=${row.canCancelActiveTurn}',
      )
      .toList();
}
