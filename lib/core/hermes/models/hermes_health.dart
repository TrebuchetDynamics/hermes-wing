import '../../protocol/wing_json.dart';

class HermesHealthStatus {
  const HermesHealthStatus({
    required this.status,
    required this.platform,
    this.version,
    this.gatewayState,
    this.activeAgents = 0,
  });

  factory HermesHealthStatus.fromJson(Map<String, Object?> json) {
    return HermesHealthStatus(
      status: wingStringFromJson(json['status'], fallback: 'unknown'),
      platform: wingStringFromJson(json['platform'], fallback: 'hermes-agent'),
      version: wingOptionalStringFromJson(json['version']),
      gatewayState: wingOptionalStringFromJson(json['gateway_state']),
      activeAgents: wingIntFromJson(json['active_agents']),
    );
  }

  final String status;
  final String platform;
  final String? version;
  final String? gatewayState;
  final int activeAgents;

  bool get isOk => status.toLowerCase() == 'ok';
}
