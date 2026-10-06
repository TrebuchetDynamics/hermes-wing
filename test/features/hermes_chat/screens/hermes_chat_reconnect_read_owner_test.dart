import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

final _source = StateProvider<HermesChannel>((_) => throw UnimplementedError());
const _saved = HermesEndpointConfig(baseUrl: 'https://example.invalid/');

class _Store extends FakeHermesEndpointStore {
  var pending = Completer<HermesEndpointConfig?>();
  int reads = 0;
  @override
  Future<HermesEndpointConfig?> load() {
    reads++;
    return pending.future;
  }
}

class _Channel extends FakeHermesChannel {
  _Channel()
    : super(
        connectedBaseUrl: 'https://example.invalid',
        errorMessage: 'Synthetic stream disconnected',
      );
  HermesChannelState? current;
  @override
  HermesChannelState get state => current ?? super.state;
  void change(HermesChannelState next) {
    current = next;
    notifyListeners();
  }

  @override
  Future<void> connect({
    required String baseUrl,
    String? apiKey,
    bool deferSessionSelection = false,
  }) {
    current = null;
    return super.connect(
      baseUrl: baseUrl,
      apiKey: apiKey,
      deferSessionSelection: deferSessionSelection,
    );
  }

  @override
  Future<void> disconnect() {
    current = null;
    return super.disconnect();
  }
}

void _noMutations(FakeHermesChannel channel, _Store store) {
  expect(channel.connectCalls, isEmpty);
  expect(channel.disconnectCalls, 0);
  expect(channel.sentTextAttachments, isEmpty);
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.selectSessionCalls, isEmpty);
  expect(channel.renameSessionCalls, isEmpty);
  expect(channel.deleteSessionCalls, isEmpty);
  expect(channel.forkSessionCalls, isEmpty);
  expect(channel.selectProfileCalls, isEmpty);
  expect(channel.createProfileCalls, isEmpty);
  expect(channel.renameProfileCalls, isEmpty);
  expect(channel.deleteProfileCalls, isEmpty);
  expect(store.saveCalls, isEmpty);
  expect(store.saveAllCalls, isEmpty);
  expect(store.deleteProfileCalls, isEmpty);
  expect(store.clearCalls, 0);
}

Future<ProviderContainer> _mount(
  WidgetTester tester,
  _Channel channel,
  _Store store,
) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(channel.dispose);
  final directory = directoryFor(
    configs: const [],
    loader: FakeGatewaySummaryLoader({}),
    activeChannel: channel,
  );
  final container = ProviderContainer(
    overrides: [
      _source.overrideWith((_) => channel),
      hermesChannelProvider.overrideWith((ref) => ref.watch(_source)),
      hermesGatewayDirectoryProvider.overrideWith((_) => directory),
      hermesEndpointStoreProvider.overrideWithValue(store),
      hermesVoiceCaptureServiceProvider.overrideWithValue(null),
      hermesTextToSpeechServiceProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(store.reads, 0);
  return container;
}

Future<void> _reconnect(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('hermes-chat-error-reconnect'));
  expect(button.hitTestable(), findsOneWidget);
  await tester.tap(button.hitTestable());
  await tester.pump();
}

void main() {
  testWidgets(
    'current storage rejection is safe and a new explicit retry works',
    (tester) async {
      final channel = _Channel();
      final store = _Store();
      await _mount(tester, channel, store);
      await _reconnect(tester);
      store.pending.completeError(
        StateError('Synthetic private storage failure'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('private storage failure'), findsNothing);
      expect(
        find.textContaining('could not read saved gateways'),
        findsOneWidget,
      );
      _noMutations(channel, store);
      store.pending = Completer<HermesEndpointConfig?>();
      await _reconnect(tester);
      expect(store.reads, 2);
      store.pending.complete(_saved);
      await tester.pumpAndSettle();
      expect(channel.connectCalls, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
  for (final rejection in [false, true]) {
    for (final invalidation in [
      'unmount',
      'channel',
      'channel return',
      'session return',
      'manual',
    ]) {
      testWidgets(
        '$invalidation late read rejection=$rejection is inert',
        (tester) async {
          final channel = _Channel();
          final store = _Store();
          final container = await _mount(tester, channel, store);
          await _reconnect(tester);
          expect(store.reads, 1);
          _noMutations(channel, store);
          final other = _Channel();
          addTearDown(other.dispose);
          if (invalidation == 'unmount') {
            await tester.pumpWidget(const SizedBox.shrink());
          } else if (invalidation.startsWith('channel')) {
            container.read(_source.notifier).state = other;
            await tester.pump();
            if (invalidation == 'channel return') {
              container.read(_source.notifier).state = channel;
              await tester.pump();
            }
          } else if (invalidation == 'session return') {
            final original = channel.state;
            channel.change(original.copyWith(activeSessionId: 'other-session'));
            channel.change(original);
            await tester.pump();
          } else {
            channel.change(
              channel.state.copyWith(
                errorMessage: 'Synthetic HTTP 401 unauthorized',
                connectionFailureKind:
                    HermesConnectionFailureKind.authentication,
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.text('Update key').hitTestable());
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const ValueKey('hermes-base-url-field')),
              'https://manual.invalid',
            );
            await tester.enterText(
              find.byKey(const ValueKey('hermes-profile-label-field')),
              'Manual label',
            );
          }
          final disconnects = channel.disconnectCalls;
          if (rejection) {
            store.pending.completeError(
              StateError('Synthetic private storage failure'),
            );
          } else {
            store.pending.complete(_saved);
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.textContaining('private storage failure'), findsNothing);
          expect(
            find.textContaining('could not read saved gateways'),
            findsNothing,
          );
          expect(channel.connectCalls, isEmpty);
          if (invalidation == 'manual') {
            expect(channel.disconnectCalls, disconnects);
            expect(
              tester
                  .widget<TextField>(
                    find.byKey(const ValueKey('hermes-base-url-field')),
                  )
                  .controller!
                  .text,
              'https://manual.invalid',
            );
            expect(
              tester
                  .widget<TextField>(
                    find.byKey(const ValueKey('hermes-profile-label-field')),
                  )
                  .controller!
                  .text,
              'Manual label',
            );
            // Update key itself disconnects once; settlement does not.
            expect(disconnects, 1);
          } else {
            _noMutations(channel, store);
          }
          _noMutations(other, store);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        variant: TargetPlatformVariant.only(TargetPlatform.linux),
      );
    }
  }
  testWidgets(
    'current equivalent saved endpoint reconnects once despite duplicate taps',
    (tester) async {
      final channel = _Channel();
      final store = _Store();
      await _mount(tester, channel, store);
      await _reconnect(tester);
      await _reconnect(tester);
      expect(store.reads, 1);
      store.pending.complete(_saved);
      await tester.pumpAndSettle();
      expect(channel.connectCalls, hasLength(1));
      expect(channel.connectCalls.single.baseUrl, 'https://example.invalid');
      expect(channel.state.isConnected, isTrue);
      expect(store.saveCalls, isEmpty);
      expect(channel.createSessionCalls, isEmpty);
      expect(channel.selectSessionCalls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
