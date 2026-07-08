import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/policy/hermes_transport_policy.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../router/app_routes.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../../voice/services/tts/text_to_speech_service.dart';
import '../providers/voice_settings_provider.dart';
import '../presentation/settings_screen_presentation.dart';

const _settingsPresentation = SettingsScreenPresentation();

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(navivoxVoiceSettingsProvider);
    final controller = ref.read(navivoxVoiceSettingsProvider.notifier);
    final channel = ref.watch(hermesChannelProvider);
    final savedEndpoint = ref.watch(_savedHermesEndpointProvider);
    final kokoroDownloader = ref.watch(_kokoroAssetDownloadServiceProvider);
    final kokoroDownloading = ref.watch(_kokoroAssetDownloadingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_settingsPresentation.title)),
      body: AnimatedBuilder(
        animation: channel,
        builder: (context, _) {
          final state = channel.state;
          return ListView(
            scrollCacheExtent: const ScrollCacheExtent.pixels(1600),
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsHeader(
                title: 'Hermes Agent dashboard',
                subtitle:
                    'Status, connection, appearance, and local voice controls for this Navivox companion.',
              ),
              _SettingsSectionCard(
                title: 'Hermes Agent',
                icon: Icons.auto_awesome,
                children: [
                  _StatusTile(
                    icon: Icons.circle,
                    title: 'Status',
                    value: _connectionStatusLabel(state.status),
                  ),
                  _StatusTile(
                    icon: Icons.memory_outlined,
                    title: 'Model',
                    value: state.models.isEmpty
                        ? state.capabilities?.model ?? 'Not reported'
                        : state.models.first,
                  ),
                  _StatusTile(
                    icon: Icons.account_tree_outlined,
                    title: 'Run transport',
                    value: _runTransportLabel(state),
                  ),
                  _StatusTile(
                    icon: Icons.info_outline,
                    title: 'Version / health',
                    value: _healthLabel(state),
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: 'Connection',
                icon: Icons.cable_outlined,
                children: [
                  savedEndpoint.when(
                    data: (endpoint) => _StatusTile(
                      icon: Icons.link,
                      title: 'Endpoint',
                      value:
                          state.connectedBaseUrl ??
                          endpoint?.baseUrl ??
                          'No saved Hermes endpoint',
                    ),
                    loading: () => const _StatusTile(
                      icon: Icons.link,
                      title: 'Endpoint',
                      value: 'Loading…',
                    ),
                    error: (_, _) => const _StatusTile(
                      icon: Icons.link_off,
                      title: 'Endpoint',
                      value: 'Could not read saved endpoint',
                    ),
                  ),
                  savedEndpoint.when(
                    data: (endpoint) => _StatusTile(
                      icon: Icons.key_outlined,
                      title: 'Authentication',
                      value: state.connectedWithApiKey
                          ? 'API key present; value hidden'
                          : endpoint?.apiKey?.trim().isNotEmpty == true
                          ? 'API key saved securely; value hidden'
                          : 'No API key saved',
                    ),
                    loading: () => const _StatusTile(
                      icon: Icons.key_outlined,
                      title: 'Authentication',
                      value: 'Loading…',
                    ),
                    error: (_, _) => const _StatusTile(
                      icon: Icons.key_off_outlined,
                      title: 'Authentication',
                      value: 'Unknown',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        key: const ValueKey('settings-open-hermes'),
                        onPressed: () => context.go(AppRoutes.hermes),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Hermes'),
                      ),
                    ),
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: 'Appearance',
                icon: Icons.palette_outlined,
                children: const [
                  _StatusTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Desktop/tablet',
                    value: 'Hermes Dark shell with branded rail',
                  ),
                  _StatusTile(
                    icon: Icons.chat_bubble_outline,
                    title: 'Mobile',
                    value: 'Telegram Light ergonomics and bottom composer',
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: 'Diagnostics',
                icon: Icons.monitor_heart_outlined,
                children: [
                  _StatusTile(
                    icon: Icons.checklist_outlined,
                    title: 'Inventory',
                    value:
                        '${state.models.length} models • ${state.skills.length} skills • ${state.enabledToolsets.length} toolsets • ${state.jobs.length} jobs',
                  ),
                  _StatusTile(
                    icon: Icons.chat_outlined,
                    title: 'Sessions',
                    value:
                        '${state.sessions.length} sessions • active ${state.activeSessionId == null ? 'none' : 'yes'}',
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: _settingsPresentation.localVoiceSectionTitle,
                icon: Icons.keyboard_voice_outlined,
                children: [
                  ListTile(
                    key: const ValueKey('settings-local-voice-section'),
                    title: Text(_settingsPresentation.localVoiceSectionTitle),
                    subtitle: Text(
                      _settingsPresentation.localVoiceSectionSubtitle,
                    ),
                  ),
                  _ConstrainedSettingsTile(
                    child: SwitchListTile(
                      key: const ValueKey('voice-continuous-enabled'),
                      title: Text(_settingsPresentation.continuousVoiceTitle),
                      subtitle: Text(
                        _settingsPresentation.continuousVoiceSubtitle,
                      ),
                      value: settings.continuousVoiceEnabled,
                      onChanged: controller.setContinuousVoiceEnabled,
                    ),
                  ),
                  _ConstrainedSettingsTile(
                    child: SwitchListTile(
                      key: const ValueKey('voice-speak-replies-enabled'),
                      title: Text(_settingsPresentation.speakRepliesTitle),
                      subtitle: Text(
                        _settingsPresentation.speakRepliesSubtitle,
                      ),
                      value: settings.speakRepliesEnabled,
                      onChanged: controller.setSpeakRepliesEnabled,
                    ),
                  ),
                  _ConstrainedSettingsTile(
                    child: SwitchListTile(
                      key: const ValueKey('voice-kokoro-tts-enabled'),
                      title: const Text('Kokoro offline TTS'),
                      subtitle: Text(
                        settings.kokoroAssetsReady
                            ? 'Use downloaded Kokoro voice pack for spoken replies'
                            : 'Download Kokoro assets before enabling',
                      ),
                      value: settings.kokoroTtsEnabled,
                      onChanged: settings.kokoroAssetsReady
                          ? controller.setKokoroTtsEnabled
                          : null,
                    ),
                  ),
                  ListTile(
                    key: const ValueKey('voice-kokoro-assets'),
                    leading: const Icon(Icons.download_for_offline_outlined),
                    title: const Text('Download Kokoro assets'),
                    subtitle: Text(
                      settings.kokoroAssetsReady
                          ? 'Ready: ${settings.kokoroModelPath}'
                          : kokoroDownloader == null
                          ? 'Build with KOKORO_MODEL_URL and KOKORO_VOICES_JSON_URL to enable downloads'
                          : 'Large optional voice pack; use Wi-Fi',
                    ),
                    trailing: kokoroDownloading
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : FilledButton(
                            onPressed: kokoroDownloader == null
                                ? null
                                : () => _downloadKokoroAssets(
                                    context,
                                    ref,
                                    controller,
                                    kokoroDownloader,
                                  ),
                            child: const Text('Download'),
                          ),
                  ),
                  ListTile(
                    key: const ValueKey('settings-command-word'),
                    title: Text(_settingsPresentation.commandWordTitle),
                    subtitle: Text(settings.commandWord),
                    trailing: const Icon(Icons.keyboard_voice),
                    onTap: () =>
                        _showCommandWordSheet(context, settings.commandWord),
                  ),
                  _ConstrainedSettingsTile(
                    child: SwitchListTile(
                      key: const ValueKey('voice-profile-switching-enabled'),
                      title: Text(_settingsPresentation.profileSwitchingTitle),
                      subtitle: Text(
                        _settingsPresentation.profileSwitchingSubtitle,
                      ),
                      value: settings.profileSwitchingEnabled,
                      onChanged: controller.setProfileSwitchingEnabled,
                    ),
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

final _savedHermesEndpointProvider = FutureProvider<HermesEndpointConfig?>(
  (ref) => ref.watch(hermesEndpointStoreProvider).load(),
);

final _kokoroAssetDownloadServiceProvider =
    Provider<KokoroAssetDownloadService?>(
      (_) => createDefaultKokoroAssetDownloadService(),
    );

class _KokoroAssetDownloadingController extends Notifier<bool> {
  @override
  bool build() => false;

  void setDownloading(bool value) => state = value;
}

final _kokoroAssetDownloadingProvider =
    NotifierProvider<_KokoroAssetDownloadingController, bool>(
      _KokoroAssetDownloadingController.new,
    );

Future<void> _downloadKokoroAssets(
  BuildContext context,
  WidgetRef ref,
  NavivoxVoiceSettingsController controller,
  KokoroAssetDownloadService downloader,
) async {
  final downloading = ref.read(_kokoroAssetDownloadingProvider.notifier);
  downloading.setDownloading(true);
  try {
    final location = await downloader.download();
    controller.setKokoroAssets(
      modelPath: location.modelPath,
      voicesPath: location.voicesPath,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kokoro assets downloaded')));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not download Kokoro assets')),
      );
    }
  } finally {
    downloading.setDownloading(false);
  }
}

String _connectionStatusLabel(HermesConnectionStatus status) =>
    switch (status) {
      HermesConnectionStatus.disconnected => 'Disconnected',
      HermesConnectionStatus.connecting => 'Connecting',
      HermesConnectionStatus.connected => 'Connected',
      HermesConnectionStatus.error => 'Error',
    };

String _runTransportLabel(HermesChannelState state) {
  final capabilities = state.capabilities;
  if (capabilities == null) return 'Not connected';
  final policy = HermesTransportPolicy(capabilities);
  if (policy.supportsRunsTransport) return 'Runs SSE enabled';
  if (policy.supportsSessionChatStream) return 'Session chat streaming';
  return 'Unavailable';
}

String _healthLabel(HermesChannelState state) {
  final health = state.detailedHealth;
  if (health == null) return state.errorMessage ?? 'No health details yet';
  final version = health.version ?? 'unknown version';
  final gateway = health.gatewayState ?? 'unknown gateway';
  return '$version • $gateway';
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
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

class _ConstrainedSettingsTile extends StatelessWidget {
  const _ConstrainedSettingsTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: child,
    );
  }
}

Future<void> _showCommandWordSheet(
  BuildContext context,
  String commandWord,
) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Command word', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(commandWord, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Say this before local voice commands when continuous voice is enabled.',
            ),
          ],
        ),
      ),
    ),
  );
}
