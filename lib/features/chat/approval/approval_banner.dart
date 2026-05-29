import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/channel/navivox_channel.dart';
import 'approval_banner_presentation.dart';

/// Listens to [NavivoxChannel.approvalRequests] and renders the most recent
/// pending approval as an Allow/Deny banner. Tapping a button resolves the
/// approval through the channel and clears the banner.
class ApprovalBanner extends StatefulWidget {
  const ApprovalBanner({required this.channel, super.key});

  final NavivoxChannel channel;

  @override
  State<ApprovalBanner> createState() => _ApprovalBannerState();
}

class _ApprovalBannerState extends State<ApprovalBanner> {
  StreamSubscription<NavivoxApprovalRequest>? _subscription;
  NavivoxApprovalRequest? _pending;

  @override
  void initState() {
    super.initState();
    _subscription = widget.channel.approvalRequests.listen((request) {
      if (!mounted) return;
      setState(() => _pending = request);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _resolve(bool approved) {
    final pending = _pending;
    if (pending == null) return;
    widget.channel.respondToApproval(
      approvalId: pending.id,
      approved: approved,
    );
    setState(() => _pending = null);
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    if (pending == null) return const SizedBox.shrink();

    final presentation = ApprovalBannerPresentation.fromRequest(pending);

    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              presentation.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(presentation.prompt),
            if (presentation.showRiskBadge)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _RiskBadge(
                  key: const ValueKey('approval-risk-badge'),
                  showWarningIcon: presentation.showHighRiskWarning,
                  label: presentation.riskLabel!,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _resolve(false),
                  child: Text(presentation.denyLabel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _resolve(true),
                  child: Text(presentation.allowLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({
    required this.showWarningIcon,
    required this.label,
    super.key,
  });

  final bool showWarningIcon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showWarningIcon) const Icon(Icons.warning, size: 16),
        if (showWarningIcon) const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
