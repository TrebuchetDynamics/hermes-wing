enum NeedleVerdict { correct, wrongTool, wrongArgs, noCall }

/// Manual evaluation tally. Holds counts only: persisting or logging
/// utterances is forbidden by the repo's voice privacy policy.
class NeedleScorecard {
  final Map<NeedleVerdict, int> _counts = {
    for (final v in NeedleVerdict.values) v: 0,
  };

  int countFor(NeedleVerdict verdict) => _counts[verdict]!;

  int get total => _counts.values.fold(0, (sum, c) => sum + c);

  void record(NeedleVerdict verdict) {
    _counts[verdict] = _counts[verdict]! + 1;
  }

  void reset() {
    for (final v in NeedleVerdict.values) {
      _counts[v] = 0;
    }
  }

  String get summaryLine =>
      'correct ${countFor(NeedleVerdict.correct)} · '
      'wrong tool ${countFor(NeedleVerdict.wrongTool)} · '
      'wrong args ${countFor(NeedleVerdict.wrongArgs)} · '
      'no call ${countFor(NeedleVerdict.noCall)} · '
      'total $total';
}
