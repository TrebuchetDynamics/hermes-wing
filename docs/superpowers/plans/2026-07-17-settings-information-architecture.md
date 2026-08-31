# Settings Information Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the long Settings scroll with a compact gateway-and-voice overview plus focused Voice & speech and Diagnostics pages.

**Architecture:** Keep one Dart library rooted at `settings_screen.dart` and split the two detail screens into `part` files, matching the repository's existing screen-part pattern without introducing shared abstractions. Existing Riverpod providers, gateway operations, diagnostics export, and download services remain authoritative; only presentation and routing change.

**Tech Stack:** Flutter 3.44.2, Dart 3.12, Riverpod 3, go_router, Material widgets, flutter_test.

**Execution:** Completed 2026-07-17. Validation: 554 Flutter tests passed, full `flutter analyze` clean, Playwright settings screenshot passed, and phone/desktop visual receipts inspected.

## Global Constraints

- Keep saved gateways, connection management, Continuous voice, and Speak assistant replies on `/settings`.
- Add `/settings/voice` and `/settings/diagnostics` inside the existing `ShellRoute`.
- Remove the read-only Appearance section, separate Hermes Agent dashboard, and Open Hermes action from Settings.
- Introduce no persistence, domain-state, enrollment, gateway-storage, voice-engine, or diagnostics-export changes.
- Keep credentials, raw logs, transcripts, private paths, and raw optional-resource errors out of rendered diagnostics.
- Use one vertical scroll region per page, Material controls with at least 48 dp touch targets, and layouts tolerant of system text scaling.
- Preserve unrelated dirty-worktree changes. Do not commit or push unless the owner separately requests delivery; commit commands below are suggested checkpoints only.

## File Structure

- Modify `lib/features/settings/screens/settings_screen.dart` — compact overview, gateway management, and shared settings-library imports/parts.
- Create `lib/features/settings/screens/settings_voice_screen.dart` — Voice & speech detail UI and existing voice/download helpers.
- Create `lib/features/settings/screens/settings_diagnostics_screen.dart` — safe operational status and diagnostics export UI.
- Modify `lib/router/routes/app_routes.dart` — detail route constants.
- Modify `lib/router/providers/app_router.dart` — register both detail routes under the shell.
- Modify `test/features/settings/settings_screen_test.dart` — overview-only behavior.
- Create `test/features/settings/settings_voice_screen_test.dart` — moved voice interaction coverage.
- Create `test/features/settings/settings_diagnostics_screen_test.dart` — moved diagnostics safety/export coverage.
- Create `test/router/settings_routes_test.dart` — production-router and shell-selection coverage.

---

### Task 1: Extract the Diagnostics page

**Files:**

- Modify: `lib/features/settings/screens/settings_screen.dart`
- Create: `lib/features/settings/screens/settings_diagnostics_screen.dart`
- Modify: `lib/router/routes/app_routes.dart`
- Modify: `lib/router/providers/app_router.dart`
- Create: `test/features/settings/settings_diagnostics_screen_test.dart`
- Modify: `test/features/settings/settings_screen_test.dart`

**Interfaces:**

- Consumes: `hermesChannelProvider`, `HermesChannelState`, `hermesDiagnosticsExport(HermesChannelState)`.
- Produces: `const DiagnosticsSettingsScreen()`, `AppRoutes.settingsDiagnostics == '/settings/diagnostics'`, and overview key `settings-diagnostics-link`.

- [ ] **Step 1: Write failing Diagnostics page tests**

Create `test/features/settings/settings_diagnostics_screen_test.dart` by moving the existing optional-inventory-warning and clipboard tests from `settings_screen_test.dart`, changing only the screen under test:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

