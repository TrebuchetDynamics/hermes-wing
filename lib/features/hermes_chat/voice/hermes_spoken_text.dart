import 'package:markdown/markdown.dart' as md;

import '../../../shared/security/wing_redaction.dart';

/// Converts rendered assistant Markdown into text suitable for speech output.
String hermesSpokenText(String markdown) {
  final safeMarkdown = wingRedactSensitiveText(markdown);
  final nodes = md.Document(
    extensionSet: md.ExtensionSet.gitHubWeb,
  ).parseLines(safeMarkdown.split('\n'));
  final text = nodes
      .map(_spokenNodeText)
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join('\n\n');
  return text
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// Splits cleaned speech at natural boundaries so buffered Agent TTS can
/// start each clause without waiting for the whole reply.
List<String> hermesSpokenTextChunks(String text, {int minimumLength = 20}) {
  final spoken = hermesSpokenText(text);
  if (spoken.isEmpty) return const [];
  final chunks = <String>[];
  var start = 0;
  for (final match in RegExp(r'[.!?](?=\s|$)|\n\n').allMatches(spoken)) {
    final end = match.end;
    final candidate = spoken.substring(start, end).trim();
    if (candidate.length < minimumLength) continue;
    chunks.add(candidate);
    start = end;
  }
  final tail = spoken.substring(start).trim();
  if (tail.isNotEmpty) {
    if (chunks.isNotEmpty && tail.length < minimumLength) {
      chunks[chunks.length - 1] = '${chunks.last} $tail';
    } else {
      chunks.add(tail);
    }
  }
  return List.unmodifiable(chunks);
}

String _spokenNodeText(md.Node node) {
  if (node is md.Text) return node.text;
  if (node is! md.Element) return '';
  if (node.tag == 'img') return node.attributes['alt'] ?? '';
  if (node.tag == 'br') return '\n';
  final children = node.children ?? const <md.Node>[];
  if (node.tag == 'ul' || node.tag == 'ol' || node.tag == 'table') {
    return children
        .map(_spokenNodeText)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join('\n');
  }
  if (node.tag == 'tr') {
    return children
        .map(_spokenNodeText)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
  }
  return children.map(_spokenNodeText).join();
}
