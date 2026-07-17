import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_speech/pocket_speech.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/policy/hermes_transport_policy.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../router/app_routes.dart';
import '../../hermes_chat/diagnostics/hermes_diagnostics_export.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../../needle_spike/needle_spike_flag.dart';
import '../../voice/services/tts/text_to_speech_service.dart';
import '../../voice_commands/providers/voice_command_providers.dart';
import '../providers/voice_settings_provider.dart';
import '../presentation/settings_screen_presentation.dart';

const _settingsPresentation = SettingsScreenPresentation();

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(wingVoiceSettingsProvider);
    final controller = ref.read(wingVoiceSettingsProvider.notifier);
    final channel = ref.watch(hermesChannelProvider);
    final savedEndpoint = ref.watch(_savedHermesEndpointProvider);
    final pocketSpeechDownloader = ref.watch(
      _pocketSpeechAssetDownloadServiceProvider,
    );
    final pocketSpeechDownload = ref.watch(
      _pocketSpeechAssetDownloadingProvider,
    );
    final pocketSpeechVoices = ref.watch(pocketSpeechVoiceNamesProvider);
    final pocketSpeechPreviewing = ref.watch(_pocketSpeechPreviewingProvider);
    final pocketSpeechDownloading = pocketSpeechDownload != null;

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
                    'Status, connection, appearance, and local voice controls for this Hermes Wing client.',
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
                  if (state.optionalResourceErrors.isNotEmpty)
                    _StatusTile(
                      icon: Icons.warning_amber_outlined,
                      title: 'Inventory warnings',
                      value: _optionalResourceWarningLabel(
                        state.optionalResourceErrors.keys,
                      ),
                    ),
                  _StatusTile(
                    icon: Icons.chat_outlined,
                    title: 'Sessions',
                    value:
                        '${state.sessions.length} sessions • active ${state.activeSessionId == null ? 'none' : 'yes'}',
                  ),
                  ListTile(
                    key: const ValueKey('settings-copy-diagnostics'),
                    leading: const Icon(Icons.copy_outlined),
                    title: const Text('Copy diagnostics'),
                    subtitle: const Text(
                      'Safe snapshot; excludes secrets, raw logs, transcripts, and local paths.',
                    ),
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: hermesDiagnosticsExport(state)),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hermes diagnostics copied'),
                        ),
                      );
                    },
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
                  ListTile(
                    key: const ValueKey('voice-pocket-speech-model'),
                    leading: const Icon(Icons.graphic_eq),
                    title: const Text('Pocket Speech model'),
                    subtitle: const Text(
                      'Choose a compact English pack or the larger bilingual pack',
                    ),
                    trailing: DropdownButton<PocketSpeechModel>(
                      value: settings.pocketSpeechModel,
                      items: [
                        for (final model in PocketSpeechModel.values)
                          DropdownMenuItem(
                            value: model,
                            child: Text(model.label),
                          ),
                      ],
                      onChanged: pocketSpeechDownloading
                          ? null
                          : (model) {
                              if (model != null) {
                                controller.setPocketSpeechModel(model);
                              }
                            },
                    ),
                  ),
                  ListTile(
                    key: const ValueKey('voice-pocket-speech-assets'),
                    leading: Icon(
                      settings.pocketSpeechVoicePackReady
                          ? Icons.check_circle_outline
                          : Icons.download_for_offline_outlined,
                    ),
                    title: Text(
                      '${settings.pocketSpeechModel.label} voice pack',
                    ),
                    subtitle: _PocketSpeechAssetSubtitle(
                      model: settings.pocketSpeechModel,
                      ready: settings.pocketSpeechVoicePackReady,
                      configured:
                          pocketSpeechDownloader?.isConfigured(
                            settings.pocketSpeechModel,
                          ) ==
                          true,
                      progress: pocketSpeechDownload,
                    ),
                    trailing: pocketSpeechDownloading
                        ? Text(
                            '${(pocketSpeechDownload.fraction * 100).round()}%',
                            style: Theme.of(context).textTheme.labelLarge,
                          )
                        : Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (settings.pocketSpeechVoicePackReady)
                                IconButton(
                                  tooltip: 'Remove downloaded voice pack',
                                  onPressed: pocketSpeechDownloader == null
                                      ? null
                                      : () => _deletePocketSpeechAssets(
                                          context,
                                          ref,
                                          controller,
                                          pocketSpeechDownloader,
                                          settings.pocketSpeechModel,
                                        ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              FilledButton(
                                onPressed:
                                    pocketSpeechDownloader?.isConfigured(
                                          settings.pocketSpeechModel,
                                        ) ==
                                        true
                                    ? () => _downloadPocketSpeechAssets(
                                        context,
                                        ref,
                                        controller,
                                        pocketSpeechDownloader!,
                                        settings.pocketSpeechModel,
                                      )
                                    : null,
                                child: Text(
                                  settings.pocketSpeechVoicePackReady
                                      ? 'Update'
                                      : 'Download',
                                ),
                              ),
                            ],
                          ),
                  ),
                  _ConstrainedSettingsTile(
                    child: SwitchListTile(
                      key: const ValueKey('voice-pocket-speech-enabled'),
                      title: const Text('Use Pocket Speech for replies'),
                      subtitle: Text(
                        settings.pocketSpeechVoicePackReady
                            ? 'Use the installed ${settings.pocketSpeechModel.label} pack when Speak assistant replies is on'
                            : 'Download ${settings.pocketSpeechModel.label} before enabling',
                      ),
                      value: settings.pocketSpeechTtsEnabled,
                      onChanged: settings.pocketSpeechVoicePackReady
                          ? controller.setPocketSpeechTtsEnabled
                          : null,
                    ),
                  ),
                  ListTile(
                    key: const ValueKey('voice-pocket-speech-voice'),
                    leading: const Icon(Icons.record_voice_over_outlined),
                    title: const Text('Offline voice'),
                    subtitle: Text(
                      settings.pocketSpeechVoicePackReady
                          ? 'Voice used for Pocket Speech replies'
                          : 'Available after the voice pack is downloaded',
                    ),
                    trailing: pocketSpeechVoices.when(
                      data: (voices) {
                        final selected = voices.contains(settings.ttsVoiceName)
                            ? settings.ttsVoiceName
                            : null;
                        return DropdownButton<String?>(
                          value: selected,
                          hint: const Text('Default'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Default'),
                            ),
                            for (final voice in voices)
                              DropdownMenuItem<String?>(
                                value: voice,
                                child: Text(
                                  _pocketSpeechVoiceLabel(
                                    settings.pocketSpeechModel,
                                    voice,
                                  ),
                                ),
                              ),
                          ],
                          onChanged: settings.pocketSpeechVoicePackReady
                              ? controller.setTtsVoiceName
                              : null,
                        );
                      },
                      loading: () => const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, _) => const Text('Unavailable'),
                    ),
                  ),
                  ListTile(
                    key: const ValueKey('voice-pocket-speech-speed'),
                    leading: const Icon(Icons.speed_outlined),
                    title: Text(
                      'Reply speed · ${settings.speechRate.clamp(0.5, 2.0).toStringAsFixed(2)}×',
                    ),
                    subtitle: Slider(
                      value: settings.speechRate.clamp(0.5, 2.0),
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      label:
                          '${settings.speechRate.clamp(0.5, 2.0).toStringAsFixed(2)}×',
                      onChanged: controller.setSpeechRate,
                    ),
                  ),
                  ListTile(
                    key: const ValueKey('voice-pocket-speech-preview'),
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('Preview offline voice'),
                    subtitle: const Text(
                      'Play a local sample with the selected voice and speed',
                    ),
                    trailing: pocketSpeechPreviewing
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : OutlinedButton.icon(
                            onPressed: settings.pocketSpeechVoicePackReady
                                ? () => _previewPocketSpeech(
                                    context,
                                    ref,
                                    settings,
                                  )
                                : null,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Preview'),
                          ),
                  ),
                  ListTile(
                    key: const ValueKey('settings-command-word'),
                    title: Text(_settingsPresentation.commandWordTitle),
                    subtitle: Text(settings.commandWord),
                    trailing: const Icon(Icons.keyboard_voice),
                    onTap: () => _showCommandWordSheet(
                      context,
                      settings.commandWord,
                      controller.setCommandWord,
                    ),
                  ),
                ],
              ),
              const _VoiceCommandsSection(),
              if (needleSpikeEnabled)
                _SettingsSectionCard(
                  title: 'Needle spike (debug)',
                  icon: Icons.science_outlined,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.play_arrow_outlined),
                      title: const Text('Open Needle evaluation screen'),
                      // push (not go): the spike route lives outside the
                      // ShellRoute, so go() would replace the whole match
                      // stack and leave no back navigation. push() stacks
                      // it over Settings for an operator round-trip.
                      onTap: () => context.push(AppRoutes.needleSpike),
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

