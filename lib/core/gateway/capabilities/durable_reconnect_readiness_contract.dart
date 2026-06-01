import '../shared/navivox_gateway_json.dart';

/// Operator-visible durable reconnect states shared by capability parsing and
/// session readiness presentation.
enum ReconnectReadinessKind { unknown, unsupported, blocked, available, saved }

/// Pure durable-reconnect eligibility evaluation for gateway capabilities.
///
/// Keeping the issue-contract fields explicit makes the safety gate replayable:
/// a gateway must advertise all fields Navivox needs before UI can present
/// durable reconnect as available.
class DurableReconnectReadinessContract {
  const DurableReconnectReadinessContract({
    required this.supported,
    required this.issueEndpoint,
    required this.authMethods,
    required this.platforms,
    required this.effectiveSecurity,
    required this.blockedReason,
  });

  final bool supported;
  final String issueEndpoint;
  final List<String> authMethods;
  final List<String> platforms;
  final String effectiveSecurity;
  final String blockedReason;

  List<String> get missingIssueContractFields {
    final missing = <String>[];
    if (!navivoxGatewayHasText(issueEndpoint)) missing.add('issue endpoint');
    if (authMethods.isEmpty) missing.add('auth methods');
    if (platforms.isEmpty) missing.add('platforms');
    if (!navivoxGatewayHasText(effectiveSecurity)) {
      missing.add('effective security');
    }
    return List.unmodifiable(missing);
  }

  String? get recoveryMessage {
    final suppliedReason = blockedReason.trim();
    if (suppliedReason.isNotEmpty) return suppliedReason;
    final missingFields = missingIssueContractFields;
    if (missingFields.isEmpty) return null;
    return 'Durable reconnect is advertised but missing ${_readinessList(missingFields)}.';
  }

  ReconnectReadinessKind get kind {
    if (!supported) return ReconnectReadinessKind.unsupported;
    if (recoveryMessage != null) return ReconnectReadinessKind.blocked;
    return ReconnectReadinessKind.available;
  }
}

String _readinessList(List<String> items) {
  if (items.length <= 1) return items.join();
  if (items.length == 2) return '${items[0]} and ${items[1]}';
  return '${items.sublist(0, items.length - 1).join(', ')}, and ${items.last}';
}
