import '../../protocol/wing_json.dart';

class HermesRun {
  const HermesRun({required this.id, required this.sessionId});

  factory HermesRun.fromJson(Map<String, Object?> json) {
    return HermesRun(
      id: wingStringFromJson(json['id'] ?? json['run_id'], fallback: ''),
      sessionId: wingStringFromJson(json['session_id'], fallback: ''),
    );
  }

  final String id;
  final String sessionId;
}
