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

  testWidgets(
    'wide supported toolbar has named forward and reverse traversal',
    (tester) async {
      final channel = _Channel();
      await _mount(tester, channel);
      await tester.enterText(find.byKey(_field), 'retained draft');
      final editor = tester.widget<TextField>(find.byKey(_field));
      expect(editor.focusNode!.hasFocus, isTrue);
      for (var i = 1; i < _order.length; i++) {
        expect(
          tester.getCenter(find.byKey(_order[i - 1])).dx,
          lessThan(tester.getCenter(find.byKey(_order[i])).dx),
        );
      }
      for (final key in _order) {
        await _tab(tester);
        _expectFocus(tester, key);
        final node = tester.getSemantics(find.byKey(key));
        expect('${node.label} ${node.tooltip}'.trim(), isNotEmpty);
      }
      for (final key in _order.reversed.skip(1)) {
        await _tab(tester, reverse: true);
        _expectFocus(tester, key);
      }
      await _tab(tester, reverse: true);
      expect(editor.focusNode!.hasFocus, isTrue);
      expect(editor.controller!.text, 'retained draft');
      _noMutations(channel);
    },
  );

  for (final activation in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
  ]) {
    testWidgets(
      'model loading is single read without writes via ${activation.keyLabel}',
      (tester) async {
        final channel = _Channel(emptyOptions: true)
          ..loadGate = Completer<void>();
        await _mount(tester, channel);
        await tester.enterText(find.byKey(_field), 'retained draft');
        for (final key in [_attachment, _draft, _model]) {
          await _tab(tester);
          _expectFocus(tester, key);
        }
        await tester.sendKeyEvent(activation);
        await tester.pump();
        expect(channel.optionReads, 1);
        await tester.sendKeyEvent(activation);
        await tester.pump();
        expect(channel.optionReads, 1);
        _noMutations(channel, restorePlatform: false);
        channel.loadGate!.complete();
        await tester.pumpAndSettle();
        expect(find.byType(SessionModelPickerSheet), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(SessionModelPickerSheet), findsNothing);
        expect(
          tester.widget<TextField>(find.byKey(_field)).controller!.text,
          'retained draft',
        );
        _noMutations(channel);
      },
    );
  }

  testWidgets(
    'empty Send is disabled and skipped without losing draft controls',
    (tester) async {
      final channel = _Channel();
      await _mount(tester, channel);
      expect(tester.widget<IconButton>(find.byKey(_send)).onPressed, isNull);
      for (final key in _order.take(5)) {
        await _tab(tester);
        _expectFocus(tester, key);
      }
      await _tab(tester);
      expect(_focusedWithin(tester, _send), isFalse);
      _noMutations(channel);
    },
  );

  for (final activation in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
  ]) {
    testWidgets(
      'active run skips disabled model and keeps Stop actionable via ${activation.keyLabel}',
      (tester) async {
        final channel = _Channel();
        await _mount(tester, channel);
        await tester.enterText(find.byKey(_field), 'keep while running');
        channel.beginStreamingTurn('synthetic active turn');
        await tester.pump();
        expect(tester.widget<ActionChip>(find.byKey(_model)).onPressed, isNull);
        // Wing permits explicit local follow-up queuing during a run; traversal
        // must not activate that separate Send action.
        expect(
          tester.widget<IconButton>(find.byKey(_send)).onPressed,
          isNotNull,
        );
        for (final key in [_attachment, _draft, _stop]) {
          await _tab(tester);
          _expectFocus(tester, key);
        }
        await _tab(tester);
        _expectFocus(tester, _switch);
        await _tab(tester, reverse: true);
        _expectFocus(tester, _stop);
        _noMutations(channel, restorePlatform: false);
        await tester.sendKeyEvent(activation);
        await tester.pumpAndSettle();
        expect(channel.stopActiveTurnCalls, 1);
        expect(
          tester.widget<TextField>(find.byKey(_field)).controller!.text,
          'keep while running',
        );
        _noMutations(channel, stops: 1);
      },
    );
  }
}

Future<void> _mount(WidgetTester tester, _Channel channel) async {
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
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
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
