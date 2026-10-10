import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

const _first = HermesEndpointConfig(
  id: 'first',
  baseUrl: 'https://first.example.invalid/p/shared',
  label: 'First synthetic host',
);
const _second = HermesEndpointConfig(
  id: 'second',
  baseUrl: 'https://second.example.invalid/p/shared',
  label: 'Second synthetic host',
);

class _Store extends FakeHermesEndpointStore {
  _Store() : super(profiles: [_first, _second]);

  Completer<void>? deletion;
  Completer<void>? rename;
  bool failDelete = false;
  bool failRename = false;

  @override
  Future<void> deleteProfile(String profileId) async {
    await deletion?.future;
    if (failDelete) throw StateError('private platform storage detail');
    await super.deleteProfile(profileId);
  }

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
    await rename?.future;
    if (failRename) throw StateError('private platform storage detail');
    await super.save(
      baseUrl: baseUrl,
      apiKey: apiKey,
      label: label,
      profileId: profileId,
      wingLinkOrigin: wingLinkOrigin,
      wingLinkToken: wingLinkToken,
      wingLinkPendingCredentialId: wingLinkPendingCredentialId,
      wingLinkHostFingerprint: wingLinkHostFingerprint,
      wingLinkDeviceId: wingLinkDeviceId,
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

Future<(FakeHermesChannel, _Loader)> _mount(
  WidgetTester tester,
  _Store store,
) async {
  tester.view.physicalSize = const Size(1280, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final channel = FakeHermesChannel.disconnected();
  final loader = _Loader();
  final directory = HermesGatewayDirectory(
    store: store,
    cache: GatewayContactCache(),
    loader: loader,
    activeChannel: channel,
  );
  addTearDown(channel.dispose);

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
  await _select(tester, 'first');
  return (channel, loader);
}

Future<void> _select(WidgetTester tester, String id) async {
  final chip = find.byKey(ValueKey('hermes-endpoint-profile-$id'));
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

String _field(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

Future<void> _remove(WidgetTester tester) async {
  final chip = find.byKey(const ValueKey('hermes-endpoint-profile-first'));
  final close = find.descendant(of: chip, matching: find.byIcon(Icons.close));
  await tester.ensureVisible(close);
  await tester.tap(close);
  await tester.pumpAndSettle();
}

Future<void> _confirmRemove(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey('hermes-endpoint-profile-delete-confirm')),
  );
  await tester.pumpAndSettle();
}

Future<void> _rename(WidgetTester tester, String label) async {
  final button = find.byKey(
    const ValueKey('hermes-endpoint-profile-rename-first'),
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('hermes-endpoint-profile-rename-field')),
    label,
  );
  await tester.tap(
    find.byKey(const ValueKey('hermes-endpoint-profile-rename-save')),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final rename in [false, true]) {
    testWidgets(
      'stale ${rename ? 'rename' : 'remove'} dialog cannot mutate a new owner',
      (tester) async {
        final store = _Store();
        final (channel, _) = await _mount(tester, store);
        if (rename) {
          await tester.tap(
            find.byKey(const ValueKey('hermes-endpoint-profile-rename-first')),
          );
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('hermes-endpoint-profile-rename-field')),
            'Superseded name',
          );
        } else {
          await _remove(tester);
        }
        // Simulate the authoritative channel changing while consent is open.
        // The same profile/session identity on another origin is a different owner.
        await channel.connect(baseUrl: _second.baseUrl);
        await channel.selectSession('shared-session');
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            ValueKey(
              rename
                  ? 'hermes-endpoint-profile-rename-save'
                  : 'hermes-endpoint-profile-delete-confirm',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(store.saveCalls, isEmpty);
        expect(store.deleteProfileCalls, isEmpty);
        expect(channel.state.connectedBaseUrl, _second.baseUrl);
        expect(channel.state.activeSessionId, 'shared-session');
      },
    );
  }

  testWidgets(
    'late rename refreshes saved label without replacing a newer draft',
    (tester) async {
      final store = _Store()..rename = Completer<void>();
      final (channel, _) = await _mount(tester, store);
      await _rename(tester, 'Renamed synthetic host');
      await _select(tester, 'second');
      store.rename!.complete();
      await tester.pumpAndSettle();
      expect(store.saveCalls.single.id, 'first');
      expect(_field(tester, 'hermes-base-url-field'), _second.baseUrl);
      expect(_field(tester, 'hermes-profile-label-field'), _second.label);
      expect(find.text('Renamed synthetic host'), findsOneWidget);
      expect(channel.connectCalls, isEmpty);
    },
  );

  testWidgets(
    'late removal retains replacement channel and same session identity',
    (tester) async {
      final store = _Store()..deletion = Completer<void>();
      final (channel, _) = await _mount(tester, store);
      await _remove(tester);
      await _confirmRemove(tester);
      await _select(tester, 'second');
      await channel.connect(baseUrl: _second.baseUrl);
      await channel.selectSession('shared-session');
      await tester.pumpAndSettle();
      final disconnects = channel.disconnectCalls;
      store.deletion!.complete();
      await tester.pumpAndSettle();
      expect(channel.state.connectedBaseUrl, _second.baseUrl);
      expect(channel.state.activeSessionId, 'shared-session');
      expect(channel.disconnectCalls, disconnects);
      expect(_field(tester, 'hermes-base-url-field'), _second.baseUrl);
      expect(store.deleteProfileCalls, ['first']);
    },
  );

  testWidgets('rename and remove cancellation never mutate saved hosts', (
    tester,
  ) async {
    final store = _Store();
    final (channel, _) = await _mount(tester, store);
    await tester.tap(
      find.byKey(const ValueKey('hermes-endpoint-profile-rename-first')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('hermes-endpoint-profile-rename-cancel')),
    );
    await tester.pumpAndSettle();
    await _remove(tester);
    await tester.tap(
      find.byKey(const ValueKey('hermes-endpoint-profile-delete-cancel')),
    );
    await tester.pumpAndSettle();
    expect(store.saveCalls, isEmpty);
    expect(store.deleteProfileCalls, isEmpty);
    expect(channel.connectCalls, isEmpty);
    expect(_field(tester, 'hermes-base-url-field'), _first.baseUrl);
  });

  testWidgets('late removal cannot clear edit-and-return connection intent', (
    tester,
  ) async {
    final store = _Store()..deletion = Completer<void>();
    final (channel, _) = await _mount(tester, store);
    await _remove(tester);
    await _confirmRemove(tester);
    await _select(tester, 'second');
    await _select(tester, 'first');
    await tester.enterText(
      find.byKey(const ValueKey('hermes-profile-label-field')),
      'New explicit draft',
    );
    store.deletion!.complete();
    await tester.pumpAndSettle();
    expect(store.deleteProfileCalls, ['first']);
    expect(_field(tester, 'hermes-base-url-field'), _first.baseUrl);
    expect(_field(tester, 'hermes-profile-label-field'), 'New explicit draft');
    expect(channel.connectCalls, isEmpty);
  });

  testWidgets('current removal clears only the selected endpoint form', (
    tester,
  ) async {
    final store = _Store();
    await _mount(tester, store);
    await _remove(tester);
    await _confirmRemove(tester);
    expect(store.deleteProfileCalls, ['first']);
    expect(_field(tester, 'hermes-base-url-field'), isEmpty);
    expect(
      find.byKey(const ValueKey('hermes-endpoint-profile-first')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('hermes-endpoint-profile-second')),
      findsOneWidget,
    );
  });

  testWidgets('remove storage failure is safe and requires explicit retry', (
    tester,
  ) async {
    final store = _Store()..failDelete = true;
    final (channel, _) = await _mount(tester, store);
    await _remove(tester);
    await _confirmRemove(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Could not remove gateway.'), findsOneWidget);
    expect(find.textContaining('private platform'), findsNothing);
    expect(_field(tester, 'hermes-base-url-field'), _first.baseUrl);
    expect(await store.loadProfiles(), hasLength(2));
    store.failDelete = false;
    await _remove(tester);
    await _confirmRemove(tester);
    expect(store.deleteProfileCalls, ['first']);
    expect(channel.connectCalls, isEmpty);
  });

  testWidgets(
    'rename storage failure is redacted and explicit retry persists',
    (tester) async {
      final store = _Store()..failRename = true;
      final (channel, _) = await _mount(tester, store);
      await _rename(tester, 'Renamed synthetic host');
      expect(find.text('Could not rename gateway.'), findsOneWidget);
      expect(find.textContaining('private platform'), findsNothing);
      expect(store.saveCalls, isEmpty);
      store.failRename = false;
      await _rename(tester, 'Renamed synthetic host');
      expect(store.saveCalls.single.id, 'first');
      expect(store.saveCalls.single.baseUrl, _first.baseUrl);
      expect(store.saveCalls.single.label, 'Renamed synthetic host');
      expect(_field(tester, 'hermes-base-url-field'), _first.baseUrl);
      expect(channel.connectCalls, isEmpty);
    },
  );

  testWidgets('late removal after screen disposal does not read disposed ref', (
    tester,
  ) async {
    final store = _Store()..deletion = Completer<void>();
    await _mount(tester, store);
    await _remove(tester);
    await _confirmRemove(tester);
    await tester.pumpWidget(const SizedBox());
    store.deletion!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(store.deleteProfileCalls, ['first']);
  });
}
