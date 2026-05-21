import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(navivoxChannelProvider).state;
    final servers = [...state.servers]
      ..sort((a, b) => a.name.compareTo(b.name));
    final contactsByServer = <String, List<NavivoxProfileContact>>{};
    for (final contact in state.profileContacts) {
      contactsByServer.putIfAbsent(contact.serverId, () => []).add(contact);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gateways')),
      body: servers.isEmpty
          ? const Center(child: Text('No gateways registered'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: servers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final server = servers[index];
                final contacts = contactsByServer[server.id] ?? const [];
                return _ServerCard(
                  server: server,
                  contacts: contacts,
                  active: server.id == state.activeServerId,
                  onManage: () => _showManageGateway(context, server, contacts),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Register gateway',
        onPressed: () => _showRegisterGateway(context),
        icon: const Icon(Icons.add_link),
        label: const Text('Register'),
      ),
    );
  }

  void _showManageGateway(
    BuildContext context,
    NavivoxServer server,
    List<NavivoxProfileContact> contacts,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              'Manage gateway',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dns),
              title: Text(server.name),
              subtitle: Text(server.status),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.tag),
              title: Text('Server ID'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 12),
              child: SelectableText(server.id),
            ),
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.people_alt_outlined),
              title: Text('Profiles on this gateway'),
            ),
            if (contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: Text('No profiles reported by this gateway yet.'),
              )
            else
              for (final contact in contacts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(
                      contact.displayName.characters.first.toUpperCase(),
                    ),
                  ),
                  title: Text(contact.displayName),
                  subtitle: Text(contact.profileId),
                  trailing: _HealthPill(health: contact.health),
                ),
          ],
        ),
      ),
    );
  }

  void _showRegisterGateway(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: const [
            ListTile(
              leading: Icon(Icons.add_link),
              title: Text('Register gateway'),
              subtitle: Text(
                'Run `gormes navivox connect-info --json` on the server, then import its base URL and auth requirements.',
              ),
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Current boundary'),
              subtitle: Text(
                'This view manages gateways already reported by Navivox. persistent multi-gateway connection storage is the next protocol slice.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    required this.server,
    required this.contacts,
    required this.active,
    required this.onManage,
  });

  final NavivoxServer server;
  final List<NavivoxProfileContact> contacts;
  final bool active;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final warningCount = contacts
        .where(
          (c) =>
              !c.workspaceRootsOk || c.health == NavivoxProfileHealth.warning,
        )
        .length;
    final authCount = contacts
        .where((c) => c.health == NavivoxProfileHealth.needsAuth)
        .length;
    final activeTurns = contacts
        .where((c) => c.activeTurnState != 'idle')
        .length;

    return Card(
      key: ValueKey('server-card-${server.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(active ? Icons.hub : Icons.dns),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        server.status,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: ValueKey('server-manage-${server.id}'),
                  tooltip: 'Manage ${server.name}',
                  onPressed: onManage,
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _CountChip(label: _plural(contacts.length, 'profile')),
                if (warningCount > 0)
                  _CountChip(label: _plural(warningCount, 'warning')),
                if (authCount > 0)
                  _CountChip(label: _plural(authCount, 'auth')),
                if (activeTurns > 0)
                  _CountChip(label: _plural(activeTurns, 'active turn')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _plural(int count, String noun) {
    if (count == 1) return '1 $noun';
    return '$count ${noun}s';
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(visualDensity: VisualDensity.compact, label: Text(label));
  }
}

class _HealthPill extends StatelessWidget {
  const _HealthPill({required this.health});

  final NavivoxProfileHealth health;

  @override
  Widget build(BuildContext context) {
    final label = switch (health) {
      NavivoxProfileHealth.online => 'online',
      NavivoxProfileHealth.offline => 'offline',
      NavivoxProfileHealth.needsAuth => 'auth',
      NavivoxProfileHealth.warning => 'warning',
    };
    return Text(label, style: Theme.of(context).textTheme.labelSmall);
  }
}
