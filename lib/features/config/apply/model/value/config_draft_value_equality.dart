bool configDraftValuesEqual(Object? left, Object? right) {
  if (identical(left, right) || left == right) return true;

  if (left is Map && right is Map) {
    return _configDraftMapsEqual(left, right);
  }
  if (left is Set && right is Set) {
    return _configDraftSetsEqual(left, right);
  }
  if (left is Iterable && right is Iterable) {
    return _configDraftIterablesEqual(left, right);
  }
  return false;
}

bool _configDraftMapsEqual(Map left, Map right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key)) return false;
    if (!configDraftValuesEqual(entry.value, right[entry.key])) return false;
  }
  return true;
}

bool _configDraftSetsEqual(Set left, Set right) {
  if (left.length != right.length) return false;
  final unmatchedRight = right.toList(growable: true);
  for (final leftValue in left) {
    final matchIndex = unmatchedRight.indexWhere(
      (rightValue) => configDraftValuesEqual(leftValue, rightValue),
    );
    if (matchIndex == -1) return false;
    unmatchedRight.removeAt(matchIndex);
  }
  return unmatchedRight.isEmpty;
}

bool _configDraftIterablesEqual(Iterable left, Iterable right) {
  final leftIterator = left.iterator;
  final rightIterator = right.iterator;
  while (true) {
    final leftHasNext = leftIterator.moveNext();
    final rightHasNext = rightIterator.moveNext();
    if (leftHasNext != rightHasNext) return false;
    if (!leftHasNext) return true;
    if (!configDraftValuesEqual(leftIterator.current, rightIterator.current)) {
      return false;
    }
  }
}
