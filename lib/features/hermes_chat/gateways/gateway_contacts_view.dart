import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'gateway_contact.dart';

class GatewayContactsView extends StatelessWidget {
  const GatewayContactsView({
    required this.contacts,
    required this.refreshing,
    required this.onRefresh,
    required this.onOpen,
    this.onConnect,
    super.key,
  });

  final List<GatewayContact> contacts;
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final ValueChanged<GatewayContactId> onOpen;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      final strings = AppLocalizations.of(context);
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height * 0.68,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    key: const ValueKey('gateway-contacts-empty'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Icon(
                            Icons.support_agent_rounded,
                            size: 36,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        strings.gatewayContactsEmptyTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.gatewayContactsEmptyBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      if (onConnect != null) ...[
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          key: const ValueKey('gateway-contacts-add'),
                          onPressed: onConnect,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(strings.gatewayContactsConnectAction),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: contacts.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Semantics(
                key: ValueKey(
                  'gateway-contact-${contact.id.gatewayId}-${contact.id.profileId}',
                ),
                label:
                    '${contact.gatewayLabel}, ${contact.profileName}, ${contact.availability.name}',
                child: ListTile(
                  key: const ValueKey('gateway-contact-row'),
                  leading: CircleAvatar(
                    child: Text(
                      contact.profileName.trim().isEmpty
                          ? '?'
                          : contact.profileName
                                .trim()
                                .characters
                                .first
                                .toUpperCase(),
                    ),
                  ),
                  title: Text(
                    _contactTitle(contact),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.availability.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contact.latestSession?.preview case final preview?)
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: _ContactStatus(contact: contact),
                  onTap: () => onOpen(contact.id),
                ),
              );
            },
          ),
        ),
        if (refreshing)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

String _contactTitle(GatewayContact contact) {
  final gateway = contact.gatewayLabel.trim();
  final profile = contact.profileName.trim();
  if (gateway.isEmpty) return profile;
  if (profile.isEmpty) return gateway;
  return '$gateway · $profile';
}

class _ContactStatus extends StatelessWidget {
  const _ContactStatus({required this.contact});

  final GatewayContact contact;

  @override
  Widget build(BuildContext context) {
    if (contact.availability == GatewayAvailability.refreshing) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final activity = contact.latestActivity;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          contact.availability == GatewayAvailability.online
              ? Icons.circle
              : Icons.cloud_off_outlined,
          size: contact.availability == GatewayAvailability.online ? 10 : 18,
          color: contact.availability == GatewayAvailability.online
              ? Colors.green
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        if (activity != null)
          Text(
            '${activity.hour.toString().padLeft(2, '0')}:${activity.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
      ],
    );
  }
}
