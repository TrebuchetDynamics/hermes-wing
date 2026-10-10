import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/session_model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

const _field = ValueKey('hermes-composer-field');
const _attachment = ValueKey('hermes-attachment-button');
const _draft = ValueKey('hermes-draft-mic-button');
const _model = ValueKey('hermes-composer-model-chip');
const _switch = ValueKey('hermes-continuous-voice-switch');
const _voice = ValueKey('hermes-mic-button');
const _send = ValueKey('hermes-send-button');
const _stop = ValueKey('hermes-composer-stop-chip');
const _order = [_attachment, _draft, _model, _switch, _voice, _send];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('named toolbar traversal survives compact and wide return', (
    tester,
  ) async {
    final channel = _Channel();
    await _mount(tester, channel);
    await tester.enterText(find.byKey(_field), 'retained owner draft');
    await _traverse(tester);
    await _resize(tester, 600);
    expect(
      find.byKey(const ValueKey('hermes-desktop-command-bar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('hermes-composer-menu-button')),
      findsOneWidget,
    );
    await _reach(tester, _field);
    for (final key in [_attachment, _send]) {
      await _tab(tester);
      _expectFocus(tester, key);
    }
    for (final key in [_attachment, _field]) {
      await _tab(tester, reverse: true);
      _expectFocus(tester, key);
    }
    await _resize(tester, 1440);
    await _reach(tester, _field);
    await _traverse(tester);
    expect(_text(tester), 'retained owner draft');
    expect(tester.takeException(), isNull);
    _noMutations(channel);
  });
  for (final owner in ['session', 'profile', 'channel']) {
    testWidgets(
      'pending model read rejects $owner replacement through adaptive return',
      (tester) async {
        final channel = _Channel(emptyOptions: true)
          ..loadGate = Completer<void>();
        final replacement = _Channel();
        addTearDown(replacement.dispose);
        await _mount(tester, channel);
        await tester.enterText(find.byKey(_field), 'original draft');
        await _reach(tester, _model);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(channel.optionReads, 1);
        await _resize(tester, 600);
        if (owner == 'channel') {
          _replaceChannel(tester, replacement);
        } else {
          channel.replace(
            owner == 'session'
                ? channel.state.copyWith(activeSessionId: 'replacement-session')
                : channel.state.copyWith(
                    selectedProfileId: 'replacement-profile',
                  ),
          );
        }
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(_field), 'replacement draft');
        await _resize(tester, 1440);
        await _reach(tester, _attachment);
        channel.loadGate!.complete();
        await tester.pumpAndSettle();
        expect(find.byType(SessionModelPickerSheet), findsNothing);
        _expectFocus(tester, _attachment);
        expect(_text(tester), 'replacement draft');
        expect(channel.optionReads, 1);
        expect(replacement.optionReads, 0);
        _noMutations(channel, restorePlatform: false);
        _noMutations(replacement);
      },
    );
  }
  testWidgets(
    'pending capture replacement rejects late draft and focus after return',
    (tester) async {
      final channel = _Channel(), replacement = _Channel();
      addTearDown(replacement.dispose);
      final capture = _Capture();
      await _mount(tester, channel, capture: capture);
      await tester.enterText(find.byKey(_field), 'original draft');
      await _reach(tester, _draft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(capture.calls, 1);
      await _resize(tester, 600);
      _replaceChannel(tester, replacement, capture: capture);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_field), 'replacement draft');
      await _resize(tester, 1440);
      await _reach(tester, _attachment);
      capture.complete('obsolete addition');
      await tester.pumpAndSettle();
      expect(_text(tester), 'replacement draft');
      _expectFocus(tester, _attachment);
      expect(capture.calls, 1);
      expect(capture.cancels, greaterThanOrEqualTo(1));
      _noMutations(channel, restorePlatform: false);
      _noMutations(replacement);
    },
  );
  for (final activation in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
  ]) {
    testWidgets(
      'capture cancel differs from current-owner run Stop via ${activation.keyLabel} after return',
      (tester) async {
        final channel = _Channel(), replacement = _Channel();
        addTearDown(replacement.dispose);
        final capture = _Capture();
        await _mount(tester, channel, capture: capture);
        await tester.enterText(find.byKey(_field), 'draft');
        await _reach(tester, _draft);
        await tester.sendKeyEvent(activation);
        await tester.pump();
        await tester.sendKeyEvent(activation);
        await tester.pump();
        expect(capture.calls, 1);
        expect(capture.cancels, 1);
        expect(channel.stopActiveTurnCalls, 0);
        capture.complete('cancelled');
        await tester.pumpAndSettle();
        channel.beginStreamingTurn('original run');
        await tester.pump();
        await _resize(tester, 600);
        replacement.beginStreamingTurn('replacement run');
        _replaceChannel(tester, replacement, capture: capture);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(find.byKey(_field), 'current run draft');
        await _resize(tester, 1440);
        await _reach(tester, _stop);
        await _tab(tester);
        _expectFocus(tester, _switch);
        await _tab(tester, reverse: true);
        _expectFocus(tester, _stop);
        await tester.sendKeyEvent(activation);
        await tester.pumpAndSettle();
        expect(_text(tester), 'current run draft');
        expect(capture.cancels, 1);
        _noMutations(channel, restorePlatform: false);
        _noMutations(replacement, stops: 1);
      },
    );
  }
}

