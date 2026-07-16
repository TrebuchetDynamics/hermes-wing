// Table-driven coverage for VoiceCommandAffinity.trusts: one hit and one
// miss per command (18 cases). Hits are drawn from the spike bank's correct
// transcripts (see spike_bank_regression_test.dart). Misses include the
// three recorded wrong-tool transcripts replayed against the tool Needle
// wrongly proposed for them, plus synthetic misses for the remaining
// commands — none of which contain an anchor for the command under test.

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice_commands/models/voice_command.dart';
import 'package:wing/features/voice_commands/services/voice_command_affinity.dart';

typedef _Case = ({
  String description,
  String transcript,
  VoiceCommandId command,
  bool expected,
});

final List<_Case> _cases = [
  // Hits — one per command, drawn from spike-bank correct transcripts.
  (
    description: 'navigateToScreen hit: open the settings screen',
    transcript: 'open the settings screen',
    command: VoiceCommandId.navigateToScreen,
    expected: true,
  ),
  (
    description: 'showStatus hit: is the agent connected',
    transcript: 'is the agent connected',
    command: VoiceCommandId.showStatus,
    expected: true,
  ),
  (
    description: 'stopVoiceRun hit: cancel the recording',
    transcript: 'cancel the recording',
    command: VoiceCommandId.stopVoiceRun,
    expected: true,
  ),
  (
    description: 'startVoiceRun hit: start listening',
    transcript: 'start listening',
    command: VoiceCommandId.startVoiceRun,
    expected: true,
  ),
  (
    description: 'toggleContinuousMode hit: turn on continuous mode',
    transcript: 'turn on continuous mode',
    command: VoiceCommandId.toggleContinuousMode,
    expected: true,
  ),
  (
    description: 'newSession hit: give me a fresh session',
    transcript: 'give me a fresh session',
    command: VoiceCommandId.newSession,
    expected: true,
  ),
  (
    description: 'switchSession hit: switch to my groceries session',
    transcript: 'switch to my groceries session',
    command: VoiceCommandId.switchSession,
    expected: true,
  ),
  (
    description: 'setTtsVoice hit: change the voice to nova',
    transcript: 'change the voice to nova',
    command: VoiceCommandId.setTtsVoice,
    expected: true,
  ),
  (
    description: 'setSpeechRate hit: slow the reading speed down to half',
    transcript: 'slow the reading speed down to half',
    command: VoiceCommandId.setSpeechRate,
    expected: true,
  ),

  // Misses — recorded wrong-tool transcripts replayed against the wrongly
  // proposed tool.
  (
    description:
        'switchSession miss (recorded wrong tool): take me back to the chat',
    transcript: 'take me back to the chat',
    command: VoiceCommandId.switchSession,
    expected: false,
  ),
  (
    description:
        'toggleContinuousMode miss (recorded wrong tool): '
        'start a new conversation',
    transcript: 'start a new conversation',
    command: VoiceCommandId.toggleContinuousMode,
    expected: false,
  ),
  (
    description: 'setTtsVoice miss (recorded wrong tool): speak faster please',
    transcript: 'speak faster please',
    command: VoiceCommandId.setTtsVoice,
    expected: false,
  ),

  // Synthetic misses for the remaining commands.
  (
    description: 'navigateToScreen miss: is the agent connected',
    transcript: 'is the agent connected',
    command: VoiceCommandId.navigateToScreen,
    expected: false,
  ),
  (
    description: 'showStatus miss: cancel the recording',
    transcript: 'cancel the recording',
    command: VoiceCommandId.showStatus,
    expected: false,
  ),
  (
    description: 'stopVoiceRun miss: give me a fresh session',
    transcript: 'give me a fresh session',
    command: VoiceCommandId.stopVoiceRun,
    expected: false,
  ),
  (
    description: 'startVoiceRun miss: switch to my groceries session',
    transcript: 'switch to my groceries session',
    command: VoiceCommandId.startVoiceRun,
    expected: false,
  ),
  (
    description: 'newSession miss: change the voice to nova',
    transcript: 'change the voice to nova',
    command: VoiceCommandId.newSession,
    expected: false,
  ),
  (
    description: 'setSpeechRate miss: turn on continuous mode',
    transcript: 'turn on continuous mode',
    command: VoiceCommandId.setSpeechRate,
    expected: false,
  ),

  // Token-boundary regressions: multiword anchors must match contiguous
  // TOKEN sequences, never raw substrings across word boundaries; and
  // punctuation must not defeat single-word anchors.
  (
    description:
        'navigateToScreen miss: "lets go together" must not '
        'substring-match the "go to" anchor',
    transcript: 'lets go together',
    command: VoiceCommandId.navigateToScreen,
    expected: false,
  ),
  (
    description:
        'navigateToScreen miss: "take measurements" must not '
        'substring-match the "take me" anchor',
    transcript: 'please take measurements of the room',
    command: VoiceCommandId.navigateToScreen,
    expected: false,
  ),
  (
    description: 'navigateToScreen hit: go to settings',
    transcript: 'go to settings',
    command: VoiceCommandId.navigateToScreen,
    expected: true,
  ),
  (
    description:
        'stopVoiceRun hit: trailing punctuation must not break the '
        '"stop" anchor',
    transcript: 'please stop.',
    command: VoiceCommandId.stopVoiceRun,
    expected: true,
  ),
  (
    description: 'toggleContinuousMode hit: turn on hands-free mode',
    transcript: 'turn on hands-free mode',
    command: VoiceCommandId.toggleContinuousMode,
    expected: true,
  ),
];

void main() {
  for (final c in _cases) {
    test(c.description, () {
      expect(
        VoiceCommandAffinity.trusts(c.transcript, c.command),
        c.expected,
        reason: c.description,
      );
    });
  }
}
