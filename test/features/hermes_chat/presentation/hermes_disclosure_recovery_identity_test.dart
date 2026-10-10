import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_transcript_viewport.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_turn_presentation_identity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'evicted unique reasoning keys reset while retained keys and canonical history remain intact',
    () {
      final scroll = ScrollController();
      final viewport = HermesTranscriptViewportController(scroll)
        ..setOwner('A', origin: 'synthetic-origin');
      final turns = [
        for (var i = 0; i < 101; i++)
          HermesChatTurn(
            id: 'synthetic-$i',
            sessionId: 'A',
            author: HermesTurnAuthor.system,
            createdAt: DateTime.utc(2026),
            kind: HermesTurnKind.reasoning,
            text: 'Synthetic $i',
          ),
      ];
      final evicted = viewport.rowKey('synthetic-0');
      final retained = viewport.rowKey('synthetic-100');
      final projected = viewport.project(turns);
      expect(projected.length, 100);
      expect(projected.first.id, 'synthetic-1');
      expect(turns.length, 101);
      viewport.retainRows(projected.map((t) => t.id).toSet());
      expect(viewport.rowKey('synthetic-100'), same(retained));
      expect(viewport.rowKey('synthetic-0'), isNot(same(evicted)));
      viewport.userScrolled(nearLatest: false);
      viewport.revealEarlier();
      expect(viewport.project(turns).length, 101);
      final generation = viewport.beginAuthoritativeRefresh();
      viewport.setOwner('B', origin: 'synthetic-origin');
      expect(viewport.generation, greaterThan(generation));
      expect(viewport.rowKey('synthetic-100'), isNot(same(retained)));
      expect(viewport.mode, HermesViewportMode.followingLatest);
      // Duplicate Agent IDs cannot acquire exact-owner restoration authority.
      final duplicate = [...turns, turns.first];
      expect(
        HermesTurnPresentationIdentity.uniqueIds(duplicate),
        isNot(contains('synthetic-0')),
      );
      viewport.dispose();
      scroll.dispose();
    },
  );
}
