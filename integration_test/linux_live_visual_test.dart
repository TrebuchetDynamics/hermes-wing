import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/app.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/hermes/setup/secure_hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/providers/theme_settings_provider.dart';
import 'package:wing/router/app_router.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'native Linux real-service visual feature tour',
    (tester) async {
      final profiles = Platform.environment['WING_LIVE_PROFILE_MANIFEST'];
      final outputPath = Platform.environment['WING_VISUAL_OUTPUT'];
      if (profiles == null || outputPath == null) {
        throw TestFailure(
          'Real isolated Agent manifest and screenshot output are required',
        );
      }
      final agent =
          (jsonDecode(File(profiles).readAsStringSync()) as List).first
              as Map<String, dynamic>;
      final output = Directory(outputPath)..createSync(recursive: true);
      final secretValues = <String>[agent['token'] as String];
      final store = SecureHermesEndpointStore();
      await store.saveAll([
        HermesEndpointConfig(
          id: 'linux-visual-review',
          label: 'Linux UI review',
          baseUrl: agent['origin'] as String,
          apiKey: agent['token'] as String,
        ),
      ]);
      final channel = HermesApiChannel();
      final container = ProviderContainer(
        overrides: [
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesChannelProvider.overrideWithValue(channel),
        ],
      );
      final router = container.read(routerProvider);
      final theme = container.read(wingThemeSettingsProvider.notifier);
      await theme.loaded;
      final boundary = GlobalKey();
      final append = Platform.environment['WING_VISUAL_APPEND'] == '1';
      final records = <Map<String, Object?>>[
        if (append)
          ...(jsonDecode(
                    File('${output.path}/manifest.json').readAsStringSync(),
                  )
                  as List)
              .cast<Map<String, dynamic>>(),
      ];
      final sessions = <String>{};
      var sequence = records.where((r) => r['file'] != null).length;
      Future<void> pause() async {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        await tester.pump();
      }

      Future<void> capture(String name, String feature) async {
        await pause();
        final text = [
          ...tester
              .widgetList<Text>(find.byType(Text))
              .map((w) => w.data ?? w.textSpan?.toPlainText() ?? ''),
          ...tester
              .widgetList<EditableText>(find.byType(EditableText))
              .map((w) => w.controller.text),
        ].join('\n');
        if (secretValues.any((s) => s.isNotEmpty && text.contains(s)) ||
            RegExp(r'/(home|Users|tmp)/').hasMatch(text)) {
          records.add({
            'name': name,
            'feature': feature,
            'status': 'not captured: sensitive value',
          });
        } else {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final pixels = await render.toImage(pixelRatio: 1);
          final bytes = (await pixels.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final file = '${(++sequence).toString().padLeft(3, '0')}-$name.png';
          await File(
            '${output.path}/$file',
          ).writeAsBytes(bytes.buffer.asUint8List());
          pixels.dispose();
          records.add({
            'name': name,
            'feature': feature,
            'file': file,
            'status': 'captured',
            'route': router.routeInformationProvider.value.uri.path,
          });
          debugPrint('Captured $name');
        }
        await File(
          '${output.path}/manifest.json',
        ).writeAsString(const JsonEncoder.withIndent('  ').convert(records));
      }

      Future<void> visit(String route) async {
        router.go(route);
        await tester.pump();
        await Future<void>.delayed(const Duration(seconds: 2));
        await tester.pump();
        expect(
          router.routeInformationProvider.value.uri.path,
          Uri.parse(route).path,
        );
      }

      Future<bool> click(Finder finder) async {
        if (finder.evaluate().isEmpty) return false;
        if (finder.hitTestable().evaluate().isEmpty) {
          await tester.ensureVisible(finder.last);
          await pause();
        }
        expect(finder.hitTestable(), findsWidgets);
        await tester.tap(finder.hitTestable().first);
        await pause();
        return true;
      }

      Future<void> dismiss() async {
        final context = boundary.currentContext!;
        FocusManager.instance.primaryFocus?.unfocus();
        if (router.canPop()) router.pop();
        await pause();
        if (!context.mounted) throw TestFailure('Application unmounted');
      }

      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(key: boundary, child: const WingApp()),
          ),
        );
        final directory = container.read(hermesGatewayDirectoryProvider);
        await directory.start();
        await directory.refresh();
        await directory.activateGateway('linux-visual-review');
        if (!channel.state.isConnected) {
          throw TestFailure('Real Agent connection failed');
        }
        const routes = <String, String>{
          'chat-empty': '/hermes',
          'profiles': '/profiles',
          'providers': '/providers',
          'tools': '/tools',
          'schedules': '/tasks',

          'persona': '/soul',
          'gateway': '/gateway',
          'settings': '/settings',
          'voice-settings': '/settings/voice',
          'diagnostics': '/settings/diagnostics',
          'enrollment': '/enroll',
          'manual-connection': '/hermes/add',
          'local-setup': '/setup/local',
        };
        for (final mode
            in append ? <ThemeMode>[] : [ThemeMode.light, ThemeMode.dark]) {
          await theme.setMode(mode);
          for (final entry in routes.entries) {
            await visit(entry.value);
            if (entry.value == '/hermes/add') {
              for (final editable in tester.widgetList<EditableText>(
                find.byType(EditableText),
              )) {
                if (secretValues.contains(editable.controller.text)) {
                  editable.controller.clear();
                }
              }
              await pause();
            }
            await capture(
              '${mode.name}-${entry.key}',
              'Full production route; live capability gating',
            );
            final lists = tester.stateList<ScrollableState>(
              find.byType(Scrollable),
            );
            final long = lists
                .where(
                  (s) =>
                      s.position.hasContentDimensions &&
                      s.position.maxScrollExtent > 40,
                )
                .firstOrNull;
            if (long != null) {
              long.position.jumpTo(long.position.maxScrollExtent);
              await pause();
              await capture(
                '${mode.name}-${entry.key}-bottom',
                'Lower content and actions',
              );
            }
          }
        }
        await theme.setMode(ThemeMode.light);
        await visit('/settings');
        if (await click(
          find.byKey(
            const ValueKey('settings-gateway-menu-linux-visual-review'),
          ),
        )) {
          await capture(
            'settings-gateway-actions',
            'Saved Agent connection actions',
          );
          final remove = find.byWidgetPredicate(
            (w) => w is PopupMenuItem<String> && w.value == 'remove',
          );
          if (await click(remove)) {
            await capture(
              'settings-gateway-remove-confirmation',
              'Local removal review; cancelled',
            );
            await dismiss();
          } else {
            await dismiss();
          }
        }
        if (await click(
          find.byKey(const ValueKey('settings-palette-picker')),
        )) {
          await capture('appearance-palette-menu', 'Theme palette choices');
          await dismiss();
        }
        await visit('/settings/voice');
        for (final key in [
          'voice-continuous-enabled',
          'voice-speak-replies-enabled',
          'voice-completion-sound-enabled',
        ]) {
          final control = find.byKey(ValueKey(key));
          final before = tester.widget<SwitchListTile>(control).value;
          expect(await click(control), isTrue);
          expect(tester.widget<SwitchListTile>(control).value, !before);
        }
        await capture(
          'voice-preferences-toggled',
          'Persisted UI preference changes; no audio hardware claim',
        );
        for (final key in [
          'voice-continuous-enabled',
          'voice-speak-replies-enabled',
          'voice-completion-sound-enabled',
        ]) {
          expect(await click(find.byKey(ValueKey(key))), isTrue);
        }

        if (await click(
          find.byKey(const ValueKey('voice-advanced-expansion')),
        )) {
          await capture(
            'voice-advanced-options',
            'Voice preferences; no microphone/audio qualification',
          );
        }
        if (await click(
          find.descendant(
            of: find.byKey(const ValueKey('voice-language-mode')),
            matching: find.byWidgetPredicate((w) => w is DropdownButton),
          ),
        )) {
          await capture(
            'voice-language-menu',
            'Recognition language preferences',
          );
          await dismiss();
        }
        if (await click(find.byKey(const ValueKey('settings-command-word')))) {
          await capture(
            'voice-command-editor',
            'Voice command configuration dialog',
          );
          await dismiss();
        }
        await visit('/gateway');
        if (await click(find.byKey(const ValueKey('gateway-refresh-button')))) {
          await capture('gateway-refreshed', 'Agent connection refresh');
        }
        await visit('/enroll');
        expect(
          find.byKey(const ValueKey('hermes-enrollment-computer-setup')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('hermes-enrollment-pair-choice')),
          findsNothing,
        );
        await capture(
          'direct-agent-entry',
          'Welcome exposes direct Agent choices without legacy computer or QR setup',
        );
        await visit('/hermes');
        await channel.createSession(title: 'Linux visual review');
        sessions.add(channel.state.activeSessionId!);
        await pause();
        await capture('chat-new-session', 'Real Agent session creation');
        final composer = find.byKey(const ValueKey('hermes-composer-field'));
        await tester.enterText(
          composer,
          'Reply with exactly: Ready for the next task.',
        );
        await pause();
        await capture(
          'chat-composer-draft',
          'Synthetic review prompt, before send',
        );
        expect(
          await click(find.byKey(const ValueKey('hermes-send-button'))),
          isTrue,
        );
        await capture('chat-sending', 'Real provider request');
        final deadline = DateTime.now().add(const Duration(minutes: 2));
        while (!channel.state.activeMessages.any(
          (t) =>
              t.author == HermesTurnAuthor.assistant &&
              t.status != HermesTurnStatus.streaming,
        )) {
          if (DateTime.now().isAfter(deadline) ||
              channel.state.errorMessage != null) {
            throw TestFailure('Real provider reply failed');
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        await pause();
        await capture(
          'chat-real-provider-reply',
          'Actual Agent provider reply to synthetic prompt',
        );
        if (await click(
          find.byKey(const ValueKey('hermes-composer-model-chip')),
        )) {
          await capture(
            'chat-model-picker',
            'Session model selection from live inventory',
          );
          await dismiss();
        }
        if (await click(find.byKey(const ValueKey('hermes-emoji-button')))) {
          await capture(
            'chat-emoji-picker',
            'Keyboard-accessible emoji selection',
          );
          await dismiss();
        }
        for (final action in ['details', 'rename', 'delete']) {
          if (await click(
            find.byKey(ValueKey('hermes-session-menu-${sessions.first}')),
          )) {
            await capture(
              'chat-session-$action-menu',
              'Real session action menu',
            );
            if (await click(
              find.byWidgetPredicate(
                (w) => w is PopupMenuItem<String> && w.value == action,
              ),
            )) {
              await capture(
                'chat-session-$action-dialog',
                'Session $action review; cancelled',
              );
              await dismiss();
            } else {
              await dismiss();
            }
          }
        }
        final search = find.byKey(
          const ValueKey('hermes-session-rail-search-field'),
        );
        if (search.evaluate().isNotEmpty) {
          await tester.enterText(search, 'not-a-session');
          await pause();
          await capture(
            'chat-session-search-empty',
            'Session search empty state',
          );
          await tester.enterText(search, '');
        }
        await channel.disconnect();
        await pause();
        await capture('chat-disconnected', 'Disconnected connection recovery');
        await channel.connect(
          baseUrl: agent['origin'] as String,
          apiKey: agent['token'] as String,
        );
        expect(channel.state.isConnected, isTrue);
        await channel.selectSession(sessions.first);
        await pause();
        await capture(
          'chat-reconnected',
          'Real reconnect and session reconciliation',
        );
        await visit('/tools');
        for (final key in ['installed-skills-search', 'toolsets-search']) {
          final field = find.byKey(ValueKey(key));
          if (field.evaluate().isNotEmpty) {
            await tester.ensureVisible(field);
            await tester.enterText(field, 'wing-ui-review-no-match');
            await pause();
            await capture('$key-empty-result', 'Search and no-result recovery');
            await tester.enterText(field, '');
          }
        }
        expect(
          records.where((r) => r['status'] == 'captured').length,
          greaterThanOrEqualTo(28),
        );
      } finally {
        for (final id in sessions) {
          await channel.deleteSession(id);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        channel.dispose();
        await store.clear();
      }
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
