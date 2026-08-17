part of 'settings_screen.dart';

class VoiceSettingsScreen extends ConsumerWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(wingVoiceSettingsProvider);
    final controller = ref.read(wingVoiceSettingsProvider.notifier);
    final offlineSttPack = ref.watch(offlineSttPackControllerProvider);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.voiceSettingsTitle),
        actions: const [AppShellMenuButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSectionCard(
            title: strings.voiceBehaviorSection,
            icon: Icons.keyboard_voice_outlined,
            children: [
              _ConstrainedSettingsTile(
                child: SwitchListTile(
                  key: const ValueKey('voice-continuous-enabled'),
                  title: Text(strings.voiceContinuousTitle),
                  subtitle: Text(strings.voiceContinuousSubtitle),
                  value: settings.continuousVoiceEnabled,
                  onChanged: controller.setContinuousVoiceEnabled,
                ),
              ),
              _ConstrainedSettingsTile(
                child: SwitchListTile(
                  key: const ValueKey('voice-speak-replies-enabled'),
                  title: Text(strings.voiceSpeakRepliesTitle),
                  subtitle: Text(strings.voiceSpeakRepliesSubtitle),
                  value: settings.speakRepliesEnabled,
                  onChanged: controller.setSpeakRepliesEnabled,
                ),
              ),
            ],
          ),
          _OfflineSttPackSection(state: offlineSttPack),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              key: const ValueKey('voice-advanced-expansion'),
              leading: const Icon(Icons.tune_outlined),
              title: Text(
                strings.voiceAdvancedSection,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              children: [
                ListTile(
                  key: const ValueKey('voice-language-mode'),
                  leading: const Icon(Icons.translate),
                  title: Text(strings.voiceRecognitionLanguageTitle),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.voiceRecognitionLanguageSubtitle),
                      Align(
                        alignment: Alignment.centerRight,
                        child: DropdownButton<VoiceLanguageMode>(
                          isExpanded: true,
                          value: settings.languageMode,
                          items: [
                            for (final mode in VoiceLanguageMode.values)
                              DropdownMenuItem(
                                value: mode,
                                child: Text(mode.label),
                              ),
                          ],
                          onChanged: (mode) {
                            if (mode != null) controller.setLanguageMode(mode);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  key: const ValueKey('settings-command-word'),
                  title: Text(strings.voiceCommandWordTitle),
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
          ),
        ],
      ),
    );
  }
}

class _OfflineSttPackSection extends ConsumerWidget {
  const _OfflineSttPackSection({required this.state});

  final OfflineSttPackState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(offlineSttPackControllerProvider.notifier);
    final tier = ref.watch(offlineSttModelTierProvider);
    final tierController = ref.read(offlineSttModelTierProvider.notifier);
    final strings = AppLocalizations.of(context);
    final installed = state.status == OfflineSttPackStatus.installed;
    return _SettingsSectionCard(
      title: strings.voiceOfflineRecognitionSection,
      icon: Icons.offline_bolt_outlined,
      children: [
        ListTile(
          key: const ValueKey('voice-offline-stt-pack'),
          leading: Icon(
            installed
                ? Icons.verified_outlined
                : Icons.download_for_offline_outlined,
          ),
          title: Text(strings.voiceOfflineSttPackTitle),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<OfflineSttModelTier>(
                key: const ValueKey('voice-offline-stt-tier'),
                isExpanded: true,
                value: tier,
                items: [
                  for (final candidate in OfflineSttModelTier.values)
                    DropdownMenuItem(
                      value: candidate,
                      child: Text(
                        '${candidate.label} · ${candidate.downloadSize}',
                      ),
                    ),
                ],
                onChanged: state.isBusy
                    ? null
                    : (selection) {
                        if (selection != null) {
                          unawaited(tierController.setTier(selection));
                        }
                      },
              ),
              Text(_statusText(strings, state)),
              if (state.isBusy) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: state.status == OfflineSttPackStatus.checking
                      ? 0
                      : state.progress,
                ),
                if (state.receivedBytes case final received?)
                  Text(
                    '$received / ${state.totalBytes ?? 0} bytes',
                    key: const ValueKey('voice-offline-stt-byte-progress'),
                  ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: switch (state.status) {
                  OfflineSttPackStatus.absent => FilledButton.icon(
                    key: const ValueKey('voice-offline-stt-download'),
                    onPressed: () => unawaited(controller.install()),
                    icon: const Icon(Icons.download),
                    label: Text(strings.voiceOfflineSttDownload),
                  ),
                  OfflineSttPackStatus.installed => OutlinedButton.icon(
                    key: const ValueKey('voice-offline-stt-delete'),
                    onPressed: () => unawaited(controller.delete()),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(strings.voiceOfflineSttRemove),
                  ),
                  OfflineSttPackStatus.error => OutlinedButton.icon(
                    key: const ValueKey('voice-offline-stt-retry'),
                    onPressed: () => unawaited(controller.refresh()),
                    icon: const Icon(Icons.refresh),
                    label: Text(strings.voiceOfflineSttRetry),
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusText(AppLocalizations strings, OfflineSttPackState state) =>
      switch (state.status) {
        OfflineSttPackStatus.checking => strings.voiceOfflineSttChecking,
        OfflineSttPackStatus.absent => strings.voiceOfflineSttAbsent,
        OfflineSttPackStatus.installing => strings.voiceOfflineSttInstalling,
        OfflineSttPackStatus.installed => strings.voiceOfflineSttInstalled(
          state.provenance ?? '',
        ),
        OfflineSttPackStatus.deleting => strings.voiceOfflineSttDeleting,
        OfflineSttPackStatus.error =>
          state.message ?? strings.voiceOfflineSttUnavailable,
      };
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
  final strings = AppLocalizations.of(context);
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
            Text(
              strings.voiceCommandWordTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('settings-command-word-field'),
              controller: controller,
              autofocus: true,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: strings.voiceCommandWordTitle,
              ),
              onSubmitted: (value) {
                onSave(value);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            Text(strings.voiceCommandWordHint),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const ValueKey('settings-command-word-save'),
                onPressed: () {
                  onSave(controller.text);
                  Navigator.of(context).pop();
                },
                child: Text(strings.saveAction),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  controller.dispose();
}
