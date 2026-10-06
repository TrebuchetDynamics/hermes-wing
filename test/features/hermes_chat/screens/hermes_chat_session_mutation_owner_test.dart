import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

final _source = StateProvider<HermesChannel>((_) => throw UnimplementedError());
const _rows = [
  HermesSession(id: 'keep', source: 'test', title: 'Keep'),
  HermesSession(id: 'target', source: 'test', title: 'Target'),
  HermesSession(id: 'second', source: 'test', title: 'Second'),
];
const _operations = ['rename', 'fork', 'delete', 'bulk'];

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );
  for (final width in [390.0, 1280.0]) {
    for (final operation in _operations) {
      testWidgets(
        '$operation rejects cross-profile same-ID confirmation at $width',
        (tester) async {
          final h = await _pump(tester, width);
          await _open(tester, width, operation);
          h.channel.change(h.channel.state.copyWith(selectedProfileId: 'b'));
          await _confirm(tester, operation);
          expect(
            h.channel.calls,
            isEmpty,
            reason: 'Owner A intent must not submit to B',
          );
          expect(tester.takeException(), isNull);
        },
      );
      for (final transition in [
        'roundtrip',
        'origin',
        'reconnect',
        'selecting',
        'replacement',
        'replacement-roundtrip',
        'removal',
        'authority',
        'authority-roundtrip',
        'grant-loss',
        'unmount',
      ]) {
        testWidgets('$operation invalidates $transition at $width', (
          tester,
        ) async {
          final h = await _pump(tester, width);
          await _open(tester, width, operation);
          final original = h.channel.state;
          _OwnerChannel? replacement;
          switch (transition) {
            case 'roundtrip':
              h.channel.change(original.copyWith(selectedProfileId: 'b'));
              h.channel.change(original);
            case 'origin':
              h.channel.change(
                original.copyWith(
                  connectedBaseUrl: 'https://replacement.invalid',
                ),
              );
            case 'reconnect':
              h.channel.change(
                original.copyWith(status: HermesConnectionStatus.disconnected),
              );
              h.channel.change(original);
            case 'selecting':
              h.channel.change(original.copyWith(isSelectingProfile: true));
              h.channel.change(original);
            case 'replacement':
            case 'replacement-roundtrip':
              replacement = _OwnerChannel();
              addTearDown(replacement.dispose);
              h.container.read(_source.notifier).state = replacement;
              h.container.read(hermesChannelProvider);
              if (transition == 'replacement-roundtrip') {
                h.container.read(_source.notifier).state = h.channel;
                h.container.read(hermesChannelProvider);
              }
            case 'removal':
              h.channel.change(original.copyWith(sessions: const []));
              h.channel.change(original);
            case 'authority':
            case 'authority-roundtrip':
              h.channel.change(
                original.copyWith(capabilities: _capabilities(writes: false)),
              );
              if (transition == 'authority-roundtrip') {
                h.channel.change(original);
              }
            case 'grant-loss':
              h.channel.change(
                original.copyWith(capabilities: _capabilities(granted: false)),
              );
            case 'unmount':
              h.page.value = const SizedBox();
              await tester.pump();
              expect(
                h.channel.listeners.length,
                1,
                reason: 'No task observer may remain after route disposal',
              );
          }
          await _confirm(tester, operation);
          expect(h.channel.calls, isEmpty);
          expect(replacement?.calls ?? [], isEmpty);
          expect(tester.takeException(), isNull);
          if (transition != 'unmount' && replacement == null) {
            expect(h.channel.listeners.length, h.listenerBaseline);
          }
        });
      }
      for (final cancel in [false, true]) {
        testWidgets('$operation same-owner cancel=$cancel at $width', (
          tester,
        ) async {
          final h = await _pump(tester, width);
          await _open(tester, width, operation);
          if (cancel) {
            await tester.tap(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.text('Cancel'),
              ),
            );
            await tester.pumpAndSettle();
          } else {
            await _confirm(tester, operation);
          }
          expect(
            h.channel.calls.length,
            cancel
                ? 0
                : operation == 'bulk'
                ? 3
                : 1,
          );
          expect(h.channel.calls.every((call) => call.profile == 'a'), isTrue);
          if (cancel) expect(h.channel.listeners.length, h.listenerBaseline);
          h.page.value = const SizedBox();
          await tester.pump();
          expect(h.channel.listeners.length, 1);
          expect(tester.takeException(), isNull);
        });
      }
      for (final fail in [false, true]) {
        testWidgets('$operation suppresses late result fail=$fail at $width', (
          tester,
        ) async {
          final h = await _pump(tester, width);
          h.channel.gate = Completer<void>();
          await _open(tester, width, operation);
          await _confirm(tester, operation);
          expect(h.channel.calls, hasLength(1));
          if (fail) h.channel.failures.add(h.channel.calls.first.id);
          h.channel.change(h.channel.state.copyWith(selectedProfileId: 'b'));
          await tester.pumpAndSettle();
          final composer = find.byKey(const ValueKey('hermes-composer-field'));
          await tester.enterText(composer, 'Replacement draft');
          h.channel.gate!.complete();
          await tester.pumpAndSettle();
          expect(h.channel.calls, hasLength(1));
          expect(
            tester.widget<TextField>(composer).controller!.text,
            'Replacement draft',
          );
          expect(find.byType(SnackBar), findsNothing);
          h.page.value = const SizedBox();
          await tester.pump();
          expect(h.channel.listeners.length, 1);
          expect(tester.takeException(), isNull);
        });
      }
    }
    testWidgets('rename remains nonblank at $width', (tester) async {
      final h = await _pump(tester, width);
      await _open(tester, width, 'rename');
      await tester.enterText(
        find.byKey(const ValueKey('hermes-session-title-field')),
        '  ',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('hermes-session-title-save')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(h.channel.calls, isEmpty);
    });
    testWidgets('bulk preserves partial deletion at $width', (tester) async {
      final h = await _pump(tester, width);
      h.channel.failures.add('target');
      await _open(tester, width, 'bulk');
      await _confirm(tester, 'bulk');
      expect(h.channel.calls.map((c) => c.id).toSet(), {
        'keep',
        'target',
        'second',
      });
      expect(
        find.text('Deleted 2 of 3 sessions. 1 could not be deleted.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
    for (final fail in [false, true]) {
      testWidgets(
        'bulk stops after awaited first request fail=$fail at $width',
        (tester) async {
          final h = await _pump(tester, width);
          h.channel.gate = Completer<void>();
          await _open(tester, width, 'bulk');
          await tester.tap(
            find.byKey(const ValueKey('hermes-sessions-delete-confirm')),
          );
          await tester.pumpAndSettle();
          expect(h.channel.calls, hasLength(1));
          if (fail) h.channel.failures.add(h.channel.calls.first.id);
          h.channel.change(h.channel.state.copyWith(selectedProfileId: 'b'));
          await tester.pumpAndSettle();
          final composer = find.byKey(const ValueKey('hermes-composer-field'));
          await tester.enterText(composer, 'Replacement draft');
          h.channel.gate!.complete();
          await tester.pumpAndSettle();
          expect(h.channel.calls, hasLength(1));
          expect(
            tester.widget<TextField>(composer).controller!.text,
            'Replacement draft',
          );
          expect(find.byType(SnackBar), findsNothing);
          expect(h.channel.listeners.length, h.listenerBaseline);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _OwnerChannel extends FakeHermesChannel {
  _OwnerChannel()
    : super(
        sessions: _rows,
        activeSessionId: 'keep',
        selectedProfileId: 'a',
        connectedBaseUrl: 'https://example.invalid',
        connectedWithApiKey: false,
        capabilities: _capabilities(),
      );
  HermesChannelState? _replacement;
  final calls = <({String operation, String? profile, String id})>[];
  Completer<void>? gate;
  final failures = <String>{};
  final listeners = <VoidCallback>{};
  @override
  HermesChannelState get state => _replacement ?? super.state;
  void change(HermesChannelState value) {
    _replacement = value;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
    super.removeListener(listener);
  }

  Future<void> _submit(String operation, String id) async {
    final owner = state;
    calls.add((operation: operation, profile: owner.selectedProfileId, id: id));
    await gate?.future;
    if (failures.contains(id)) throw StateError('bounded test failure');
    // Model the channel's existing response-owner fence, not the UI intent fix.
    if (owner.selectedProfileId != state.selectedProfileId ||
        owner.connectedBaseUrl != state.connectedBaseUrl) {
      return;
    }
    if (operation == 'delete') {
      change(
        state.copyWith(
          sessions: state.sessions.where((s) => s.id != id).toList(),
        ),
      );
    } else if (operation == 'fork') {
      change(
        state.copyWith(
          activeSessionId: 'child',
          sessions: [
            ...state.sessions,
            HermesSession(id: 'child', source: 'test', parentSessionId: id),
          ],
        ),
      );
    }
  }

  @override
  Future<void> renameSession({
    required String sessionId,
    required String title,
  }) => _submit('rename', sessionId);
  @override
  Future<void> forkSession(String sessionId, {String? title}) =>
      _submit('fork', sessionId);
  @override
  Future<void> deleteSession(String sessionId) => _submit('delete', sessionId);
}

HermesCapabilityDocument _capabilities({
  bool writes = true,
  bool granted = true,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'auth': {
    'type': 'bearer',
    'required': true,
    'granted_scopes': ['sessions:read', if (granted) 'sessions:write'],
  },
  'features': {'session_chat_streaming': true},
  'endpoints': {
    'sessions': {
      'method': 'GET',
      'path': '/api/sessions',
      'required_scopes': ['sessions:read'],
    },
    'session_chat_stream': {
      'method': 'POST',
      'path': '/api/sessions/{session_id}/chat/stream',
    },
    if (writes) ...{
      'session_update': {
        'method': 'PATCH',
        'path': '/api/sessions/{session_id}',
        'required_scopes': ['sessions:write'],
      },
      'session_delete': {
        'method': 'DELETE',
        'path': '/api/sessions/{session_id}',
        'required_scopes': ['sessions:write'],
      },
      'session_fork': {
        'method': 'POST',
        'path': '/api/sessions/{session_id}/fork',
        'required_scopes': ['sessions:write'],
      },
    },
  },
});

Future<
  ({
    _OwnerChannel channel,
    ProviderContainer container,
    ValueNotifier<Widget> page,
    int listenerBaseline,
  })
>
_pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final channel = _OwnerChannel();
  addTearDown(channel.dispose);
  final store = FakeHermesEndpointStore();
  final directory = HermesGatewayDirectory(
    store: store,
    cache: FakeGatewayContactCache(),
    loader: FakeGatewaySummaryLoader({}),
    activeChannel: channel,
  );
  // Explicit inert directory: no production startup, restoration or live reads.
  final container = ProviderContainer(
    overrides: [
      _source.overrideWith((_) => channel),
      hermesChannelProvider.overrideWith((ref) => ref.watch(_source)),
      hermesEndpointStoreProvider.overrideWithValue(store),
      hermesGatewayDirectoryProvider.overrideWith((_) => directory),
      hermesVoiceCaptureServiceProvider.overrideWithValue(null),
      hermesTextToSpeechServiceProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  final page = ValueNotifier<Widget>(const HermesChatScreen());
  addTearDown(page.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ValueListenableBuilder<Widget>(
          valueListenable: page,
          builder: (_, child, _) => child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return (
    channel: channel,
    container: container,
    page: page,
    listenerBaseline: channel.listeners.length,
  );
}

Future<void> _open(WidgetTester tester, double width, String operation) async {
  if (width < 900) {
    await tester.tap(find.byKey(const ValueKey('hermes-more-actions-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();
  }
  if (operation == 'bulk') {
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey(
          width < 900
              ? 'hermes-sessions-select-all'
              : 'hermes-session-rail-select-all',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete 3'));
  } else {
    await tester.tap(find.byKey(const ValueKey('hermes-session-menu-target')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(switch (operation) {
        'rename' => 'Rename',
        'fork' => 'Branch',
        _ => 'Delete',
      }),
    );
  }
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
  if (operation == 'rename') {
    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-title-field')),
      'Updated',
    );
    await tester.pump();
  }
}

Future<void> _confirm(WidgetTester tester, String operation) async {
  await tester.tap(
    find.byKey(
      ValueKey(switch (operation) {
        'rename' => 'hermes-session-title-save',
        'fork' => 'hermes-session-branch-confirm',
        'bulk' => 'hermes-sessions-delete-confirm',
        _ => 'hermes-session-delete-confirm',
      }),
    ),
  );
  await tester.pumpAndSettle();
}
