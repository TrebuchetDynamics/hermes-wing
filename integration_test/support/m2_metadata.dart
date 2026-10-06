import 'dart:convert';

import 'package:uuid/uuid.dart';

// No live counting source or public pre-removal history-admission seam exists.
// This module deliberately cannot issue a qualification receipt.
enum M2Phase {
  availability,
  storeLoad,
  storeWrite,
  storeRemoval,
  state,
  historyUser,
  historyAssistant,
  canonical,
  settlement,
}

enum M2Status { success, failure, unavailable, fixture }

enum M2Error {
  delegateFailure,
  ownerMismatch,
  historyAdmissionUnavailable,
  authoritativeCountsUnavailable,
}

String _wire(Enum value) => value.name.replaceAllMapped(
  RegExp('[A-Z]'),
  (m) => '_${m[0]!.toLowerCase()}',
);
String m2RandomAlias() => const Uuid().v4();
final _aliasPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
void _alias(Object? value) {
  if (value is! String || !_aliasPattern.hasMatch(value)) {
    throw const FormatException('Invalid QA alias');
  }
}

/// Strict metadata decoder shared by admission and private sink readback.
/// Fixture counts remain diagnostic; authoritative counters are refused entirely
/// until a separately reviewed source can supply credential-wide continuity.
final class M2Validator {
  M2Validator({
    required this.attempt,
    required this.generation,
    this.expectedUserAlias,
    this.expectedAssistantAlias,
    this.syntheticExpectedDigest,
  }) {
    _alias(attempt);
    _alias(generation);
  }
  static const maxEvents = 128;
  static const maxBytes = 65536;
  static const maxInteger = 9007199254740991;
  static Map<String, Object?> freeze(Map<String, Object?> row) =>
      Map.unmodifiable({
        for (final entry in row.entries)
          entry.key: entry.value is Map<String, Object?>
              ? Map<String, Object?>.unmodifiable(
                  entry.value as Map<String, Object?>,
                )
              : entry.value,
      });
  static void validateEnvelope(
    String encoded,
    String attempt,
    String generation,
  ) {
    if (utf8.encode(encoded).length > maxBytes) {
      _reject();
    }
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, Object?> ||
        decoded.length != 4 ||
        decoded['schema_version'] != 1 ||
        decoded['attempt_alias'] != attempt ||
        decoded['process_generation_alias'] != generation ||
        decoded['events'] is! List) {
      _reject();
    }
    final rows = decoded['events'] as List;
    if (rows.isEmpty || rows.length > maxEvents) {
      _reject();
    }
    final validator = M2Validator(attempt: attempt, generation: generation);
    for (final row in rows) {
      if (row is! Map<String, Object?>) {
        _reject();
      }
      validator.accept(row);
    }
  }

  static const owners = [
    'origin_alias',
    'profile_alias',
    'session_alias',
    'run_alias',
  ];
  static const counters = {
    'deliberate_submission',
    'run_start',
    'session_create',
    'chat_send',
    'completions_send',
    'stop',
    'approval_response',
    'unknown_mutation',
  };
  static const booleans = {
    'store_write_ack',
    'store_load_ack',
    'store_removal_ack',
    'exact_owner',
    'history_match',
    'order_match',
    'synthetic_result_match',
    'notification_denied',
    'old_pid_absent',
    'new_generation',
    'complete_coverage',
  };
  static const aliases = {
    'attempt_alias',
    'target_alias',
    'process_generation_alias',
    'origin_alias',
    'profile_alias',
    'session_alias',
    'run_alias',
    'message_alias',
    'ledger_epoch_alias',
  };
  static const integers = {'schema_version', 'sequence', 'elapsed_ms', 'api'};
  static const digests = {
    'source_digest',
    'apk_digest',
    'synthetic_expected_digest',
  };
  final String attempt;
  final String generation;
  final String? expectedUserAlias;
  final String? expectedAssistantAlias;
  final String? syntheticExpectedDigest;
  final List<Map<String, Object?>> _events = [];
  Map<String, Object?>? _owner;
  String? _user;
  String? _assistant;
  bool _canonical = false;
  int _elapsed = 0;

  static String envelope(
    String attempt,
    String generation,
    List<Map<String, Object?>> events,
  ) => jsonEncode({
    'schema_version': 1,
    'attempt_alias': attempt,
    'process_generation_alias': generation,
    'events': events,
  });

  void accept(Map<String, Object?> event) {
    const other = {
      'phase',
      'status',
      'error',
      'application_id',
      'abi',
      'client_attempt_counts',
      'authoritative_accepted_counts',
      'authoritative_rejected_counts',
      'phase_delta_counts',
    };
    final allowed = {
      ...booleans,
      ...aliases,
      ...integers,
      ...digests,
      ...other,
    };
    if (event.keys.any((key) => !allowed.contains(key))) {
      _reject();
    }
    for (final entry in event.entries) {
      final key = entry.key;
      final value = entry.value;
      if (aliases.contains(key)) _alias(value);
      if (booleans.contains(key) && value is! bool) {
        _reject();
      }
      if (integers.contains(key) &&
          (value is! int || value < 0 || value > maxInteger)) {
        _reject();
      }
      if (digests.contains(key) &&
          (value is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(value))) {
        _reject();
      }
    }
    if (event['schema_version'] != 1 ||
        event['attempt_alias'] != attempt ||
        event['process_generation_alias'] != generation ||
        event['sequence'] != _events.length + 1 ||
        event['elapsed_ms'] is! int ||
        (event['elapsed_ms'] as int) < _elapsed) {
      _reject();
    }
    if (!M2Phase.values.any((p) => _wire(p) == event['phase']) ||
        !M2Status.values.any((s) => s.name == event['status'])) {
      _reject();
    }
    if (event.containsKey('error') &&
        !M2Error.values.any((e) => _wire(e) == event['error'])) {
      _reject();
    }
    if (event.containsKey('application_id') &&
        event['application_id'] != 'com.trebuchetdynamics.hermes.wing.qa') {
      _reject();
    }
    if (event.containsKey('abi') &&
        !{'arm64-v8a', 'armeabi-v7a', 'x86_64'}.contains(event['abi'])) {
      _reject();
    }
    if (event.containsKey('authoritative_accepted_counts') ||
        event.containsKey('authoritative_rejected_counts') ||
        event.containsKey('ledger_epoch_alias') ||
        event['complete_coverage'] == true) {
      _reject();
    }
    for (final key in ['client_attempt_counts', 'phase_delta_counts']) {
      if (!event.containsKey(key)) continue;
      final counts = event[key];
      if (counts is! Map<String, Object?> ||
          counts.keys.toSet().difference(counters).isNotEmpty ||
          counts.length != counters.length) {
        _reject();
      }
      for (final entry in counts.entries) {
        final count = entry.value;
        if (count is! int || count < 0 || count > maxInteger) {
          _reject();
        }
        if ((key == 'phase_delta_counts' && count != 0) ||
            ({
                  'deliberate_submission',
                  'run_start',
                  'chat_send',
                  'completions_send',
                }.contains(entry.key)
                ? count > 1
                : entry.key == 'unknown_mutation' && count != 0)) {
          _reject();
        }
      }
    }
    final phase = event['phase'];
    final success = event['status'] == 'success';
    for (final ack in [
      'store_write_ack',
      'store_load_ack',
      'store_removal_ack',
    ]) {
      final requiredPhase = {
        'store_write_ack': 'store_write',
        'store_load_ack': 'store_load',
        'store_removal_ack': 'store_removal',
      }[ack];
      if (event[ack] == true && (!success || phase != requiredPhase)) {
        _reject();
      }
      if (success && phase == requiredPhase && event[ack] != true) {
        _reject();
      }
    }
    final hasOwner = owners.any(event.containsKey);
    if (hasOwner ||
        {
          'state',
          'store_removal',
          'history_user',
          'history_assistant',
          'canonical',
          'settlement',
        }.contains(phase)) {
      if (!owners.every(event.containsKey) || event['exact_owner'] != true) {
        _reject();
      }
      if (_owner != null && owners.any((key) => _owner![key] != event[key])) {
        _reject();
      }
    }
    // Matching aliases/flags cannot turn a failed or unavailable observation
    // into history admission. Fixture controls remain synthetic evidence only.
    if ({'history_user', 'history_assistant', 'canonical'}.contains(phase) &&
        !success &&
        event['status'] != 'fixture') {
      _reject();
    }
    if (phase == 'history_user' &&
        (_user != null ||
            expectedUserAlias == null ||
            event['message_alias'] != expectedUserAlias)) {
      _reject();
    }
    if (phase == 'history_assistant' &&
        (_user == null ||
            _assistant != null ||
            expectedAssistantAlias == null ||
            event['message_alias'] != expectedAssistantAlias ||
            event['message_alias'] == _user ||
            !event.containsKey('message_alias'))) {
      _reject();
    }
    if (phase == 'canonical' &&
        (_user == null ||
            _assistant == null ||
            syntheticExpectedDigest == null ||
            event['synthetic_expected_digest'] != syntheticExpectedDigest ||
            event['history_match'] != true ||
            event['order_match'] != true ||
            event['synthetic_result_match'] != true)) {
      _reject();
    }
    if (phase == 'settlement' && (!_canonical || !success)) {
      _reject();
    }
    final candidate = [..._events, event];
    if (candidate.length > maxEvents ||
        utf8.encode(envelope(attempt, generation, candidate)).length >
            maxBytes) {
      _reject();
    }
    // Never partially advance validator state on rejection.
    _events.add(freeze(event));
    _elapsed = event['elapsed_ms'] as int;
    if (hasOwner) _owner ??= Map.of(event);
    if (phase == 'history_user') _user = event['message_alias'] as String;
    if (phase == 'history_assistant') {
      _assistant = event['message_alias'] as String;
    }
    if (phase == 'canonical') _canonical = true;
  }

  static Never _reject() => throw const FormatException('Invalid QA metadata');
}