final _pocketSpeechAssetDownloadServiceProvider =
    Provider<PocketSpeechAssetDownloadService?>(
      (_) => createDefaultPocketSpeechAssetDownloadService(),
    );

class _PocketSpeechPreviewingController extends Notifier<bool> {
  @override
  bool build() => false;

  void setPreviewing(bool value) => state = value;
}

final _pocketSpeechPreviewingProvider =
    NotifierProvider<_PocketSpeechPreviewingController, bool>(
      _PocketSpeechPreviewingController.new,
    );

class _PocketSpeechAssetDownloadingController
    extends Notifier<PocketSpeechDownloadProgress?> {
  @override
  PocketSpeechDownloadProgress? build() => null;

  void start(PocketSpeechModel model) {
    state = PocketSpeechDownloadProgress(
      model: model,
      part: PocketSpeechDownloadPart.model,
      receivedBytes: 0,
      totalBytes: model.downloadBytes,
    );
  }

  void update(PocketSpeechDownloadProgress progress) => state = progress;

  void finish() => state = null;
}

final _pocketSpeechAssetDownloadingProvider =
    NotifierProvider<
      _PocketSpeechAssetDownloadingController,
      PocketSpeechDownloadProgress?
    >(_PocketSpeechAssetDownloadingController.new);

