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
