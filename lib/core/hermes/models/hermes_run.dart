import '../../protocol/navivox_json.dart';

class HermesRun {
  const HermesRun({required this.id, required this.sessionId});

  factory HermesRun.fromJson(Map<String, Object?> json) {
    return HermesRun(
      id: navivoxStringFromJson(json['id'] ?? json['run_id'], fallback: ''),
      sessionId: navivoxStringFromJson(json['session_id'], fallback: ''),
    );
  }

  final String id;
  final String sessionId;
}
