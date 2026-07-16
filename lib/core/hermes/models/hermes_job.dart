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
      id: wingStringFromJson(json['id'], fallback: ''),
      name: wingOptionalStringFromJson(json['name']),
      enabled: wingBoolFromJson(json['enabled']),
      state: wingOptionalStringFromJson(json['state']),
      scheduleDisplay:
          wingOptionalStringFromJson(json['schedule_display']) ??
          wingOptionalStringFromJson(schedule['display']) ??
          wingOptionalStringFromJson(schedule['expr']),
      nextRunAt: wingOptionalStringFromJson(json['next_run_at']),
      lastRunAt: wingOptionalStringFromJson(json['last_run_at']),
      lastError: wingOptionalStringFromJson(json['last_error']),
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
