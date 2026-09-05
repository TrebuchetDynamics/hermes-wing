import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../groups/chat_group_controller.dart';
import '../widgets/hermes_profile_identity.dart';
import 'gateway_contact.dart';

class GatewayContactsView extends StatelessWidget {
  const GatewayContactsView({
    required this.contacts,
    required this.refreshing,
    required this.onRefresh,
    required this.onOpen,
    this.onConnect,
    this.groupController,
    super.key,
  });

  final List<GatewayContact> contacts;
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final ValueChanged<GatewayContactId> onOpen;
  final VoidCallback? onConnect;
  final ChatGroupController? groupController;

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

    final controller = groupController;
    if (controller != null) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) => _GroupedGatewayContacts(
          contacts: contacts,
          refreshing: refreshing,
          onRefresh: onRefresh,
          onOpen: onOpen,
          controller: controller,
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
              final contactTitle = _contactTitle(contact);
              final profileTitle = _profileTitle(contact);
              final contactStatus = contact.chatAvailable
                  ? contact.availability.name
                  : AppLocalizations.of(context).profileChatUnavailable;
              return Semantics(
                key: ValueKey(
                  'gateway-contact-${contact.id.gatewayId}-${contact.id.profileId}',
                ),
                excludeSemantics: true,
                label: '$contactTitle, $contactStatus',
                child: ListTile(
                  key: const ValueKey('gateway-contact-row'),
                  leading: _ContactAvatar(contact: contact),
                  title: Text(
                    profileTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (contact.gatewayLabel.trim().isNotEmpty &&
                          contact.gatewayLabel.trim().toLowerCase() !=
                              contact.profileName.trim().toLowerCase())
                        Text(
                          contact.gatewayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      if (!contact.chatAvailable)
                        Text(
                          AppLocalizations.of(context).profileChatUnavailable,
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
                  onTap: contact.chatAvailable
                      ? () => onOpen(contact.id)
                      : null,
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

class _GroupedGatewayContacts extends StatelessWidget {
  const _GroupedGatewayContacts({
    required this.contacts,
    required this.refreshing,
    required this.onRefresh,
    required this.onOpen,
    required this.controller,
  });

  final List<GatewayContact> contacts;
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final ValueChanged<GatewayContactId> onOpen;
  final ChatGroupController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final sections =
        <({String? id, String name, List<GatewayContact> items})>[
              for (final group in controller.groups)
                (
                  id: group.id,
                  name: group.name,
                  items: contacts
                      .where(
                        (contact) =>
                            controller.groupIdFor(contact.id) == group.id,
                      )
                      .toList(),
                ),
              (
                id: null,
                name: strings.chatGroupsUngrouped,
                items: contacts
                    .where(
                      (contact) => controller.groupIdFor(contact.id) == null,
                    )
                    .toList(),
              ),
            ]
            .where((section) => section.id != null || section.items.isNotEmpty)
            .toList();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: OutlinedButton.icon(
                    key: const ValueKey('chat-groups-new'),
                    onPressed: () => _showGroupNameDialog(context),
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: Text(strings.chatGroupsNewAction),
                  ),
                ),
              ),
              for (final section in sections) ...[
                ListTile(
                  key: ValueKey('chat-group-${section.id ?? 'ungrouped'}'),
                  dense: true,
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(
                    section.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  trailing: section.id == null
                      ? Text('${section.items.length}')
                      : PopupMenuButton<_GroupAction>(
                          onSelected: (action) {
                            if (action == _GroupAction.rename) {
                              _showGroupNameDialog(
                                context,
                                group: controller.groups.firstWhere(
                                  (group) => group.id == section.id,
                                ),
                              );
                            } else {
                              controller.deleteGroup(section.id!);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: _GroupAction.rename,
                              child: Text(strings.chatGroupsRenameAction),
                            ),
                            PopupMenuItem(
                              value: _GroupAction.delete,
                              child: Text(strings.chatGroupsDeleteAction),
                            ),
                          ],
                        ),
                ),
                for (final contact in section.items)
                  _GroupedContactTile(
                    contact: contact,
                    onOpen: onOpen,
                    onMove: () => _showMoveSheet(context, contact.id),
                  ),
              ],
            ],
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

  Future<void> _showMoveSheet(
    BuildContext context,
    GatewayContactId contactId,
  ) async {
    final strings = AppLocalizations.of(context);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(title: Text(strings.chatGroupsMoveAction)),
            ListTile(
              title: Text(strings.chatGroupsUngrouped),
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final group in controller.groups)
              ListTile(
                title: Text(group.name),
                onTap: () => Navigator.pop(context, group.id),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await controller.moveContact(contactId, chosen.isEmpty ? null : chosen);
  }

  Future<void> _showGroupNameDialog(
    BuildContext context, {
    ChatGroup? group,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          _GroupNameDialog(initialName: group?.name, isNew: group == null),
    );
    if (name == null || name.trim().isEmpty) return;
    if (group == null) {
      await controller.createGroup(name);
    } else {
      await controller.renameGroup(group.id, name);
    }
  }
}

class _GroupNameDialog extends StatefulWidget {
  const _GroupNameDialog({this.initialName, required this.isNew});

  final String? initialName;
  final bool isNew;

  @override
  State<_GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<_GroupNameDialog> {
  late final TextEditingController _textController = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.isNew
            ? strings.chatGroupsNewTitle
            : strings.chatGroupsRenameTitle,
      ),
      content: TextField(
        key: const ValueKey('chat-group-name-field'),
        controller: _textController,
        autofocus: true,
        decoration: InputDecoration(labelText: strings.chatGroupsNameLabel),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancelAction),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _textController.text),
          child: Text(strings.saveAction),
        ),
      ],
    );
  }
}

