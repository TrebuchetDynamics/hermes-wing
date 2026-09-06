import 'package:flutter/material.dart';

import '../../features/hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../l10n/app_localizations.dart';

/// The saved-gateway selector shared by every gateway-scoped screen.
///
/// Each screen supplies its own [fieldKey] and [helpText] because those are
/// surface-specific; the layout, selection guard, and item list are identical
/// everywhere and used to be copied per screen.
class WingGatewayPicker extends StatelessWidget {
  const WingGatewayPicker({
    super.key,
    required this.fieldKey,
    required this.directory,
    required this.helpText,
    required this.onSelected,
    this.hint,
    this.enabled = true,
  });

  /// Key applied to the dropdown itself, which is what tests and device flows
  /// target.
  final Key fieldKey;
  final HermesGatewayDirectory directory;

  /// Scope explanation exposed to assistive technology and through a tooltip.
  final String helpText;

  /// Called only for a gateway that is not already selected.
  final void Function(String gatewayId) onSelected;

  /// Defaults to the shared "Select gateway" hint.
  final String? hint;

  /// False while a switch is in flight, which disables the dropdown.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final hosts = directory.hosts;
    final activeGatewayId = directory.activeContactId?.gatewayId;
    // A profile-bound endpoint maps back to its paired host. A stale endpoint
    // must not be shown as a selection because the dropdown has no item for it.
    final selected = hosts
        .where((host) => host.containsGateway(activeGatewayId))
        .firstOrNull
        ?.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        label: strings.gatewayLabel,
        hint: helpText,
        child: DropdownButtonFormField<String>(
          key: fieldKey,
          isExpanded: true,
          style: Theme.of(context).textTheme.bodyMedium,
          initialValue: selected,
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            constraints: const BoxConstraints(minHeight: 48),
            prefixIconConstraints: const BoxConstraints(minWidth: 32),
            prefixIcon: Tooltip(
              message: helpText,
              child: const Icon(Icons.dns_outlined, size: 18),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 10,
            ),
            isDense: true,
          ),
          hint: Text(hint ?? strings.selectGatewayHint),
          items: [
            for (final host in hosts)
              DropdownMenuItem(
                value: host.id,
                child: Text(host.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: enabled
              ? (gatewayId) {
                  if (gatewayId != null && gatewayId != selected) {
                    onSelected(gatewayId);
                  }
                }
              : null,
        ),
      ),
    );
  }
}
