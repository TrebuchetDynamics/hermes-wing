import '../../protocol/wing_json.dart';

class HermesJob {
  const HermesJob({
    required this.id,
    this.name,
    this.enabled = false,
    this.state,
    this.scheduleDisplay,
    this.nextRunAt,
    this.lastRunAt,
    this.lastError,
  });

  factory HermesJob.fromJson(Map<String, Object?> json) {
    final schedule = wingMapFieldFromJson(json, 'schedule');
    return HermesJob(
      id: _boundedString(json['id'], 128),
      name: _boundedOptionalString(json['name'], 200),
      enabled: wingBoolFromJson(json['enabled']),
      state: _boundedOptionalString(json['state'], 80),
      scheduleDisplay:
          _boundedOptionalString(json['schedule_display'], 200) ??
          _boundedOptionalString(schedule['display'], 200) ??
          _boundedOptionalString(schedule['expr'], 200),
      nextRunAt: _boundedOptionalString(json['next_run_at'], 64),
      lastRunAt: _boundedOptionalString(json['last_run_at'], 64),
      lastError: _boundedOptionalString(json['last_error'], 1000),
    );
  }

  final String id;
  final String? name;
  final bool enabled;
  final String? state;
  final String? scheduleDisplay;
  final String? nextRunAt;
  final String? lastRunAt;
  final String? lastError;

  String get displayName => name == null || name!.trim().isEmpty ? id : name!;
}

final _jobControlPattern = RegExp(r'[\x00-\x1f\x7f]');

String _boundedString(Object? value, int maximum) {
  return _truncateJobText(wingStringFromJson(value, fallback: ''), maximum);
}

String? _boundedOptionalString(Object? value, int maximum) {
  final text = wingOptionalStringFromJson(value);
  return text == null ? null : _truncateJobText(text, maximum);
}

String _truncateJobText(String value, int maximum) {
  final sanitized = value.replaceAll(_jobControlPattern, '');
  final runes = sanitized.runes;
  if (runes.length <= maximum) return sanitized;
  return '${String.fromCharCodes(runes.take(maximum - 1))}…';
}