enum _GroupAction { rename, delete }

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({required this.contact});

  final GatewayContact contact;

  @override
  Widget build(BuildContext context) {
    final color = hermesProfileColor(
      '${contact.id.gatewayId}:${contact.id.profileId}',
    );
    return CircleAvatar(
      backgroundColor: color,
      foregroundColor: hermesProfileForeground(color),
      child: Text(
        contact.profileName.trim().isEmpty
            ? '?'
            : contact.profileName.trim().characters.first.toUpperCase(),
      ),
    );
  }
}

class _GroupedContactTile extends StatelessWidget {
  const _GroupedContactTile({
    required this.contact,
    required this.onOpen,
    required this.onMove,
  });

  final GatewayContact contact;
  final ValueChanged<GatewayContactId> onOpen;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final contactStatus = contact.chatAvailable
        ? contact.availability.name
        : AppLocalizations.of(context).profileChatUnavailable;
    return Semantics(
      key: ValueKey(
        'gateway-contact-${contact.id.gatewayId}-${contact.id.profileId}',
      ),
      container: true,
      label: '${_contactTitle(contact)}, $contactStatus',
      child: ListTile(
        key: const ValueKey('gateway-contact-row'),
        leading: ExcludeSemantics(child: _ContactAvatar(contact: contact)),
        title: ExcludeSemantics(
          child: Text(
            _profileTitle(contact),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        subtitle: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contact.gatewayLabel.trim().isNotEmpty &&
                  contact.gatewayLabel.trim().toLowerCase() !=
                      contact.profileName.trim().toLowerCase())
                Text(
                  contact.gatewayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (!contact.chatAvailable)
                Text(AppLocalizations.of(context).profileChatUnavailable),
              if (contact.latestSession?.preview case final preview?)
                Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: ValueKey(
                'gateway-contact-groups-${contact.id.gatewayId}-${contact.id.profileId}',
              ),
              tooltip: AppLocalizations.of(context).chatGroupsMoveAction,
              onPressed: onMove,
              icon: const Icon(Icons.drive_file_move_outline),
            ),
            ExcludeSemantics(child: _ContactStatus(contact: contact)),
          ],
        ),
        onTap: contact.chatAvailable ? () => onOpen(contact.id) : null,
      ),
    );
  }
}

String _profileTitle(GatewayContact contact) {
  final value = contact.profileName.trim();
  if (value.isEmpty) return '?';
  final first = value.characters.first;
  return '${first.toUpperCase()}${value.substring(first.length)}';
}

String _contactTitle(GatewayContact contact) {
  final gateway = contact.gatewayLabel.trim();
  final profile = contact.profileName.trim();
  if (gateway.isEmpty) return profile;
  if (profile.isEmpty || gateway.toLowerCase() == profile.toLowerCase()) {
    return gateway;
  }
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
    final activity = contact.latestActivity?.toLocal();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          contact.chatAvailable ? Icons.circle : Icons.settings_outlined,
          size: contact.chatAvailable ? 10 : 18,
          color: contact.chatAvailable
              ? contact.availability == GatewayAvailability.online
                    ? Colors.green
                    : Colors.red
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
