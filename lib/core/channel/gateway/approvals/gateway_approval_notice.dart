import '../../../gateway/navivox_gateway_protocol.dart';
import '../../../protocol/navivox_event.dart';
import '../../contracts/navivox_channel.dart';

/// Gateway approval payload shared by stream notifications, tool-call cards,
/// and durable approval-request messages.
class NavivoxGatewayApprovalNotice {
  const NavivoxGatewayApprovalNotice({
    required this.id,
    required this.toolCallId,
    required this.prompt,
    required this.risk,
  });

  final String id;
  final String toolCallId;
  final String prompt;
  final String? risk;

  NavivoxApprovalRequest toChannelRequest() {
    return NavivoxApprovalRequest(
      id: id,
      toolCallId: toolCallId,
      prompt: prompt,
      risk: risk,
    );
  }
}

NavivoxGatewayApprovalNotice navivoxGatewayApprovalNotice({
  required NavivoxGatewayEvent event,
  required String Function() fallbackApprovalId,
}) {
  return NavivoxGatewayApprovalNotice(
    id: event.approvalId ?? fallbackApprovalId(),
    toolCallId: event.toolCallId ?? '',
    prompt: event.message ?? 'Approval required',
    risk: event.risk,
  );
}

NavivoxToolApproval navivoxGatewayToolApproval({
  required NavivoxGatewayApprovalNotice notice,
}) {
  return NavivoxToolApproval(
    id: notice.id,
    status: 'approval_required',
    prompt: notice.prompt,
    risk: notice.risk,
  );
}