String _text(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(_field)).controller!.text;
Future<void> _resize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  // Compact active-run progress is intentionally continuous.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void _replaceChannel(
  WidgetTester tester,
  _Channel channel, {
  _Capture? capture,
}) {
  ProviderScope.containerOf(
    tester.element(find.byType(HermesChatScreen)),
  ).updateOverrides([
    hermesChannelProvider.overrideWithValue(channel),
    hermesVoiceCaptureServiceProvider.overrideWithValue(capture),
    hermesTextToSpeechServiceProvider.overrideWithValue(null),
  ]);
}

Future<void> _reach(WidgetTester tester, Key key) async {
  for (var i = 0; i < 40 && !_focusedWithin(tester, key); i++) {
    await _tab(tester);
  }
  _expectFocus(tester, key);
}

Future<void> _traverse(WidgetTester tester) async {
  for (final key in _order) {
    await _tab(tester);
    _expectFocus(tester, key);
    expect(
      '${tester.getSemantics(find.byKey(key)).label} ${tester.getSemantics(find.byKey(key)).tooltip}'
          .trim(),
      isNotEmpty,
    );
  }
  for (final key in _order.reversed.skip(1)) {
    await _tab(tester, reverse: true);
    _expectFocus(tester, key);
  }
  await _tab(tester, reverse: true);
  _expectFocus(tester, _field);
}

class _Capture implements VoiceCaptureService {
  int calls = 0, cancels = 0;
  final pending = Completer<VoiceCapture>();
  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    calls++;
    return pending.future;
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }

  void complete(String text) => pending.complete(
    VoiceCapture(
      audio: Uint8List(0),
      transcript: text,
      duration: Duration.zero,
      confidence: 1,
    ),
  );
}

Future<void> _mount(
  WidgetTester tester,
  _Channel channel, {
  _Capture? capture,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(channel.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesVoiceCaptureServiceProvider.overrideWithValue(capture),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, {bool reverse = false}) async {
  if (reverse) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  if (reverse) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pump();
}

bool _focusedWithin(WidgetTester tester, Key key) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  final target = tester.element(find.byKey(key));
  var found = identical(target, context);
  context.visitAncestorElements((element) {
    if (identical(element, target)) found = true;
    return !found;
  });
  return found;
}

void _expectFocus(WidgetTester tester, Key key) => expect(
  _focusedWithin(tester, key),
  isTrue,
  reason: 'Expected focus within $key',
);

void _noMutations(
  _Channel channel, {
  int stops = 0,
  bool restorePlatform = true,
}) {
  expect(channel.sentImageDataUrls, isEmpty);
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.lockSessionModelCalls, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
  expect(channel.stopActiveTurnCalls, stops);
  if (restorePlatform) debugDefaultTargetPlatformOverride = null;
}

class _Channel extends FakeHermesChannel {
  _Channel({bool emptyOptions = false})
    : super(
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
        modelOptions: emptyOptions ? null : _options,
      );
  static const _options = HermesModelOptions(
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
  );
  Completer<void>? loadGate;
  int optionReads = 0;
  HermesChannelState? replacement;
  void replace(HermesChannelState value) {
    replacement = value;
    notifyListeners();
  }

  @override
  HermesChannelState get state => replacement ?? super.state;
  @override
  Future<void> loadModelOptions({bool refresh = false}) async {
    optionReads++;
    await loadGate?.future;
    replacement = state.copyWith(modelOptions: _options);
    notifyListeners();
  }
}
