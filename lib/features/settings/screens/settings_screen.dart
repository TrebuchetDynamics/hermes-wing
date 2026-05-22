import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/channel/navivox_channel_provider.dart';
import '../../../router/app_routes.dart';
import '../providers/voice_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(navivoxChannelProvider);
    final settings = ref.watch(navivoxVoiceSettingsProvider);
    final controller = ref.read(navivoxVoiceSettingsProvider.notifier);
    final activeServer = channel.state.activeServer;
    final activeServerTrusted =
        activeServer != null && settings.isTrusted(activeServer.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Voice settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.settings_applications),
            title: Text('Global app settings'),
            subtitle: Text(
              'Voice controls stay local to this app. Gateway and profile settings live in their own screens.',
            ),
          ),
          ListTile(
            key: const ValueKey('settings-manage-gateways'),
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Manage gateways'),
            subtitle: const Text(
              'Add, test, edit, and remove Gormes gateway connections.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.servers),
          ),
          ListTile(
            key: const ValueKey('settings-manage-profiles'),
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Manage profile contacts'),
            subtitle: const Text(
              'Create, refresh, edit, or select profiles from the Agents tab.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.agents),
          ),
          const Divider(),
          SwitchListTile(
            key: const ValueKey('voice-continuous-enabled'),
            title: const Text('Continuous voice'),
            subtitle: const Text('Use local device STT for the active profile'),
            value: settings.continuousVoiceEnabled,
            onChanged: controller.setContinuousVoiceEnabled,
          ),
          ListTile(
            title: const Text('Command word'),
            subtitle: Text(settings.commandWord),
            trailing: const Icon(Icons.keyboard_voice),
          ),
          SwitchListTile(
            key: const ValueKey('voice-profile-switching-enabled'),
            title: const Text('Voice profile switching'),
            subtitle: const Text('Allow local command-word profile switches'),
            value: settings.profileSwitchingEnabled,
            onChanged: controller.setProfileSwitchingEnabled,
          ),
          if (activeServer != null)
            SwitchListTile(
              key: ValueKey('voice-trust-${activeServer.id}'),
              title: Text('Trust ${activeServer.name} for voice'),
              subtitle: const Text('Local-only trust, not server config'),
              value: activeServerTrusted,
              onChanged: (trusted) =>
                  controller.setServerTrusted(activeServer.id, trusted),
            ),
        ],
      ),
    );
  }
}
