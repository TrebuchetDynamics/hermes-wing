import '../../../../core/protocol/navivox_event.dart';

class TranscriptThreadPresentation {
  const TranscriptThreadPresentation({
    required this.rows,
    required this.typingIndicatorLabel,
  });

  factory TranscriptThreadPresentation.fromMessages(
    List<NavivoxChatMessage> messages, {
    required String? assistantTypingLabel,
  }) {
    final rows = <TranscriptThreadMessageRowPresentation>[];
    for (var index = 0; index < messages.length; index += 1) {
      final message = messages[index];
      final next = index < messages.length - 1 ? messages[index + 1] : null;
      final isUser = message.author == NavivoxMessageAuthor.user;
      rows.add(
        TranscriptThreadMessageRowPresentation(
          message: message,
          isUser: isUser,
          showTail: next == null || next.author != message.author,
          canCancelActiveTurn:
              assistantTypingLabel != null &&
              message.author == NavivoxMessageAuthor.assistant,
        ),
      );
    }

    return TranscriptThreadPresentation(
      rows: rows,
      typingIndicatorLabel: assistantTypingLabel,
    );
  }

  static const defaultEmptyStateTitle = 'Start a conversation';

  final List<TranscriptThreadMessageRowPresentation> rows;
  final String? typingIndicatorLabel;

  String get emptyStateTitle =>
      TranscriptThreadPresentation.defaultEmptyStateTitle;

  bool get showEmptyState => rows.isEmpty && typingIndicatorLabel == null;
  bool get showTypingIndicator => typingIndicatorLabel != null;
  int get itemCount => rows.length + (showTypingIndicator ? 1 : 0);
}

class TranscriptThreadMessageRowPresentation {
  const TranscriptThreadMessageRowPresentation({
    required this.message,
    required this.isUser,
    required this.showTail,
    required this.canCancelActiveTurn,
  });

  final NavivoxChatMessage message;
  final bool isUser;
  final bool showTail;
  final bool canCancelActiveTurn;
}
