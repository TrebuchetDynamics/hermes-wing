import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_gateway_directory.dart';

class PickerChannel extends FakeHermesChannel {
  PickerChannel()
    : super(
        selectedProfileId: 'default',
        capabilities: HermesCapabilityDocument.fromJson(const {
          'schema_version': 1,
          'auth': {'granted_scopes': []},
          'endpoints': {
            'model_options': {'method': 'GET', 'path': '/api/model/options'},
            'session_model_lock': {
              'method': 'POST',
              'path': '/api/sessions/{session_id}/model',
            },
          },
        }),
        modelOptions: const HermesModelOptions(
          currentProvider: 'synthetic',
          currentModel: 'model-a',
          providers: [
            HermesModelOptionProvider(
              slug: 'synthetic',
              label: 'Synthetic',
              models: ['model-a', 'model-b'],
              authenticated: true,
            ),
          ],
        ),
      );
  HermesChannelState? replacement;
  Completer<void>? pending;
  Completer<void>? loadGate;
  int submissions = 0;
  @override
  HermesChannelState get state => replacement ?? super.state;
  void replace(HermesChannelState value) {
    replacement = value;
    notifyListeners();
  }

  @override
  Future<void> loadModelOptions({bool refresh = false}) async {
    await loadGate?.future;
    replace(state.copyWith(modelOptions: modelOptions));
  }

  @override
  Future<void> lockSessionModel({
    required String sessionId,
    required String provider,
    required String model,
  }) async {
    submissions++;
    final original = state;
    await pending?.future;
    if (identical(state, original)) {
      lockSessionModelCalls.add({
        'sessionId': sessionId,
        'provider': provider,
        'model': model,
      });
      replace(
        state.copyWith(
          sessionModelLocks: {
            ...state.sessionModelLocks,
            sessionId: HermesSessionModelLock(
              sessionId: sessionId,
              provider: provider,
              model: model,
              accepted: true,
            ),
          },
        ),
      );
    }
  }
}

Widget app(PickerChannel channel) => ProviderScope(
  overrides: [
    hermesChannelProvider.overrideWithValue(channel),
    hermesGatewayDirectoryProvider.overrideWith(
      (_) => directoryFor(
        configs: const [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      ),
    ),
    hermesVoiceCaptureServiceProvider.overrideWithValue(null),
    hermesTextToSpeechServiceProvider.overrideWithValue(null),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const HermesChatScreen(),
  ),
);
Future<void> open(WidgetTester tester, PickerChannel channel) async {
  await tester.pumpWidget(app(channel));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('hermes-composer-model-chip')));
  await tester.pumpAndSettle();
  expect(find.text('Use a model for this session'), findsOneWidget);
}

final pickerRows = find.descendant(
  of: find.byKey(const ValueKey('session-model-results')),
  matching: find.byType(ListTile),
);