Future<void> _downloadPocketSpeechAssets(
  BuildContext context,
  WidgetRef ref,
  WingVoiceSettingsController controller,
  PocketSpeechAssetDownloadService downloader,
  PocketSpeechModel model,
) async {
  if (model == PocketSpeechModel.kokoro &&
      !await _confirmLargePocketSpeechDownload(context, model)) {
    return;
  }
  if (!context.mounted) return;

  final downloading = ref.read(_pocketSpeechAssetDownloadingProvider.notifier);
  downloading.start(model);
  try {
    final voicePack = await downloader.download(
      model,
      onProgress: downloading.update,
    );
    controller.setPocketSpeechVoicePack(voicePack);
    ref.invalidate(pocketSpeechVoiceNamesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${model.label} voice pack is ready'),
          action: SnackBarAction(
            label: 'Use for replies',
            onPressed: () {
              controller.setPocketSpeechTtsEnabled(true);
              controller.setSpeakRepliesEnabled(true);
            },
          ),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${model.label} download failed. Check the connection and free storage, then retry.',
          ),
        ),
      );
    }
  } finally {
    downloading.finish();
  }
}

Future<bool> _confirmLargePocketSpeechDownload(
  BuildContext context,
  PocketSpeechModel model,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download ${model.label}?'),
        content: Text(
          '${model.downloadSummary}. Keep Hermes Wing open until the verified download finishes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    ) ??
    false;

Future<void> _deletePocketSpeechAssets(
  BuildContext context,
  WidgetRef ref,
  WingVoiceSettingsController controller,
  PocketSpeechAssetDownloadService downloader,
  PocketSpeechModel model,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Remove ${model.label} voice pack?'),
      content: Text(
        'This frees ${model.downloadSize} of app storage. You can download it again later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await downloader.delete(model);
    controller.clearPocketSpeechVoicePack();
    ref.invalidate(pocketSpeechVoiceNamesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${model.label} voice pack removed')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove ${model.label} voice pack')),
      );
    }
  }
}

