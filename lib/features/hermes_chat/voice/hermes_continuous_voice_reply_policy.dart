import '../../../core/hermes/models/hermes_chat_turn.dart';

final class HermesSpokenReplyChunk {
  const HermesSpokenReplyChunk({
    required this.turn,
    required this.text,
    required this.spokenCharacterCount,
  });

  final HermesChatTurn turn;
  final String text;
  final int spokenCharacterCount;
}

/// Returns the next stable part of the newest assistant reply that can be
/// spoken without replaying text already handed to TTS.
HermesSpokenReplyChunk? hermesContinuousVoiceReplyChunkToSpeak({
  required List<HermesChatTurn> turns,
  required bool enabled,
  required String? spokenTurnId,
  required int spokenCharacterCount,
  String? spokenText,
  String? replyTurnId,
  HermesChatTurn? spokenUserTurn,
}) {
  if (!enabled) return null;

  final conversationTurns = turns;
  if (replyTurnId != null) {
    turns = turns.where((turn) => turn.id == replyTurnId).toList();
  }
  HermesChatTurn? latest;
  for (final turn in turns) {
    if (turn.author == HermesTurnAuthor.assistant) latest = turn;
  }
  if (spokenTurnId != null) {
    for (final turn in turns) {
      if (turn.id == spokenTurnId &&
          turn.author == HermesTurnAuthor.assistant &&
          turn.status == HermesTurnStatus.completed) {
        final spokenEnd = _reconciledSpokenEnd(
          currentText: turn.text,
          spokenText: spokenText,
          fallbackCharacterCount: spokenCharacterCount,
        );
        if (spokenEnd == null) return null;
        if (spokenEnd < turn.text.length) latest = turn;
        break;
      }
    }
  }
  if (latest == null || latest.text.trim().isEmpty) return null;

  // History replaces optimistic IDs. Only carry the cursor across that
  // replacement when the exact submitted prefix still identifies the text.
  // A retained previous turn means this really is a new reply instead.
  final replacedSpokenTurn =
      spokenTurnId != null &&
      !conversationTurns.any((turn) => turn.id == spokenTurnId);
  if (replacedSpokenTurn) {
    final latestIndex = conversationTurns.indexOf(latest);
    HermesChatTurn? userTurn;
    for (final turn in conversationTurns.take(latestIndex)) {
      if (turn.author == HermesTurnAuthor.user) userTurn = turn;
    }
    final sameRequest =
        spokenUserTurn != null &&
        userTurn != null &&
        (userTurn.id == spokenUserTurn.id ||
            (userTurn.createdAt == spokenUserTurn.createdAt &&
                userTurn.text == spokenUserTurn.text));
    if (!sameRequest ||
        spokenText == null ||
        !latest.text.startsWith(spokenText)) {
      return null;
    }
  }
  final start = replacedSpokenTurn
      ? spokenText!.length
      : latest.id == spokenTurnId
      ? _reconciledSpokenEnd(
          currentText: latest.text,
          spokenText: spokenText,
          fallbackCharacterCount: spokenCharacterCount,
        )
      : 0;
  if (start == null) return null;
  var end = latest.text.length;
  if (latest.status == HermesTurnStatus.streaming) {
    end = start;
    for (final match in RegExp(
      r'[.!?](?=\s|$)',
    ).allMatches(latest.text, start)) {
      end = match.end;
    }
  }
  if (end <= start) return null;

  final text = latest.text.substring(start, end).trim();
  if (text.isEmpty) return null;
  return HermesSpokenReplyChunk(
    turn: latest,
    text: text,
    spokenCharacterCount: end,
  );
}

int? _reconciledSpokenEnd({
  required String currentText,
  required String? spokenText,
  required int fallbackCharacterCount,
}) {
  if (spokenText == null) {
    return fallbackCharacterCount.clamp(0, currentText.length);
  }
  if (spokenText.isEmpty) return 0;
  if (currentText.startsWith(spokenText)) return spokenText.length;

  final trimmed = spokenText.trimRight();
  final anchor = RegExp(r'\S+$').firstMatch(trimmed)?.group(0);
  if (anchor == null || anchor.length < 2) return null;
  final first = currentText.indexOf(anchor);
  if (first < 0 || currentText.indexOf(anchor, first + 1) >= 0) return null;
  return first + anchor.length;
}

/// Decides which completed assistant reply (if any) hands-free continuous
/// voice should speak aloud now.
HermesChatTurn? hermesContinuousVoiceReplyToSpeak({
  required List<HermesChatTurn> turns,
  required bool enabled,
  required String? lastSpokenTurnId,
}) {
  final chunk = hermesContinuousVoiceReplyChunkToSpeak(
    turns: turns,
    enabled: enabled,
    spokenTurnId: lastSpokenTurnId,
    spokenCharacterCount: 0,
  );
  if (chunk == null || chunk.turn.status != HermesTurnStatus.completed) {
    return null;
  }
  return chunk.turn.id == lastSpokenTurnId ? null : chunk.turn;
}
