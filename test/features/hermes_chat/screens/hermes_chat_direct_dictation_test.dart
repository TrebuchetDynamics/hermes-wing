import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:wing/shared/voice/voice_capture_failures.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';

import '../support/fake_hermes_channel.dart';

const _draft = ValueKey('hermes-draft-mic-button');
const _field = ValueKey('hermes-composer-field');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets('wide draft microphone keyboard activation ${key.keyLabel}', (
      tester,
    ) async {
      final channel = _Channel();
      final capture = _Capture();
      await _mount(tester, channel, capture);
      final draft = find.byKey(_draft);
      expect(draft, findsOneWidget);
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('hermes-attachment-button')))
            .dx,
        lessThan(tester.getTopLeft(draft).dx),
      );
      expect(
        tester.getTopLeft(draft).dx,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('hermes-composer-model-chip')),
              )
              .dx,
        ),
      );
      final semantics = tester.getSemantics(draft);
      expect(
        '${semantics.label} ${semantics.tooltip}',
        contains('Dictate a draft'),
      );
      await tester.enterText(find.byKey(_field), 'existing draft');
      final button = tester.widget<IconButton>(draft);
      final start = button.onPressed!;
      // Reach the direct microphone from the editor without a pointer.
      for (var i = 0; i < 12 && !_draftFocused(); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(_draftFocused(), isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(_draftFocused(), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_draftFocused(), isTrue);
      await tester.sendKeyEvent(key);
      await tester.pump();
      start();
      await tester.pump();
      expect(capture.calls, 1);
      expect(find.byTooltip('Cancel draft dictation'), findsOneWidget);
      capture.complete('addition');
      await tester.pumpAndSettle();
      final composer = tester.widget<TextField>(find.byKey(_field));
      expect(composer.controller!.text, 'existing draft addition');
      expect(
        composer.controller!.selection.baseOffset,
        composer.controller!.text.length,
      );
      expect(composer.focusNode!.hasFocus, isTrue);
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('hermes-continuous-voice-switch')),
            )
            .value,
        isFalse,
      );
      _zeroMutations(channel);
    });
  }

  testWidgets('named cancel discards late capture and permits a fresh retry', (
    tester,
  ) async {
    final channel = _Channel();
    final capture = _Capture();
    await _mount(tester, channel, capture);
    await tester.enterText(find.byKey(_field), 'keep');
    await tester.tap(find.byKey(_draft));
    await tester.pump();
    await tester.tap(find.byTooltip('Cancel draft dictation'));
    await tester.pump();
    expect(capture.cancels, 1);
    capture.complete('discard');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(_field)).controller!.text,
      'keep',
    );
    await tester.tap(find.byKey(_draft));
    await tester.pump();
    expect(capture.calls, 2);
    capture.complete('fresh');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(_field)).controller!.text,
      'keep fresh',
    );
    _zeroMutations(channel);
  });

  for (final change in [
    'session',
    'profile',
    'origin',
    'disconnect',
    'selecting',
    'recovery',
  ]) {
    testWidgets('cached action and late capture reject $change owner/gate loss', (
      tester,
    ) async {
      final channel = _Channel();
      final capture = _Capture();
      await _mount(tester, channel, capture);
      final cached = tester.widget<IconButton>(find.byKey(_draft)).onPressed!;
      final original = channel.state;
      channel.replace(_changed(original, change));
      cached();
      await tester.pump();
      expect(capture.calls, 0);
      channel.replace(original);
      cached(); // Returning to the same identity does not revive cached intent.
      await tester.pumpAndSettle();
      expect(capture.calls, 0);
      await tester.enterText(find.byKey(_field), 'keep');
      await tester.tap(find.byKey(_draft));
      await tester.pump();
      expect(capture.calls, 1);
      channel.replace(_changed(original, change));
      channel.replace(original);
      await tester.pumpAndSettle();
      final composer = tester.widget<TextField>(find.byKey(_field));
      composer.controller!.text = 'replacement';
      composer.focusNode!.unfocus();
      await tester.pump();
      capture.complete('late');
      await tester.pumpAndSettle();
      expect(composer.controller!.text, 'replacement');
      expect(composer.focusNode!.hasFocus, isFalse);
      expect(capture.calls, 1);
      _zeroMutations(channel);
    });
  }

  for (final failure in <Object?>[
    null,
    const DeviceSpeechUnavailable('microphone_permission_denied'),
    const VoiceCaptureTimeout(),
    const SpeechToTextCaptureFailure('Synthetic transcription failure'),
  ]) {
    testWidgets('draft failure keeps text and explicit retry: $failure', (
      tester,
    ) async {
      final channel = _Channel();
      final capture = failure == null ? null : _Capture();
      await _mount(tester, channel, capture);
      await tester.enterText(find.byKey(_field), 'keep');
      await tester.tap(find.byKey(_draft));
      await tester.pump();
      capture?.pending!.completeError(failure!);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hermes-voice-error')), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(_field)).controller!.text,
        'keep',
      );
      if (capture != null) {
        expect(capture.cancels, 1);
        await tester.tap(find.byKey(_draft));
        await tester.pump();
        expect(capture.calls, 2);
        capture.complete('retry');
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byKey(_field)).controller!.text,
          'keep retry',
        );
      } else {
        await tester.tap(find.text('Continue in text'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('hermes-voice-error')), findsNothing);
        await tester.enterText(find.byKey(_field), 'text still works');
      }
      _zeroMutations(channel);
    });
  }

  testWidgets('retry waits for cancelled microphone teardown', (tester) async {
    final channel = _Channel();
    final barrier = Completer<void>();
    final capture = _Capture()..cancelBarrier = barrier.future;
    await _mount(tester, channel, capture);
    await tester.tap(find.byKey(_draft));
    await tester.pump();
    final old = capture.pending!;
    await tester.tap(find.byTooltip('Cancel draft dictation'));
    await tester.pump();
    await tester.tap(find.byKey(_draft));
    await tester.pump();
    expect(capture.calls, 1);
    barrier.complete();
    await tester.pump();
    expect(capture.calls, 2);
    old.complete(
      VoiceCapture(
        audio: Uint8List(0),
        transcript: 'late',
        duration: Duration.zero,
        confidence: 1,
      ),
    );
    capture.complete('fresh');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(_field)).controller!.text,
      'fresh',
    );
    _zeroMutations(channel);
  });

  testWidgets('voice master gate invalidates cached intent and active draft', (
    tester,
  ) async {
    final channel = _Channel();
    final capture = _Capture();
    await _mount(tester, channel, capture);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HermesChatScreen)),
    );
    final cached = tester.widget<IconButton>(find.byKey(_draft)).onPressed!;
    final settings = container.read(wingVoiceSettingsProvider.notifier);
    settings.setContinuousVoiceEnabled(false);
    cached();
    await tester.pumpAndSettle();
    expect(capture.calls, 0);
    expect(tester.widget<IconButton>(find.byKey(_draft)).onPressed, isNull);
    settings.setContinuousVoiceEnabled(true);
    cached();
    await tester.pumpAndSettle();
    expect(capture.calls, 0);
    await tester.tap(find.byKey(_draft));
    await tester.pump();
    settings.setContinuousVoiceEnabled(false);
    await tester.pump();
    capture.complete('discard');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(_field)).controller!.text,
      isEmpty,
    );
    _zeroMutations(channel);
  });

  for (final dispose in [false, true]) {
    testWidgets('late draft rejects channel replacement/disposal $dispose', (
      tester,
    ) async {
      final channel = _Channel();
      final replacement = _Channel();
      addTearDown(replacement.dispose);
      final capture = _Capture();
      await _mount(tester, channel, capture);
      final cached = tester.widget<IconButton>(find.byKey(_draft)).onPressed!;
      await tester.tap(find.byKey(_draft));
      await tester.pump();
      if (dispose) {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      } else {
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HermesChatScreen)),
        );
        container.updateOverrides([
          hermesChannelProvider.overrideWithValue(replacement),
          hermesVoiceCaptureServiceProvider.overrideWithValue(capture),
        ]);
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(_field), 'replacement');
        tester.widget<TextField>(find.byKey(_field)).focusNode!.unfocus();
        await tester.pump();
      }
      cached();
      capture.complete('late');
      await tester.pumpAndSettle();
      expect(capture.calls, 1);
      if (!dispose) {
        final composer = tester.widget<TextField>(find.byKey(_field));
        expect(composer.controller!.text, 'replacement');
        expect(composer.focusNode!.hasFocus, isFalse);
      }
      expect(tester.takeException(), isNull);
      _zeroMutations(channel);
      _zeroMutations(replacement);
    });
  }

  testWidgets(
    'production channel draft sends zero mutations or unsupported audio requests',
    (tester) async {
      final mutations = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' =>
              '{"object":"hermes.api_server.capabilities","schema_version":1,"platform":"test","model":"test","features":{"session_chat_streaming":true},"endpoints":{"session_chat_stream":{"method":"POST","path":"/api/sessions/{session_id}/chat/stream"}}}',
            '/api/sessions' =>
              '{"object":"list","data":[{"id":"synthetic","source":"test"}]}',
            '/api/sessions/synthetic/messages' =>
              '{"object":"list","session_id":"synthetic","data":[]}',
            _ => throw StateError('Unexpected read: ${uri.path}'),
          },
          post: (uri, headers, body) async {
            mutations.add(uri.path);
            throw StateError('Unexpected mutation');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      expect(channel.state.isConnected, isTrue);
      final capture = _Capture();
      await _mount(tester, channel, capture);
      await tester.enterText(find.byKey(_field), 'keep');
      await tester.tap(find.byKey(_draft));
      await tester.pump();
      capture.complete('addition', audio: Uint8List.fromList([0, 0]));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byKey(_field)).controller!.text,
        'keep addition',
      );
      await tester.tap(find.byKey(_draft));
      await tester.pump();
      await tester.tap(find.byTooltip('Cancel draft dictation'));
      await tester.pump();
      capture.complete('discard');
      await tester.pumpAndSettle();
      expect(channel.state.voiceRuns, isEmpty);
      expect(mutations, isEmpty);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}

