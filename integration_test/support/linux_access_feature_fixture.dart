import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/app/desktop_host_command_listener.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/session_model_picker_sheet.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:wing/features/voice/services/platform/default_voice_capture_service.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';
import 'package:wing/shared/voice/voice_capture_failures.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';
import 'package:wing/theme/wing_theme.dart';

import '../../test/features/hermes_chat/support/fake_hermes_channel.dart';
import '../../test/shared/widgets/app_shell_status_accessibility_test.dart'
    as status;
import 'status_accessibility_native_fixture.dart';

typedef AccessResize = Future<void> Function(Size?);
const _editor = ValueKey('hermes-composer-field');
const _model = ValueKey('hermes-composer-model-chip');
const _dictate = ValueKey('hermes-draft-mic-button');
const _live = ValueKey('hermes-live-voice-start');
const _send = ValueKey('hermes-send-button');

/// Published only after every assertion succeeds; the driver adds source/log
/// digests and verifies that the reported GTK process belongs to its group.
class LinuxAccessReceipts {
  LinuxAccessReceipts(this.root);
  final String root;
  final _rows = <Map<String, Object?>>[];
  Set<String> get ids => _rows.map((row) => row['id']! as String).toSet();

  void add(
    String id,
    List<String> features,
    List<String> routes,
    int owners,
    Map<String, int> counts,
    Map<String, Object?> evidence, {
    String input = 'framework keys/text/resize/lifecycle in Linux GTK',
    String storage = 'mock preferences; volatile synthetic Agent state',
  }) {
    expect(ids, isNot(contains(id)));
    _rows.add({
      'id': id,
      'feature_ids': features,
      'route_ids': routes,
      'native_pid': pid,
      'owner_count': owners,
      'operation_counts': counts,
      'backend': 'in-memory Agent fixture; deferred synthetic voice services',
      'input': input,
      'storage': storage,
      'status': 'pass',
      'evidence': evidence,
    });
  }

  void publish() {
    final pending = File('$root/feature-cases.pending');
    pending.writeAsStringSync(
      jsonEncode({'schema': 1, 'cases': _rows}),
      flush: true,
    );
    pending.renameSync('$root/feature-cases.json');
  }
}

class _Channel extends FakeHermesChannel {
  _Channel({String profile = 'synthetic-access'})
    : super(
        selectedProfileId: profile,
        capabilities: HermesCapabilityDocument.fromJson(const {
          'schema_version': 1,
          'features': {'session_chat_streaming': true},
          'endpoints': {
            'session_chat_stream': {
              'method': 'POST',
              'path': '/api/sessions/{session_id}/chat/stream',
            },
            'model_options': {'method': 'GET', 'path': '/api/model/options'},
            'session_model_lock': {
              'method': 'POST',
              'path': '/api/sessions/{session_id}/model',
            },
          },
        }),
        modelOptions: const HermesModelOptions(
          currentProvider: 'synthetic',
          currentModel: 'model-a',
          providers: [
            HermesModelOptionProvider(
              slug: 'synthetic',
              label: 'Synthetic',
              models: ['model-a'],
              authenticated: true,
            ),
          ],
        ),
      );
}

class _VoiceSettings extends WingVoiceSettingsController {
  @override
  WingVoiceSettings build() =>
      const WingVoiceSettings(speakRepliesEnabled: true);
}

Future<void> _size(
  WidgetTester tester,
  AccessResize resize,
  double width,
) async {
  await resize(Size(width, 1000));
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1000);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _chat(
  WidgetTester tester,
  _Channel channel, {
  VoiceCaptureService? capture,
  TextToSpeechService? speech,
  Brightness brightness = Brightness.light,
  double scale = 2,
}) async {
  addTearDown(channel.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(
          const EmptyHermesEndpointStore(),
        ),
        hermesVoiceCaptureServiceProvider.overrideWithValue(capture),
        hermesTextToSpeechServiceProvider.overrideWithValue(speech),
        wingVoiceSettingsProvider.overrideWith(_VoiceSettings.new),
      ],
      child: MaterialApp(
        theme: wingThemeFor(WingThemePalette.wing, brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(HermesChatScreen)),
  );
}

