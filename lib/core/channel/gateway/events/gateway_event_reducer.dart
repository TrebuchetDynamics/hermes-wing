import '../../../gateway/messages/navivox_gateway_event.dart';
import '../../../protocol/navivox_event.dart';
import '../../../protocol/navivox_json.dart';
import '../../../protocol/navivox_profile_contact_key.dart';
import '../../contracts/navivox_channel.dart';
import '../../contracts/navivox_message_scope.dart';
import '../../contracts/navivox_profile_contact_codec.dart';
import '../approvals/gateway_approval_notice.dart';
import '../codecs/gateway_tool_artifact_codec.dart';

part '../messages/gateway_assistant_message_policy.dart';
part '../messages/gateway_message_scope_policy.dart';
part '../messages/gateway_safety_notice_policy.dart';
part '../messages/gateway_tool_call_policy.dart';

/// Reduces gateway stream events into explicit channel runtime effects.
///
/// The reducer is pure apart from supplied id/time callbacks. The runtime keeps
/// WebSocket listening, ChangeNotifier notifications, and approval stream side
/// effects.
GatewayEventReduction navivoxReduceGatewayEvent({
  required NavivoxGatewayEvent event,
  required NavivoxChannelState state,
  required String Function() fallbackId,
  required DateTime Function() clock,
}) {
  switch (event.type) {
    case 'pong':
    case 'gateway_identity':
    case 'done':
      return const GatewayEventReduction.ignore();
    case 'session_started':
      final scope = _navivoxGatewayMessageScopeFromEvent(
        event: event,
        messages: state.messages,
      );
      return GatewayEventReduction.updateActiveSession(
        sessionId: event.sessionId,
        profileContactKey: navivoxProfileContactKeyFromNullable(
          serverId: scope.serverId,
          profileId: scope.profileId,
        ),
      );
    case 'assistant_delta':
      return _assistantReduction(
        event: event,
        state: state,
        fallbackId: fallbackId,
        clock: clock,
        appendText: true,
      );
    case 'assistant_message':
      return _assistantReduction(
        event: event,
        state: state,
        fallbackId: fallbackId,
        clock: clock,
        appendText: false,
      );
    case 'tool_call_started':
      return _toolCallReduction(
        event: event,
        state: state,
        fallbackId: fallbackId,
        clock: clock,
        status: 'started',
      );
    case 'tool_call_updated':
      return _toolCallReduction(
        event: event,
        state: state,
        fallbackId: fallbackId,
        clock: clock,
        status: event.status ?? 'updated',
      );
    case 'tool_call_finished':
      return _toolCallReduction(
        event: event,
        state: state,
        fallbackId: fallbackId,
        clock: clock,
        status: event.status ?? 'finished',
      );
    case 'safety_warning':
      return GatewayEventReduction.putMessage(
        _navivoxGatewaySafetyWarningMessage(
          event: event,
          id: event.safetyId ?? 'safety-${fallbackId()}',
          createdAt: clock(),
          scope: _navivoxGatewayMessageScopeFromEvent(
            event: event,
            messages: state.messages,
          ),
        ),
      );
    case 'approval_required':
      final notice = navivoxGatewayApprovalNotice(
        event: event,
        fallbackApprovalId: () => 'approval-${fallbackId()}',
      );
      final scope = _navivoxGatewayMessageScopeFromEvent(
        event: event,
        messages: state.messages,
      );
      final messages = <NavivoxChatMessage>[];
      final toolApprovalMessage = _navivoxGatewayToolApprovalMessage(
        id: notice.toolCallId,
        event: event,
        priorMessage: state.messages[notice.toolCallId],
        notice: notice,
        createdAt: clock(),
        scope: scope,
      );
      if (toolApprovalMessage != null) messages.add(toolApprovalMessage);
      messages.add(
        _navivoxGatewayApprovalRequestMessage(
          event: event,
          notice: notice,
          createdAt: clock(),
          scope: scope,
        ),
      );
      return GatewayEventReduction.approval(messages: messages, notice: notice);
    case 'profile_contact_update':
      final contact = event.contact;
      if (contact == null) return const GatewayEventReduction.ignore();
      return GatewayEventReduction.upsertProfileContact(
        navivoxProfileContactFromJson(contact),
      );
    case 'error':
      if (event.code == 'turn_in_progress') {
        return GatewayEventReduction.appendSystemMessage(
          event.message ?? 'Another device is in a turn. Try again shortly.',
        );
      }
      return GatewayEventReduction.appendSystemMessage(
        event.message ?? 'Gateway error',
      );
    default:
      return const GatewayEventReduction.ignore();
  }
}

