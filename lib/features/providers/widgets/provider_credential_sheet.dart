import 'package:flutter/material.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../l10n/app_localizations.dart';

/// Retains the existing sheet entry point without collecting secrets for the
/// unqualified legacy slug/env-var contract. Exact route grants are insufficient.
class ProviderCredentialSheet extends StatelessWidget {
  const ProviderCredentialSheet({
    required this.channel,
    required this.provider,
    super.key,
  });

  final HermesChannel channel;
  final HermesProvider provider;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.credentialSheetTitle(provider.label),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(strings.credentialContractUnavailable),
          const SizedBox(height: 20),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(strings.cancelAction),
            ),
          ),
        ],
      ),
    );
  }
}
