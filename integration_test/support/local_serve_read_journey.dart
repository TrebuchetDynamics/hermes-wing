import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'local_serve_read_fixture.dart';

class _NoWriteStore extends EmptyHermesEndpointStore {
  int writes = 0;
  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
  }) async {
    writes++;
    throw StateError('Serve credentials must not enter gateway records.');
  }
}

Future<Map<String, Object?>> runLocalServeReadJourney(
  WidgetTester tester, {
  LocalServeReadFixture? backend,
  Future<Map<String, Object?>> Function(HermesApiChannel)? afterConnected,
}) async {
  SharedPreferences.setMockInitialValues({});
  final previous = HttpOverrides.current;
  HttpOverrides.global = null;
  final fixture = backend ?? LocalServeReadFixture();
  final store = _NoWriteStore();
  final container = ProviderContainer(
    overrides: [
      hermesEndpointStoreProvider.overrideWithValue(store),
      hermesChannelProvider.overrideWith((ref) {
        final channel = HermesApiChannel();
        ref.onDispose(channel.dispose);
        return channel;
      }),
    ],
  );
  final channel = container.read(hermesChannelProvider) as HermesApiChannel;
  await tester.runAsync(fixture.start);
  Future<void> waitFor(bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(
      done(),
      isTrue,
      reason: 'Production control did not settle: ${channel.state.status}',
    );
  }

  Finder control(String key) => find.byKey(ValueKey(key));
  Future<void> press(String key) async {
    final target = control(key);
    expect(target, findsOneWidget);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
  }

  Future<void> type(String key, String value) async {
    final target = control(key);
    await tester.ensureVisible(target);
    await tester.enterText(target, value);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(target).controller!.text == value, isTrue);
  }

  try {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HermesChatScreen(
            initiallyEditingConnection: true,
            initialConnectionMode: HermesConnectionMode.local,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await press('hermes-local-serve-reads');
    await press('platform-local-advanced-endpoint');
    await tester.pumpAndSettle();
    await type('hermes-base-url-field', fixture.origin);
    await type('hermes-api-key-field', 'synthetic-denied');
    await press('hermes-connect-button');
    await waitFor(() => channel.state.status == HermesConnectionStatus.error);
    expect(
      channel.state.connectionFailureKind,
      HermesConnectionFailureKind.authentication,
    );
    expect(fixture.requests.length, 1);

    fixture.unsupported = true;
    await type('hermes-api-key-field', LocalServeReadFixture.token);
    await press('hermes-connect-button');
    await waitFor(
      () =>
          fixture.requests.length == 2 &&
          channel.state.status == HermesConnectionStatus.error,
    );
    expect(
      channel.state.connectionFailureKind,
      HermesConnectionFailureKind.incompatibleResponse,
    );

    fixture.unsupported = false;
    fixture.holdProfiles = Completer<void>();
    await press('hermes-connect-button');
    await waitFor(() => fixture.requests.length == 3);
    await press('hermes-local-serve-cancel');
    expect(channel.state.status, HermesConnectionStatus.disconnected);
    fixture.holdProfiles!.complete();
    fixture.holdProfiles = null;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pump();
    expect(channel.state.status, HermesConnectionStatus.disconnected);

    await press('hermes-connect-button');
    await waitFor(() => channel.state.isConnected);
    expect(channel.state.activeSessionId, 'default-session');
    expect(channel.state.activeMessages.last.text, 'default fixture answer');
    expect(find.text('default fixture answer'), findsWidgets);
    expect(channel.state.canCreateSessions, isFalse);
    expect(store.writes, 0);
    expect(fixture.requests.length, 6);
    expect(fixture.requests.every((r) => r.startsWith('GET ')), isTrue);
    expect(tester.takeException(), isNull);
    final chatReceipt =
        await afterConnected?.call(channel) ?? const <String, Object?>{};
    return {
      'requests': fixture.requests.length,
      'mutations': 0,
      'credential_saves': store.writes,
      'denied': true,
      'unsupported': true,
      'cancelled': true,
      'explicit_retry': true,
      'profile': channel.state.selectedProfileId,
      'session': channel.state.activeSessionId,
      ...chatReceipt,
    };
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.runAsync(fixture.close);
    HttpOverrides.global = previous;
  }
}
