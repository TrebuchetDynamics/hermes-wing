import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

const _first = 'https://first.example.invalid/p/shared';
const _second = 'https://second.example.invalid/p/shared';
const _notice =
    'Connected to Hermes, but saving this connection could not be confirmed. Keep this form open and retry Add Hermes to connect and save again.';

class _Store extends FakeHermesEndpointStore {
  int attempts = 0;
  bool fail = false;
  Completer<void>? gate;

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
    String? wingLinkOrigin,
    String? wingLinkToken,
    String? wingLinkPendingCredentialId,
    String? wingLinkHostFingerprint,
    String? wingLinkDeviceId,
  }) async {
    attempts++;
    await gate?.future;
    if (fail) throw StateError('private keychain detail');
    await super.save(
      baseUrl: baseUrl,
      apiKey: apiKey,
      label: label,
      profileId: profileId,
    );
  }
}

class _Channel extends FakeHermesChannel {
  _Channel() : super(status: HermesConnectionStatus.disconnected);
  bool reject = false;
  HermesChannelState? failure;

  @override
  HermesChannelState get state => failure ?? super.state;

  @override
  Future<void> connect({
    required String baseUrl,
    String? apiKey,
    bool deferSessionSelection = false,
  }) async {
    if (reject) {
      connectCalls.add(FakeHermesConnectCall(baseUrl: baseUrl, apiKey: apiKey));
      failure = const HermesChannelState(
        status: HermesConnectionStatus.error,
        errorMessage: 'private authentication response',
        connectionFailureKind: HermesConnectionFailureKind.authentication,
      );
      notifyListeners();
      return;
    }
    failure = null;
    await super.connect(
      baseUrl: baseUrl,
      apiKey: apiKey,
      deferSessionSelection: deferSessionSelection,
    );
  }
}

class _Loader implements GatewaySummaryLoader {
  int calls = 0;
  @override
  Future<GatewaySummary> load(HermesEndpointConfig config) async {
    calls++;
    return const GatewaySummary(profiles: [], sessionsByProfile: {});
  }
}

