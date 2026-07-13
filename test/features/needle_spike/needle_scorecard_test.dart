import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/needle_spike/models/needle_scorecard.dart';

void main() {
  test('records verdict counts and totals', () {
    final card = NeedleScorecard();
    card.record(NeedleVerdict.correct);
    card.record(NeedleVerdict.correct);
    card.record(NeedleVerdict.wrongArgs);
    card.record(NeedleVerdict.noCall);
    expect(card.countFor(NeedleVerdict.correct), 2);
    expect(card.countFor(NeedleVerdict.wrongTool), 0);
    expect(card.countFor(NeedleVerdict.wrongArgs), 1);
    expect(card.countFor(NeedleVerdict.noCall), 1);
    expect(card.total, 4);
    expect(
      card.summaryLine,
      'correct 2 · wrong tool 0 · wrong args 1 · no call 1 · total 4',
    );
  });

  test('reset clears all counts', () {
    final card = NeedleScorecard()..record(NeedleVerdict.correct);
    card.reset();
    expect(card.total, 0);
  });
}
