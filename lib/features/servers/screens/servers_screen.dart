import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../../router/app_routes.dart';
import '../../profile_contacts/profile_contact_avatar.dart';
import '../registration/register_gateway_presentation.dart';
import '../overview/servers_screen_presentation.dart';

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(navivoxChannelProvider).state;
    final presentation = ServersScreenPresentation.fromState(state);

    return Scaffold(
      appBar: AppBar(title: const Text('Gateways')),
      body: !presentation.hasGateways
          ? const Center(child: Text('No gateways registered'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: presentation.gateways.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final gateway = presentation.gateways[index];
                return _ServerCard(
                  gateway: gateway,
                  onManage: () => _showManageGateway(
                    context,
                    ref.read(navivoxChannelProvider),
                    gateway,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Register gateway',
        onPressed: () =>
            _showRegisterGateway(context, ref.read(navivoxChannelProvider)),
        icon: const Icon(Icons.add_link),
        label: const Text('Register'),
      ),
    );
  }

  void _showManageGateway(
    BuildContext context,
    NavivoxChannel channel,
    ServerGatewayPresentation gateway,
  ) {
    final server = gateway.server;
    final parentContext = context;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              gateway.manageTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dns),
              title: Text(server.name),
              subtitle: Text(server.status),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tag),
              title: Text(gateway.serverIdTitle),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 12),
              child: SelectableText(server.id),
            ),
            if (gateway.activeProfileLabel != null) ...[
              const Divider(),
              ListTile(
                key: ValueKey('server-active-profile-${server.id}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined),
                title: Text(gateway.activeProfileTitle),
                subtitle: Text(gateway.activeProfileLabel!),
              ),
            ],
            if (gateway.showDisconnectAction) ...[
              const Divider(),
              ListTile(
                key: const ValueKey('server-disconnect-current'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_off),
                title: Text(gateway.disconnectActionTitle),
                subtitle: Text(gateway.disconnectActionSubtitle),
                onTap: () => _confirmDisconnect(context, channel, gateway),
              ),
            ],
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.people_alt_outlined),
              title: Text(gateway.profilesSectionTitle),
            ),
            if (gateway.profileContacts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Text(gateway.emptyProfilesLabel),
              )
            else
              for (final profile in gateway.profileContacts)
                ListTile(
                  key: ValueKey(
                    'server-profile-${profile.contact.serverId}-${profile.contact.profileId}',
                  ),
                  contentPadding: EdgeInsets.zero,
                  leading: ProfileContactAvatar(contact: profile.contact),
                  title: Text(profile.contact.displayName),
                  subtitle: Text(profile.contact.profileId),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HealthPill(label: profile.compactHealthLabel),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    channel.selectProfileContact(
                      serverId: profile.contact.serverId,
                      profileId: profile.contact.profileId,
                    );
                    GoRouter.maybeOf(parentContext)?.go(
                      AppRoutes.chatLocation(
                        serverId: profile.contact.serverId,
                        profileId: profile.contact.profileId,
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    NavivoxChannel channel,
    ServerGatewayPresentation gateway,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(gateway.disconnectDialogTitle),
        content: Text(gateway.disconnectDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(gateway.disconnectCancelLabel),
          ),
          FilledButton(
            key: const ValueKey('server-disconnect-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(gateway.disconnectConfirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await channel.disconnect();
      if (!context.mounted) return;
      await Navigator.of(context).maybePop();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(gateway.disconnectedMessage)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(gateway.disconnectFailedMessage(error))),
        );
    }
  }

  void _showRegisterGateway(BuildContext context, NavivoxChannel channel) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _RegisterGatewaySheet(channel: channel),
    );
  }
}

class _RegisterGatewaySheet extends StatefulWidget {
  const _RegisterGatewaySheet({required this.channel});

  final NavivoxChannel channel;

  @override
  State<_RegisterGatewaySheet> createState() => _RegisterGatewaySheetState();
}

class _RegisterGatewaySheetState extends State<_RegisterGatewaySheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _testing = false;

  @override
  void dispose() {
    _labelController.dispose();
    _baseUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final presentation = RegisterGatewayPresentation(testing: _testing);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_link),
                title: Text(presentation.title),
                subtitle: Text(presentation.instructions),
              ),
              TextFormField(
                key: const ValueKey('register-gateway-label'),
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: presentation.gatewayLabelFieldLabel,
                  helperText: presentation.gatewayLabelHelperText,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('register-gateway-base-url'),
                controller: _baseUrlController,
                decoration: InputDecoration(
                  labelText: presentation.baseUrlFieldLabel,
                  hintText: presentation.baseUrlHintText,
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: presentation.validateBaseUrl,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('register-gateway-token'),
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: presentation.tokenFieldLabel,
                  helperText: presentation.tokenHelperText,
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const ValueKey('register-gateway-test'),
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check),
                  label: Text(presentation.testButtonLabel),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: Text(presentation.boundaryTitle),
                subtitle: Text(presentation.boundarySubtitle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    const presentation = RegisterGatewayPresentation();
    final request = presentation.connectRequest(
      baseUrl: _baseUrlController.text,
      token: _tokenController.text,
    );
    setState(() => _testing = true);
    try {
      await widget.channel.connect(
        baseUrl: request.baseUrl,
        token: request.token,
      );
      if (!mounted) return;
      _showSnackBar(presentation.connectionPassedMessage(request));
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(presentation.connectionFailedMessage(error));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(duration: const Duration(seconds: 8), content: Text(message)),
      );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.gateway, required this.onManage});

  final ServerGatewayPresentation gateway;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final server = gateway.server;
    return Card(
      key: ValueKey('server-card-${server.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(gateway.active ? Icons.hub : Icons.dns),
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
                        gateway.statusSubtitle,
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
                for (final label in gateway.countLabels)
                  _CountChip(label: label),
              ],
            ),
          ],
        ),
      ),
    );
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
  const _HealthPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.labelSmall);
  }
}
