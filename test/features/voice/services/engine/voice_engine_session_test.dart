import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/engine/voice_engine_session.dart';

void main() {
  test('only events owned by the active generation are delivered', () {
    final session = VoiceEngineSession();
    final delivered = <VoiceEngineEvent>[];
    final subscription = session.events.listen(delivered.add);
    addTearDown(subscription.cancel);
    addTearDown(session.dispose);

    final first = session.begin();
    expect(first, 1);
    expect(
      session.deliver(
        VoiceEngineEvent(
          generation: first,
          kind: VoiceEngineEventKind.partialTranscript,
          text: 'hello',
        ),
      ),
      isTrue,
    );

    final second = session.begin();
    expect(second, 2);
    expect(
      session.deliver(
        VoiceEngineEvent(
          generation: first,
          kind: VoiceEngineEventKind.finalTranscript,
          text: 'stale predecessor',
        ),
      ),
      isFalse,
    );
    expect(
      session.deliver(
        VoiceEngineEvent(
          generation: second,
          kind: VoiceEngineEventKind.finalTranscript,
          text: 'hola Hermes',
        ),
      ),
      isTrue,
    );

    expect(delivered.map((event) => event.text), ['hello', 'hola Hermes']);
  });

  test('cancel invalidates ownership before native teardown completes', () {
    final session = VoiceEngineSession();
    addTearDown(session.dispose);
    final generation = session.begin();

    session.cancel(generation);

    expect(session.activeGeneration, isNull);
    expect(
      session.deliver(
        VoiceEngineEvent(
          generation: generation,
          kind: VoiceEngineEventKind.status,
          text: 'done',
        ),
      ),
      isFalse,
    );
  });

  test('a stale cancellation cannot cancel its successor', () {
    final session = VoiceEngineSession();
    addTearDown(session.dispose);
    final first = session.begin();
    final second = session.begin();

    session.cancel(first);

    expect(session.activeGeneration, second);
  });
}