Future<void> _previewPocketSpeech(
  BuildContext context,
  WidgetRef ref,
  WingVoiceSettings settings,
) async {
  final voicePack = settings.pocketSpeechVoicePack;
  if (voicePack == null) return;

  final previewing = ref.read(_pocketSpeechPreviewingProvider.notifier);
  TextToSpeechService? service;
  previewing.setPreviewing(true);
  try {
    service = createPocketSpeechTextToSpeechService(
      enabled: true,
      voicePack: voicePack,
      settings: () => ref.read(wingVoiceSettingsProvider),
    );
    if (service == null) throw StateError('Pocket Speech preview unavailable');
    final spanishVoice =
        settings.pocketSpeechModel == PocketSpeechModel.kokoro &&
        (settings.ttsVoiceName?.startsWith('ef_') == true ||
            settings.ttsVoiceName?.startsWith('em_') == true);
    await service.speak(
      spanishVoice
          ? 'Hermes Wing responde con Pocket Speech.'
          : 'Hermes Wing is ready to speak.',
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not preview this voice. Update the voice pack and try again.',
          ),
        ),
      );
    }
  } finally {
    try {
      await service?.dispose();
    } catch (_) {
      // Preview cleanup must not replace the actionable synthesis error.
    }
    previewing.setPreviewing(false);
  }
}

class _PocketSpeechAssetSubtitle extends StatelessWidget {
  const _PocketSpeechAssetSubtitle({
    required this.model,
    required this.ready,
    required this.configured,
    required this.progress,
  });

  final PocketSpeechModel model;
  final bool ready;
  final bool configured;
  final PocketSpeechDownloadProgress? progress;

  @override
  Widget build(BuildContext context) {
    final activeProgress = progress?.model == model ? progress : null;
    if (activeProgress != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${activeProgress.part.label} · ${_formatDownloadBytes(activeProgress.receivedBytes)} of ${_formatDownloadBytes(activeProgress.totalBytes)}',
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: activeProgress.fraction,
              semanticsLabel: '${model.label} download progress',
              semanticsValue:
                  '${(activeProgress.fraction * 100).round()} percent',
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(model.downloadSummary),
        Text(
          ready
              ? 'Installed and stored on this device for offline use'
              : configured
              ? 'Verified download; stored on this device. Keep the app open.'
              : 'Downloads are unavailable in this build',
        ),
      ],
    );
  }
}

String _pocketSpeechVoiceLabel(PocketSpeechModel model, String voice) {
  if (model != PocketSpeechModel.kokoro ||
      !KokoroCatalog.supportsVoice(voice)) {
    return voice;
  }
  final metadata = KokoroCatalog.voice(voice);
  final language = KokoroCatalog.language(metadata.languageCode);
  return '${metadata.name} · ${language.name}';
}

String _formatDownloadBytes(int bytes) =>
    '${(bytes / 1000 / 1000).toStringAsFixed(bytes < 100000000 ? 1 : 0)} MB';

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

