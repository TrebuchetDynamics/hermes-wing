import 'dart:convert';

import '../../protocol/navivox_json.dart';

class HermesSseEvent {
  const HermesSseEvent({this.id, required this.event, required this.data});

  final String? id;
  final String event;
  final String data;

  bool get isDone => event == 'done' || data.trim() == '[DONE]';
}

class HermesStreamEvent {
  const HermesStreamEvent({required this.name, required this.payload});

  factory HermesStreamEvent.done() {
    return const HermesStreamEvent(name: 'done', payload: {});
  }

  factory HermesStreamEvent.fromSse(HermesSseEvent event) {
    if (event.isDone) return HermesStreamEvent.done();
    try {
      final decoded = jsonDecode(event.data);
      if (decoded is! Map) {
        throw const FormatException('Hermes SSE data must be a JSON object');
      }
      final payload = navivoxMapFromJson(decoded);
      final embeddedName = event.event == 'message'
          ? _embeddedEventName(payload)
          : null;
      return HermesStreamEvent(
        name: embeddedName ?? event.event,
        payload: payload,
      );
    } on FormatException {
      if (_isErrorEvent(event.event) && event.data.trim().isNotEmpty) {
        return HermesStreamEvent(
          name: event.event,
          payload: {'message': event.data.trim()},
        );
      }
      rethrow;
    }
  }

  final String name;
  final Map<String, Object?> payload;

  bool get isDone => name == 'done';
  String? get runId => navivoxOptionalStringFromJson(payload['run_id']);
  String? get sessionId => navivoxOptionalStringFromJson(payload['session_id']);
  String? get messageId => navivoxOptionalStringFromJson(payload['message_id']);
  String? get delta => navivoxOptionalStringFromJson(payload['delta']);
}

String? _embeddedEventName(Map<String, Object?> payload) {
  for (final key in const ['event', 'type', 'name']) {
    final value = navivoxOptionalStringFromJson(payload[key])?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

bool _isErrorEvent(String name) =>
    name == 'error' ||
    name == 'stream.error' ||
    name == 'run.error' ||
    name == 'assistant.error' ||
    name == 'message.error';

/// Pure Dart server-sent event decoder for Hermes HTTP streams.
class HermesSseEventDecoder {
  const HermesSseEventDecoder();

  List<HermesSseEvent> decode(Iterable<String> chunks) {
    final events = <HermesSseEvent>[];
    final buffer = StringBuffer();
    for (final chunk in chunks) {
      buffer.write(chunk);
      _drainEvents(buffer, events);
    }
    return events;
  }

  List<HermesStreamEvent> decodeJsonEvents(Iterable<String> chunks) {
    final events = <HermesStreamEvent>[];
    for (final event in decode(chunks)) {
      try {
        events.add(HermesStreamEvent.fromSse(event));
      } on FormatException {
        continue;
      }
    }
    return events;
  }

  /// Same framing as [decode], but consumes chunks as they arrive on a live
  /// [Stream] instead of requiring the full transcript up front.
  Stream<HermesSseEvent> decodeStream(Stream<String> chunks) async* {
    final buffer = StringBuffer();
    await for (final chunk in chunks) {
      buffer.write(chunk);
      final events = <HermesSseEvent>[];
      _drainEvents(buffer, events);
      for (final event in events) {
        yield event;
      }
    }
    final remaining = buffer.toString();
    if (remaining.isEmpty) return;
    final event = _parseFrame(remaining);
    if (event != null) yield event;
  }

  /// Same as [decodeJsonEvents], but over a live [Stream] via [decodeStream].
  Stream<HermesStreamEvent> decodeJsonEventStream(
    Stream<String> chunks,
  ) async* {
    await for (final event in decodeStream(chunks)) {
      try {
        yield HermesStreamEvent.fromSse(event);
      } on FormatException {
        continue;
      }
    }
  }

  void _drainEvents(StringBuffer buffer, List<HermesSseEvent> events) {
    var text = buffer.toString();
    var separator = _eventSeparatorIndex(text);
    if (separator.index == -1) return;

    buffer.clear();
    while (separator.index != -1) {
      final frame = text.substring(0, separator.index);
      final event = _parseFrame(frame);
      if (event != null) events.add(event);
      text = text.substring(separator.index + separator.length);
      separator = _eventSeparatorIndex(text);
    }
    buffer.write(text);
  }

  _SseSeparator _eventSeparatorIndex(String text) {
    final crlf = text.indexOf('\r\n\r\n');
    final lf = text.indexOf('\n\n');
    final cr = text.indexOf('\r\r');
    final candidates = <_SseSeparator>[
      if (crlf != -1) _SseSeparator(crlf, 4),
      if (lf != -1) _SseSeparator(lf, 2),
      if (cr != -1) _SseSeparator(cr, 2),
    ];
    if (candidates.isEmpty) return const _SseSeparator(-1, 0);
    candidates.sort((a, b) => a.index.compareTo(b.index));
    return candidates.first;
  }

  HermesSseEvent? _parseFrame(String frame) {
    String? id;
    var event = 'message';
    final dataLines = <String>[];

    final normalizedFrame = frame
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    for (final line in normalizedFrame.split('\n')) {
      if (line.isEmpty || line.startsWith(':')) continue;
      final colon = line.indexOf(':');
      final field = colon == -1 ? line : line.substring(0, colon);
      var value = colon == -1 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      if (field == 'id') {
        id = value;
      } else if (field == 'event') {
        event = value.isEmpty ? 'message' : value;
      } else if (field == 'data') {
        dataLines.add(value);
      }
    }

    if (dataLines.isEmpty) {
      if (event == 'done') {
        return HermesSseEvent(id: id, event: 'done', data: '');
      }
      return null;
    }
    final data = dataLines.join('\n');
    return HermesSseEvent(
      id: id,
      event: data.trim() == '[DONE]' ? 'done' : event,
      data: data,
    );
  }
}

class _SseSeparator {
  const _SseSeparator(this.index, this.length);

  final int index;
  final int length;
}