String _draft(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(_editor)).controller!.text;
bool _hasFocus(WidgetTester tester, Key key) {
  final target = tester.element(find.byKey(key));
  final focus = FocusManager.instance.primaryFocus?.context;
  var found = identical(target, focus);
  focus?.visitAncestorElements((element) {
    found = found || identical(element, target);
    return !found;
  });
  return found;
}

Future<void> _tabTo(WidgetTester tester, Key key) async {
  for (
    var attempts = 0;
    attempts < 100 && !_hasFocus(tester, key);
    attempts++
  ) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  expect(
    _hasFocus(tester, key),
    isTrue,
    reason: 'Unreachable keyboard action: $key',
  );
}

void _passive(_Channel channel, {int deliberateSends = 0}) {
  expect(channel.sentTextAttachments.length, deliberateSends);
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
  expect(channel.lockSessionModelCalls, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
  expect(channel.stopActiveTurnCalls, 0);
}

Future<Map<String, Object?>> qualifyAccessKeyboard(
  WidgetTester tester,
  AccessResize resize,
) async {
  final semantics = tester.ensureSemantics();
  try {
    final observations = <Map<String, Object?>>[];
    for (final brightness in Brightness.values) {
      final channel = _Channel();
      await _size(tester, resize, 1280);
      final container = await _chat(tester, channel, brightness: brightness);
      await tester.enterText(
        find.byKey(_editor),
        'Synthetic retained keyboard draft',
      );
      for (final width in [1280.0, 390.0, 1280.0]) {
        await _size(tester, resize, width);
        final media = MediaQuery.of(tester.element(find.byKey(_editor)));
        expect(media.disableAnimations, isTrue);
        expect(media.textScaler.scale(14), 28);
        final controls = <Map<String, Object?>>[];
        for (final key in [
          _editor,
          _model,
          const ValueKey('hermes-attachment-button'),
          _dictate,
          const ValueKey('hermes-composer-voice-options'),
          _live,
          _send,
        ]) {
          await _tabTo(tester, key);
          final finder = find.byKey(key);
          expect(finder.hitTestable(), findsOneWidget);
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(1000));
          final node = tester.getSemantics(
            key == _editor
                ? find.descendant(
                    of: finder,
                    matching: find.byType(EditableText),
                  )
                : finder,
          );
          final label = '${node.label} ${node.tooltip}'.trim();
          if (key == _editor) {
            expect(node.flagsCollection.isTextField, isTrue);
            expect(node.value, 'Synthetic retained keyboard draft');
          } else {
            expect(label, isNotEmpty, reason: 'Unnamed control: $key');
          }
          controls.add({
            'label': label,
            'rect': [rect.left, rect.top, rect.right, rect.bottom],
          });
        }
        await _tabTo(tester, _model);
        final launcher = FocusManager.instance.primaryFocus;
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(SessionModelPickerSheet), findsOneWidget);
        await _tabTo(tester, const ValueKey('session-model-search'));
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(SessionModelPickerSheet), findsNothing);
        expect(FocusManager.instance.primaryFocus, same(launcher));
        expect(_draft(tester), 'Synthetic retained keyboard draft');
        final surface = find.byKey(
          ValueKey(
            width < 600
                ? 'hermes-composer-surface'
                : 'hermes-desktop-command-bar',
          ),
        );
        expect(
          find.descendant(of: surface, matching: find.byType(ScaleTransition)),
          findsNothing,
        );
        expect(
          tester.widget<TextField>(find.byKey(_editor)).decoration!.filled,
          isFalse,
        );
        final background =
            (tester.widget<Container>(surface).decoration! as BoxDecoration)
                .color!;
        expect(background.a, 1);
        final editor = tester.widget<EditableText>(
          find.byType(EditableText).first,
        );
        final foreground = Color.alphaBlend(editor.style.color!, background);
        final light = foreground.computeLuminance(),
            dark = background.computeLuminance();
        final ratio =
            ((light > dark ? light : dark) + .05) /
            ((light > dark ? dark : light) + .05);
        expect(ratio, greaterThanOrEqualTo(4.5));
        observations.add({
          'width': width,
          'brightness': brightness.name,
          'controls': controls,
          'editor_contrast_ratio': ratio,
          'foreground_argb': foreground.toARGB32(),
          'paint_background_argb': background.toARGB32(),
          'dismissal_focus_restored': true,
        });
        _passive(channel);
        expect(tester.takeException(), isNull);
      }
      // Draft ownership changes intentionally retire the old platform input
      // client. A stable, non-editor action must not lose keyboard focus.
      await _tabTo(tester, _model);
      final focusedModel = FocusManager.instance.primaryFocus;
      final replacement = _Channel(profile: 'synthetic-keyboard-replacement');
      addTearDown(replacement.dispose);
      container.updateOverrides([
        hermesChannelProvider.overrideWithValue(replacement),
        hermesEndpointStoreProvider.overrideWithValue(
          const EmptyHermesEndpointStore(),
        ),
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
        wingVoiceSettingsProvider.overrideWith(_VoiceSettings.new),
      ]);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus,
        same(focusedModel),
        reason: 'Owner replacement lost model action focus',
      );
      expect(_hasFocus(tester, _model), isTrue);
      await tester.enterText(
        find.byKey(_editor),
        'Synthetic replacement keyboard draft',
      );
      channel.notifyListeners();
      await tester.pumpAndSettle();
      expect(_hasFocus(tester, _editor), isTrue);
      expect(_draft(tester), 'Synthetic replacement keyboard draft');
      _passive(channel);
      _passive(replacement);
      observations.add({
        'brightness': brightness.name,
        'owner_replacement_model_focus_retained': true,
        'obsolete_owner_notification_ignored': true,
      });
      await tester.pumpWidget(const SizedBox.shrink());
    }
    return {
      'observations': observations,
      'text_scale': 2,
      'reduced_motion': true,
      'contrast_scope':
          'alpha-composited editor text against its painted container only',
      'input': 'framework Tab/Enter/Escape and resize, not physical input',
    };
  } finally {
    semantics.dispose();
  }
}

