import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/forwarding/forward_message_intent.dart';

import '../transcript/shared/transcript_test_fixtures.dart';
import '../../../support/test_navivox_channel.dart';
import '../../shared/fixtures/profile_contact_channel_fixtures.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';

const _target = NavivoxProfileContact(
  serverId: 'office team',
  profileId: 'support desk',
  displayName: 'Support Desk',
  serverLabel: 'office',
  health: NavivoxProfileHealth.online,
  latestPreview: 'Watching tickets',
);

void main() {
  const intent = ForwardMessageIntent();

  test('forwards text messages to the target Profile contact', () {
    final channel = _seedChannel();

    final result = intent.forward(
      channel,
      message: transcriptTextMessage(
        text: 'send this to support',
        createdAt: DateTime.utc(2026, 5, 23, 10),
      ),
      target: _target,
    );

    expect(result.forwarded, isTrue);
    expect(result.text, 'send this to support');
    expect(result.routeLocation, '/chats/office%20team/support%20desk');
    expect(result.snackbarMessage, 'Forwarded to Support Desk');
    expect(channel.selectedProfileScope, (
      serverId: 'office team',
      profileId: 'support desk',
    ));
    expect(channel.sentTextCalls.last, (
      text: 'send this to support',
      serverId: 'office team',
      profileId: 'support desk',
    ));
  });

  test('forwards voice transcripts', () {
    final channel = _seedChannel();

    final result = intent.forward(
      channel,
      message: transcriptVoiceMessage(
        transcript: 'voice update',
        duration: const Duration(milliseconds: 500),
        confidence: 0.92,
        createdAt: DateTime.utc(2026, 5, 23, 10),
      ),
      target: _target,
    );

    expect(result.forwarded, isTrue);
    expect(result.text, 'voice update');
    expect(channel.sentTexts, ['voice update']);
  });

  test('forwards tool cards as name, status, and summary lines', () {
    final channel = _seedChannel();

    final result = intent.forward(
      channel,
      message: transcriptToolMessage(
        toolCall: const NavivoxToolCall(
          name: 'grep',
          status: 'completed',
          summary: 'Found 3 TODOs',
        ),
        createdAt: DateTime.utc(2026, 5, 23, 10),
      ),
      target: _target,
    );

    expect(result.forwarded, isTrue);
    expect(result.text, 'grep\ncompleted\nFound 3 TODOs');
    expect(channel.sentTexts, ['grep\ncompleted\nFound 3 TODOs']);
  });

  test('forwards safety and approval notices as message and risk lines', () {
    final channel = _seedChannel();

    final safety = intent.forward(
      channel,
      message: transcriptNoticeMessage(
        kind: NavivoxMessageKind.safetyWarning,
        notice: const NavivoxSafetyNotice(
          id: 'safe-1',
          message: 'Needs confirmation',
          risk: 'Writes config',
        ),
        createdAt: DateTime.utc(2026, 5, 23, 10),
      ),
      target: _target,
    );
    final approval = intent.forward(
      channel,
      message: transcriptNoticeMessage(
        kind: NavivoxMessageKind.approvalRequest,
        notice: const NavivoxSafetyNotice(
          id: 'approval-1',
          message: 'Approve tool call?',
          risk: 'Runs shell command',
        ),
        createdAt: DateTime.utc(2026, 5, 23, 10),
      ),
      target: _target,
    );

    expect(safety.text, 'Needs confirmation\nWrites config');
    expect(approval.text, 'Approve tool call?\nRuns shell command');
    expect(channel.sentTexts, [
      'Needs confirmation\nWrites config',
      'Approve tool call?\nRuns shell command',
    ]);
  });

  test('does not forward empty extracted text', () {
    final channel = _seedChannel();

    final result = intent.forward(
      channel,
      message: transcriptTextMessage(
        text: '',
        createdAt: DateTime.utc(2026, 5, 23, 10),
      ),
      target: _target,
    );

    expect(result.forwarded, isFalse);
    expect(result.text, isEmpty);
    expect(result.routeLocation, isNull);
    expect(result.snackbarMessage, isNull);
    expect(channel.selectedProfileScope, isNull);
    expect(channel.sentTexts, isEmpty);
  });
}

TestNavivoxChannel _seedChannel() {
  return profileContactChannel(
    servers: const [
      NavivoxServer(id: 'local', name: 'local', status: 'connected'),
      NavivoxServer(id: 'office team', name: 'office', status: 'connected'),
    ],
    contacts: [
      mineruBuilderProfile(displayName: 'Mineru', latestPreview: 'Ready'),
      _target,
    ],
  );
}
