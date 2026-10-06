import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';
import 'hermes_chat_profile_picker_test.dart' as picker;

final _source = StateProvider<HermesChannel>((_) => throw UnimplementedError());
final _failure = find.textContaining('Could not switch profile:');

class _Channel extends picker.OwnerChannel {
  _Channel({super.gate, super.rejected});

  final listeners = <VoidCallback, int>{};
  int get listenerCount => listeners.values.fold(0, (sum, n) => sum + n);

  @override
  void addListener(VoidCallback listener) {
    listeners.update(listener, (n) => n + 1, ifAbsent: () => 1);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    final n = listeners[listener];
    if (n == 1) {
      listeners.remove(listener);
    } else if (n != null) {
      listeners[listener] = n - 1;
    }
    super.removeListener(listener);
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

  final listeners = <VoidCallback, int>{};
  int get listenerCount => listeners.values.fold(0, (sum, n) => sum + n);

  @override
  void addListener(VoidCallback listener) {
    listeners.update(listener, (n) => n + 1, ifAbsent: () => 1);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    final n = listeners[listener];
    if (n == 1) {
      listeners.remove(listener);
    } else if (n != null) {
      listeners[listener] = n - 1;
    }
    super.removeListener(listener);
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  double width,
  _Channel channel,
  _Directory directory,
) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      _source.overrideWith((_) => channel),
      hermesChannelProvider.overrideWith((ref) => ref.watch(_source)),
      // Keep the empty directory stable while replacing the channel. It owns no
      // active contact, so public selection uses the direct channel path.
      hermesGatewayDirectoryProvider.overrideWith((_) => directory),
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
  return container;
}

Future<void> _choose(WidgetTester tester) async {
  await picker.openPicker(tester);
  await tester.tap(picker.row('beta'));
  await tester.pumpAndSettle();
  expect(picker.search, findsNothing);
}

void _expectOnlySelection(_Channel channel, List<String> selections) {
  expect(channel.selectProfileCalls, selections);
  expect(channel.selectSessionCalls, isEmpty);
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.sentImageDataUrls, isEmpty);
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(channel.createProfileCalls, isEmpty);
  expect(channel.renameProfileCalls, isEmpty);
  expect(channel.deleteProfileCalls, isEmpty);
  expect(channel.lockSessionModelCalls, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );
  for (final width in [390.0, 1280.0]) {
    for (final transition in [
      'replacement',
      'disconnect roundtrip',
      'endpoint roundtrip',
      'profile roundtrip',
      'same owner',
      'dispose',
    ]) {
      testWidgets('submitted rejection $transition at $width', (tester) async {
        final gate = Completer<void>();
        final channel = _Channel(gate: (_) => gate.future, rejected: true);
        final replacement = _Channel();
        addTearDown(channel.dispose);
        addTearDown(replacement.dispose);
        final directory = _Directory(channel);
        final container = await _pump(tester, width, channel, directory);
        final listenersBefore = channel.listenerCount;
        // Compare operation listeners against the mounted screen baseline:
        // its existing extension-method channel observer is outside this slice.
        final baselineListeners = channel.listeners.keys.toSet();
        final directoryBefore = directory.listenerCount;
        final original = channel.state;
        final replacementState = replacement.state;
        await _choose(tester);
        _expectOnlySelection(channel, ['beta']);
        expect(channel.listenerCount, greaterThan(listenersBefore));
        if (transition == 'replacement') {
          container.read(_source.notifier).state = replacement;
          container.read(hermesChannelProvider);
          await tester.pump();
        } else if (transition == 'dispose') {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          container.dispose();
          // Pending operation observers must release before it settles.
          expect(
            channel.listeners.keys.toSet().difference(baselineListeners),
            isEmpty,
          );
        } else if (transition != 'same owner') {
          final changed = switch (transition) {
            'disconnect roundtrip' => original.copyWith(
              status: HermesConnectionStatus.disconnected,
            ),
            'endpoint roundtrip' => original.copyWith(
              connectedBaseUrl: 'https://other.example.invalid',
            ),
            _ => original.copyWith(selectedProfileId: 'elsewhere'),
          };
          channel.change(changed);
          channel.change(original);
        }
        gate.complete();
        await tester.pumpAndSettle();
        expect(
          _failure,
          transition == 'same owner' ? findsOneWidget : findsNothing,
        );
        expect(identical(channel.state, original), isTrue);
        expect(identical(replacement.state, replacementState), isTrue);
        _expectOnlySelection(channel, ['beta']);
        _expectOnlySelection(replacement, []);
        if (transition != 'dispose') {
          final replacementBaseline = replacement.listeners.keys.toSet();
          expect(directory.listenerCount, directoryBefore);
          if (transition != 'replacement') {
            expect(channel.listenerCount, listenersBefore);
          } else {
            expect(
              channel.listeners.keys.toSet().difference(baselineListeners),
              isEmpty,
            );
          }
          // A settled operation must not prevent a fresh public open/selection.
          await picker.openPicker(tester);
          expect(picker.search, findsOneWidget);
          await tester.tap(
            picker.row(transition == 'replacement' ? 'beta' : 'active'),
          );
          await tester.pumpAndSettle();
          if (transition == 'replacement') {
            expect(replacement.state.selectedProfileId, 'beta');
            _expectOnlySelection(replacement, ['beta']);
          } else {
            _expectOnlySelection(channel, ['beta']);
            ScaffoldMessenger.of(
              tester.element(find.byType(HermesChatScreen)),
            ).removeCurrentSnackBar();
            await _choose(tester);
            expect(_failure, findsOneWidget);
            _expectOnlySelection(channel, ['beta', 'beta']);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          container.dispose();
          expect(
            channel.listeners.keys.toSet().difference(baselineListeners),
            isEmpty,
          );
          expect(
            replacement.listeners.keys.toSet().difference(replacementBaseline),
            isEmpty,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('expected target transition and reopen at $width', (
      tester,
    ) async {
      final gate = Completer<void>();
      final channel = _Channel(gate: (_) => gate.future);
      addTearDown(channel.dispose);
      final directory = _Directory(channel);
      final container = await _pump(tester, width, channel, directory);
      final before = channel.listenerCount;
      final baselineListeners = channel.listeners.keys.toSet();
      final directoryBefore = directory.listenerCount;
      await _choose(tester);
      gate.complete();
      await tester.pumpAndSettle();
      expect(channel.state.selectedProfileId, 'beta');
      expect(_failure, findsNothing);
      expect(channel.listenerCount, before);
      expect(directory.listenerCount, directoryBefore);
      await picker.openPicker(tester);
      await tester.tap(picker.row('active'));
      await tester.pumpAndSettle();
      expect(channel.state.selectedProfileId, 'active');
      _expectOnlySelection(channel, ['beta', 'active']);
      expect(_failure, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
      expect(
        channel.listeners.keys.toSet().difference(baselineListeners),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
