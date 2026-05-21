import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/protocol/navivox_memory.dart';

final memoryOverviewProvider =
    FutureProvider.autoDispose<NavivoxMemoryOverview>((ref) {
      final channel = ref.watch(navivoxChannelProvider);
      final activeProfile = channel.state.activeProfileContact;
      return channel.memoryOverview(
        serverId: activeProfile?.serverId,
        profileId: activeProfile?.profileId,
      );
    });

class MemoryDashboardScreen extends ConsumerWidget {
  const MemoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(navivoxChannelProvider);
    final activeProfile = channel.state.activeProfileContact;
    final overview = ref.watch(memoryOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Memory')),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _MemoryError(
          profileLabel: _profileLabel(activeProfile, fallback: 'default'),
          message: 'Gormes memory API is unavailable.',
        ),
        data: (overview) => _MemoryOverviewBody(
          overview: overview,
          profileLabel: _profileLabel(
            activeProfile,
            fallback: overview.profileId,
          ),
        ),
      ),
    );
  }
}

class _MemoryOverviewBody extends StatelessWidget {
  const _MemoryOverviewBody({
    required this.overview,
    required this.profileLabel,
  });

  final NavivoxMemoryOverview overview;
  final String profileLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      overview.isActive
                          ? Icons.psychology_alt
                          : Icons.warning_amber_outlined,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        overview.healthLabel,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Profile: $profileLabel'),
                if (overview.workspaceId.isNotEmpty)
                  Text('Workspace: ${overview.workspaceId}'),
                const Text('Database'),
                SelectableText(overview.databaseLabel),
                if (overview.lastUpdatedAt != null)
                  Text(
                    'Last updated: ${overview.lastUpdatedAt!.toUtc().toIso8601String()}',
                  ),
                if (overview.degradedReason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    overview.degradedReason,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MemoryCountCard(label: 'Turns', count: overview.totalTurns),
            _MemoryCountCard(
              label: 'Active memory items',
              count: overview.activeMemoryItems,
            ),
            _MemoryCountCard(
              label: 'Observations',
              count: overview.observations,
            ),
            _MemoryCountCard(label: 'Conclusions', count: overview.conclusions),
            _MemoryCountCard(
              label: 'Session summaries',
              count: overview.sessionSummaries,
            ),
            _MemoryCountCard(label: 'Entities', count: overview.entities),
            _MemoryCountCard(
              label: 'Relationships',
              count: overview.relationships,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _MemorySearchSection(),
      ],
    );
  }
}

class _MemorySearchSection extends ConsumerStatefulWidget {
  const _MemorySearchSection();

  @override
  ConsumerState<_MemorySearchSection> createState() =>
      _MemorySearchSectionState();
}

class _MemorySearchSectionState extends ConsumerState<_MemorySearchSection> {
  String _query = '';
  NavivoxMemoryType _selectedType = NavivoxMemoryType.all;
  late Future<NavivoxMemorySearchResult> _results;

  @override
  void initState() {
    super.initState();
    _results = _load();
  }

  Future<NavivoxMemorySearchResult> _load() {
    final channel = ref.read(navivoxChannelProvider);
    final activeProfile = channel.state.activeProfileContact;
    return channel.memorySearch(
      serverId: activeProfile?.serverId,
      profileId: activeProfile?.profileId,
      query: _query,
      type: _selectedType,
      limit: 20,
    );
  }

  void _refresh({String? query, NavivoxMemoryType? type}) {
    setState(() {
      if (query != null) _query = query.trim();
      if (type != null) _selectedType = type;
      _results = _load();
    });
  }

