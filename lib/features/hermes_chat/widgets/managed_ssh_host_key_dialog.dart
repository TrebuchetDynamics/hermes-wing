import 'package:flutter/material.dart';

/// Reviews one SSH handshake. The transport must fence obsolete answers and
/// reverify on reconnect; this dialog does not persist a host-trust decision.
Future<bool> reviewManagedSshHostKey(
  BuildContext context, {
  required String host,
  required int port,
  required String algorithm,
  required String fingerprint,
  required String title,
  required String explanation,
  required String cancelLabel,
  required String trustLabel,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(explanation),
            const SizedBox(height: 16),
            SelectableText('$host:$port'),
            const SizedBox(height: 8),
            SelectableText(algorithm),
            const SizedBox(height: 8),
            SelectableText(fingerprint),
          ],
        ),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(trustLabel),
        ),
      ],
    ),
  );
  return accepted == true;
}