GatewayEventReduction _assistantReduction({
  required NavivoxGatewayEvent event,
  required NavivoxChannelState state,
  required String Function() fallbackId,
  required DateTime Function() clock,
  required bool appendText,
}) {
  final messageId = _navivoxGatewayAssistantMessageId(
    event: event,
    fallbackRequestId: fallbackId,
  );
  return GatewayEventReduction.putMessage(
    _navivoxGatewayAssistantTextMessage(
      id: messageId,
      event: event,
      existing: state.messages[messageId],
      createdAt: clock(),
      scope: _navivoxGatewayMessageScopeFromEvent(
        event: event,
        messages: state.messages,
      ),
      appendText: appendText,
    ),
  );
}

GatewayEventReduction _toolCallReduction({
  required NavivoxGatewayEvent event,
  required NavivoxChannelState state,
  required String Function() fallbackId,
  required DateTime Function() clock,
  required String status,
}) {
  final toolCallId = event.toolCallId ?? 'tool-${fallbackId()}';
  return GatewayEventReduction.putMessage(
    _navivoxGatewayToolCallMessage(
      id: toolCallId,
      event: event,
      status: status,
      priorMessage: state.messages[toolCallId],
      createdAt: clock(),
      scope: _navivoxGatewayMessageScopeFromEvent(
        event: event,
        messages: state.messages,
      ),
    ),
  );
}

sealed class GatewayEventReduction {
  const GatewayEventReduction._();

  const factory GatewayEventReduction.ignore() = IgnoreGatewayEvent;

  const factory GatewayEventReduction.updateActiveSession({
    required String? sessionId,
    String? profileContactKey,
  }) = UpdateGatewayActiveSession;

  const factory GatewayEventReduction.putMessage(NavivoxChatMessage message) =
      PutGatewayEventMessage;

  const factory GatewayEventReduction.approval({
    required List<NavivoxChatMessage> messages,
    required NavivoxGatewayApprovalNotice notice,
  }) = PutGatewayApprovalEvent;

  const factory GatewayEventReduction.upsertProfileContact(
    NavivoxProfileContact contact,
  ) = UpsertGatewayProfileContact;

  const factory GatewayEventReduction.appendSystemMessage(String text) =
      AppendGatewaySystemMessage;
}

final class IgnoreGatewayEvent extends GatewayEventReduction {
  const IgnoreGatewayEvent() : super._();
}

final class UpdateGatewayActiveSession extends GatewayEventReduction {
  const UpdateGatewayActiveSession({
    required this.sessionId,
    this.profileContactKey,
  }) : super._();

  final String? sessionId;

  /// The profile contact the session belongs to, resolved from event scope or
  /// the correlated request. Null when the gateway omitted scope and no prior
  /// message correlated the session to a profile.
  final String? profileContactKey;
}

final class PutGatewayEventMessage extends GatewayEventReduction {
  const PutGatewayEventMessage(this.message) : super._();

  final NavivoxChatMessage message;
}

final class PutGatewayApprovalEvent extends GatewayEventReduction {
  const PutGatewayApprovalEvent({required this.messages, required this.notice})
    : super._();

  final List<NavivoxChatMessage> messages;
  final NavivoxGatewayApprovalNotice notice;
}

final class UpsertGatewayProfileContact extends GatewayEventReduction {
  const UpsertGatewayProfileContact(this.contact) : super._();

  final NavivoxProfileContact contact;
}

final class AppendGatewaySystemMessage extends GatewayEventReduction {
  const AppendGatewaySystemMessage(this.text) : super._();

  final String text;
}