  void _showMemoryDetail(BuildContext context, NavivoxMemoryItem item) {
    final channel = ref.read(navivoxChannelProvider);
    final activeProfile = channel.state.activeProfileContact;
    final detail = channel.memoryDetail(
      serverId: activeProfile?.serverId,
      profileId: activeProfile?.profileId,
      id: item.id,
      type: item.type,
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _MemoryDetailSheet(detail: detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search & Browse',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search memories',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _refresh(query: value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final type in NavivoxMemoryType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: _selectedType == type,
                    onSelected: (_) => _refresh(type: type),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<NavivoxMemorySearchResult>(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const _MemorySearchMessage(
                    icon: Icons.warning_amber_outlined,
                    message: 'Gormes memory search API is unavailable.',
                  );
                }
                final result =
                    snapshot.data ??
                    const NavivoxMemorySearchResult.degraded(
                      reason: 'Gormes memory search API is unavailable.',
                    );
                if (result.isDegraded) {
                  return _MemorySearchMessage(
                    icon: Icons.warning_amber_outlined,
                    message: result.degradedReason,
                  );
                }
                if (result.items.isEmpty) {
                  return const _MemorySearchMessage(
                    icon: Icons.manage_search,
                    message: 'No memories found.',
                  );
                }
                return Column(
                  children: [
                    for (final item in result.items)
                      _MemoryItemCard(
                        item: item,
                        onTap: () => _showMemoryDetail(context, item),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryItemCard extends StatelessWidget {
  const _MemoryItemCard({required this.item, required this.onTap});

  final NavivoxMemoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      item.type.wireValue,
      item.status,
      item.sessionId,
      item.peerId,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    return Card.outlined(
      key: ValueKey('memory-item-${item.type.wireValue}-${item.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        title: Text(item.snippet),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (metadata.isNotEmpty) Text(metadata),
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in item.tags)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(tag),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemoryDetailSheet extends ConsumerWidget {
  const _MemoryDetailSheet({required this.detail});

  final Future<NavivoxMemoryDetail> detail;

  Future<void> _requestAction(
    BuildContext context,
    WidgetRef ref,
    NavivoxMemoryDetail item,
    NavivoxMemoryActionType action, {
    String? correction,
  }) async {
    final channel = ref.read(navivoxChannelProvider);
    final activeProfile = channel.state.activeProfileContact;
    final result = await channel.memoryAction(
      serverId: activeProfile?.serverId,
      profileId: activeProfile?.profileId,
      id: item.id,
      type: item.type,
      action: action,
      correction: correction,
    );
    if (!context.mounted) return;
    final message = result.isDegraded
        ? result.degradedReason
        : result.message.trim().isEmpty
        ? '${action.label} requested.'
        : result.message;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestCorrection(
    BuildContext context,
    WidgetRef ref,
    NavivoxMemoryDetail item,
  ) async {
    var note = '';
    final correction = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add correction'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Correction note',
            helperText: 'Adds a superseding note; raw source is preserved.',
          ),
          maxLines: 3,
          onChanged: (value) => note = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(note),
            child: const Text('Save correction'),
          ),
        ],
      ),
    );
    final trimmed = correction?.trim();
    if (trimmed == null || trimmed.isEmpty || !context.mounted) return;
    await _requestAction(
      context,
      ref,
      item,
      NavivoxMemoryActionType.addCorrection,
      correction: trimmed,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: FutureBuilder<NavivoxMemoryDetail>(
        future: detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = snapshot.data;
          if (snapshot.hasError || item == null || item.isDegraded) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                item?.degradedReason ??
                    'Gormes memory detail API is unavailable.',
              ),
            );
          }
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(
                'Memory detail',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SelectableText(item.content),
              const SizedBox(height: 12),
              _DetailLine(label: 'Type', value: item.type.wireValue),
              _DetailLine(label: 'Source', value: item.source),
              _DetailLine(label: 'Session', value: item.sessionId),
              _DetailLine(label: 'Peer', value: item.peerId),
              _DetailLine(label: 'Status', value: item.status),
              _DetailLine(label: 'Created', value: item.createdAt),
              if (item.provenance.isNotEmpty) ...[
                const Divider(),
                Text(
                  'Provenance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SelectableText(item.provenance),
              ],
              if (item.linkedEntities.isNotEmpty) ...[
                const Divider(),
                Text(
                  'Linked entities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final entity in item.linkedEntities) Text(entity),
              ],
              if (item.linkedRelationships.isNotEmpty) ...[
                const Divider(),
                Text(
                  'Linked relationships',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final relationship in item.linkedRelationships)
                  Text(relationship),
              ],
              const Divider(),
              const Text('Raw source preserved'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _requestAction(
                      context,
                      ref,
                      item,
                      NavivoxMemoryActionType.pin,
                    ),
                    child: const Text('Pin'),
                  ),
                  OutlinedButton(
                    onPressed: () => _requestAction(
                      context,
                      ref,
                      item,
                      NavivoxMemoryActionType.archive,
                    ),
                    child: const Text('Archive'),
                  ),
                  OutlinedButton(
                    onPressed: () => _requestAction(
                      context,
                      ref,
                      item,
                      NavivoxMemoryActionType.markStale,
                    ),
                    child: const Text('Mark stale'),
                  ),
                  OutlinedButton(
                    onPressed: () => _requestCorrection(context, ref, item),
                    child: const Text('Add correction'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Text('$label: $value');
  }
}

class _MemorySearchMessage extends StatelessWidget {
  const _MemorySearchMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _MemoryCountCard extends StatelessWidget {
  const _MemoryCountCard({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryError extends StatelessWidget {
  const _MemoryError({required this.profileLabel, required this.message});

  final String profileLabel;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              'Goncho degraded',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Profile: $profileLabel'),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _profileLabel(
  NavivoxProfileContact? contact, {
  required String fallback,
}) {
  final displayName = contact?.displayName.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;
  return fallback;
}
