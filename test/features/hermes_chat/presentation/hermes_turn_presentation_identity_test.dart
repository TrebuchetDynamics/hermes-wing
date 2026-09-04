import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_turn_presentation_identity.dart';

HermesChatTurn turn(String id) => HermesChatTurn(
  id: id,
  sessionId: 's',
  author: HermesTurnAuthor.assistant,
  createdAt: DateTime.utc(2026),
  text: 'synthetic',
);

void main() {
  test(
    'blank and duplicate IDs are distinct only within their presentation snapshot',
    () {
      final a = turn('');
      final b = turn('');
      final turns = [a, b, turn('duplicate'), turn('duplicate')];
      final keys = [
        for (var i = 0; i < turns.length; i++)
          HermesTurnPresentationIdentity.resolve(turns, i),
      ];
      expect(keys.toSet().length, 4);
      expect(HermesTurnPresentationIdentity.uniqueIds(turns), isEmpty);
      expect(
        HermesTurnPresentationIdentity.resolve([turn('old'), ...turns], 1),
        keys.first,
      );
      expect(
        HermesTurnPresentationIdentity.resolve([turn('')], 0),
        isNot(keys.first),
      );
    },
  );
  test('unique authoritative ID survives canonical object replacement', () {
    expect(
      HermesTurnPresentationIdentity.resolve([turn('id')], 0),
      HermesTurnPresentationIdentity.resolve([turn('id')], 0),
    );
  });
}
