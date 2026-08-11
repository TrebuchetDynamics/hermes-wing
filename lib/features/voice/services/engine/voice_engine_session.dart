import 'dart:async';

enum VoiceEngineEventKind {
  status,
  vad,
  soundLevel,
  partialTranscript,
  finalTranscript,
  error,
}

class VoiceEngineEvent {
  const VoiceEngineEvent({
    required this.generation,
    required this.kind,
    this.text,
    this.value,
  });

  final int generation;
  final VoiceEngineEventKind kind;
  final String? text;
  final double? value;
}

/// Owns the app-side boundary for one native voice generation at a time.
///
/// Cancellation invalidates delivery synchronously, before asynchronous native
/// teardown begins. Native callbacks must carry the immutable generation that
/// was assigned by [begin].
class VoiceEngineSession {
  final _events = StreamController<VoiceEngineEvent>.broadcast(sync: true);
  int _nextGeneration = 0;
  int? _activeGeneration;
  bool _disposed = false;

  Stream<VoiceEngineEvent> get events => _events.stream;
  int? get activeGeneration => _activeGeneration;

  int begin() {
    if (_disposed) throw StateError('voice engine session is disposed');
    final generation = ++_nextGeneration;
    _activeGeneration = generation;
    return generation;
  }

  bool deliver(VoiceEngineEvent event) {
    if (_disposed || event.generation != _activeGeneration) return false;
    _events.add(event);
    return true;
  }

  void cancel(int generation) {
    if (_activeGeneration == generation) _activeGeneration = null;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _activeGeneration = null;
    await _events.close();
  }
}
