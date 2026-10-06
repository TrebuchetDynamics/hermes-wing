import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

final _source = StateProvider<HermesChannel>((_) => throw UnimplementedError());
const _contact = GatewayContactId(gatewayId: 'original', profileId: 'a');
const _otherContact = GatewayContactId(
  gatewayId: 'replacement',
  profileId: 'b',
);
const _rows = [
  HermesSession(id: 'keep', source: 'test', title: 'Keep'),
  HermesSession(id: 'target', source: 'test', title: 'Target'),
];
final _composer = find.byKey(const ValueKey('hermes-composer-field'));

// Count registrations, not unique callbacks: ChangeNotifier permits duplicates.
mixin _Listeners on ChangeNotifier {
  final listeners = <VoidCallback, int>{};
  int get listenerCount => listeners.values.fold(0, (sum, n) => sum + n);
  @override
  void addListener(VoidCallback listener) {
    listeners.update(listener, (n) => n + 1, ifAbsent: () => 1);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    final count = listeners[listener];
    if (count == 1) {
      listeners.remove(listener);
    } else if (count != null) {
      listeners[listener] = count - 1;
    }
    super.removeListener(listener);
  }
}

class _Channel extends FakeHermesChannel with _Listeners {
  _Channel()
    : super(
        sessions: _rows,
        activeSessionId: 'keep',
        selectedProfileId: 'a',
        connectedBaseUrl: 'https://example.invalid',
        capabilities: HermesCapabilityDocument.fromJson({
          'schema_version': 1,
          'features': {'session_chat_streaming': true},
          'endpoints': {
            'sessions': {'method': 'GET', 'path': '/api/sessions'},
            'session_create': {'method': 'POST', 'path': '/api/sessions'},
            'session_chat_stream': {
              'method': 'POST',
              'path': '/api/sessions/{session_id}/chat/stream',
            },
          },
        }),
      ) {
    change(
      state.copyWith(
        messages: {
          'keep': [
            HermesChatTurn(
              id: 'fixture-reply',
              sessionId: 'keep',
              author: HermesTurnAuthor.assistant,
              createdAt: DateTime.utc(2026, 1, 1),
              text: 'Synthetic loaded reply',
            ),
          ],
          'target': const [],
        },
      ),
    );
  }

  HermesChannelState? _current;
  @override
  HermesChannelState get state => _current ?? super.state;
  int generation = 0;
  Completer<void>? gate;
  bool reject = false;
  // The normal production open history path suppresses obsolete errors. This
  // extra mode characterizes defensive caller behavior for other channels.
  bool suppressObsoleteOpenError = false;
  void change(HermesChannelState next) {
    if (next.isConnected != state.isConnected ||
        next.connectedBaseUrl != state.connectedBaseUrl ||
        next.selectedProfileId != state.selectedProfileId ||
        next.isSelectingProfile != state.isSelectingProfile) {
      generation++;
    }
    _current = next;
    notifyListeners();
  }

  Future<void> _submit(bool create) async {
    final owner = generation;
    final previousSession = state.activeSessionId;
    if (create) {
      createSessionCalls.add(null);
      // Production create legitimately clears the old active session first.
      change(state.copyWith(clearActiveSessionId: true));
    } else {
      selectSessionCalls.add('target');
    }
    await gate?.future;
    if (reject) {
      if (!create && suppressObsoleteOpenError && owner != generation) return;
      if (create && owner == generation) {
        change(state.copyWith(activeSessionId: previousSession));
      }
      // Production create rethrows even when its profile guard is obsolete.
      throw StateError('bounded settlement failure');
    }
    if (owner != generation) return;
    final createdId = 'created-${createSessionCalls.length}';
    change(
      state.copyWith(
        activeSessionId: create ? createdId : 'target',
        sessions: [
          ...state.sessions,
          if (create) HermesSession(id: createdId, source: 'test'),
        ],
      ),
    );
  }

  @override
  Future<void> createSession({String? title, bool Function()? canAccept}) =>
      _submit(true);
  @override
  Future<void> selectSession(String id, {bool Function()? canAccept}) {
    expect(id, 'target');
    return _submit(false);
  }
}

