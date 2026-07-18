import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_speech/pocket_speech.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/policy/hermes_transport_policy.dart';
import '../../../router/app_routes.dart';
import '../../hermes_chat/diagnostics/hermes_diagnostics_export.dart';
import '../../hermes_chat/gateways/gateway_contact.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../../voice/services/tts/text_to_speech_service.dart';
import '../presentation/settings_screen_presentation.dart';
import '../providers/voice_settings_provider.dart';

part 'settings_diagnostics_screen.dart';
part 'settings_voice_screen.dart';

const _settingsPresentation = SettingsScreenPresentation();

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(wingVoiceSettingsProvider);
    final controller = ref.read(wingVoiceSettingsProvider.notifier);
    final channel = ref.watch(hermesChannelProvider);
    final gatewayDirectory = ref.watch(hermesGatewayDirectoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_settingsPresentation.title)),
      body: AnimatedBuilder(
        animation: channel,
        builder: (context, _) {
          final state = channel.state;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsSectionCard(
                title: 'Gateways',
                icon: Icons.cable_outlined,
                children: [
                  if (gatewayDirectory.gateways.isEmpty)
                    const _StatusTile(
                      icon: Icons.link_off,
                      title: 'Gateways',
                      value: 'No saved Hermes gateways',
                    )
                  else
                    for (final gateway in gatewayDirectory.gateways)
                      _GatewaySettingsTile(
                        gateway: gateway,
                        directory: gatewayDirectory,
                      ),
                  ListTile(
                    key: const ValueKey('settings-connect-another-gateway'),
                    leading: const Icon(Icons.add_link),
                    title: const Text('Connect another gateway'),
                    subtitle: const Text('Scan a Hermes pairing QR code'),
                    onTap: () => context.push(AppRoutes.enroll),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Credentials stay in secure storage; values hidden',
                    ),
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: 'Voice',
                icon: Icons.keyboard_voice_outlined,
                children: [
                  SwitchListTile(
                    key: const ValueKey('voice-continuous-enabled'),
                    title: Text(_settingsPresentation.continuousVoiceTitle),
                    subtitle: Text(
                      _settingsPresentation.continuousVoiceSubtitle,
                    ),
                    value: settings.continuousVoiceEnabled,
                    onChanged: controller.setContinuousVoiceEnabled,
                  ),
                  SwitchListTile(
                    key: const ValueKey('voice-speak-replies-enabled'),
                    title: Text(_settingsPresentation.speakRepliesTitle),
                    subtitle: Text(_settingsPresentation.speakRepliesSubtitle),
                    value: settings.speakRepliesEnabled,
                    onChanged: controller.setSpeakRepliesEnabled,
                  ),
                  ListTile(
                    key: const ValueKey('settings-voice-link'),
                    leading: const Icon(Icons.graphic_eq),
                    title: const Text('Voice & speech'),
                    subtitle: Text(
                      '${settings.pocketSpeechModel.label} • '
                      '${settings.pocketSpeechVoicePackReady ? 'installed' : 'not installed'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.settingsVoice),
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: 'Diagnostics',
                icon: Icons.monitor_heart_outlined,
                children: [
                  ListTile(
                    key: const ValueKey('settings-diagnostics-link'),
                    leading: const Icon(Icons.monitor_heart_outlined),
                    title: const Text('Diagnostics'),
                    subtitle: Text(_connectionStatusLabel(state.status)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.settingsDiagnostics),
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

class _GatewaySettingsTile extends StatelessWidget {
  const _GatewaySettingsTile({required this.gateway, required this.directory});

  final GatewayOverview gateway;
  final HermesGatewayDirectory directory;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        gateway.availability == GatewayAvailability.online
            ? Icons.cloud_done_outlined
            : Icons.cloud_off_outlined,
      ),
      title: Text(gateway.label),
      subtitle: Text('${gateway.baseUrl} · ${gateway.availability.name}'),
      trailing: PopupMenuButton<String>(
        key: ValueKey('settings-gateway-menu-${gateway.id}'),
        onSelected: (action) async {
          if (action == 'agents') {
            await _runGatewayAction(context, () async {
              await directory.activateGateway(gateway.id);
              if (context.mounted) context.go(AppRoutes.agents);
            }, 'Could not connect to this gateway.');
          } else if (action == 'rename') {
            await _renameGateway(context, directory, gateway);
          } else if (action == 'reconnect') {
            await _runGatewayAction(
              context,
              () => directory.reconnectGateway(gateway.id),
              'Could not reconnect gateway.',
            );
          } else if (action == 'remove') {
            await _removeGateway(context, directory, gateway);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'agents', child: Text('Manage agents')),
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(value: 'reconnect', child: Text('Reconnect')),
          PopupMenuItem(value: 'remove', child: Text('Remove')),
        ],
      ),
    );
  }
}

Future<void> _renameGateway(
  BuildContext context,
  HermesGatewayDirectory directory,
  GatewayOverview gateway,
) async {
  var draftLabel = gateway.label;
  final label = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Rename gateway'),
      content: TextFormField(
        key: const ValueKey('settings-gateway-rename-field'),
        initialValue: gateway.label,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Gateway name'),
        onChanged: (value) => draftLabel = value,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, draftLabel),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (label == null || !context.mounted) return;
  await _runGatewayAction(
    context,
    () => directory.renameGateway(gateway.id, label),
    'Could not rename gateway.',
  );
}

Future<void> _removeGateway(
  BuildContext context,
  HermesGatewayDirectory directory,
  GatewayOverview gateway,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('settings-gateway-remove-dialog'),
      title: const Text('Remove gateway?'),
      content: Text(
        'Remove ${gateway.label} and its saved credential from this device?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('settings-gateway-remove-confirm'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await _runGatewayAction(
    context,
    () => directory.removeGateway(gateway.id),
    'Could not remove gateway.',
  );
}

Future<void> _runGatewayAction(
  BuildContext context,
  Future<void> Function() action,
  String errorMessage,
) async {
  try {
    await action();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      dense: true,
    );
  }
}
