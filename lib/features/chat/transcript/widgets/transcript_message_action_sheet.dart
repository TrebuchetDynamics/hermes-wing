import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/channel/navivox_channel.dart';
import '../../transcript/presentation/transcript_message_action_presentation.dart';

class TranscriptMessageActionSheet extends StatelessWidget {
  const TranscriptMessageActionSheet({
    required this.presentation,
    this.onPauseStream,
    this.onCopyText,
    this.onReadAloud,
    this.onInspectRunRecord,
    this.onForward,
    this.scrollController,
    super.key,
  });

  final TranscriptMessageActionPresentation presentation;
  final FutureOr<void> Function()? onPauseStream;
  final FutureOr<void> Function()? onCopyText;
  final FutureOr<void> Function()? onReadAloud;
  final FutureOr<void> Function()? onInspectRunRecord;
  final void Function(NavivoxProfileContact target)? onForward;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        controller: scrollController,
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            presentation.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (presentation.hasText)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(presentation.text),
            ),
          if (presentation.showPauseStream)
            ListTile(
              leading: const Icon(Icons.pause_circle_outline),
              title: Text(presentation.pauseLabel),
              subtitle: Text(presentation.pauseSubtitle),
              onTap: onPauseStream,
            ),
          if (presentation.showCopy) ...[
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(presentation.copyLabel),
              onTap: onCopyText,
            ),
            if (presentation.canReadAloud)
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: Text(presentation.readAloudLabel),
                onTap: onReadAloud,
              ),
          ],
          if (presentation.showForwardSection) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.forward),
              title: Text(presentation.forwardTitle),
            ),
            for (final target in presentation.forwardTargets)
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(target.displayName),
                subtitle: Text(target.subtitle),
                onTap: () => onForward?.call(target.contact),
              ),
          ],
          if (presentation.showInspectRunRecord)
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: Text(presentation.inspectRunRecordLabel),
              subtitle: Text(presentation.inspectRunRecordSubtitle),
              onTap: onInspectRunRecord,
            ),
          if (presentation.showReadAloudUnavailable)
            ListTile(
              enabled: false,
              leading: const Icon(Icons.volume_off),
              title: Text(presentation.readAloudUnavailableLabel),
              subtitle: Text(presentation.readAloudUnavailableSubtitle),
            ),
        ],
      ),
    );
  }
}
