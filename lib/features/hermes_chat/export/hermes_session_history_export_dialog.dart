import 'package:flutter/material.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/client/hermes_session_history_export.dart';
import '../../../l10n/app_localizations.dart';
import 'hermes_transcript_export.dart';

Future<bool> confirmTranscriptOverwrite(
  BuildContext context,
  bool Function() owns,
) async {
  if (!context.mounted || !owns()) return false;
  final strings = AppLocalizations.of(context);
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(strings.transcriptOverwriteTitle),
      content: Text(strings.transcriptOverwriteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.historyJsonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(strings.transcriptOverwriteConfirm),
        ),
      ],
    ),
  );
  return context.mounted && owns() && accepted == true;
}

/// Volatile owner-bound bytes only. No preference, clipboard or partial save path.
class HermesSessionHistoryExportDialog extends StatefulWidget {
  const HermesSessionHistoryExportDialog({
    super.key,
    required this.channel,
    required this.attempt,
    required this.saver,
    required this.owns,
  });
  final HermesChannel channel;
  final HermesSessionHistoryExportAttempt attempt;
  final HermesTranscriptSaver saver;
  final bool Function() owns;

  @override
  State<HermesSessionHistoryExportDialog> createState() =>
      _HistoryExportState();
}

class _HistoryExportState extends State<HermesSessionHistoryExportDialog> {
  HermesTranscriptExport? _snapshot;
  int _count = 0;
  bool _preparing = false, _saving = false, _failed = false;
  bool _finished = false;
  String? _outcome;
  bool get _owns => mounted && widget.owns() && widget.attempt.isCurrent;

  @override
  void initState() {
    super.initState();
    widget.channel.addListener(_ownerChanged);
  }

  void _ownerChanged() {
    if (_finished && mounted && widget.owns()) return;
    if (_owns) return;
    widget.attempt.cancel();
    if (mounted) {
      setState(() {
        _snapshot = null;
        _outcome = null;
        _failed = true;
        _preparing = false;
      });
    }
  }

  @override
  void dispose() {
    widget.channel.removeListener(_ownerChanged);
    widget.attempt.cancel();
    _snapshot = null;
    super.dispose();
  }

  Future<void> _prepare() async {
    if (_preparing || _snapshot != null || _failed) return;
    if (!_owns) {
      _ownerChanged();
      return;
    }
    setState(() => _preparing = true);
    try {
      final json = await widget.attempt.collect(
        onProgress: (count) {
          if (_owns) setState(() => _count = count);
        },
      );
      if (!_owns) {
        _ownerChanged();
        return;
      }
      setState(() {
        _snapshot = HermesTranscriptExport(
          json,
          HermesTranscriptExportFormat.json,
        );
        _preparing = false;
      });
    } catch (_) {
      widget.attempt.cancel();
      if (mounted) {
        setState(() {
          _snapshot = null;
          _failed = true;
          _preparing = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final snapshot = _snapshot;
    if (_saving || snapshot == null) return;
    if (!_owns) {
      _ownerChanged();
      return;
    }
    setState(() => _saving = true);
    final strings = AppLocalizations.of(context);
    try {
      final result = await widget.saver.save(
        snapshot,
        canWrite: () => _owns,
        confirmOverwrite: () =>
            confirmTranscriptOverwrite(context, () => _owns),
      );
      // An already-started OS write may have completed even after owner loss.
      // Do not claim rollback or display its success against a replacement owner.
      if (!_owns) {
        _ownerChanged();
        return;
      }
      setState(() {
        _finished = true;
        _outcome = switch (result) {
          HermesTranscriptExportResult.saved => strings.transcriptExportSaved,
          HermesTranscriptExportResult.downloadStarted =>
            strings.transcriptExportDownloadStarted,
          HermesTranscriptExportResult.unsupported =>
            strings.transcriptExportUnsupported,
          HermesTranscriptExportResult.cancelled =>
            strings.historyJsonCancelled,
        };
        _snapshot = null;
      });
      widget.attempt.cancel();
    } catch (_) {
      widget.attempt.cancel();
      if (mounted) {
        setState(() {
          _snapshot = null;
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          widget.attempt.cancel();
          _snapshot = null;
        }
      },
      child: AlertDialog(
        title: Text(strings.historyJsonAction),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.historyJsonConsent),
              if (_preparing) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                Semantics(
                  liveRegion: true,
                  child: Text(strings.historyJsonProgress(_count)),
                ),
              ],
              if (_snapshot != null) Text(strings.historyJsonReady(_count)),
              if (_failed) Text(strings.historyJsonFailed),
              if (_outcome != null) Text(_outcome!),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-cancel-history-json'),
            onPressed: () {
              widget.attempt.cancel();
              _snapshot = null;
              Navigator.pop(context);
            },
            child: Text(strings.historyJsonCancel),
          ),
          if (!_preparing && !_saving && !_failed && _outcome == null)
            if (_snapshot == null)
              FilledButton(
                key: const ValueKey('hermes-prepare-history-json'),
                onPressed: _prepare,
                child: Text(strings.historyJsonPrepare),
              )
            else
              FilledButton(
                key: const ValueKey('hermes-save-history-json'),
                onPressed: _save,
                child: Text(strings.historyJsonSave),
              ),
        ],
      ),
    );
  }
}
