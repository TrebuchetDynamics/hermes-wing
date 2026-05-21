import 'dart:typed_data';

/// Thin abstraction over a platform audio recorder. The default production
/// implementation wraps the `record` plugin; tests use a fake.
abstract interface class AudioRecorder {
  /// Begin capturing audio from the active input device.
  Future<void> start();

  /// Stop the recording and return the captured PCM bytes.
  Future<Uint8List> stop();

  /// Stop the recording and discard whatever was captured.
  Future<void> cancel();
}
