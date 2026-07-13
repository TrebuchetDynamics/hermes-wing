import 'dart:convert';

import 'needle_engine.dart';
import 'needle_result.dart';
import 'needle_tool_catalog.dart';

/// Turns one transcript into one measured Needle inference.
class NeedleSpikeService {
  // Private field behind a public named parameter; an initializing formal
  // would force the parameter to be named `_engine`.
  // ignore: prefer_initializing_formals
  NeedleSpikeService({required NeedleEngineApi engine}) : _engine = engine;

  final NeedleEngineApi _engine;
  bool _busy = false;

  /// Generation options: deterministic, tool-constrained, and strictly
  /// on-device (`auto_handoff` defaults to true upstream — keep it false).
  static const String optionsJson =
      '{"max_tokens": 128, "temperature": 0, "force_tools": true, '
      '"tool_rag_top_k": 0, "auto_handoff": false}';

  bool get busy => _busy;

  Future<NeedleResult> parseTranscript(String transcript) async {
    if (_busy) {
      throw StateError('Needle is already processing a request.');
    }
    _busy = true;
    final stopwatch = Stopwatch()..start();
    try {
      final raw = await _engine.complete(
        messagesJson: jsonEncode([
          {'role': 'user', 'content': transcript},
        ]),
        toolsJson: NeedleToolCatalog.toolsJson,
        optionsJson: optionsJson,
      );
      return NeedleResult.fromEngineJson(
        raw,
        wallLatencyMs: stopwatch.elapsedMilliseconds,
      );
    } finally {
      _busy = false;
    }
  }
}
