import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

const _local = 'http://127.0.0.1:8642';
const _saved = HermesEndpointConfig(
  id: 'saved',
  label: 'Saved gateway',
  baseUrl: 'https://saved.invalid',
);
const _other = HermesEndpointConfig(
  id: 'other',
  label: 'Other gateway',
  baseUrl: 'https://other.invalid',
);

Finder _field(String name) => find.byKey(ValueKey('hermes-$name-field'));

String _text(WidgetTester tester, String name) =>
    tester.widget<TextField>(_field(name)).controller!.text;

Future<void> _tap(WidgetTester tester, String key) async {
  final control = find.byKey(ValueKey(key));
  await tester.ensureVisible(control);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(control);
  await tester.pump(const Duration(milliseconds: 300));
}

void _expectForm(WidgetTester tester, String url, String label) {
  expect(_text(tester, 'profile-label'), label);
  expect(_text(tester, 'base-url'), url);
  expect(_text(tester, 'api-key'), isEmpty);
}

void _expectNoMutations(
  FakeHermesChannel channel,
  FakeHermesEndpointStore store,
) {
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
  expect(store.saveCalls, isEmpty);
  expect(store.saveAllCalls, isEmpty);
  expect(store.deleteProfileCalls, isEmpty);
  expect(store.clearCalls, 0);
}

Future<void> _mount(
  WidgetTester tester,
  FakeHermesChannel channel,
  FakeHermesEndpointStore store,
  Size size,
) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(channel.dispose);
  final directory = directoryFor(
    configs: const [],
    loader: FakeGatewaySummaryLoader({}),
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
  await tester.pump();
  expect(store.loadProfilesCalls, 1);
}

void main() {
  void linuxTest(String name, WidgetTesterCallback body) => testWidgets(
    name,
    body,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
  for (final size in [const Size(1280, 900), const Size(390, 844)]) {
    final layout = size.width > 600 ? 'desktop' : 'compact';
    for (final edit in ['label', 'url return', 'local preset']) {
      linuxTest('$layout delayed load preserves $edit intent', (tester) async {
        final pending = Completer<List<HermesEndpointConfig>>();
        final channel = FakeHermesChannel.disconnected();
        final store = FakeHermesEndpointStore(
          onLoadProfiles: () => pending.future,
        );
        await _mount(tester, channel, store, size);
        expect(
          find.byKey(const ValueKey('hermes-endpoints-loading')),
          findsOneWidget,
        );
        _expectForm(tester, '', '');
        if (edit == 'label') {
          await tester.enterText(_field('profile-label'), 'Manual label');
        } else if (edit == 'url return') {
          await tester.enterText(_field('base-url'), 'https://manual.invalid');
          await tester.enterText(_field('base-url'), '');
        } else {
          await _tap(tester, 'hermes-developer-shortcuts');
          await _tap(tester, 'hermes-preset-local');
          await _tap(tester, 'hermes-preset-local');
        }
        _expectNoMutations(channel, store);
        pending.complete(const [_saved]);
        await tester.pumpAndSettle();
        // The list becomes available, without implicitly selecting it.
        expect(
          find.byKey(const ValueKey('hermes-endpoint-profile-saved')),
          findsOneWidget,
        );
        _expectNoMutations(channel, store);
        _expectForm(
          tester,
          edit == 'local preset' ? _local : '',
          edit == 'label' ? 'Manual label' : '',
        );
      });
    }

    linuxTest('$layout pristine load and explicit saved selection populate', (
      tester,
    ) async {
      final pending = Completer<List<HermesEndpointConfig>>();
      final channel = FakeHermesChannel.disconnected();
      final store = FakeHermesEndpointStore(
        onLoadProfiles: () => pending.future,
      );
      await _mount(tester, channel, store, size);
      pending.complete(const [_saved, _other]);
      await tester.pumpAndSettle();
      _expectForm(tester, _saved.baseUrl, _saved.label!);
      await tester.enterText(_field('profile-label'), 'Manual label');
      await _tap(tester, 'hermes-endpoint-profile-other');
      _expectForm(tester, _other.baseUrl, _other.label!);
      _expectNoMutations(channel, store);
    });

    for (final edited in [false, true]) {
      linuxTest('$layout load error retry edited=$edited', (tester) async {
        final first = Completer<List<HermesEndpointConfig>>();
        final retry = Completer<List<HermesEndpointConfig>>();
        var loads = 0;
        final channel = FakeHermesChannel.disconnected();
        final store = FakeHermesEndpointStore(
          onLoadProfiles: () => ++loads == 1 ? first.future : retry.future,
        );
        await _mount(tester, channel, store, size);
        if (edited) {
          await tester.enterText(_field('profile-label'), 'Manual label');
        }
        first.completeError(StateError('synthetic storage failure'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('hermes-endpoints-load-error')),
          findsOneWidget,
        );
        expect(find.textContaining('synthetic storage failure'), findsNothing);
        await _tap(tester, 'hermes-endpoints-retry');
        expect(store.loadProfilesCalls, 2);
        retry.complete(const [_saved]);
        await tester.pumpAndSettle();
        _expectForm(
          tester,
          edited ? '' : _saved.baseUrl,
          edited ? 'Manual label' : _saved.label!,
        );
        _expectNoMutations(channel, store);
      });
    }

    linuxTest('$layout unmount before saved load settles is inert', (
      tester,
    ) async {
      final pending = Completer<List<HermesEndpointConfig>>();
      final channel = FakeHermesChannel.disconnected();
      final store = FakeHermesEndpointStore(
        onLoadProfiles: () => pending.future,
      );
      await _mount(tester, channel, store, size);
      await tester.enterText(_field('profile-label'), 'Manual label');
      await tester.pumpWidget(const SizedBox());
      pending.complete(const [_saved]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      _expectNoMutations(channel, store);
    });
  }
}
