import 'dart:async';

import 'package:flutter/material.dart';

import '../models/voice_command.dart';

/// Confirmation banner for a confirm-tier routed voice command. Shown above
/// the chat composer with the command's [VoiceRouteResult.describe] text and
/// Confirm/'Not now' actions.
///
/// [autoDeclineAfter] is `null` for a sticky chip (manual voice capture — the
/// operator must explicitly confirm or decline) or a short duration in
/// continuous mode, where the hands-free loop should not stall indefinitely
/// waiting for a tap.
class VoiceCommandChip extends StatefulWidget {
  const VoiceCommandChip({
    required this.result,
    required this.onConfirm,
    required this.onDecline,
    this.autoDeclineAfter,
    super.key,
  });

  final VoiceRouteResult result;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;
  final Duration? autoDeclineAfter;

  @override
  State<VoiceCommandChip> createState() => _VoiceCommandChipState();
}

class _VoiceCommandChipState extends State<VoiceCommandChip> {
  Timer? _autoDeclineTimer;

  @override
  void initState() {
    super.initState();
    _armAutoDeclineTimer();
  }

  @override
  void didUpdateWidget(VoiceCommandChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new result replaces the old chip in place (same widget identity via
    // the parent's single pending-command slot): restart the countdown for
    // whatever is now showing rather than firing the previous command's
    // timer against the new one.
    if (oldWidget.result != widget.result ||
        oldWidget.autoDeclineAfter != widget.autoDeclineAfter) {
      _autoDeclineTimer?.cancel();
      _armAutoDeclineTimer();
    }
  }

  void _armAutoDeclineTimer() {
    final duration = widget.autoDeclineAfter;
    if (duration == null) return;
    _autoDeclineTimer = Timer(duration, () {
      if (mounted) widget.onDecline();
    });
  }

  @override
  void dispose() {
    _autoDeclineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      key: const ValueKey('voice-command-chip'),
      content: Text(widget.result.describe()),
      actions: [
        TextButton(
          key: const ValueKey('voice-command-chip-decline'),
          onPressed: widget.onDecline,
          child: const Text('Not now'),
        ),
        FilledButton(
          key: const ValueKey('voice-command-chip-confirm'),
          onPressed: widget.onConfirm,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
