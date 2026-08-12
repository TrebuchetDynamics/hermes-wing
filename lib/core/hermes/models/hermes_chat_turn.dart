import 'hermes_run.dart';
import 'hermes_tool_call.dart';

export 'hermes_tool_call.dart';

enum HermesTurnAuthor { user, assistant, system }

enum HermesTurnStatus { streaming, completed, failed }

enum HermesTurnKind { text, toolCall, reasoning }

enum HermesAttachmentKind { file, image }

class HermesTurnAttachment {
  const HermesTurnAttachment({required this.name, required this.kind});

  final String name;
  final HermesAttachmentKind kind;
}

const hermesAttachmentEncodedNameLimit = 512;

String canonicalHermesAttachmentName(
  String? value, {
  required String fallback,
}) {
  final normalized = (value ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  final source = normalized.isEmpty ? fallback : normalized;
  final result = StringBuffer();
  var encodedLength = 0;
  for (final rune in source.runes) {
    final character = String.fromCharCode(rune);
    final length = escapeHermesAttachmentName(character).length;
    if (encodedLength + length > hermesAttachmentEncodedNameLimit) break;
    result.write(character);
    encodedLength += length;
  }
  final canonical = result.toString().trim();
  return canonical.isEmpty ? fallback : canonical;
}

String escapeHermesAttachmentName(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// One turn in a Hermes session transcript. Assistant turns start
/// `streaming` and accumulate `text` via [appendDelta] as SSE deltas arrive.
/// `toolCall`-kind turns carry a [HermesToolCall] instead of prose `text`.
class HermesChatTurn {
  const HermesChatTurn({
    required this.id,
    required this.sessionId,
    required this.author,
    required this.createdAt,
    this.status = HermesTurnStatus.completed,
    this.kind = HermesTurnKind.text,
    this.text = '',
    this.attachment,
    this.toolCall,
    this.usage,
  });

  final String id;
  final String sessionId;
  final HermesTurnAuthor author;
  final HermesTurnStatus status;
  final HermesTurnKind kind;
  final String text;
  final HermesTurnAttachment? attachment;
  final HermesToolCall? toolCall;
  final HermesRunUsage? usage;
  final DateTime createdAt;

  HermesChatTurn appendDelta(String delta) => copyWith(text: text + delta);

  HermesChatTurn copyWith({
    HermesTurnStatus? status,
    String? text,
    HermesTurnAttachment? attachment,
    HermesToolCall? toolCall,
    HermesRunUsage? usage,
  }) {
    return HermesChatTurn(
      id: id,
      sessionId: sessionId,
      author: author,
      createdAt: createdAt,
      status: status ?? this.status,
      kind: kind,
      text: text ?? this.text,
      attachment: attachment ?? this.attachment,
      toolCall: toolCall ?? this.toolCall,
      usage: usage ?? this.usage,
    );
  }
}
