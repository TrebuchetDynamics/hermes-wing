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
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.65,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context).gatewayContactsEmptyTitle,
                    ),
                    if (onConnect != null) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: onConnect,
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).gatewayContactsConnectAction,
                        ),
                      ),
                    ],
                  ],
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
                    '${contact.profileName}, ${contact.gatewayLabel}, ${contact.availability.name}',
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
                    contact.profileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${contact.gatewayLabel} · ${contact.availability.name}',
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