void main() {
  testWidgets('shows bounded inventory failures without raw errors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel(
      optionalResourceErrors: const {
        HermesOptionalResource.skills: 'Authorization: Bearer private-value',
        HermesOptionalResource.models: '/home/operator/private-models',
      },
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: DiagnosticsSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inventory warnings'), findsOneWidget);
    expect(find.text('Models, skills unavailable'), findsOneWidget);
    expect(find.textContaining('private-value'), findsNothing);
    expect(find.textContaining('/home/operator'), findsNothing);
  });

  testWidgets('copies the bounded Hermes diagnostics snapshot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.connected,
      models: const ['hermes-3'],
    );
    addTearDown(channel.dispose);
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: DiagnosticsSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('settings-copy-diagnostics')),
    );
    await tester.pump();

    expect(copiedText, contains('Hermes Wing diagnostics'));
    expect(copiedText, contains('Models: hermes-3'));
    expect(copiedText, contains('Secrets: excluded'));
    expect(find.text('Hermes diagnostics copied'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the page tests and verify RED**

Run:

```bash
flutter test --concurrency=1 test/features/settings/settings_diagnostics_screen_test.dart
```

Expected: compilation fails because `DiagnosticsSettingsScreen` does not exist.

- [ ] **Step 3: Add the Diagnostics route contract**

In `lib/router/routes/app_routes.dart`, add:

```dart
static const settingsDiagnostics = '/settings/diagnostics';
```

In `lib/router/providers/app_router.dart`, add this route next to `AppRoutes.settings`:

```dart
GoRoute(
  path: AppRoutes.settingsDiagnostics,
  builder: (context, state) => const DiagnosticsSettingsScreen(),
),
```

No navigation helper is needed: the existing `isSettingsLocation()` path-prefix check already classifies the detail location as Settings.

- [ ] **Step 4: Create the Diagnostics part and move existing diagnostics presentation**

Add this directive after the imports in `settings_screen.dart`:

```dart
part 'settings_diagnostics_screen.dart';
```

Create `settings_diagnostics_screen.dart` with:

```dart
part of 'settings_screen.dart';

class DiagnosticsSettingsScreen extends ConsumerWidget {
  const DiagnosticsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(hermesChannelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: AnimatedBuilder(
        animation: channel,
        builder: (context, _) {
          final state = channel.state;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsSectionCard(
                title: 'Connection',
                icon: Icons.cable_outlined,
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
                title: 'Inventory',
                icon: Icons.checklist_outlined,
                children: [
                  _StatusTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Resources',
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
                ],
              ),
              _SettingsSectionCard(
                title: 'Sessions',
                icon: Icons.chat_outlined,
                children: [
                  _StatusTile(
                    icon: Icons.chat_outlined,
                    title: 'Sessions',
                    value:
                        '${state.sessions.length} sessions • active ${state.activeSessionId == null ? 'none' : 'yes'}',
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: 'Export',
                icon: Icons.copy_outlined,
                children: [
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
            ],
          );
        },
      ),
    );
  }
}
```

Move the complete definitions of these four functions from `settings_screen.dart` into the same part file below the screen class, with no body edits:

```text
_connectionStatusLabel
_runTransportLabel
_healthLabel
_optionalResourceWarningLabel
```

Keep `_StatusTile` in `settings_screen.dart`; both the overview and Diagnostics part use it through the shared Dart library.

- [ ] **Step 5: Replace overview diagnostics/status cards with one navigation row**

Delete the existing `Hermes Agent` and `Diagnostics` `_SettingsSectionCard` blocks from `SettingsScreen.build()`. Insert this compact card after the gateway card:

```dart
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
```

Delete the two moved diagnostics tests from `settings_screen_test.dart`; their assertions now belong to the detail-page test.

- [ ] **Step 6: Run focused tests and verify GREEN**

Run:

```bash
flutter test --concurrency=1 \
  test/features/settings/settings_diagnostics_screen_test.dart \
  test/features/settings/settings_screen_test.dart
```

Expected: all tests pass; diagnostics safety and clipboard behavior are unchanged.

- [ ] **Step 7: Suggested commit checkpoint (only with explicit delivery approval)**

```bash
git add \
  lib/features/settings/screens/settings_screen.dart \
  lib/features/settings/screens/settings_diagnostics_screen.dart \
  lib/router/routes/app_routes.dart \
  lib/router/providers/app_router.dart \
  test/features/settings/settings_diagnostics_screen_test.dart \
  test/features/settings/settings_screen_test.dart
git commit -m "refactor(settings): move diagnostics to detail page"
```

---

### Task 2: Extract Voice & speech and add quick controls

**Files:**

- Modify: `lib/features/settings/screens/settings_screen.dart`
- Create: `lib/features/settings/screens/settings_voice_screen.dart`
- Modify: `lib/router/routes/app_routes.dart`
- Modify: `lib/router/providers/app_router.dart`
- Create: `test/features/settings/settings_voice_screen_test.dart`
- Modify: `test/features/settings/settings_screen_test.dart`

**Interfaces:**

- Consumes: `wingVoiceSettingsProvider` and existing Pocket Speech providers/services.
- Produces: `const VoiceSettingsScreen()`, `AppRoutes.settingsVoice == '/settings/voice'`, overview keys `voice-continuous-enabled`, `voice-speak-replies-enabled`, and `settings-voice-link`.

- [ ] **Step 1: Write failing Voice & speech tests**

Create `test/features/settings/settings_voice_screen_test.dart` by moving the existing `Pocket Speech settings explain downloads and playback choices` test from `settings_screen_test.dart`, changing the home widget to `VoiceSettingsScreen`. Add this Advanced disclosure test:

```dart
testWidgets('advanced voice controls start collapsed and can be revealed', (
  tester,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final channel = FakeHermesChannel.disconnected();
  addTearDown(channel.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: const MaterialApp(home: VoiceSettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('Advanced'), findsOneWidget);
  expect(find.byKey(const ValueKey('settings-command-word')), findsNothing);

  await tester.tap(find.text('Advanced'));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('settings-command-word')), findsOneWidget);
});
```

Retain the existing imports for `SharedPreferences`, `FakeHermesChannel`, endpoint-store override, and Pocket Speech settings fixture from the moved test.

- [ ] **Step 2: Run the Voice & speech tests and verify RED**

Run:

```bash
flutter test --concurrency=1 test/features/settings/settings_voice_screen_test.dart
```

Expected: compilation fails because `VoiceSettingsScreen` does not exist.

- [ ] **Step 3: Add the Voice & speech route contract**

In `lib/router/routes/app_routes.dart`, add:

```dart
static const settingsVoice = '/settings/voice';
```

In `lib/router/providers/app_router.dart`, add:

```dart
GoRoute(
  path: AppRoutes.settingsVoice,
  builder: (context, state) => const VoiceSettingsScreen(),
),
```

- [ ] **Step 4: Create the Voice & speech part**

Add this directive beside the diagnostics part in `settings_screen.dart`:

```dart
part 'settings_voice_screen.dart';
```

Create `settings_voice_screen.dart`:

```dart
part of 'settings_screen.dart';

class VoiceSettingsScreen extends ConsumerWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(wingVoiceSettingsProvider);
    final controller = ref.read(wingVoiceSettingsProvider.notifier);
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
      appBar: AppBar(title: const Text('Voice & speech')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSectionCard(
            title: 'Voice behavior',
            icon: Icons.keyboard_voice_outlined,
            children: [
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
                  subtitle: Text(_settingsPresentation.speakRepliesSubtitle),
                  value: settings.speakRepliesEnabled,
                  onChanged: controller.setSpeakRepliesEnabled,
                ),
              ),
            ],
          ),
          _PocketSpeechSettingsSection(
            settings: settings,
            controller: controller,
            downloader: pocketSpeechDownloader,
            download: pocketSpeechDownload,
            voices: pocketSpeechVoices,
            previewing: pocketSpeechPreviewing,
            downloading: pocketSpeechDownloading,
          ),
          _SettingsSectionCard(
            title: 'Advanced',
            icon: Icons.tune_outlined,
            children: [
              ExpansionTile(
                key: const ValueKey('voice-advanced-expansion'),
                title: const Text('Advanced'),
                children: [
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
            ],
          ),
        ],
      ),
    );
  }
}
```

Extract the current Pocket Speech controls into this private widget in the same part file:

```dart
class _PocketSpeechSettingsSection extends ConsumerWidget {
  const _PocketSpeechSettingsSection({
    required this.settings,
    required this.controller,
    required this.downloader,
    required this.download,
    required this.voices,
    required this.previewing,
    required this.downloading,
  });

  final WingVoiceSettings settings;
  final WingVoiceSettingsController controller;
  final PocketSpeechAssetDownloadService? downloader;
  final PocketSpeechDownloadProgress? download;
  final AsyncValue<List<String>> voices;
  final bool previewing;
  final bool downloading;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _SettingsSectionCard(
    title: _settingsPresentation.localVoiceSectionTitle,
    icon: Icons.graphic_eq,
    children: [
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
              DropdownMenuItem(value: model, child: Text(model.label)),
          ],
          onChanged: downloading
              ? null
              : (model) {
                  if (model != null) controller.setPocketSpeechModel(model);
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
        title: Text('${settings.pocketSpeechModel.label} voice pack'),
        subtitle: _PocketSpeechAssetSubtitle(
          model: settings.pocketSpeechModel,
          ready: settings.pocketSpeechVoicePackReady,
          configured:
              downloader?.isConfigured(settings.pocketSpeechModel) == true,
          progress: download,
        ),
        trailing: downloading
            ? Text(
                '${(download!.fraction * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge,
              )
            : Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (settings.pocketSpeechVoicePackReady)
                    IconButton(
                      tooltip: 'Remove downloaded voice pack',
                      onPressed: downloader == null
                          ? null
                          : () => _deletePocketSpeechAssets(
                              context,
                              ref,
                              controller,
                              downloader!,
                              settings.pocketSpeechModel,
                            ),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  FilledButton(
                    onPressed:
                        downloader?.isConfigured(settings.pocketSpeechModel) ==
                            true
                        ? () => _downloadPocketSpeechAssets(
                            context,
                            ref,
                            controller,
                            downloader!,
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
        trailing: voices.when(
          data: (availableVoices) {
            final selected = availableVoices.contains(settings.ttsVoiceName)
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
                for (final voice in availableVoices)
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
        trailing: previewing
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : OutlinedButton.icon(
                onPressed: settings.pocketSpeechVoicePackReady
                    ? () => _previewPocketSpeech(context, ref, settings)
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Preview'),
              ),
      ),
    ],
  );
}
```

Move the complete definitions of these symbols from `settings_screen.dart` into `settings_voice_screen.dart` below the screen widgets, retaining their current bodies and keys:

```text
_pocketSpeechAssetDownloadServiceProvider
_PocketSpeechPreviewingController
_pocketSpeechPreviewingProvider
_PocketSpeechAssetDownloadingController
_pocketSpeechAssetDownloadingProvider
_downloadPocketSpeechAssets
_confirmLargePocketSpeechDownload
_deletePocketSpeechAssets
_previewPocketSpeech
_PocketSpeechAssetSubtitle
_pocketSpeechVoiceLabel
_formatDownloadBytes
_ConstrainedSettingsTile
_showCommandWordSheet
```

- [ ] **Step 5: Replace the long overview voice content with quick controls**

Delete the old local-voice section from `SettingsScreen.build()`. Insert:

```dart
_SettingsSectionCard(
  title: 'Voice',
  icon: Icons.keyboard_voice_outlined,
  children: [
    SwitchListTile(
      key: const ValueKey('voice-continuous-enabled'),
      title: Text(_settingsPresentation.continuousVoiceTitle),
      value: settings.continuousVoiceEnabled,
      onChanged: controller.setContinuousVoiceEnabled,
    ),
    SwitchListTile(
      key: const ValueKey('voice-speak-replies-enabled'),
      title: Text(_settingsPresentation.speakRepliesTitle),
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
```

Delete the moved Pocket Speech test from `settings_screen_test.dart`.

- [ ] **Step 6: Run focused tests and verify GREEN**

Run:

```bash
flutter test --concurrency=1 \
  test/features/settings/settings_voice_screen_test.dart \
  test/features/settings/settings_screen_test.dart
```

Expected: all tests pass; the overview exposes only two quick switches and the detail page retains all existing voice controls.

- [ ] **Step 7: Suggested commit checkpoint (only with explicit delivery approval)**

```bash
git add \
  lib/features/settings/screens/settings_screen.dart \
  lib/features/settings/screens/settings_voice_screen.dart \
  lib/router/routes/app_routes.dart \
  lib/router/providers/app_router.dart \
  test/features/settings/settings_voice_screen_test.dart \
  test/features/settings/settings_screen_test.dart
git commit -m "refactor(settings): move voice controls to detail page"
```

---

### Task 3: Compact the overview and preserve gateway operations

**Files:**

- Modify: `lib/features/settings/screens/settings_screen.dart`
- Modify: `test/features/settings/settings_screen_test.dart`

**Interfaces:**

- Consumes: `hermesGatewayDirectoryProvider`, `wingVoiceSettingsProvider`, and the two detail route constants.
- Produces: a three-section `/settings` overview: Gateways, Voice, Diagnostics.

- [ ] **Step 1: Add failing overview assertions**

Extend `settings manage gateways without rendering credentials` in `settings_screen_test.dart` immediately after the initial pump:

```dart
expect(find.text('Hermes Agent dashboard'), findsNothing);
expect(find.text('Appearance'), findsNothing);
expect(find.byKey(const ValueKey('settings-open-hermes')), findsNothing);
expect(find.byKey(const ValueKey('voice-continuous-enabled')), findsOneWidget);
expect(find.byKey(const ValueKey('voice-speak-replies-enabled')), findsOneWidget);
expect(find.byKey(const ValueKey('settings-voice-link')), findsOneWidget);
expect(find.byKey(const ValueKey('settings-diagnostics-link')), findsOneWidget);
expect(find.text('Credentials stay in secure storage; values hidden'),
    findsOneWidget);
```

Add a small-phone overflow regression:

```dart
testWidgets('settings overview fits a narrow phone without horizontal overflow', (
  tester,
) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final channel = FakeHermesChannel.disconnected();
  addTearDown(channel.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(
          const EmptyHermesEndpointStore(),
        ),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(find.byType(ListView), findsOneWidget);
});
```

- [ ] **Step 2: Run overview tests and verify RED**

Run:

```bash
flutter test --concurrency=1 test/features/settings/settings_screen_test.dart
```

Expected: at least the old header, Appearance, and Open Hermes assertions fail.

- [ ] **Step 3: Reduce `SettingsScreen.build()` to three sections**

Keep the existing app bar and outer `AnimatedBuilder`, but remove `_SettingsHeader`, the Appearance card, and the Open Hermes button. The `ListView.children` order must be:

```dart
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
        value: settings.continuousVoiceEnabled,
        onChanged: controller.setContinuousVoiceEnabled,
      ),
      SwitchListTile(
        key: const ValueKey('voice-speak-replies-enabled'),
        title: Text(_settingsPresentation.speakRepliesTitle),
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
```

Delete `_SettingsHeader` if no call sites remain. Keep `_SettingsSectionCard`, `_GatewaySettingsTile`, and gateway action helpers in `settings_screen.dart`.

- [ ] **Step 4: Run overview and gateway tests and verify GREEN**

Run:

```bash
flutter test --concurrency=1 \
  test/features/settings/settings_screen_test.dart \
  test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart
```

Expected: all tests pass; rename, reconnect, remove, and connect-another behavior remain available.

- [ ] **Step 5: Suggested commit checkpoint (only with explicit delivery approval)**

```bash
git add \
  lib/features/settings/screens/settings_screen.dart \
  test/features/settings/settings_screen_test.dart
git commit -m "refactor(settings): compact the settings overview"
```

---

### Task 4: Verify production routing, shell selection, and accessibility basics

**Files:**

- Create: `test/router/settings_routes_test.dart`
- Modify: `test/shared/widgets/app_shell_test.dart`

**Interfaces:**

- Consumes: `routerProvider`, `AppRoutes.settingsVoice`, `AppRoutes.settingsDiagnostics`, and existing Settings path-prefix classification.
- Produces: regression evidence that both detail pages render in the production router while Settings remains the selected shell destination.

- [ ] **Step 1: Write failing route classification test**

Add to `app_shell_test.dart`:

```dart
test('settings detail routes remain settings locations', () {
  expect(AppRoutes.isSettingsLocation(AppRoutes.settingsVoice), isTrue);
  expect(AppRoutes.isSettingsLocation(AppRoutes.settingsDiagnostics), isTrue);
});
```

Create `test/router/settings_routes_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';
import 'package:wing/router/app_routes.dart';

import '../features/hermes_chat/support/fake_hermes_channel.dart';
import '../features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../features/hermes_chat/support/fake_hermes_gateway_directory.dart';

void main() {
  testWidgets('settings detail routes render inside the app shell and return', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore(profiles: const []);
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader(const {}),
      activeChannel: channel,
    );
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(store),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
      ],
    );
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    addTearDown(container.dispose);
    addTearDown(channel.dispose);
    router.go(AppRoutes.settings);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-voice-link')));
    await tester.pumpAndSettle();
    expect(find.text('Voice & speech'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-voice-link')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-diagnostics-link')));
    await tester.pumpAndSettle();
    expect(find.text('Diagnostics'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run route tests and verify RED or the expected missing integration**

Run:

```bash
flutter test --concurrency=1 \
  test/router/settings_routes_test.dart \
  test/shared/widgets/app_shell_test.dart
```

Expected before route wiring is complete: a detail route is not found or the detail screen assertion fails. After Tasks 1–3, this may already be GREEN; record that as integration evidence rather than forcing an artificial failure.

- [ ] **Step 3: Add semantic labels only where native widget text is insufficient**

Inspect the two detail screens at 320 px and with `textScaler: const TextScaler.linear(2)`. Native `ListTile`, `SwitchListTile`, `ExpansionTile`, and `IconButton.tooltip` semantics require no wrappers. Add a `tooltip` to any remaining icon-only control without one; do not add duplicate `Semantics` around labeled Material controls.

Use this test wrapper for the large-text pass:

```dart
MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(
      size: Size(320, 700),
      textScaler: TextScaler.linear(2),
    ),
    child: const VoiceSettingsScreen(),
  ),
)
```

Assert `tester.takeException()` is null after scrolling the full page.

- [ ] **Step 4: Run the complete settings verification**

Run:

```bash
dart format \
  lib/features/settings/screens/settings_screen.dart \
  lib/features/settings/screens/settings_voice_screen.dart \
  lib/features/settings/screens/settings_diagnostics_screen.dart \
  lib/router/routes/app_routes.dart \
  lib/router/providers/app_router.dart \
  test/features/settings \
  test/router/settings_routes_test.dart \
  test/shared/widgets/app_shell_test.dart

