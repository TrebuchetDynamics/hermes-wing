import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/session_model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';

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

final _scale = ValueNotifier<double>(2);
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _scale.value = 2;
  });
  for (final activation in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
  ]) {
    testWidgets(
      '200% text reduced-motion adaptive keyboard ${activation.keyLabel}',
      (tester) async {
        final channel = _Channel();
        final capture = _Capture();
        await _mount(tester, channel, capture: capture);
        await tester.enterText(find.byKey(_field), 'retained owner draft');
        final owner = (
          channel.state.activeSessionId,
          channel.state.selectedProfileId,
          channel.state.connectedBaseUrl,
        );
        final media = MediaQuery.of(tester.element(find.byKey(_field)));
        expect(media.textScaler.scale(14), 28);
        expect(media.disableAnimations, isTrue);
        await _reach(tester, _field);
        await _traverse(tester);
        _readable(tester, _order);
        await _reach(tester, _draft);
        await tester.sendKeyEvent(activation);
        await tester.pump();
        await tester.sendKeyEvent(activation);
        await tester.pump();
        expect(capture.calls, 1);
        expect(capture.cancels, 1);
        expect(channel.stopActiveTurnCalls, 0);
        capture.complete('cancelled addition');
        await tester.pumpAndSettle();
        await _reach(tester, _model);
        await tester.sendKeyEvent(activation);
        await tester.pumpAndSettle();
        expect(find.byType(SessionModelPickerSheet), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await _resize(tester, 600);
        await _reach(tester, _field);
        for (final key in [_attachment, _send]) {
          await _tab(tester);
          _expectFocus(tester, key);
        }
        for (final key in [_attachment, _field]) {
          await _tab(tester, reverse: true);
          _expectFocus(tester, key);
        }
        _readable(tester, [
          _attachment,
          _send,
          const ValueKey('hermes-composer-menu-button'),
        ]);
        final switcher = tester.widget<AnimatedSwitcher>(
          find.descendant(
            of: find.byKey(const ValueKey('hermes-composer-surface')),
            matching: find.byType(AnimatedSwitcher),
          ),
        );
        expect(switcher.duration, Duration.zero);
        // Real text scaling changes, without remounting the channel or editor.
        _scale.value = 1.5;
        await tester.pumpAndSettle();
        _scale.value = 2;
        await _resize(tester, 1440);
        await _reach(tester, _field);
        await _traverse(tester);
        expect(_text(tester), 'retained owner draft');
        expect((
          channel.state.activeSessionId,
          channel.state.selectedProfileId,
          channel.state.connectedBaseUrl,
        ), owner);
        _noMutations(channel);
        channel.beginStreamingTurn('synthetic run');
        await tester.pump();
        await _reach(tester, _stop);
        _readable(tester, [_stop]);
        await tester.sendKeyEvent(activation);
        await tester.pumpAndSettle();
        expect(_text(tester), 'retained owner draft');
        _noMutations(channel, stops: 1);
        expect(channel.stopOwners, [owner]);
        expect(tester.takeException(), isNull);
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}

void _readable(WidgetTester tester, List<Key> keys) {
  for (final key in keys) {
    final finder = find.byKey(key);
    final rect = tester.getRect(finder);
    expect(rect.width, greaterThan(0));
    expect(rect.height, greaterThan(0));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(tester.view.physicalSize.width));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(tester.view.physicalSize.height));
    final semantics = tester.getSemantics(finder);
    expect('${semantics.label} ${semantics.tooltip}'.trim(), isNotEmpty);
  }
  expect(tester.takeException(), isNull);
}

String _text(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(_field)).controller!.text;
Future<void> _resize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  // Compact active-run progress is intentionally continuous.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
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
      child: MaterialApp(
        builder: (context, child) => ValueListenableBuilder<double>(
          valueListenable: _scale,
          builder: (context, scale, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
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

void _noMutations(_Channel channel, {int stops = 0}) {
  expect(channel.sentImageDataUrls, isEmpty);
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.lockSessionModelCalls, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
  expect(channel.stopActiveTurnCalls, stops);
}

class _Channel extends FakeHermesChannel {
  _Channel()
    : super(
        selectedProfileId: 'synthetic-profile',
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
        modelOptions: _options,
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
  final stopOwners = <(String?, String?, String?)>[];
  @override
  void stopActiveTurn() {
    stopOwners.add((
      state.activeSessionId,
      state.selectedProfileId,
      state.connectedBaseUrl,
    ));
    super.stopActiveTurn();
  }
}