Future<void> confirm(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Use for session'));
  await tester.tap(find.text('Use for session'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('existing composer confirms session-only raw identity', (
    tester,
  ) async {
    final channel = PickerChannel();
    addTearDown(channel.dispose);
    await open(tester, channel);
    await tester.tap(
      find.byKey(const ValueKey('session-model-synthetic/model-b')),
    );
    await confirm(tester);
    expect(channel.lockSessionModelCalls, [
      {'sessionId': 'sess_1', 'provider': 'synthetic', 'model': 'model-b'},
    ]);
    expect(channel.assignModelCalls, isEmpty);
    expect(find.text('Use a model for this session'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('hermes-composer-model-chip')));
    await tester.pumpAndSettle();
    expect(
      find.text('Selected: Synthetic (synthetic) — model-b'),
      findsOneWidget,
    );
    expect(
      tester.widgetList<ListTile>(pickerRows).first.key,
      const ValueKey('session-model-synthetic/model-b'),
    );
    await confirm(tester);
    expect(channel.lockSessionModelCalls, [
      {'sessionId': 'sess_1', 'provider': 'synthetic', 'model': 'model-b'},
      {'sessionId': 'sess_1', 'provider': 'synthetic', 'model': 'model-b'},
    ]);
  });
  testWidgets('pre-existing confirmed lock overrides the catalog default', (
    tester,
  ) async {
    final channel = PickerChannel();
    addTearDown(channel.dispose);
    channel.replace(
      channel.state.copyWith(
        sessionModelLocks: const {
          'sess_1': HermesSessionModelLock(
            sessionId: 'sess_1',
            provider: 'synthetic',
            model: 'model-b',
            accepted: true,
          ),
        },
      ),
    );
    await open(tester, channel);
    expect(
      find.text('Selected: Synthetic (synthetic) — model-b'),
      findsOneWidget,
    );
    expect(
      tester.widgetList<ListTile>(pickerRows).first.key,
      const ValueKey('session-model-synthetic/model-b'),
    );
    await confirm(tester);
    expect(channel.lockSessionModelCalls.single['model'], 'model-b');
    expect(channel.state.modelOptions?.currentModel, 'model-a');
  });
  testWidgets('idle compact composer exposes the existing session picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = PickerChannel();
    addTearDown(channel.dispose);
    await open(tester, channel);
    expect(
      find.text('Selected: Synthetic (synthetic) — model-a'),
      findsOneWidget,
    );
    await confirm(tester);
    expect(channel.lockSessionModelCalls.single['sessionId'], 'sess_1');
  });

  for (final identity in [
    (provider: 'unconfigured', model: 'model-b'),
    (provider: 'synthetic', model: 'removed-model'),
  ]) {
    testWidgets('unavailable session identity $identity never falls back', (
      tester,
    ) async {
      final channel = PickerChannel();
      addTearDown(channel.dispose);
      channel.replace(
        channel.state.copyWith(
          sessionModelLocks: {
            'sess_1': HermesSessionModelLock(
              sessionId: 'sess_1',
              provider: identity.provider,
              model: identity.model,
              accepted: true,
            ),
          },
        ),
      );
      await open(tester, channel);
      expect(
        find.text(
          'The selected model is no longer available. Choose a model from the current catalog.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('Use for session'),
                matching: find.byWidgetPredicate(
                  (widget) => widget is FilledButton,
                ),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(channel.submissions, 0);
      await tester.tap(
        find.byKey(const ValueKey('session-model-synthetic/model-a')),
      );
      await tester.pumpAndSettle();
      await confirm(tester);
      expect(channel.lockSessionModelCalls.single['model'], 'model-a');
    });
  }

  for (final lock in [
    const HermesSessionModelLock(
      sessionId: 'sess_1',
      provider: 'synthetic',
      model: 'model-b',
    ),
    const HermesSessionModelLock(
      sessionId: 'other-session',
      provider: 'synthetic',
      model: 'model-b',
      accepted: true,
    ),
  ]) {
    testWidgets(
      'unconfirmed or mismatched session lock uses catalog fallback ${lock.sessionId}/${lock.accepted}',
      (tester) async {
        final channel = PickerChannel();
        addTearDown(channel.dispose);
        channel.replace(
          channel.state.copyWith(sessionModelLocks: {'sess_1': lock}),
        );
        await open(tester, channel);
        expect(
          find.text('Selected: Synthetic (synthetic) — model-a'),
          findsOneWidget,
        );
        await confirm(tester);
        expect(channel.lockSessionModelCalls.single['model'], 'model-a');
      },
    );
  }

  testWidgets(
    'profile roundtrip during inventory loading cannot open a stale picker',
    (tester) async {
      final channel = PickerChannel()..loadGate = Completer<void>();
      addTearDown(channel.dispose);
      channel.replace(channel.state.copyWith(clearModelOptions: true));
      await tester.pumpWidget(app(channel));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-composer-model-chip')),
      );
      await tester.pump();
      final original = channel.state;
      channel.replace(original.copyWith(selectedProfileId: 'other'));
      channel.replace(original);
      channel.loadGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Use a model for this session'), findsNothing);
      expect(
        find.text('Models could not be loaded from Hermes.'),
        findsNothing,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(channel.submissions, 0);
    },
  );

  for (final change in [
    'profile',
    'session',
    'inventory',
    'connection',
    'profile-pending',
  ]) {
    testWidgets(
      '$change change then return invalidates open picker before I/O',
      (tester) async {
        final channel = PickerChannel();
        addTearDown(channel.dispose);
        await open(tester, channel);
        final original = channel.state;
        channel.replace(switch (change) {
          'profile' => original.copyWith(selectedProfileId: 'other'),
          'session' => original.copyWith(activeSessionId: 'other-session'),
          'inventory' => original.copyWith(
            modelOptions: const HermesModelOptions(providers: []),
          ),
          'profile-pending' => original.copyWith(isSelectingProfile: true),
          _ => original.copyWith(status: HermesConnectionStatus.disconnected),
        });
        channel.replace(original);
        await tester.pumpAndSettle();
        await confirm(tester);
        expect(channel.submissions, 0);
        expect(
          find.text('Hermes could not confirm this session model.'),
          findsOneWidget,
        );
        expect(
          find.text('Selected: Synthetic (synthetic) — model-a'),
          findsOneWidget,
        );
      },
    );
  }
  testWidgets('session switch during pending success never closes as saved', (
    tester,
  ) async {
    final channel = PickerChannel()..pending = Completer<void>();
    addTearDown(channel.dispose);
    await open(tester, channel);
    await confirm(tester);
    channel.replace(channel.state.copyWith(activeSessionId: 'other-session'));
    channel.pending!.complete();
    await tester.pumpAndSettle();
    expect(channel.submissions, 1);
    expect(find.text('Use a model for this session'), findsOneWidget);
    expect(
      find.text('Hermes could not confirm this session model.'),
      findsOneWidget,
    );
  });
}
