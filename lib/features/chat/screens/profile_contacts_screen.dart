import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/navigation_intent.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../profile_contacts/profile_contact_avatar.dart';
import '../../profile_contacts/profile_contact_list_presentation.dart';
import '../../profile_contacts/profile_contact_presentation.dart';
import '../../profiles/profile_seed_sheet.dart';

const _profileContactsPresentation = ProfileContactsScreenPresentation();

class ProfileContactsScreen extends ConsumerStatefulWidget {
  const ProfileContactsScreen({super.key});

  @override
  ConsumerState<ProfileContactsScreen> createState() =>
      _ProfileContactsScreenState();
}

class _ProfileContactsScreenState extends ConsumerState<ProfileContactsScreen> {
  NavivoxChannel? _subscribed;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
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
    _searchFocusNode.dispose();
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

    final presentation = ProfileContactListPresentation.fromContacts(
      servers: channel.state.servers,
      contacts: channel.state.profileContacts,
      selectedServerId: _selectedServerId,
      query: _query,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const SizedBox.shrink(),
        leadingWidth: 56,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Text('N'),
            ),
            const SizedBox(width: 10),
            Text(_profileContactsPresentation.title),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _searching
                ? _profileContactsPresentation.closeSearchTooltip
                : _profileContactsPresentation.searchTooltip,
            onPressed: _toggleSearch,
            icon: Icon(_searching ? Icons.close : Icons.search),
          ),
          PopupMenuButton<ProfileContactsMenuActionKind>(
            tooltip: _profileContactsPresentation.profileListMenuTooltip,
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleProfileContactsMenu(context, action),
            itemBuilder: (context) => [
              for (final row in _profileContactsPresentation.menuRows)
                PopupMenuItem(
                  value: row.kind,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_profileContactsMenuIcon(row.kind)),
                    title: Text(row.title),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _ProfileSearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: _profileContactsPresentation.searchHint,
            query: _query,
            onTap: () => setState(() => _searching = true),
            onChanged: (value) => setState(() => _query = value),
            onClear: () => setState(() {
              _query = '';
              _searchController.clear();
            }),
          ),
          if (!presentation.hasContacts)
            Expanded(
              child: Center(
                child: Text(_profileContactsPresentation.noProfilesMessage),
              ),
            )
          else ...[
            if (presentation.showServerFilter) ...[
              _ServerFilterBar(
                servers: presentation.servers,
                selectedServerId: presentation.selectedServerId,
                visibleCountLabel: presentation.visibleCountLabel,
                allServersLabel: _profileContactsPresentation.allServersLabel,
                onSelected: (serverId) => setState(() {
                  _selectedServerId = serverId;
                }),
              ),
              const Divider(height: 1),
            ],
            Expanded(
              child: !presentation.hasVisibleContacts
                  ? Center(
                      child: Text(
                        _profileContactsPresentation.noVisibleChatsMessage,
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.viewPaddingOf(context).bottom + 96,
                      ),
                      itemCount: presentation.visibleContacts.length,
                      separatorBuilder: (context, index) => Padding(
                        padding: const EdgeInsetsDirectional.only(start: 76),
                        child: Divider(
                          height: 1,
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.18),
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final contact = presentation.visibleContacts[index];
                        return _ProfileContactTile(
                          contact: contact,
                          query: _query,
                          selected:
                              contact.key ==
                              channel.state.selectedProfileContactKey,
                          onTap: () {
                            channel.selectProfileContact(
                              serverId: contact.serverId,
                              profileId: contact.profileId,
                            );
                            NavigationIntent.go(
                              context,
                              OpenChatThread(
                                contact.serverId,
                                contact.profileId,
                              ),
                            );
                          },
                          onLongPress: () =>
                              _showProfileDetails(context, contact),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: _profileContactsPresentation.addProfileTooltip,
        shape: const CircleBorder(),
        onPressed: () => _showAddProfileSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _toggleSearch() {
    if (_searching) {
      setState(() {
        _searching = false;
        _query = '';
        _searchController.clear();
      });
      _searchFocusNode.unfocus();
      return;
    }
    setState(() => _searching = true);
    _searchFocusNode.requestFocus();
  }

  void _handleProfileContactsMenu(
    BuildContext context,
    ProfileContactsMenuActionKind action,
  ) {
    NavigationIntent.go(context, switch (action) {
      ProfileContactsMenuActionKind.manageGateways => const OpenGateways(),
      ProfileContactsMenuActionKind.manageProfiles => const OpenAgents(),
      ProfileContactsMenuActionKind.openMemory => const OpenWorkspace(),
      ProfileContactsMenuActionKind.openConfig => const OpenConfig(),
      ProfileContactsMenuActionKind.openSettings => const OpenSettings(),
    });
  }

  void _handleAddProfileRow(ProfileContactsAddRowKind kind) {
    switch (kind) {
      case ProfileContactsAddRowKind.newProfile:
        _showProfileSeedSheet(context);
      case ProfileContactsAddRowKind.addServer:
        NavigationIntent.go(context, const OpenGateways());
    }
  }

  void _showAddProfileSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              key: const ValueKey('profile-create-from-seed'),
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Create from seed'),
              subtitle: const Text(
                'Ask Gormes to draft a profile from natural language.',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showProfileSeedSheet(context);
              },
            ),
            for (final row in _profileContactsPresentation.addProfileRows)
              ListTile(
                leading: Icon(_addProfileRowIcon(row.kind)),
                title: Text(row.title),
                subtitle: Text(row.subtitle),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleAddProfileRow(row.kind);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showProfileSeedSheet(BuildContext context) {
    final channel = ref.read(navivoxChannelProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ProfileSeedSheet(channel: channel),
    );
  }

  void _showProfileDetails(
    BuildContext context,
    NavivoxProfileContact contact,
  ) {
    final channel = ref.read(navivoxChannelProvider);
    final summary = ProfileContactPresentation(contact);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: ProfileContactAvatar(contact: contact),
              title: Text(summary.detailsTitle),
              subtitle: Text(summary.detailsSubtitle),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: Text(summary.diagnosticsTitle),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 72, right: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in summary.diagnosticLines) Text(line),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final section in summary.detailSections)
              _ProfileDetailSection(
                icon: _detailSectionIcon(section.kind),
                title: section.title,
                lines: section.lines,
              ),
            const Divider(height: 1),
            for (final action in summary.detailActions)
              ListTile(
                leading: Icon(_detailActionIcon(action.kind)),
                title: Text(action.title),
                subtitle: Text(action.subtitle),
                onTap: () => _handleProfileDetailAction(
                  context,
                  channel,
                  contact,
                  action.kind,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleProfileDetailAction(
    BuildContext context,
    NavivoxChannel channel,
    NavivoxProfileContact contact,
    ProfileContactDetailActionKind kind,
  ) {
    Navigator.of(context).pop();
    switch (kind) {
      case ProfileContactDetailActionKind.openChat:
        channel.selectProfileContact(
          serverId: contact.serverId,
          profileId: contact.profileId,
        );
        NavigationIntent.go(
          context,
          OpenChatThread(contact.serverId, contact.profileId),
        );
      case ProfileContactDetailActionKind.openMemory:
        channel.selectProfileContact(
          serverId: contact.serverId,
          profileId: contact.profileId,
        );
        NavigationIntent.go(context, const OpenWorkspace());
      case ProfileContactDetailActionKind.editProfile:
        channel.selectProfileContact(
          serverId: contact.serverId,
          profileId: contact.profileId,
        );
        NavigationIntent.go(context, const OpenConfig());
    }
  }
}

class _ProfileDetailSection extends StatelessWidget {
  const _ProfileDetailSection({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          for (final line in lines) Text(line),
        ],
      ),
    );
  }
}

class _ServerFilterBar extends StatelessWidget {
  const _ServerFilterBar({
    required this.servers,
    required this.selectedServerId,
    required this.visibleCountLabel,
    required this.allServersLabel,
    required this.onSelected,
  });

  final List<NavivoxServer> servers;
  final String? selectedServerId;
  final String visibleCountLabel;
  final String allServersLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          ChoiceChip(
            key: const ValueKey('server-filter-all'),
            label: Text(allServersLabel),
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
              visibleCountLabel,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSearchBar extends StatelessWidget {
  const _ProfileSearchBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.query,
    required this.onTap,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String query;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: SizedBox(
        height: 52,
        child: TextField(
          key: const ValueKey('profile-search-field'),
          controller: controller,
          focusNode: focusNode,
          onTap: onTap,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search, size: 22),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 18),
                  ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.70 : 1,
            ),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSearchHighlightText extends StatelessWidget {
  const _ProfileSearchHighlightText({
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final normalizedQuery = query.trim().toLowerCase();
    final start = normalizedQuery.isEmpty
        ? -1
        : text.toLowerCase().indexOf(normalizedQuery);
    if (start < 0) {
      return Text(
        text,
        style: effectiveStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final end = start + normalizedQuery.length;
    final accent = Theme.of(context).colorScheme.primary;
    return Text.rich(
      TextSpan(
        style: effectiveStyle,
        children: [
          if (start > 0) TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: effectiveStyle.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (end < text.length) TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class _ProfileContactAvatarStack extends StatelessWidget {
  const _ProfileContactAvatarStack({required this.contact});

  final NavivoxProfileContact contact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(child: ProfileContactAvatar(contact: contact, radius: 24)),
    );
  }
}

class _ProfileTypingDots extends StatelessWidget {
  const _ProfileTypingDots({required this.contact});

  final NavivoxProfileContact contact;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 3; index += 1) ...[
          Container(
            key: ValueKey(
              'profile-typing-dot-${contact.serverId}-${contact.profileId}-$index',
            ),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.55 + index * 0.15),
              shape: BoxShape.circle,
            ),
          ),
          if (index < 2) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

class _ProfileContactTile extends StatelessWidget {
  const _ProfileContactTile({
    required this.contact,
    required this.query,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final NavivoxProfileContact contact;
  final String query;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ProfileContactPresentation(contact);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: 16.5,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    final previewStyle = theme.textTheme.bodyMedium?.copyWith(
      color: contact.activeTurnState == 'streaming'
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
      fontSize: 15,
      height: 1.15,
      fontStyle: contact.activeTurnState == 'streaming'
          ? FontStyle.italic
          : FontStyle.normal,
    );

    return ListTile(
      key: ValueKey('profile-contact-${contact.serverId}-${contact.profileId}'),
      selected: selected,
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      minVerticalPadding: 8,
      horizontalTitleGap: 12,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      leading: _ProfileContactAvatarStack(contact: contact),
      title: _ProfileSearchHighlightText(
        key: ValueKey(
          'profile-contact-title-${contact.serverId}-${contact.profileId}',
        ),
        text: contact.displayName,
        query: query,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: titleStyle,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: _ProfileSearchHighlightText(
              key: ValueKey(
                'profile-contact-preview-${contact.serverId}-${contact.profileId}',
              ),
              text: summary.chatListPreviewLabel,
              query: query,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: previewStyle,
            ),
          ),
          if (contact.activeTurnState == 'streaming') ...[
            Container(
              key: ValueKey(
                'profile-active-turn-${contact.serverId}-${contact.profileId}',
              ),
              margin: const EdgeInsets.only(left: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            _ProfileTypingDots(contact: contact),
          ],
        ],
      ),
      trailing: _ProfileContactTrailing(summary: summary, contact: contact),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class _ProfileContactTrailing extends StatelessWidget {
  const _ProfileContactTrailing({required this.summary, required this.contact});

  final ProfileContactPresentation summary;
  final NavivoxProfileContact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 52,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (summary.latestTimeLabel.isNotEmpty)
              Text(
                summary.latestTimeLabel,
                textAlign: TextAlign.right,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (contact.micAvailable)
                  Icon(
                    Icons.mic,
                    key: ValueKey(
                      'profile-contact-voice-${contact.serverId}-${contact.profileId}',
                    ),
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                if (summary.attentionCount > 0) ...[
                  if (contact.micAvailable) const SizedBox(width: 5),
                  _AttentionCountBadge(
                    key: ValueKey(
                      'profile-attention-${contact.serverId}-${contact.profileId}',
                    ),
                    count: summary.attentionCount,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _profileContactsMenuIcon(ProfileContactsMenuActionKind kind) {
  return switch (kind) {
    ProfileContactsMenuActionKind.manageGateways => Icons.dns_outlined,
    ProfileContactsMenuActionKind.manageProfiles => Icons.smart_toy_outlined,
    ProfileContactsMenuActionKind.openMemory => Icons.psychology_alt_outlined,
    ProfileContactsMenuActionKind.openConfig => Icons.settings_outlined,
    ProfileContactsMenuActionKind.openSettings => Icons.keyboard_voice_outlined,
  };
}

IconData _addProfileRowIcon(ProfileContactsAddRowKind kind) {
  return switch (kind) {
    ProfileContactsAddRowKind.newProfile => Icons.person_add_alt,
    ProfileContactsAddRowKind.addServer => Icons.dns,
  };
}

IconData _detailSectionIcon(ProfileContactDetailSectionKind kind) {
  return switch (kind) {
    ProfileContactDetailSectionKind.identity => Icons.badge_outlined,
    ProfileContactDetailSectionKind.channels => Icons.forum_outlined,
    ProfileContactDetailSectionKind.memory => Icons.psychology_alt_outlined,
    ProfileContactDetailSectionKind.skills => Icons.extension_outlined,
    ProfileContactDetailSectionKind.config =>
      Icons.settings_applications_outlined,
    ProfileContactDetailSectionKind.logs => Icons.article_outlined,
  };
}

IconData _detailActionIcon(ProfileContactDetailActionKind kind) {
  return switch (kind) {
    ProfileContactDetailActionKind.openChat => Icons.chat_bubble_outline,
    ProfileContactDetailActionKind.openMemory => Icons.psychology_alt_outlined,
    ProfileContactDetailActionKind.editProfile => Icons.edit,
  };
}

class _AttentionCountBadge extends StatelessWidget {
  const _AttentionCountBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$count attention ${count == 1 ? 'item' : 'items'}',
      child: Icon(Icons.error, size: 14, color: theme.colorScheme.error),
    );
  }
}