Future<Map<String, Object?>> qualifyAccessStatus(
  WidgetTester tester,
  AccessResize resize,
) async {
  final semantics = tester.ensureSemantics();
  try {
    final phases = <Map<String, Object?>>[];
    for (final width in [390.0, 1280.0]) {
      final channel = StatusAccessibilityNativeFixture();
      addTearDown(channel.dispose);
      await _size(tester, resize, width);
      await tester.pumpWidget(status.statusApp(channel, 2));
      await tester.pumpAndSettle();
      await status.inspectStatus(tester, width);
      for (final phase in [
        'connected',
        'recovering',
        'failed',
        'replacement',
      ]) {
        if (phase != 'connected') channel.phase(phase);
        await tester.pumpAndSettle();
        if (phase == 'connected' || phase == 'replacement') {
          final model = phase == 'connected'
              ? StatusAccessibilityNativeFixture.model
              : StatusAccessibilityNativeFixture.replacementModel;
          expect(find.bySemanticsLabel('Model: $model'), findsOneWidget);
          final label = find.text(model);
          expect(tester.widget<Text>(label).maxLines, isNull);
          final rect = tester.getRect(label);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
          expect(rect.bottom, lessThanOrEqualTo(1000));
        } else {
          expect(
            find.text(StatusAccessibilityNativeFixture.model),
            findsNothing,
          );
          expect(find.text('Disconnected'), findsOneWidget);
        }
        expect(channel.mutationCounts.values, everyElement(0));
        expect(tester.takeException(), isNull);
        phases.add({'width': width, 'phase': phase});
      }
      if (width < 600) {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
    return {'phases': phases, 'text_scale': 2, 'screen_reader': 'not_run'};
  } finally {
    semantics.dispose();
  }
}

enum AccessVoiceBoundary {
  unavailable,
  denied,
  cancel,
  background,
  owner,
  dispose,
  playback,
}

class _Capture implements VoiceCaptureService {
  final result = Completer<VoiceCapture>();
  int starts = 0, cancels = 0;
  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    starts++;
    return result.future;
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }

  void finishLate() {
    if (!result.isCompleted) {
      result.complete(
        VoiceCapture(
          audio: Uint8List(0),
          transcript: 'Obsolete synthetic recognition',
          duration: Duration.zero,
          confidence: 1,
        ),
      );
    }
  }
}

class _Speech implements TextToSpeechService {
  final result = Completer<void>();
  int starts = 0, stops = 0;
  @override
  Future<void> speak(String text) {
    starts++;
    return result.future;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() => stop();
}

Future<({Map<String, int> counts, Map<String, Object?> evidence})>
qualifyVoiceBoundary(
  WidgetTester tester,
  AccessVoiceBoundary boundary,
  AccessResize resize,
) async {
  await _size(tester, resize, 1280);
  final channel = _Channel(), capture = _Capture(), speech = _Speech();
  final channels = [channel];
  final live = [
    AccessVoiceBoundary.background,
    AccessVoiceBoundary.owner,
    AccessVoiceBoundary.dispose,
  ].contains(boundary);
  final container = await _chat(
    tester,
    channel,
    capture: boundary == AccessVoiceBoundary.unavailable ? null : capture,
    speech: speech,
  );
  await tester.enterText(find.byKey(_editor), 'Synthetic retained voice draft');
  await tester.pumpAndSettle();
  expect(capture.starts, 0, reason: 'Capture requires explicit entry');
  expect(speech.starts, 0, reason: 'Playback requires an explicit turn');
  _passive(channel);
  if (boundary == AccessVoiceBoundary.unavailable) {
    expect(createDefaultVoiceCaptureService(), isNull);
    await tester.tap(find.byKey(_live));
    await tester.pumpAndSettle();
    expect(find.text('Live voice unavailable'), findsOneWidget);
    await tester.tap(find.text('Continue in text'));
  } else if (boundary == AccessVoiceBoundary.playback) {
    await tester.tap(find.byKey(_send));
    await tester.pumpAndSettle();
    expect(speech.starts, 1);
    await tester.enterText(
      find.byKey(_editor),
      'Synthetic retained voice draft',
    );
    await tester.tap(find.byTooltip('Stop speaking'));
    await tester.pumpAndSettle();
    expect(speech.stops, greaterThanOrEqualTo(1));
    speech.result.complete();
  } else {
    await _tabTo(tester, live ? _live : _dictate);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(capture.starts, 1);
    if (live) {
      expect(
        find.byKey(const ValueKey('hermes-voice-mode-surface')),
        findsOneWidget,
      );
    }
    switch (boundary) {
      case AccessVoiceBoundary.denied:
        capture.result.completeError(
          const DeviceSpeechUnavailable('microphone permission denied'),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('hermes-voice-error')),
          findsOneWidget,
        );
        expect(
          find.text(
            AppLocalizations.of(
              tester.element(find.byKey(_editor)),
            ).chatVoiceMicrophonePermissionDenied,
          ),
          findsOneWidget,
        );
      case AccessVoiceBoundary.cancel:
        await tester.tap(find.byTooltip('Cancel draft dictation'));
      case AccessVoiceBoundary.background:
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      case AccessVoiceBoundary.owner:
        final replacement = _Channel(profile: 'synthetic-replacement');
        channels.add(replacement);
        addTearDown(replacement.dispose);
        container.updateOverrides([
          hermesChannelProvider.overrideWithValue(replacement),
          hermesEndpointStoreProvider.overrideWithValue(
            const EmptyHermesEndpointStore(),
          ),
          hermesVoiceCaptureServiceProvider.overrideWithValue(capture),
          hermesTextToSpeechServiceProvider.overrideWithValue(speech),
          wingVoiceSettingsProvider.overrideWith(_VoiceSettings.new),
        ]);
        await tester.pumpAndSettle();
        // Live voice replaces the editor. Its returned text alternative must
        // be keyboard reachable and must not lose focus to obsolete callbacks.
        await _tabTo(tester, _editor);
        await tester.enterText(
          find.byKey(_editor),
          'Synthetic replacement draft',
        );
      case AccessVoiceBoundary.dispose:
        await tester.pumpWidget(const SizedBox.shrink());
      default:
        throw StateError('Unreachable voice boundary');
    }
    await tester.pumpAndSettle();
    expect(capture.cancels, greaterThanOrEqualTo(1));
    capture.finishLate();
  }
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  final expectedStarts =
      boundary == AccessVoiceBoundary.unavailable ||
          boundary == AccessVoiceBoundary.playback
      ? 0
      : 1;
  expect(capture.starts, expectedStarts, reason: 'No automatic re-arm');
  expect(speech.starts, boundary == AccessVoiceBoundary.playback ? 1 : 0);
  if (boundary != AccessVoiceBoundary.dispose) {
    expect(
      _draft(tester),
      boundary == AccessVoiceBoundary.owner
          ? 'Synthetic replacement draft'
          : 'Synthetic retained voice draft',
    );
    expect(tester.widget<TextField>(find.byKey(_editor)).enabled, isTrue);
    if (boundary == AccessVoiceBoundary.owner) {
      expect(_hasFocus(tester, _editor), isTrue);
    }
  }
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  for (final owner in channels) {
    _passive(
      owner,
      deliberateSends:
          identical(owner, channel) && boundary == AccessVoiceBoundary.playback
          ? 1
          : 0,
    );
  }
  expect(tester.takeException(), isNull);
  return (
    counts: {
      'capture_starts': capture.starts,
      'capture_cancels': capture.cancels,
      'playback_starts': speech.starts,
      'playback_stops': speech.stops,
      'text_sends': channels.fold(
        0,
        (sum, c) => sum + c.sentTextAttachments.length,
      ),
      'voice_sends': channels.fold(
        0,
        (sum, c) => sum + c.sentVoiceTranscripts.length,
      ),
      'automatic_rearms': capture.starts - expectedStarts,
    },
    evidence: {
      'boundary': boundary.name,
      'active_live_loop': live,
      'draft_retained': boundary != AccessVoiceBoundary.dispose,
      'late_callback_injected':
          boundary != AccessVoiceBoundary.unavailable &&
          boundary != AccessVoiceBoundary.denied,
      'late_callback_boundary': boundary == AccessVoiceBoundary.playback
          ? 'explicit playback Stop'
          : live
          ? boundary.name
          : boundary == AccessVoiceBoundary.cancel
          ? 'explicit draft cancellation'
          : 'not applicable',
      'lifecycle': boundary == AccessVoiceBoundary.background
          ? 'framework inactive/resumed; not OS minimize'
          : 'none',
      'positive_microphone_audio': 'not_run',
    },
  );
}

Future<Map<String, Object?>> qualifyHostCommand(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/hermes',
    routes: [
      for (final path in ['/hermes', '/settings'])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(
            body: TextField(
              autofocus: true,
              decoration: InputDecoration(labelText: path),
            ),
          ),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        hermesChannelProvider.overrideWith(
          (_) => throw StateError('Host command constructed Agent channel'),
        ),
      ],
      child: DesktopHostCommandListener(
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final handled = Completer<void>();
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    WingDesktopHostCommands.channelName,
    const StandardMethodCodec().encodeMethodCall(
      const MethodCall(WingDesktopHostCommands.openSettings),
    ),
    (_) => handled.complete(),
  );
  await handled.future;
  await tester.pumpAndSettle();
  expect(router.routeInformationProvider.value.uri.path, '/settings');
  router.go('/hermes');
  await tester.pumpAndSettle();
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.comma);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
  expect(router.routeInformationProvider.value.uri.path, '/settings');
  expect(tester.takeException(), isNull);
  return {
    'command': 'openSettings',
    'shortcut': 'Ctrl+,',
    'OS_menu_click': 'not_run',
  };
}