HermesChannelState _changed(HermesChannelState state, String change) =>
    switch (change) {
      'session' => state.copyWith(activeSessionId: 'other'),
      'profile' => state.copyWith(selectedProfileId: 'other'),
      'origin' => state.copyWith(connectedBaseUrl: 'http://other.invalid'),
      'disconnect' => state.copyWith(
        status: HermesConnectionStatus.disconnected,
      ),
      'selecting' => state.copyWith(isSelectingProfile: true),
      _ => state.copyWith(hasUnreconciledRun: true),
    };

Future<void> _mount(
  WidgetTester tester,
  HermesChannel channel,
  _Capture? capture,
) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown((channel as ChangeNotifier).dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesVoiceCaptureServiceProvider.overrideWithValue(capture),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HermesChatScreen(voiceCaptureServiceOverride: capture),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _zeroMutations(_Channel channel) {
  debugDefaultTargetPlatformOverride = null;
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.lockSessionModelCalls, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
  expect(channel.sentImageDataUrls, isEmpty);
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(channel.state.voiceRuns, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
  expect(channel.stopActiveTurnCalls, 0);
}

bool _draftFocused() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<IconButton>()
        ?.key ==
    _draft;

class _Channel extends FakeHermesChannel {
  HermesChannelState? replacement;
  @override
  HermesChannelState get state => replacement ?? super.state;
  void replace(HermesChannelState state) {
    replacement = state;
    notifyListeners();
  }
}

class _Capture implements VoiceCaptureService {
  Future<void>? cancelBarrier;
  int calls = 0;
  int cancels = 0;
  Completer<VoiceCapture>? pending;
  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    calls++;
    pending = Completer<VoiceCapture>();
    return pending!.future;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    await cancelBarrier;
  }

  void complete(String text, {Uint8List? audio}) => pending!.complete(
    VoiceCapture(
      audio: audio ?? Uint8List(0),
      transcript: text,
      duration: const Duration(seconds: 1),
      confidence: 1,
    ),
  );
}