flutter test --concurrency=1 \
  test/features/settings \
  test/router/settings_routes_test.dart \
  test/shared/widgets/app_shell_test.dart

flutter analyze \
  lib/features/settings \
  lib/router \
  test/features/settings \
  test/router/settings_routes_test.dart \
  test/shared/widgets/app_shell_test.dart

git diff --check
```

Expected: formatting makes no further changes on a second run, all tests pass, analyzer reports `No issues found!`, and `git diff --check` exits 0.

- [ ] **Step 5: Manual visual receipt**

Run the app at a 390×844 phone viewport and a width of at least 1024 px. Record these checks:

```text
/settings: Gateways, Voice, Diagnostics only; no Appearance/dashboard/Open Hermes
/settings/voice: all prior voice controls reachable; Advanced starts collapsed
/settings/diagnostics: safe status/export content; no raw errors or credentials
Back: each detail page returns to the same Settings overview position
Themes: readable in light and dark modes
Text scale 200%: no clipped controls or horizontal overflow
```

Do not update `playwright/screenshots/settings.png` unless the repository's screenshot command regenerates it deterministically and the owner asks to include visual baselines.

- [ ] **Step 6: Suggested commit checkpoint (only with explicit delivery approval)**

```bash
git add \
  test/router/settings_routes_test.dart \
  test/shared/widgets/app_shell_test.dart
git commit -m "test(settings): cover detail routes and responsive layout"
```
