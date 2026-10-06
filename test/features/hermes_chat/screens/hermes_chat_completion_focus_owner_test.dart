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
final _composer = find.byKey(const ValueKey('hermes-composer-field'));
const _sessions = [
  HermesSession(id: 'a', source: 'test', title: 'Session A'),
  HermesSession(id: 'b', source: 'test', title: 'Session B'),
];

class _Channel extends FakeHermesChannel {
  _Channel({String session = 'a'})
    : super(
        sessions: _sessions,
        activeSessionId: session,
        selectedProfileId: 'profile-a',
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
          for (final id in ['a', 'b'])
            id: [
              HermesChatTurn(
                id: 'loaded-$id',
                sessionId: id,
                author: HermesTurnAuthor.assistant,
                createdAt: DateTime.utc(2026, 1, 1),
                text: 'Synthetic reply $id',
                status: HermesTurnStatus.completed,
              ),
            ],
        },
      ),
    );
  }

  HermesChannelState? _current;
  @override
  HermesChannelState get state => _current ?? super.state;

  void change(HermesChannelState next) {
    _current = next;
    notifyListeners();
  }

  // An asynchronous transport completion explicitly notifies mounted consumers.
  void finish() {
    change(
      state.copyWith(
        messages: {
          ...state.messages,
          'a': [
            ...state.messages['a']!.take(state.messages['a']!.length - 1),
            state.messages['a']!.last.copyWith(
              status: HermesTurnStatus.completed,
            ),
          ],
        },
      ),
    );
  }

  @override
  Future<void> selectSession(String id, {bool Function()? canAccept}) async {
    if (!(canAccept?.call() ?? true)) return;
    selectSessionCalls.add(id);
    change(state.copyWith(activeSessionId: id));
  }
}

class _Directory extends HermesGatewayDirectory {
  _Directory(_Channel channel)
    : super(
        store: FakeHermesEndpointStore(),
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );

  GatewayContactId? contact;
  String? restoration;
  @override
  GatewayContactId? get activeContactId => contact;
  @override
  String? get restoringSessionId => restoration;

  void changeContact(GatewayContactId? next) {
    contact = next;
    notifyListeners();
  }

  void changeRestoration(String? next) {
    restoration = next;
    notifyListeners();
  }

  // Completion refresh is a read, not a contact/transport selection.
  @override
  Future<void> reconnectGateway(String gatewayId) async {}
}

Future<
  ({
    _Channel channel,
    _Directory directory,
    ProviderContainer container,
    FocusNode outside,
    ValueNotifier<bool> visible,
  })
