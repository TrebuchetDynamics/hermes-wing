import '../../../core/hermes/models/hermes_chat_turn.dart';

/// Local row keys are never used as evidence of Agent identity.
abstract final class HermesTurnPresentationIdentity {
  static Set<String> uniqueIds(List<HermesChatTurn> turns) {
    final counts = <String, int>{};
    for (final turn in turns) {
      if (turn.id.trim().isNotEmpty) {
        counts[turn.id] = (counts[turn.id] ?? 0) + 1;
      }
    }
    return {
      for (final entry in counts.entries)
        if (entry.value == 1) entry.key,
    };
  }

  static Object resolve(
    List<HermesChatTurn> turns,
    int index, {
    Set<String>? unique,
  }) {
    final turn = turns[index];
    if ((unique ?? uniqueIds(turns)).contains(turn.id)) {
      return (turn.sessionId, turn.id);
    }
    // Object identity survives prepends of existing rows, but not canonical
    // replacement. Occurrence separates even a duplicated object instance.
    final occurrence = turns
        .take(index)
        .where((item) => identical(item, turn))
        .length;
    return (turn, occurrence);
  }
}
