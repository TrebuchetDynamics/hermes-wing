import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';

class ProfileContactsScreen extends ConsumerStatefulWidget {
  const ProfileContactsScreen({super.key});

  @override
  ConsumerState<ProfileContactsScreen> createState() =>
      _ProfileContactsScreenState();
}

class _ProfileContactsScreenState extends ConsumerState<ProfileContactsScreen> {
  NavivoxChannel? _subscribed;
  final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';
  String? _selectedServerId;

  void _onChannelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscribed?.removeListener(_onChannelChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(navivoxChannelProvider);
    if (!identical(_subscribed, channel)) {
      _subscribed?.removeListener(_onChannelChanged);
      channel.addListener(_onChannelChanged);
      _subscribed = channel;
    }

    final servers = channel.state.servers;
    final allContacts = [...channel.state.profileContacts]
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final contacts = _filterContacts(allContacts);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                key: const ValueKey('profile-search-field'),
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _query = value),
              )
            : const Text('Navivox'),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search profiles',
            onPressed: _toggleSearch,
            icon: Icon(_searching ? Icons.close : Icons.search),
          ),
          IconButton(
            tooltip: 'Manage gateways',
            onPressed: () => context.go('/servers'),
            icon: const Icon(Icons.dns),
          ),
        ],
      ),
      body: allContacts.isEmpty
          ? const Center(child: Text('No profiles loaded'))
          : Column(
              children: [
                if (servers.length > 1) ...[
                  _ServerFilterBar(
                    servers: servers,
                    selectedServerId: _selectedServerId,
                    visibleCount: contacts.length,
                    onSelected: (serverId) => setState(() {
                      _selectedServerId = serverId;
                    }),
                  ),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: contacts.isEmpty
                      ? const Center(child: Text('No chats found'))
                      : ListView.separated(
                          itemCount: contacts.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            return _ProfileContactTile(
                              contact: contact,
                              onTap: () {
                                channel.selectProfileContact(
                                  serverId: contact.serverId,
                                  profileId: contact.profileId,
                                );
                                context.go(
                                  '/chats/${contact.serverId}/${contact.profileId}',
                                );
                              },
                              onLongPress: () =>
                                  _showProfileDetails(context, contact),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Add profile',
        onPressed: () => _showAddProfilePlaceholder(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<NavivoxProfileContact> _filterContacts(
    List<NavivoxProfileContact> contacts,
  ) {
    final query = _query.trim().toLowerCase();
    return contacts
        .where(
          (contact) =>
              _selectedServerId == null ||
              contact.serverId == _selectedServerId,
        )
        .where(
          (contact) =>
              query.isEmpty ||
              [
                contact.displayName,
                contact.profileId,
                contact.serverId,
                contact.serverLabel,
                contact.latestPreview,
                ...contact.attentionBadges,
              ].any((field) => field.toLowerCase().contains(query)),
        )
        .toList(growable: false);
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _query = '';
        _searchController.clear();
      }
    });
  }

  void _showAddProfilePlaceholder(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: const [
            ListTile(
              leading: Icon(Icons.person_add_alt),
              title: Text('New profile'),
              subtitle: Text('Server-validated profile creation is next.'),
            ),
            ListTile(
              leading: Icon(Icons.dns),
              title: Text('Add server'),
              subtitle: Text('Import connect-info from Gormes.'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDetails(
    BuildContext context,
    NavivoxProfileContact contact,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: _ProfileAvatar(contact: contact),
              title: const Text('Profile details'),
              subtitle: Text('${contact.displayName}\n${contact.profileId}'),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit profile'),
              subtitle: const Text('Schema-driven editor placeholder.'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerFilterBar extends StatelessWidget {
  const _ServerFilterBar({
    required this.servers,
    required this.selectedServerId,
    required this.visibleCount,
    required this.onSelected,
  });

  final List<NavivoxServer> servers;
  final String? selectedServerId;
  final int visibleCount;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final countLabel = visibleCount == 1
        ? '1 profile'
        : '$visibleCount profiles';
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          ChoiceChip(
            key: const ValueKey('server-filter-all'),
            label: const Text('All'),
            selected: selectedServerId == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final server in servers) ...[
            ChoiceChip(
              key: ValueKey('server-filter-${server.id}'),
              label: Text(server.name),
              selected: selectedServerId == server.id,
              onSelected: (_) => onSelected(server.id),
            ),
            const SizedBox(width: 8),
          ],
          Center(
            child: Text(
              countLabel,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileContactTile extends StatelessWidget {
  const _ProfileContactTile({
    required this.contact,
    required this.onTap,
    required this.onLongPress,
  });

  final NavivoxProfileContact contact;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('profile-contact-${contact.serverId}-${contact.profileId}'),
      leading: _ProfileAvatar(contact: contact),
      title: Row(
        children: [
          Expanded(child: Text(contact.displayName)),
          _ServerChip(label: contact.serverLabel),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _previewLabel(contact),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: contact.activeTurnState == 'streaming'
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        )
                      : null,
                ),
              ),
              if (contact.activeTurnState == 'streaming')
                Container(
                  key: ValueKey(
                    'profile-active-turn-${contact.serverId}-${contact.profileId}',
                  ),
                  margin: const EdgeInsets.only(left: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HealthChip(health: contact.health),
              Text(
                _workspaceLabel(contact),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              for (final badge in contact.attentionBadges)
                Chip(visualDensity: VisualDensity.compact, label: Text(badge)),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            contact.micAvailable ? Icons.mic : Icons.mic_off,
            size: 18,
            color: contact.micAvailable
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
          if (contact.latestAt != null)
            Text(
              DateFormat.Hm().format(contact.latestAt!),
              style: Theme.of(context).textTheme.labelSmall,
            ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String _previewLabel(NavivoxProfileContact contact) {
    if (contact.activeTurnState == 'streaming') return 'typing…';
    return contact.latestPreview;
  }

  String _workspaceLabel(NavivoxProfileContact contact) {
    if (!contact.workspaceRootsOk) return 'workspace issue';
    if (contact.workspaceRootCount == 1) return '1 root';
    return '${contact.workspaceRootCount} roots';
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.contact});

  final NavivoxProfileContact contact;

  @override
  Widget build(BuildContext context) {
    final color =
        Colors.primaries[contact.avatarSeed.codeUnits.fold<int>(
              0,
              (a, b) => a + b,
            ) %
            Colors.primaries.length];
    return CircleAvatar(
      backgroundColor: color.shade700,
      foregroundColor: Colors.white,
      child: Text(contact.displayName.characters.first.toUpperCase()),
    );
  }
}

class _ServerChip extends StatelessWidget {
  const _ServerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(visualDensity: VisualDensity.compact, label: Text(label));
  }
}

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.health});

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