>
_mount(WidgetTester tester, {String session = 'a'}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final channel = _Channel(session: session);
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
  final outside = FocusNode();
  final visible = ValueNotifier(true);
  addTearDown(channel.dispose);
  addTearDown(container.dispose);
  addTearDown(outside.dispose);
  addTearDown(visible.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Column(
          children: [
            TextButton(
              focusNode: outside,
              onPressed: outside.requestFocus,
              child: const Text('Outside Chat'),
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
  // Initialize replacement draft before scheduling completion; initial focus
  // and history loading are fully settled before the race starts.
  await channel.selectSession('b');
  await tester.pumpAndSettle();
  await tester.enterText(_composer, 'Draft B');
  await channel.selectSession(session);
  await tester.pumpAndSettle();
  if (session == 'a') await tester.enterText(_composer, 'Draft A');
  channel.change(
    channel.state.copyWith(
      messages: {
        ...channel.state.messages,
        'a': [
          ...channel.state.messages['a']!,
          HermesChatTurn(
            id: 'reply-a',
            sessionId: 'a',
            author: HermesTurnAuthor.assistant,
            createdAt: DateTime.utc(2026, 1, 1, 0, 1),
            text: 'Synthetic streaming reply',
            status: HermesTurnStatus.streaming,
          ),
        ],
      },
    ),
  );
  outside.requestFocus();
  await tester.pump();
  expect(outside.hasFocus, isTrue);
  return (
    channel: channel,
    directory: directory,
    container: container,
    outside: outside,
    visible: visible,
  );
}

void _noMutations(_Channel channel) {
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
  expect(channel.connectCalls, isEmpty);
  expect(channel.disconnectCalls, 0);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final loss in [
    'session',
    'profile',
    'origin',
    'connection',
    'contact',
    'restoration',
    'provider',
  ]) {
    for (final returns in [false, true]) {
      testWidgets('completion focus rejects $loss returns=$returns', (
        tester,
      ) async {
        final h = await _mount(tester);
        final replacement = _Channel(session: 'b');
        addTearDown(replacement.dispose);
        final replacementMessages = replacement.state.messages;
        h.channel.finish();
        final completed = h.channel.state;
        switch (loss) {
          case 'session':
            await h.channel.selectSession('b');
            if (returns) await h.channel.selectSession('a');
          case 'profile':
            h.channel.change(
              completed.copyWith(
                selectedProfileId: 'profile-b',
                activeSessionId: 'b',
                sessions: [_sessions.last],
                messages: {'b': replacementMessages['b']!},
              ),
            );
            if (returns) h.channel.change(completed);
          case 'origin':
            h.channel.change(
              completed.copyWith(
                connectedBaseUrl: 'https://other.invalid',
                activeSessionId: 'b',
                sessions: [_sessions.last],
                messages: {'b': replacementMessages['b']!},
              ),
            );
            if (returns) h.channel.change(completed);
          case 'connection':
            h.channel.change(const HermesChannelState());
            if (returns) h.channel.change(completed);
          case 'contact':
            h.directory.changeContact(
              const GatewayContactId(
                gatewayId: 'other',
                profileId: 'profile-a',
              ),
            );
            if (returns) h.directory.changeContact(null);
          case 'restoration':
            h.directory.changeRestoration('a');
            if (returns) h.directory.changeRestoration(null);
          case 'provider':
            h.container.read(_source.notifier).state = replacement;
            // Riverpod lazy evaluation must be flushed without drawing a frame.
            h.container.read(hermesChannelProvider);
            if (returns) {
              h.container.read(_source.notifier).state = h.channel;
              h.container.read(hermesChannelProvider);
            }
        }
        final expectedState = h.container.read(hermesChannelProvider).state;
        final originalMessages = h.channel.state.messages;
        await tester.pumpAndSettle();
        expect(h.outside.hasFocus, isTrue);
        final current = h.container.read(hermesChannelProvider);
        expect(current.state.activeSessionId, expectedState.activeSessionId);
        expect(
          current.state.selectedProfileId,
          expectedState.selectedProfileId,
        );
        expect(current.state.messages, expectedState.messages);
        expect(h.channel.state.messages, originalMessages);
        expect(replacement.state.messages, replacementMessages);
        if (_composer.evaluate().isNotEmpty) {
          expect(
            tester.widget<TextField>(_composer).focusNode!.hasFocus,
            isFalse,
          );
          if (loss == 'session' || loss == 'provider') {
            expect(
              tester.widget<TextField>(_composer).controller!.text,
              returns ? 'Draft A' : 'Draft B',
            );
          }
        }
        _noMutations(h.channel);
        _noMutations(replacement);
        expect(tester.takeException(), isNull);
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }

  for (final control in [
    'same owner',
    'unrelated notification',
    'background',
    'android',
    'modal',
    'unmount',
  ]) {
    testWidgets('completion focus control: $control', (tester) async {
      if (control == 'android') {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
      }
      final h = await _mount(
        tester,
        session: control == 'background' ? 'b' : 'a',
      );
      final messages = h.channel.state.messages;
      if (control == 'modal') {
        final context = tester.element(_composer);
        // Public route push, after completion but before its queued frame.
        h.channel.finish();
        // This dialog legitimately owns focus; the old composer must not.
        unawaited(
          showDialog<void>(
            context: context,
            builder: (_) => const AlertDialog(content: Text('Modal control')),
          ),
        );
      } else {
        h.channel.finish();
      }
      if (control == 'unrelated notification') {
        h.channel.change(h.channel.state.copyWith(models: ['synthetic-model']));
        h.directory.notifyListeners();
      }
      if (control == 'unmount') h.visible.value = false;
      await tester.pumpAndSettle();
      if (control == 'same owner' || control == 'unrelated notification') {
        expect(tester.widget<TextField>(_composer).focusNode!.hasFocus, isTrue);
        expect(tester.widget<TextField>(_composer).controller!.text, 'Draft A');
      } else if (control != 'unmount') {
        expect(
          tester.widget<TextField>(_composer).focusNode!.hasFocus,
          isFalse,
        );
      }
      if (control == 'background' ||
          control == 'android' ||
          control == 'unmount') {
        expect(h.outside.hasFocus, isTrue);
      }
      expect(
        h.channel.state.activeSessionId,
        control == 'background' ? 'b' : 'a',
      );
      expect(h.channel.state.messages['b'], messages['b']);
      _noMutations(h.channel);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