String _optionalResourceWarningLabel(
  Iterable<HermesOptionalResource> resources,
) {
  final labels =
      resources
          .map(
            (resource) => switch (resource) {
              HermesOptionalResource.detailedHealth => 'health',
              HermesOptionalResource.models => 'models',
              HermesOptionalResource.skills => 'skills',
              HermesOptionalResource.toolsets => 'toolsets',
              HermesOptionalResource.jobs => 'jobs',
            },
          )
          .toList()
        ..sort();
  final summary = labels.join(', ');
  return '${summary[0].toUpperCase()}${summary.substring(1)} unavailable';
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

/// 'On-device voice commands (beta)' section: toggle, model download with
/// progress, and delete-model tile. Kept as its own stateful widget (rather
/// than folded into the stateless [SettingsScreen]) because it owns the
/// download-in-progress/installed-model-dir state that drives which tile
/// shows.
class _VoiceCommandsSection extends ConsumerStatefulWidget {
  const _VoiceCommandsSection();

  @override
  ConsumerState<_VoiceCommandsSection> createState() =>
      _VoiceCommandsSectionState();
}

class _VoiceCommandsSectionState extends ConsumerState<_VoiceCommandsSection> {
  bool _checkingInstall = true;
  String? _installedDir;
  bool _downloading = false;
  int _downloadedBytes = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_checkInstalled());
  }

  Future<void> _checkInstalled() async {
    try {
      final install = await ref.read(voiceCommandInstallServiceProvider.future);
      final dir = await install.installedModelDir();
      if (!mounted) return;
      setState(() {
        _installedDir = dir;
        _checkingInstall = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingInstall = false);
    }
  }

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _downloadedBytes = 0;
    });
    try {
      final install = await ref.read(voiceCommandInstallServiceProvider.future);
      final dir = await install.ensureModel(
        onProgress: (bytes) {
          if (mounted) setState(() => _downloadedBytes = bytes);
        },
      );
      if (!mounted) return;
      setState(() => _installedDir = dir);
    } catch (_) {
      if (!mounted) return;
      // Toggle stays on: the router simply keeps returning null (no
      // installed model dir) until a retry succeeds.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not download the voice command model.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _delete() async {
    try {
      final install = await ref.read(voiceCommandInstallServiceProvider.future);
      await install.deleteModel();
    } finally {
      if (mounted) setState(() => _installedDir = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(
      wingVoiceSettingsProvider.select((s) => s.voiceCommandsEnabled),
    );
    final controller = ref.read(wingVoiceSettingsProvider.notifier);

    return _SettingsSectionCard(
      title: 'On-device voice commands (beta)',
      icon: Icons.bolt_outlined,
      children: [
        const ListTile(
          key: ValueKey('voice-commands-section-subtitle'),
          title: Text(
            'Runs a small on-device model to execute simple commands '
            'instantly. Transcripts never leave the device.',
          ),
        ),
        _ConstrainedSettingsTile(
          child: SwitchListTile(
            key: const ValueKey('voice-commands-enabled'),
            title: const Text('On-device voice commands'),
            value: enabled,
            onChanged: controller.setVoiceCommandsEnabled,
          ),
        ),
        if (enabled && !_checkingInstall && _installedDir == null)
          ListTile(
            key: const ValueKey('voice-commands-download'),
            leading: const Icon(Icons.download_for_offline_outlined),
            title: const Text('Download model (16 MB)'),
            subtitle: _downloading
                ? Text('Downloading… $_downloadedBytes bytes')
                : const Text('Required for on-device commands'),
            trailing: _downloading
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton(
                    onPressed: _download,
                    child: const Text('Download'),
                  ),
          ),
        if (_installedDir != null)
          ListTile(
            key: const ValueKey('voice-commands-delete'),
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete model (16 MB)'),
            onTap: _delete,
          ),
      ],
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
  ValueChanged<String> onSave,
) async {
  final controller = TextEditingController(text: commandWord);
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
            TextField(
              key: const ValueKey('settings-command-word-field'),
              controller: controller,
              autofocus: true,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Command word'),
              onSubmitted: (value) {
                onSave(value);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Say this before “stop”, “pause”, “mute”, or “cancel” while the foreground voice loop is listening.',
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const ValueKey('settings-command-word-save'),
                onPressed: () {
                  onSave(controller.text);
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  controller.dispose();
}