Future<(ProviderContainer, _Loader)> _mount(
  WidgetTester tester,
  _Channel channel,
  _Store store,
) async {
  tester.view.physicalSize = const Size(1280, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final loader = _Loader();
  final directory = HermesGatewayDirectory(
    store: store,
    cache: GatewayContactCache(),
    loader: loader,
    activeChannel: channel,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(store),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HermesChatScreen(initiallyEditingConnection: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('hermes-base-url-field')),
    _first,
  );
  await tester.enterText(
    find.byKey(const ValueKey('hermes-profile-label-field')),
    'Synthetic host',
  );
  await tester.pump();
  return (
    ProviderScope.containerOf(tester.element(find.byType(HermesChatScreen))),
    loader,
  );
}

TextEditingController _controller(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(ValueKey(key))).controller!;

Future<void> _connect(WidgetTester tester, {bool pending = false}) async {
  final button = find.byKey(const ValueKey('hermes-connect-button'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  if (pending) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
    'Remote authentication rejection is sanitized and retries only explicitly',
    (tester) async {
      final channel = _Channel()..reject = true;
      final store = _Store();
      addTearDown(channel.dispose);
      await _mount(tester, channel, store);
      await _connect(tester);
      expect(find.text('Hermes API rejected the API key.'), findsOneWidget);
      expect(find.textContaining('private authentication'), findsNothing);
      expect(channel.connectCalls, hasLength(1));
      expect(store.attempts, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(channel.connectCalls, hasLength(1));
      channel.reject = false;
      await _connect(tester);
      expect(channel.connectCalls, hasLength(2));
      expect(store.attempts, 1);
      expect(store.saveCalls.single.baseUrl, _first);
    },
  );

  testWidgets(
    'Remote save failure retains connected draft and explicit retry saves once',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final channel = _Channel();
      final store = _Store()..fail = true;
      addTearDown(channel.dispose);
      await _mount(tester, channel, store);
      await tester.enterText(
        find.byKey(const ValueKey('hermes-api-key-field')),
        'synthetic-test-only',
      );
      await _connect(tester);
      expect(tester.takeException(), isNull);
      expect(channel.state.isConnected, isTrue);
      expect(channel.disconnectCalls, 0);
      expect(store.attempts, 1);
      expect(store.saveCalls, isEmpty);
      expect(_controller(tester, 'hermes-base-url-field').text, _first);
      expect(
        _controller(tester, 'hermes-api-key-field').text,
        'synthetic-test-only',
      );
      expect(find.textContaining('Your token is stored'), findsNothing);
      expect(find.textContaining('never shown after connecting'), findsNothing);
      expect(
        find.text(
          'Saving a connection uses secure device storage. Connecting alone does not confirm that your token was saved.',
        ),
        findsOneWidget,
      );
      final notice = find.byKey(const ValueKey('hermes-connection-save-error'));
      expect(find.text(_notice), findsOneWidget);
      expect(tester.getSemantics(notice).flagsCollection.isLiveRegion, isTrue);
      expect(find.textContaining('private keychain'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(store.attempts, 1);
      store.fail = false;
      await _connect(tester);
      expect(channel.connectCalls, hasLength(2));
      expect(store.attempts, 2);
      expect(store.saveCalls, hasLength(1));
      expect(channel.disconnectCalls, 1);
      expect(find.text(_notice), findsNothing);
      semantics.dispose();
    },
  );

  for (final change in [
    'cancel',
    'edit-return',
    'origin-return',
    'session-return',
    'channel',
    'dispose',
  ]) {
    testWidgets('old cleartext consent cannot connect after $change', (
      tester,
    ) async {
      final channel = _Channel();
      final replacement = _Channel();
      final store = _Store();
      addTearDown(channel.dispose);
      addTearDown(replacement.dispose);
      final (container, _) = await _mount(tester, channel, store);
      _controller(tester, 'hermes-base-url-field').text =
          'http://first.example.invalid/p/shared';
      _controller(tester, 'hermes-api-key-field').text = 'synthetic-test-only';
      await tester.pump();
      await _connect(tester);
      expect(
        find.byKey(const ValueKey('hermes-cleartext-credential-warning')),
        findsOneWidget,
      );
      if (change == 'cancel') {
        await tester.tap(find.text('Cancel'));
      } else if (change == 'dispose') {
        await tester.pumpWidget(const SizedBox.shrink());
      } else {
        if (change == 'edit-return') {
          final controller = _controller(tester, 'hermes-profile-label-field');
          final text = controller.text;
          controller.text = 'Intervening edit';
          controller.text = text;
        } else if (change == 'channel') {
          final directory = container.read(hermesGatewayDirectoryProvider);
          container.updateOverrides([
            hermesChannelProvider.overrideWithValue(replacement),
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
          ]);
        } else {
          await channel.connect(baseUrl: _second);
          await channel.selectSession('shared-session');
          if (change == 'origin-return') await channel.connect(baseUrl: _first);
          if (change == 'session-return') {
            await channel.selectSession('other');
            await channel.selectSession('shared-session');
          }
        }
        await tester.pumpAndSettle();
        final calls = channel.connectCalls.length;
        await tester.tap(
          find.byKey(const ValueKey('hermes-cleartext-credential-confirm')),
        );
        await tester.pumpAndSettle();
        expect(channel.connectCalls, hasLength(calls));
      }
      await tester.pumpAndSettle();
      expect(store.attempts, 0);
      expect(replacement.connectCalls, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final fail in [false, true]) {
    for (final change in [
      'edit-return',
      'origin-return',
      'session-return',
      'channel',
      'dispose',
    ]) {
      testWidgets(
        'late save ${fail ? 'error' : 'success'} cannot affect $change owner',
        (tester) async {
          final channel = _Channel();
          final replacement = _Channel();
          final store = _Store()
            ..fail = fail
            ..gate = Completer<void>();
          addTearDown(channel.dispose);
          addTearDown(replacement.dispose);
          final (container, loader) = await _mount(tester, channel, store);
          await _connect(tester, pending: true);
          expect(store.attempts, 1);
          if (change == 'edit-return') {
            final controller = _controller(
              tester,
              'hermes-profile-label-field',
            );
            final text = controller.text;
            controller.text = 'Intervening edit';
            controller.text = text;
          } else if (change == 'dispose') {
            await tester.pumpWidget(const SizedBox.shrink());
          } else if (change == 'channel') {
            final directory = container.read(hermesGatewayDirectoryProvider);
            container.updateOverrides([
              hermesChannelProvider.overrideWithValue(replacement),
              hermesEndpointStoreProvider.overrideWithValue(store),
              hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
            ]);
          } else {
            await channel.connect(baseUrl: _second);
            await channel.selectSession('shared-session');
            if (change == 'origin-return') {
              await channel.connect(baseUrl: _first);
            }
            if (change == 'session-return') {
              await channel.selectSession('other');
              await channel.selectSession('shared-session');
            }
          }
          await tester.pump(const Duration(milliseconds: 300));
          final disconnects = channel.disconnectCalls;
          final reads = loader.calls;
          store.gate!.complete();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(channel.disconnectCalls, disconnects);
          expect(replacement.disconnectCalls, 0);
          expect(loader.calls, reads);
          expect(find.text(_notice), findsNothing);
          expect(store.attempts, 1);
          if (change != 'dispose') {
            expect(
              find.byKey(const ValueKey('hermes-connect-button')),
              findsOneWidget,
            );
            expect(
              tester
                  .widget<FilledButton>(
                    find.byKey(const ValueKey('hermes-connect-button')),
                  )
                  .onPressed,
              isNotNull,
            );
          }
        },
      );
    }
  }
}
