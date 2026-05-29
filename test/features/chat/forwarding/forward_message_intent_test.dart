import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/forwarding/forward_message_intent.dart';

import '../../../support/test_navivox_channel.dart';

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
      message: _textMessage('send this to support'),
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
      message: _voiceMessage('voice update'),
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
      message: _toolMessage(
        const NavivoxToolCall(
          name: 'grep',
          status: 'completed',
          summary: 'Found 3 TODOs',
        ),
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
      message: _safetyMessage(
        kind: NavivoxMessageKind.safetyWarning,
        notice: const NavivoxSafetyNotice(
          id: 'safe-1',
          message: 'Needs confirmation',
          risk: 'Writes config',
        ),
      ),
      target: _target,
    );
    final approval = intent.forward(
      channel,
      message: _safetyMessage(
        kind: NavivoxMessageKind.approvalRequest,
        notice: const NavivoxSafetyNotice(
          id: 'approval-1',
          message: 'Approve tool call?',
          risk: 'Runs shell command',
        ),
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
      message: _textMessage(''),
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
  return TestNavivoxChannel()
    ..seedServers(const [
      NavivoxServer(id: 'local', name: 'local', status: 'connected'),
      NavivoxServer(id: 'office team', name: 'office', status: 'connected'),
    ], activeServerId: 'local')
    ..seedProfileContacts(const [
      NavivoxProfileContact(
        serverId: 'local',
        profileId: 'mineru',
        displayName: 'Mineru',
        serverLabel: 'local',
        health: NavivoxProfileHealth.online,
        latestPreview: 'Ready',
      ),
      _target,
    ], selectedKey: 'local::mineru');
}

NavivoxChatMessage _textMessage(String text) {
  return NavivoxChatMessage(
    id: 'text-1',
    author: NavivoxMessageAuthor.assistant,
    kind: NavivoxMessageKind.text,
    createdAt: DateTime.utc(2026, 5, 23, 10),
    text: text,
  );
}

NavivoxChatMessage _voiceMessage(String transcript) {
  return NavivoxChatMessage(
    id: 'voice-1',
    author: NavivoxMessageAuthor.user,
    kind: NavivoxMessageKind.voice,
    createdAt: DateTime.utc(2026, 5, 23, 10),
    voice: NavivoxVoiceMessage(
      duration: const Duration(milliseconds: 500),
      transcript: transcript,
      confidence: 0.92,
    ),
  );
}

NavivoxChatMessage _toolMessage(NavivoxToolCall toolCall) {
  return NavivoxChatMessage(
    id: 'tool-1',
    author: NavivoxMessageAuthor.system,
    kind: NavivoxMessageKind.toolCall,
    createdAt: DateTime.utc(2026, 5, 23, 10),
    toolCall: toolCall,
  );
}

NavivoxChatMessage _safetyMessage({
  required NavivoxMessageKind kind,
  required NavivoxSafetyNotice notice,
}) {
  return NavivoxChatMessage(
    id: 'safety-1',
    author: NavivoxMessageAuthor.system,
    kind: kind,
    createdAt: DateTime.utc(2026, 5, 23, 10),
    safetyNotice: notice,
  );
}
