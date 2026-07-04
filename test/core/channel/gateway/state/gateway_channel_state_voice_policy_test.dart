import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway/state/gateway_channel_state_policy.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';

NavivoxVoiceRun _recording(String id) => NavivoxVoiceRun.recording(
  id: id,
  serverId: 'local',
  profileId: 'mineru',
  createdAt: DateTime.utc(2026, 6, 16, 12),
);

void main() {
  test('non-terminal run upsert tracks the active run id', () {
    const initial = NavivoxChannelState();

    final state = navivoxStateWithGatewayVoiceRun(
      state: initial,
      run: _recording('voice-1'),
      active: true,
    );

    expect(state.activeVoiceRunId, 'voice-1');
  });

  test('submitted run upsert keeps the run active (still in flight)', () {
    final state = navivoxStateWithGatewayVoiceRun(
      state: const NavivoxChannelState(),
      run: _recording('voice-1').markSubmitted(requestId: 'req-1'),
      active: true,
    );

    expect(state.activeVoiceRunId, 'voice-1');
  });

  test('terminal run upsert clears the active run id', () {
    final active = navivoxStateWithGatewayVoiceRun(
      state: const NavivoxChannelState(),
      run: _recording('voice-1'),
      active: true,
    );

    final cancelled = navivoxStateWithGatewayVoiceRun(
      state: active,
      run: active.voiceRuns['voice-1']!.markCancelled('user cancelled'),
      active: true,
    );

    expect(
      cancelled.activeVoiceRunId,
      isNull,
      reason: 'a terminal run is not the in-flight active run',
    );
    expect(
      cancelled.voiceRuns['voice-1']?.status,
      NavivoxVoiceRunStatus.cancelled,
    );
  });

  test('terminal upsert for a non-active run leaves active id intact', () {
    final twoActive = navivoxStateWithGatewayVoiceRun(
      state: navivoxStateWithGatewayVoiceRun(
        state: const NavivoxChannelState(),
        run: _recording('voice-1'),
        active: true,
      ),
      run: _recording('voice-2'),
      active: true,
    );
    expect(twoActive.activeVoiceRunId, 'voice-2');

    // Fail the older, non-active run.
    final state = navivoxStateWithGatewayVoiceRun(
      state: twoActive,
      run: twoActive.voiceRuns['voice-1']!.markFailed('stale'),
      active: false,
    );

    expect(state.activeVoiceRunId, 'voice-2');
  });
}
