import '../serialization/navivox_json.dart';

/// Count fields accepted by the memory overview wire contract.
const navivoxMemoryTotalTurnsCountFields = [
  'turns',
  'total_turns',
  'totalTurns',
];
const navivoxMemoryActiveItemsCountFields = [
  'memory_items',
  'active_memory_items',
  'activeMemoryItems',
];
const navivoxMemoryObservationsCountFields = ['observations'];
const navivoxMemoryConclusionsCountFields = ['conclusions'];
const navivoxMemorySessionSummariesCountFields = [
  'session_summaries',
  'sessionSummaries',
];
const navivoxMemoryEntitiesCountFields = ['entities'];
const navivoxMemoryRelationshipsCountFields = ['relationships'];

/// Decodes memory aggregate counters while preserving their invariant.
///
/// Memory overview counts are cardinalities from the gateway; malformed,
/// missing, or negative values cannot represent real item totals and are
/// surfaced as zero instead of leaking impossible counters into presentation.
int navivoxMemoryCountFromJson(Object? value) {
  final count = navivoxIntFromJson(value);
  return count < 0 ? 0 : count;
}

/// Reads the first present count value for an overview field alias group.
///
/// Exact aliases are preferred in caller-supplied order, then a compatibility
/// pass accepts case/underscore drift such as `sessionSummaries` vs
/// `session_summaries`. A present malformed value remains authoritative and is
/// decoded by [navivoxMemoryCountFromJson] instead of silently falling through
/// to a later alias.
Object? navivoxMemoryCountFieldFromJson(
  Map<String, Object?> json,
  Iterable<String> names,
) {
  for (final name in names) {
    if (json.containsKey(name)) return json[name];
  }

  final canonicalNames = navivoxCanonicalWireFieldNames(names);
  for (final entry in json.entries) {
    if (canonicalNames.contains(navivoxCanonicalWireFieldName(entry.key))) {
      return entry.value;
    }
  }
  return null;
}
