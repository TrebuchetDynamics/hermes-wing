import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/presentation/transcript/transcript_voice_message_presentation.dart';

void main() {
  test('derives Voice run bubble display state with transcript', () {
    final presentation = TranscriptVoiceMessagePresentation.fromVoice(
      const NavivoxVoiceMessage(
        transcript: 'hello voice',
        duration: Duration(milliseconds: 1200),
        confidence: 0.91,
      ),
    );

    expect(presentation.title, 'Voice message');
    expect(presentation.durationLabel, '1s');
    expect(presentation.transcript, 'hello voice');
    expect(presentation.showTranscript, isTrue);
    expect(presentation.morphIntensity, 0.91);
  });

  test('omits transcript row when Voice run transcript is empty', () {
    final presentation = TranscriptVoiceMessagePresentation.fromVoice(
      const NavivoxVoiceMessage(
        transcript: '',
        duration: Duration(milliseconds: 500),
        confidence: 0.42,
      ),
    );

    expect(presentation.title, 'Voice message');
    expect(presentation.durationLabel, '0s');
    expect(presentation.transcript, '');
    expect(presentation.showTranscript, isFalse);
    expect(presentation.morphIntensity, 0.42);
  });
}
