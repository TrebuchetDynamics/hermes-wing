import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';

import '../../support/test_navivox_channel.dart';

void main() {
  test('channel state exposes voice runs in insertion order', () {
    final first = NavivoxVoiceRun.recording(
      id: 'voice-1',
      serverId: 'local',
      profileId: 'mineru',
      createdAt: DateTime.utc(2026, 5, 21, 12),
    );
    final second = NavivoxVoiceRun.recording(
      id: 'voice-2',
      serverId: 'local',
      profileId: 'support',
      createdAt: DateTime.utc(2026, 5, 21, 12, 1),
    );

    final state = NavivoxChannelState(
      voiceRuns: {first.id: first, second.id: second},
    );

    expect(state.voiceRunsList.map((run) => run.id), ['voice-1', 'voice-2']);
    expect(state.activeVoiceRun?.id, 'voice-2');
  });

  test('test channel can create stage cancel fail and submit voice runs', () {
    final channel = TestNavivoxChannel()
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
          micAvailable: true,
        ),
      ], selectedKey: 'local::mineru');

    final id = channel.startVoiceRun();
    expect(
      channel.state.activeVoiceRun?.status,
      NavivoxVoiceRunStatus.recording,
    );

    channel.stageVoiceRunTranscript(
      voiceRunId: id,
      transcript: 'check status',
      duration: const Duration(milliseconds: 900),
      confidence: 0.9,
    );
    expect(
      channel.state.voiceRuns[id]?.status,
      NavivoxVoiceRunStatus.pendingSend,
    );

    channel.submitVoiceRun(id);
    expect(channel.sentVoiceTranscripts, ['check status']);
    expect(
      channel.state.voiceRuns[id]?.status,
      NavivoxVoiceRunStatus.submitted,
    );
  });
}
