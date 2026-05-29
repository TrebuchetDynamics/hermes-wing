/// Result emitted by [SpeechRecognizer.stop].
class SpeechResult {
  const SpeechResult({required this.transcript, required this.confidence});
  final String transcript;
  final double confidence;
}

/// Thin abstraction over a streaming speech-to-text engine. The default
/// production implementation wraps the `speech_to_text` plugin; tests use a
/// fake.
abstract interface class SpeechRecognizer {
  /// Begin recognising speech from the active input device.
  Future<void> start();

  /// Stop recognition and return the final transcript + confidence.
  Future<SpeechResult> stop();

  /// Stop recognition and discard partial state.
  Future<void> cancel();

  /// Interim (in-progress) transcripts the engine emits before the final.
  Stream<String> get interimTranscripts;

  /// Resolves when the engine signals a final transcript on its own (e.g. a
  /// silence timeout). Callers can race [onFinal] against an external stop
  /// signal to drive auto-stopping.
  Future<void> get onFinal;
}
