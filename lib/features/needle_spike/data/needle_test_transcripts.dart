/// Canned evaluation bank: 20 realistic voice-command transcripts, two per
/// catalog tool. `expectedTool` is what a correct parse must call.
class NeedleTestTranscript {
  const NeedleTestTranscript({required this.text, required this.expectedTool});

  final String text;
  final String expectedTool;
}

const List<NeedleTestTranscript> needleTestTranscripts = [
  NeedleTestTranscript(
    text: 'open the settings screen',
    expectedTool: 'navigate_to_screen',
  ),
  NeedleTestTranscript(
    text: 'take me back to the chat',
    expectedTool: 'navigate_to_screen',
  ),
  NeedleTestTranscript(
    text: 'start listening',
    expectedTool: 'start_voice_run',
  ),
  NeedleTestTranscript(
    text: 'begin a voice command',
    expectedTool: 'start_voice_run',
  ),
  NeedleTestTranscript(
    text: 'stop listening now',
    expectedTool: 'stop_voice_run',
  ),
  NeedleTestTranscript(
    text: 'cancel the recording',
    expectedTool: 'stop_voice_run',
  ),
  NeedleTestTranscript(
    text: 'turn on continuous mode',
    expectedTool: 'toggle_continuous_mode',
  ),
  NeedleTestTranscript(
    text: 'disable hands free mode please',
    expectedTool: 'toggle_continuous_mode',
  ),
  NeedleTestTranscript(
    text: 'tell the agent I will be ten minutes late',
    expectedTool: 'send_message',
  ),
  NeedleTestTranscript(
    text: 'send a message saying good morning',
    expectedTool: 'send_message',
  ),
  NeedleTestTranscript(
    text: 'start a new conversation',
    expectedTool: 'new_session',
  ),
  NeedleTestTranscript(
    text: 'give me a fresh session',
    expectedTool: 'new_session',
  ),
  NeedleTestTranscript(
    text: 'switch to my groceries session',
    expectedTool: 'switch_session',
  ),
  NeedleTestTranscript(
    text: 'go to the session called work notes',
    expectedTool: 'switch_session',
  ),
  NeedleTestTranscript(
    text: 'change the voice to nova',
    expectedTool: 'set_tts_voice',
  ),
  NeedleTestTranscript(
    text: 'use the british voice for speech',
    expectedTool: 'set_tts_voice',
  ),
  NeedleTestTranscript(
    text: 'speak faster please',
    expectedTool: 'set_speech_rate',
  ),
  NeedleTestTranscript(
    text: 'slow the reading speed down to half',
    expectedTool: 'set_speech_rate',
  ),
  NeedleTestTranscript(
    text: 'is the agent connected',
    expectedTool: 'show_status',
  ),
  NeedleTestTranscript(
    text: 'show me the connection status',
    expectedTool: 'show_status',
  ),
];