Future<Map<String, Object?>> qualifyNativeExport(
  WidgetTester tester,
  String root,
  AccessResize resize,
) async {
  // The campaign isolates XDG_DATA_DIRS as well as HOME. GdkPixbuf needs
  // shared-mime-info even for GTK's built-in fallback PNG; seed only this
  // fixed public metadata file, never user MIME settings or inherited roots.
  expect(Platform.environment['XDG_DATA_DIRS'], '$root/data');
  final mimeBytes = File('/usr/share/mime/mime.cache').readAsBytesSync();
  final mimeCache = File('$root/data/mime/mime.cache');
  mimeCache.parent.createSync(recursive: true);
  mimeCache.writeAsBytesSync(mimeBytes, flush: true);
  await _size(tester, resize, 1280);
  final channel = _Channel()
    ..replaceTranscript([
      HermesChatTurn(
        id: 'synthetic-export',
        sessionId: 'sess_1',
        author: HermesTurnAuthor.assistant,
        createdAt: DateTime.utc(2026),
        text: 'Synthetic exported text — 日本語 😀',
      ),
    ]);
  await _chat(tester, channel, scale: 1);
  final owned = Directory('$root/cache').createTempSync('wing-linux-native.');
  File('${owned.path}/.wing-linux-test-owner').writeAsStringSync('access');
  final destination = File('${owned.path}/hermes-transcript.txt');
  addTearDown(() async {
    await Clipboard.setData(const ClipboardData(text: ''));
    if (owned.existsSync()) owned.deleteSync(recursive: true);
  });
  Future<void> menu() async {
    await tester.tap(
      find.byKey(const ValueKey('hermes-copy-transcript-button')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooser(String mode) async {
    final result = await tester.runAsync(
      () => Process.run(
        '/usr/bin/python3',
        ['scripts/linux_native_input.py', mode],
        environment: {
          'WING_ISOLATED_NATIVE_INPUT': '1',
          'WING_LINUX_TEST_ROOT': owned.path,
          'XDG_CONFIG_HOME': '${owned.path}/config',
          'TMPDIR': '$root/cache',
          'WING_NATIVE_SAVE_FILENAME': 'hermes-transcript.txt',
        },
      ),
    );
    expect(result!.exitCode, 0, reason: 'Owned X11 chooser failed');
  }

  await menu();
  await tester.tap(find.byKey(const ValueKey('hermes-copy-transcript-text')));
  await tester.pumpAndSettle();
  final copied = (await Clipboard.getData(Clipboard.kTextPlain))!.text!;
  expect(copied, contains('Synthetic exported text — 日本語 😀'));
  await menu();
  await tester.tap(find.byKey(const ValueKey('hermes-save-transcript-text')));
  await tester.pump();
  await chooser('save_cancel');
  await tester.pumpAndSettle();
  expect(destination.existsSync(), isFalse);
  await menu();
  await tester.tap(find.byKey(const ValueKey('hermes-save-transcript-text')));
  await tester.pump();
  await chooser('save');
  Future<void> waitFor(Finder finder) async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsOneWidget);
  }

  final confirm = find.widgetWithText(
    FilledButton,
    'Save and allow replacement',
  );
  await waitFor(confirm);
  expect(destination.existsSync(), isFalse);
  await tester.tap(confirm);
  await waitFor(find.text('Transcript saved to the selected file.'));
  expect(destination.readAsBytesSync(), utf8.encode(copied));
  expect(channel.loadEarlierMessagesCalls, 0);
  _passive(channel);
  expect(tester.takeException(), isNull);
  return {
    'mime_metadata': 'stock shared-mime-info cache in owned XDG data only',
    'mime_cache_sha256': sha256.convert(mimeBytes).toString(),
    'clipboard': 'real owned GTK clipboard',
    'chooser': 'real GTK; OS-injected X11 keys',
    'readback': 'exact UTF-8 bytes',
    'cleanup': 'clear owned clipboard and delete owned export root in teardown',
    'physical_input': 'not_run',
  };
}