class _Directory extends HermesGatewayDirectory with _Listeners {
  _Directory(_Channel channel)
    : channel = channel,
      super(
        store: FakeHermesEndpointStore(),
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
  final _Channel channel;
  GatewayContactId? contact = _contact;
  @override
  GatewayContactId? get activeContactId => contact;
  void changeContact(GatewayContactId? next) {
    // Contact activation invalidates transport ownership in the real directory.
    // Keep that response fence without network or restoration in this fake;
    // only the directory notifies, independently testing the caller's observer.
    channel.generation++;
    contact = next;
    notifyListeners();
  }

  final refreshes = <String>[];
  @override
  Future<void> reconnectGateway(String gatewayId) async {
    refreshes.add(gatewayId);
  }
}

Future<
  ({
    _Channel channel,
    _Directory directory,
    ProviderContainer container,
    ValueNotifier<bool> visible,
    FocusNode outsideFocus,
  })
>
_pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final channel = _Channel();
  addTearDown(channel.dispose);
  final directory = _Directory(channel);
  final container = ProviderContainer(
    overrides: [
      _source.overrideWith((_) => channel),
      hermesChannelProvider.overrideWith((ref) => ref.watch(_source)),
      hermesGatewayDirectoryProvider.overrideWith((_) => directory),
      hermesEndpointStoreProvider.overrideWithValue(FakeHermesEndpointStore()),
      hermesVoiceCaptureServiceProvider.overrideWithValue(null),
      hermesTextToSpeechServiceProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  final visible = ValueNotifier(true);
  final outsideFocus = FocusNode();
  addTearDown(visible.dispose);
  addTearDown(outsideFocus.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Column(
          children: [
            TextButton(
              focusNode: outsideFocus,
              onPressed: outsideFocus.requestFocus,
              child: const Text('Keep focus outside Chat'),
            ),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: visible,
                builder: (_, show, _) =>
                    show ? const HermesChatScreen() : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return (
    channel: channel,
    directory: directory,
    container: container,
    visible: visible,
    outsideFocus: outsideFocus,
  );
}

Future<void> _submit(WidgetTester tester, double width, String action) async {
  if (width < 900) {
    await tester.tap(find.byKey(const ValueKey('hermes-more-actions-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();
  }
  await tester.tap(
    find.byKey(
      ValueKey(
        action == 'create'
            ? width < 900
                  ? 'hermes-sessions-new'
                  : 'hermes-session-rail-new'
            : 'hermes-session-row-target',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectCalls(_Channel channel, String? action, {int count = 1}) {
  expect(channel.createSessionCalls, hasLength(action == 'create' ? count : 0));
  expect(
    channel.selectSessionCalls,
    action == 'open' ? List.filled(count, 'target') : isEmpty,
  );
  expect(channel.sentImageDataUrls, isEmpty);
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
  expect(channel.createProfileCalls, isEmpty);
  expect(channel.renameProfileCalls, isEmpty);
  expect(channel.deleteProfileCalls, isEmpty);
  expect(channel.selectProfileCalls, isEmpty);
  expect(channel.setProviderCredentialCalls, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
  expect(channel.lockSessionModelCalls, isEmpty);
}

void _testWidgets(String name, WidgetTesterCallback body) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    });
  });
  for (final width in [390.0, 1280.0]) {
    for (final transition in [
      'same owner',
      'profile roundtrip',
      'contact roundtrip',
      'replacement roundtrip',
      'unmount',
    ]) {
      _testWidgets('open focus callback owns $transition at $width', (
        tester,
      ) async {
        final h = await _pump(tester, width);
        final baseline = h.channel.listeners.keys.toSet();
        final directoryBaseline = h.directory.listenerCount;
        h.channel.gate = Completer<void>();
        await _submit(tester, width, 'open');
        final observers = h.channel.listeners.keys
            .toSet()
            .intersection(h.directory.listeners.keys.toSet())
            .difference(baseline);
        expect(observers, hasLength(1));
        await tester.tap(find.text('Keep focus outside Chat'));
        await tester.pumpAndSettle();
        h.channel.gate!.complete();
        // Flush the submitted future without a frame: the public Open caller
        // has now queued its focus callback, but ownership can still change.
        await tester.idle();
        expect(h.channel.state.activeSessionId, 'target');
        expect(
          h.channel.listeners.keys.toSet().intersection(observers),
          observers,
        );
        final owner = h.channel.state;
        if (transition == 'profile roundtrip') {
          h.channel.change(owner.copyWith(selectedProfileId: 'b'));
          h.channel.change(owner);
        } else if (transition == 'contact roundtrip') {
          h.directory.changeContact(null);
          h.directory.changeContact(_contact);
        } else if (transition == 'replacement roundtrip') {
          final replacement = _Channel();
          addTearDown(replacement.dispose);
          h.container.read(_source.notifier).state = replacement;
          h.container.read(hermesChannelProvider);
          h.container.read(_source.notifier).state = h.channel;
          h.container.read(hermesChannelProvider);
          _expectCalls(replacement, null);
        } else if (transition == 'unmount') {
          h.visible.value = false;
        }
        await tester.pumpAndSettle();
        expect(
          h.outsideFocus.hasFocus,
          transition == 'same owner' ? isFalse : isTrue,
        );
        expect(
          h.channel.listeners.keys.toSet().intersection(observers),
          isEmpty,
        );
        expect(
          h.directory.listenerCount,
          transition == 'unmount'
              ? lessThanOrEqualTo(directoryBaseline)
              : directoryBaseline,
        );
        _expectCalls(h.channel, 'open');
        expect(find.byType(SnackBar), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
    for (final action in ['create', 'open']) {
      for (final reject in [true, false]) {
        for (final transition in [
          'replacement',
          'replacement roundtrip',
          'profile loss',
          'profile roundtrip',
          'endpoint loss',
          'endpoint roundtrip',
          'disconnect roundtrip',
          'contact loss',
          'contact roundtrip',
          'unmount',
          'same owner',
        ]) {
          _testWidgets('$action reject=$reject $transition at $width', (
            tester,
          ) async {
            final h = await _pump(tester, width);
            final replacement = _Channel();
            addTearDown(replacement.dispose);
            final baseline = Map.of(h.channel.listeners);
            final directoryBaseline = h.directory.listenerCount;
            await tester.enterText(_composer, 'Replacement draft');
            h.channel.gate = Completer<void>();
            h.channel.reject = reject;
            await _submit(tester, width, action);
            _expectCalls(h.channel, action);
            final observers = h.channel.listeners.keys
                .toSet()
                .intersection(h.directory.listeners.keys.toSet())
                .difference(baseline.keys.toSet());
            final owner = h.channel.state;
            if (transition.startsWith('replacement')) {
              h.container.read(_source.notifier).state = replacement;
              h.container.read(hermesChannelProvider);
              if (transition.endsWith('roundtrip')) {
                // Model the old transport's invalidated response generation on
                // provider disposal/return without notifying channel listeners.
                h.channel.generation++;
                h.container.read(_source.notifier).state = h.channel;
                h.container.read(hermesChannelProvider);
              }
            } else if (transition.startsWith('contact')) {
              h.directory.changeContact(null);
              h.directory.changeContact(
                transition.endsWith('roundtrip') ? _contact : _otherContact,
              );
            } else if (transition == 'unmount') {
              h.visible.value = false;
              await tester.pumpAndSettle();
              expect(
                h.channel.listeners.keys.toSet().intersection(observers),
                isEmpty,
              );
              expect(
                h.directory.listenerCount,
                lessThanOrEqualTo(directoryBaseline),
              );
            } else if (transition != 'same owner') {
              h.channel.change(switch (transition) {
                'disconnect roundtrip' => owner.copyWith(
                  status: HermesConnectionStatus.disconnected,
                ),
                'endpoint loss' || 'endpoint roundtrip' => owner.copyWith(
                  connectedBaseUrl: 'https://other.example.invalid',
                ),
                _ => owner.copyWith(selectedProfileId: 'b'),
              });
              if (transition.endsWith('roundtrip')) h.channel.change(owner);
            }
            if (action == 'create' &&
                transition != 'same owner' &&
                transition != 'unmount' &&
                transition != 'replacement') {
              // Create cleared A's selection. Supply the replacement owner's
              // authoritative loaded session before entering its draft: a null
              // active session intentionally has no persistent composer draft.
              h.channel.change(
                h.channel.state.copyWith(activeSessionId: 'keep'),
              );
            }
            await tester.pumpAndSettle();
            if (transition != 'unmount') {
              await tester.enterText(_composer, 'Replacement draft');
              await tester.tap(find.text('Keep focus outside Chat'));
              await tester.pumpAndSettle();
              expect(h.outsideFocus.hasFocus, isTrue);
              if (transition != 'same owner' || action == 'open') {
                expect(
                  tester.widget<TextField>(_composer).controller!.text,
                  'Replacement draft',
                );
              }
              if (transition != 'same owner') {
                expect(find.text('Synthetic loaded reply'), findsOneWidget);
              }
            }
            final replacementState = replacement.state;
            final presentedChannel = h.container.read(hermesChannelProvider);
            final presentedState = presentedChannel.state;
            final messages = h.channel.state.messages;
            final refreshBaseline = h.directory.refreshes.length;
            h.channel.gate!.complete();
            await tester.pumpAndSettle();
            final current = transition == 'same owner';
            expect(
              find.byType(SnackBar),
              current && reject ? findsOneWidget : findsNothing,
            );
            expect(
              h.directory.refreshes.skip(refreshBaseline).toList(),
              current && !reject && action == 'create' ? ['original'] : isEmpty,
            );
            if (transition != 'unmount') {
              if (!current || reject) {
                expect(
                  tester.widget<TextField>(_composer).controller!.text,
                  'Replacement draft',
                );
                expect(h.outsideFocus.hasFocus, isTrue);
                if (!current) {
                  expect(find.text('Synthetic loaded reply'), findsOneWidget);
                }
              } else if (action == 'open') {
                expect(
                  tester.widget<TextField>(_composer).focusNode!.hasFocus,
                  isTrue,
                );
              }
              expect(h.directory.listenerCount, directoryBaseline);
            }
            expect(identical(replacement.state, replacementState), isTrue);
            if (transition != 'same owner' && transition != 'unmount') {
              expect(identical(presentedChannel.state, presentedState), isTrue);
            }
            expect(identical(h.channel.state.messages, messages), isTrue);
            _expectCalls(h.channel, action);
            _expectCalls(replacement, null);
            expect(
              observers,
              hasLength(1),
              reason:
                  'One operation-owned shared observer was installed above the mounted baseline',
            );
            expect(
              h.channel.listeners.keys.toSet().intersection(observers),
              isEmpty,
            );
            if (current) {
              if (reject) {
                ScaffoldMessenger.of(
                  tester.element(find.byType(HermesChatScreen)),
                ).removeCurrentSnackBar();
              }
              h.channel.gate = null;
              h.channel.reject = false;
              await _submit(tester, width, action);
              _expectCalls(h.channel, action, count: 2);
              expect(
                h.channel.state.activeSessionId,
                action == 'create' ? 'created-2' : 'target',
              );
              expect(find.byType(SnackBar), findsNothing);
            } else if (transition != 'unmount') {
              final fresh = transition == 'replacement'
                  ? replacement
                  : h.channel;
              fresh.gate = null;
              fresh.reject = false;
              await _submit(tester, width, action);
              _expectCalls(
                fresh,
                action,
                count: transition == 'replacement' ? 1 : 2,
              );
              expect(
                fresh.state.activeSessionId,
                action == 'create'
                    ? 'created-${fresh.createSessionCalls.length}'
                    : 'target',
              );
              expect(find.byType(SnackBar), findsNothing);
            }
            expect(tester.takeException(), isNull);
          });
        }
      }
      _testWidgets('$action production-style obsolete failure at $width', (
        tester,
      ) async {
        final h = await _pump(tester, width);
        h.channel.gate = Completer<void>();
        h.channel.reject = true;
        h.channel.suppressObsoleteOpenError = true;
        await _submit(tester, width, action);
        h.channel.change(h.channel.state.copyWith(selectedProfileId: 'b'));
        h.channel.gate!.complete();
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
        _expectCalls(h.channel, action);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
