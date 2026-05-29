import 'package:flutter/material.dart';

import '../../../../core/gateway/navivox_gateway_protocol.dart';
import '../../presentation/transcript/transcript_run_record_presentation.dart';

class TranscriptRunRecordSheet extends StatelessWidget {
  const TranscriptRunRecordSheet({
    required this.record,
    this.scrollController,
    super.key,
  });

  final NavivoxRunRecordSnapshot record;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final presentation = TranscriptRunRecordPresentation.fromRecord(record);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('transcript-run-record-scroll'),
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(presentation.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _Section(
              title: 'Identity',
              children: [
                _InfoTile(label: 'Run ID', value: presentation.runId),
                _InfoTile(label: 'Session ID', value: presentation.sessionId),
                _InfoTile(label: 'Status', value: presentation.statusLabel),
              ],
            ),
            _Section(
              title: 'Timeline',
              children: [
                _InfoTile(label: 'Created', value: presentation.createdAtLabel),
                _InfoTile(label: 'Updated', value: presentation.updatedAtLabel),
                _InfoTile(
                  label: 'Completed',
                  value: presentation.completedAtLabel,
                ),
              ],
            ),
            _Section(
              title: 'Provider',
              children: [
                _InfoTile(
                  label: 'Provider usage',
                  value: presentation.providerUsageLabel,
                ),
                _InfoTile(
                  label: 'Provider cost',
                  value: presentation.providerCostLabel,
                ),
              ],
            ),
            if (presentation.transcriptRows.isNotEmpty)
              _Section(
                title: 'Transcript',
                children: [
                  for (final row in presentation.transcriptRows)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(row.role),
                      subtitle: SelectableText(row.text),
                    ),
                ],
              ),
            _Section(
              title: 'Voice',
              children: [
                for (final row in presentation.voiceRows)
                  _InfoTile(label: row.label, value: row.value),
              ],
            ),
            if (presentation.toolRows.isNotEmpty)
              _Section(
                title: 'Tool timeline',
                children: [
                  for (final row in presentation.toolRows)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.build_outlined),
                      title: Text(row.name),
                      subtitle: Text('${row.status} • ${row.artifactRef}'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: SelectableText(value),
    );
  }
}
