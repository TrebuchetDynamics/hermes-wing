import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/wing_skeleton.dart';
import '../../../router/app_routes.dart';
import '../../hermes_chat/gateways/gateway_contact.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';

/// Accessible, contract-safe Office projection of saved gateway contacts.
///
/// The Office owns no agent state: profiles and session counts remain sourced
/// from [HermesGatewayDirectory], which itself falls back to one unscoped
/// default contact when a gateway lacks the exact profile-query contract.
class OfficeScreen extends ConsumerStatefulWidget {
  const OfficeScreen({super.key});

  @override
  ConsumerState<OfficeScreen> createState() => _OfficeScreenState();
}

class _OfficeScreenState extends ConsumerState<OfficeScreen> {
  final _searchController = TextEditingController();
  GatewayContactId? _openingId;
  String _query = '';
  bool _openFailed = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.officeTitle),
        actions: [
          IconButton(
            key: const ValueKey('office-refresh'),
            tooltip: strings.officeRefresh,
            onPressed: directory.refreshing
                ? null
                : () => unawaited(directory.refresh()),
            icon: directory.refreshing
                ? const SizedBox.square(
                    key: ValueKey('office-refresh-progress'),
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          const AppShellMenuButton(),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: directory,
          builder: (context, _) => Column(
            children: [
              if (_openFailed)
                MaterialBanner(
                  content: Semantics(
                    liveRegion: true,
                    child: Text(strings.officeOpenFailed),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _openFailed = false),
                      child: Text(strings.doneAction),
                    ),
                  ],
                ),
              Expanded(child: _buildBody(context, directory, strings)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    HermesGatewayDirectory directory,
    AppLocalizations strings,
  ) {
    final contacts = directory.contacts;
    final query = _safeOfficeText(_query, 96).toLowerCase();
    final visible = query.isEmpty
        ? contacts
        : contacts
              .where(
                (contact) =>
                    [
                      contact.profileName,
                      contact.gatewayLabel,
                      _availabilityLabel(strings, contact.availability),
                    ].any(
                      (value) => _safeOfficeText(
                        value,
                        160,
                      ).toLowerCase().contains(query),
                    ),
              )
              .toList(growable: false);

    if (contacts.isEmpty && directory.refreshing) {
      return WingSkeletonList(semanticLabel: strings.officeRefresh);
    }

    return RefreshIndicator(
      onRefresh: directory.refresh,
      child: ListView(
        key: const ValueKey('office-agent-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _OfficeHeader(subtitle: strings.officeSubtitle),
          if (contacts.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('office-agent-search'),
              controller: _searchController,
              decoration: InputDecoration(
                labelText: strings.officeSearchLabel,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: strings.officeClearSearch,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? strings.officeAgentCount(contacts.length)
                  : strings.officeShowingCount(visible.length, contacts.length),
              key: const ValueKey('office-agent-count'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (contacts.isEmpty)
            _OfficeEmptyState(strings: strings)
          else if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text(strings.officeNoMatches)),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 600
                    ? 2
                    : 1;
                const gap = 12.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final contact in visible)
                      SizedBox(
                        width: width,
                        child: _OfficeAgentCard(
                          contact: contact,
                          strings: strings,
                          current: directory.activeContactId == contact.id,
                          opening: _openingId == contact.id,
                          onOpen: () => unawaited(
                            _openContact(context, directory, contact.id),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _openContact(
    BuildContext context,
    HermesGatewayDirectory directory,
    GatewayContactId id,
  ) async {
    if (_openingId != null) return;
    setState(() {
      _openingId = id;
      _openFailed = false;
    });
    try {
      final channel = ref.read(hermesChannelProvider);
      if (directory.activeContactId != id || !channel.state.isConnected) {
        await directory.activate(id);
      }
      final connected = channel.state.isConnected;
      if (directory.activeContactId != id || !connected) {
        throw StateError('Hermes profile activation did not connect.');
      }
      if (!context.mounted) return;
      context.go(AppRoutes.hermes);
    } catch (_) {
      if (mounted) setState(() => _openFailed = true);
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }
}

class _OfficeHeader extends StatelessWidget {
  const _OfficeHeader({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colors.primaryContainer,
              child: Icon(Icons.apartment_outlined, color: colors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(subtitle)),
          ],
        ),
      ),
    );
  }
}

class _OfficeAgentCard extends StatelessWidget {
  const _OfficeAgentCard({
    required this.contact,
    required this.strings,
    required this.current,
    required this.opening,
    required this.onOpen,
  });

  final GatewayContact contact;
  final AppLocalizations strings;
  final bool current;
  final bool opening;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = _safeOfficeText(contact.profileName, 96);
    final gateway = _safeOfficeText(contact.gatewayLabel, 96);
    final status = _availabilityLabel(strings, contact.availability);
    final online = contact.availability == GatewayAvailability.online;
    final statusIcon = switch (contact.availability) {
      GatewayAvailability.online => Icons.check_circle_outline,
      GatewayAvailability.refreshing => Icons.sync,
      GatewayAvailability.authenticationFailed => Icons.lock_outline,
      GatewayAvailability.offline => Icons.cloud_off_outlined,
    };
    return Semantics(
      label:
          '$name, $gateway, $status, ${strings.officeSessionCount(contact.sessionCount)}',
      child: Card(
        key: ValueKey(
          'office-agent-${contact.id.gatewayId}-${contact.id.profileId}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: colors.secondaryContainer,
                    foregroundColor: colors.onSecondaryContainer,
                    child: Text(_initial(name)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gateway,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      statusIcon,
                      size: 18,
                      color: online ? colors.primary : colors.onSurfaceVariant,
                    ),
                    label: Text(status),
                  ),
                  Chip(
                    avatar: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(
                      strings.officeSessionCount(contact.sessionCount),
                    ),
                  ),
                  if (contact.isFallbackProfile)
                    Chip(label: Text(strings.officeGatewayDefault)),
                  if (!contact.chatAvailable)
                    Chip(label: Text(strings.officeProfileManagementOnly)),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                key: ValueKey(
                  'office-open-${contact.id.gatewayId}-${contact.id.profileId}',
                ),
                onPressed: opening || !contact.chatAvailable ? null : onOpen,
                icon: opening
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        current
                            ? Icons.arrow_forward
                            : Icons.chat_bubble_outline,
                      ),
                label: Text(
                  !contact.chatAvailable
                      ? strings.officeProfileManagementOnly
                      : current
                      ? strings.officeReturnToChat
                      : strings.officeOpenChat,
                ),
              ),
              if (current) ...[
                const SizedBox(height: 8),
                Text(
                  strings.officeCurrentChat,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficeEmptyState extends StatelessWidget {
  const _OfficeEmptyState({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
    child: Column(
      children: [
        const Icon(Icons.apartment_outlined, size: 48),
        const SizedBox(height: 16),
        Text(
          strings.officeNoAgentsTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(strings.officeNoAgentsBody, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () => context.go(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
          label: Text(strings.officeOpenSettings),
        ),
      ],
    ),
  );
}

String _availabilityLabel(
  AppLocalizations strings,
  GatewayAvailability availability,
) => switch (availability) {
  GatewayAvailability.online => strings.officeStatusOnline,
  GatewayAvailability.offline => strings.officeStatusOffline,
  GatewayAvailability.refreshing => strings.officeStatusRefreshing,
  GatewayAvailability.authenticationFailed =>
    strings.officeStatusAuthenticationFailed,
};

String _safeOfficeText(String value, int maximumLength) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.length <= maximumLength) return normalized;
  return '${normalized.substring(0, maximumLength - 1)}…';
}

String _initial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}
