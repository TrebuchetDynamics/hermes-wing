import 'dart:convert';

class NeedleFunctionCall {
  const NeedleFunctionCall({required this.name, required this.arguments});

  final String name;
  final Map<String, dynamic> arguments;
}

/// Parsed `cactus_complete` response plus the Dart-side wall latency.
class NeedleResult {
  const NeedleResult({
    required this.success,
    required this.error,
    required this.response,
    required this.functionCalls,
    required this.confidence,
    required this.totalTimeMs,
    required this.timeToFirstTokenMs,
    required this.wallLatencyMs,
  });

  factory NeedleResult.fromEngineJson(
    String raw, {
    required int wallLatencyMs,
  }) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      decoded = null;
    }
    if (decoded is! Map<String, dynamic>) {
      return NeedleResult(
        success: false,
        error: 'Unparseable engine response (${raw.length} chars)',
        response: '',
        functionCalls: const [],
        confidence: null,
        totalTimeMs: null,
        timeToFirstTokenMs: null,
        wallLatencyMs: wallLatencyMs,
      );
    }
    return NeedleResult(
      success: decoded['success'] == true,
      error: decoded['error'] is String ? decoded['error'] as String : null,
      response: decoded['response'] is String
          ? decoded['response'] as String
          : '',
      functionCalls: _parseFunctionCalls(decoded['function_calls']),
      confidence: decoded['confidence'] is num
          ? (decoded['confidence'] as num).toDouble()
          : null,
      totalTimeMs: decoded['total_time_ms'] is num
          ? (decoded['total_time_ms'] as num).toDouble()
          : null,
      timeToFirstTokenMs: decoded['time_to_first_token_ms'] is num
          ? (decoded['time_to_first_token_ms'] as num).toDouble()
          : null,
      wallLatencyMs: wallLatencyMs,
    );
  }

  final bool success;
  final String? error;
  final String response;
  final List<NeedleFunctionCall> functionCalls;
  final double? confidence;
  final double? totalTimeMs;
  final double? timeToFirstTokenMs;
  final int wallLatencyMs;

  static List<NeedleFunctionCall> _parseFunctionCalls(Object? rawCalls) {
    if (rawCalls is! List) return const [];
    final calls = <NeedleFunctionCall>[];
    for (final entry in rawCalls) {
      if (entry is! Map) continue;
      final function = entry['function'];
      final source = function is Map ? function : entry;
      final name = source['name'];
      if (name is! String || name.isEmpty) continue;
      calls.add(
        NeedleFunctionCall(
          name: name,
          arguments: _parseArguments(source['arguments']),
        ),
      );
    }
    return calls;
  }

  static Map<String, dynamic> _parseArguments(Object? rawArguments) {
    if (rawArguments is Map) {
      return rawArguments.map((k, v) => MapEntry(k.toString(), v));
    }
    if (rawArguments is String && rawArguments.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawArguments);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } on FormatException {
        // Fall through to empty.
      }
    }
    return const {};
  }
}
