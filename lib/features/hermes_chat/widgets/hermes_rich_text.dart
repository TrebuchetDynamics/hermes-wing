import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';

typedef HermesUriLauncher = Future<bool> Function(Uri uri);

/// Selectable GitHub-flavored Markdown used for Hermes-authored transcript text.
class HermesRichText extends StatelessWidget {
  const HermesRichText(
    this.data, {
    this.launchUri,
    this.selectable = true,
    super.key,
  });

  final String data;
  final HermesUriLauncher? launchUri;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final markdownStyle = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(height: 1.38),
      listBullet: theme.textTheme.bodyMedium?.copyWith(height: 1.38),
      h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      code: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Roboto Mono'],
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.34),
        border: Border(
          left: BorderSide(color: theme.colorScheme.secondary, width: 3),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      blockSpacing: 12,
      listIndent: 22,
    );
    final content = MarkdownBody(
      data: data,
      styleSheet: markdownStyle,
      shrinkWrap: true,
      builders: {'pre': _HermesCodeBlockBuilder()},
      imageBuilder: (uri, title, alt) => Text(
        '${(alt == null || alt.trim().isEmpty) ? strings.transcriptImageFallbackLabel : alt.trim()} '
        '(${strings.transcriptImageNotLoaded})',
      ),
      onTapLink: (text, href, title) {
        final uri = href == null ? null : Uri.tryParse(href);
        if (uri == null ||
            !_safeLinkSchemes.contains(uri.scheme.toLowerCase())) {
          return;
        }
        unawaited((launchUri ?? _launchUri)(uri));
      },
    );
    return selectable ? SelectionArea(child: content) : content;
  }
}

const _safeLinkSchemes = {'http', 'https', 'mailto'};

Future<bool> _launchUri(Uri uri) => launchUrl(uri);

class _HermesCodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent.replaceFirst(RegExp(r'\n$'), '');
    final firstChild = element.children?.isEmpty == false
        ? element.children!.first
        : null;
    final codeClass = firstChild is md.Element
        ? firstChild.attributes['class']
        : null;
    final language = codeClass?.startsWith('language-') == true
        ? codeClass!.substring('language-'.length)
        : '';
    final colors = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context);
    final isLong = code.split('\n').length > 15 || code.length > 800;
    final codeContent = SingleChildScrollView(
      key: const ValueKey('hermes-code-content'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: language == 'diff'
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, line) in code.split('\n').indexed)
                  SelectableText(
                    line.isEmpty ? '\u00a0' : line,
                    key: ValueKey('hermes-diff-line-$index'),
                    style: _diffLineStyle(preferredStyle, line, colors),
                  ),
              ],
            )
          : SelectableText(code, style: preferredStyle),
    );
    return DecoratedBox(
      key: const ValueKey('hermes-code-block'),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    language.isEmpty ? 'code' : language,
                    key: const ValueKey('hermes-code-language'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('hermes-code-copy'),
                tooltip: strings.copyCodeAction,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_outlined, size: 18),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!context.mounted) return;
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(content: Text(strings.codeCopiedMessage)),
                  );
                },
              ),
            ],
          ),
          if (isLong)
            _CollapsibleCodeContent(
              showMoreLabel: strings.showMoreAction,
              showLessLabel: strings.showLessAction,
              child: codeContent,
            )
          else
            codeContent,
        ],
      ),
    );
  }
}

class _CollapsibleCodeContent extends StatefulWidget {
  const _CollapsibleCodeContent({
    required this.showMoreLabel,
    required this.showLessLabel,
    required this.child,
  });

  final String showMoreLabel;
  final String showLessLabel;
  final Widget child;

  @override
  State<_CollapsibleCodeContent> createState() =>
      _CollapsibleCodeContentState();
}

class _CollapsibleCodeContentState extends State<_CollapsibleCodeContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_expanded) widget.child,
      Align(
        alignment: Alignment.center,
        child: TextButton(
          key: const ValueKey('hermes-code-toggle'),
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? widget.showLessLabel : widget.showMoreLabel),
        ),
      ),
    ],
  );
}

TextStyle _diffLineStyle(TextStyle? base, String line, ColorScheme colors) {
  final style = base ?? const TextStyle();
  if (line.startsWith('+')) {
    return style.copyWith(
      color: colors.onTertiaryContainer,
      backgroundColor: colors.tertiaryContainer,
    );
  }
  if (line.startsWith('-')) {
    return style.copyWith(
      color: colors.onErrorContainer,
      backgroundColor: colors.errorContainer,
    );
  }
  if (line.startsWith('@@')) {
    return style.copyWith(
      color: colors.onSecondaryContainer,
      backgroundColor: colors.secondaryContainer,
    );
  }
  return style;
}
