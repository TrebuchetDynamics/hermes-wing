import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/channel/contracts/navivox_message_scope.dart';
import 'package:navivox/core/channel/gateway/approvals/gateway_approval_notice.dart';
import 'package:navivox/core/channel/gateway/messages/gateway_assistant_message_policy.dart';
import 'package:navivox/core/channel/gateway/messages/gateway_message_scope_policy.dart';
import 'package:navivox/core/channel/gateway/messages/gateway_safety_notice_policy.dart';
import 'package:navivox/core/channel/gateway/messages/gateway_tool_call_policy.dart';
import 'package:navivox/core/gateway/messages/navivox_gateway_event.dart';
import 'package:navivox/core/protocol/navivox_event.dart';

void main() {
  group('gateway message policies', () {
    test('resolves scope from metadata before existing transcript messages', () {
      final requestMessage = NavivoxChatMessage(
        id: 'request-1',
        author: NavivoxMessageAuthor.user,
        kind: NavivoxMessageKind.text,
        createdAt: DateTime.utc(2026),
        serverId: 'request-server',
        profileId: 'request-profile',
      );

      final scope = navivoxGatewayMessageScopeFromEvent(
        event: const NavivoxGatewayEvent(
          type: 'assistant_delta',
          requestId: 'request-1',
          metadata: {
            'server_id': 'metadata-server',
            'profile_id': 'metadata-profile',
          },
        ),
        messages: {'request-1': requestMessage},
      );

      expect(scope.serverId, 'metadata-server');
      expect(scope.profileId, 'metadata-profile');
    });

    test('assistant updates preserve prior scope and merge run records', () {
      final createdAt = DateTime.utc(2026, 1, 1);
      final prior = NavivoxChatMessage(
        id: 'assistant-request-1',
        author: NavivoxMessageAuthor.assistant,
        kind: NavivoxMessageKind.text,
        createdAt: createdAt,
        text: 'Hel',
        runRecordReference: 'run-prior',
        serverId: 'prior-server',
        profileId: 'prior-profile',
      );

      final message = navivoxGatewayAssistantTextMessage(
        id: prior.id,
        event: const NavivoxGatewayEvent(
          type: 'assistant_delta',
          text: 'lo',
          runRecordReference: 'run-next',
        ),
        existing: prior,
        createdAt: DateTime.utc(2026, 1, 2),
        scope: navivoxMessageScope(
          serverId: 'event-server',
          profileId: 'event-profile',
        ),
        appendText: true,
      );

      expect(message.text, 'Hello');
      expect(message.createdAt, createdAt);
      expect(message.runRecordReference, 'run-next');
      expect(message.serverId, 'prior-server');
      expect(message.profileId, 'prior-profile');
    });

    test('tool approval updates preserve the tool card and attach approval', () {
      final prior = NavivoxChatMessage(
        id: 'tool-1',
        author: NavivoxMessageAuthor.assistant,
        kind: NavivoxMessageKind.toolCall,
        createdAt: DateTime.utc(2026, 1, 1),
        toolCall: const NavivoxToolCall(
          name: 'browser.open',
          status: 'waiting',
          summary: 'Open browser',
        ),
        serverId: 'prior-server',
        profileId: 'prior-profile',
      );
      final notice = navivoxGatewayApprovalNotice(
        event: const NavivoxGatewayEvent(
          type: 'approval_required',
          approvalId: 'approval-1',
          toolCallId: 'tool-1',
          message: 'Allow browser open?',
          risk: 'medium',
        ),
        fallbackApprovalId: () => 'fallback-approval',
      );

      final message = navivoxGatewayToolApprovalMessage(
        id: 'tool-1',
        event: const NavivoxGatewayEvent(
          type: 'approval_required',
          runRecordReference: 'run-approval',
        ),
        priorMessage: prior,
        notice: notice,
        createdAt: DateTime.utc(2026, 1, 2),
        scope: navivoxMessageScope(
          serverId: 'event-server',
          profileId: 'event-profile',
        ),
      );

      expect(message, isNotNull);
      expect(message!.toolCall!.name, 'browser.open');
      expect(message.toolCall!.approval!.id, 'approval-1');
      expect(message.runRecordReference, 'run-approval');
      expect(message.serverId, 'prior-server');
      expect(message.profileId, 'prior-profile');
    });

    test('safety warnings keep event severity and scoped notice payload', () {
      final message = navivoxGatewaySafetyWarningMessage(
        id: 'safety-1',
        event: const NavivoxGatewayEvent(
          type: 'safety_warning',
          severity: 'blocker',
          message: 'Stop',
          risk: 'high',
          runRecordReference: 'run-safety',
        ),
        createdAt: DateTime.utc(2026, 1, 1),
        scope: navivoxMessageScope(
          serverId: 'server-1',
          profileId: 'profile-1',
        ),
      );

      expect(message.kind, NavivoxMessageKind.safetyWarning);
      expect(message.safetyNotice!.severity, 'blocker');
      expect(message.safetyNotice!.message, 'Stop');
      expect(message.safetyNotice!.risk, 'high');
      expect(message.runRecordReference, 'run-safety');
      expect(message.serverId, 'server-1');
      expect(message.profileId, 'profile-1');
    });
  });
}
