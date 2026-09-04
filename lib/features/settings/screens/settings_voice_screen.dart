part of 'settings_screen.dart';

class VoiceSettingsScreen extends ConsumerWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(wingVoiceSettingsProvider);
    final controller = ref.read(wingVoiceSettingsProvider.notifier);
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
              _ConstrainedSettingsTile(
                child: SwitchListTile(
                  key: const ValueKey('voice-completion-sound-enabled'),
                  title: Text(strings.voiceCompletionSoundTitle),
                  subtitle: Text(strings.voiceCompletionSoundSubtitle),
                  value: settings.completionSoundEnabled,
                  onChanged: controller.setCompletionSoundEnabled,
                ),
              ),
            ],
          ),
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
    builder: (context) => ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final normalized = value.text.trim();
        final canSave = normalized.isNotEmpty;
        void save() {
          if (!canSave) return;
          onSave(normalized);
          Navigator.of(context).pop();
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
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
                    enableSuggestions: false,
                    enableIMEPersonalizedLearning: false,
                    textInputAction: TextInputAction.done,
                    maxLength: maxVoiceCommandWordCharacters,
                    decoration: InputDecoration(
                      labelText: strings.voiceCommandWordTitle,
                    ),
                    onSubmitted: (_) => save(),
                  ),
                  const SizedBox(height: 8),
                  Text(strings.voiceCommandWordHint),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      key: const ValueKey('settings-command-word-save'),
                      onPressed: canSave ? save : null,
                      child: Text(strings.saveAction),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  controller.dispose();
}
