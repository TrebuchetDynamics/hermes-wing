import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/providers/widgets/model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../gateways/hermes_gateway_session_restoration_test.dart'
    show RestorationHarness, target;

String inventory(String model) => jsonEncode({
  'catalog': {
    'providers': {
      'synthetic': {
        'models': [
          {'id': model},
        ],
      },
    },
  },
  'active': {'provider': 'synthetic', 'model': model},
  'revision': 'synthetic-revision',
});

Future<RestorationHarness> mountChat(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = RestorationHarness();
  addTearDown(h.dispose);
  h.configureCapabilities = (document) {
    final auth = document['auth']! as Map<String, Object?>;
    auth['granted_scopes'] = ['sessions:read', 'models:read', 'models:write'];
    final endpoints = document['endpoints']! as Map<String, Object?>;
    endpoints['models'] = {
      'method': 'GET',
      'path': '/api/models',
      'profile_scoped': true,
      'required_scopes': ['models:read'],
    };
    endpoints['models_assignment'] = {
      'method': 'PUT',
      'path': '/api/models/assignment',
      'profile_scoped': true,
      'required_scopes': ['models:write'],
    };
  };
  await h.directory.start();
  expect(h.channel.state.selectedProfileId, 'coder');
  expect(h.channel.state.canReadModels, isTrue);
  expect(h.channel.state.canWriteModels, isTrue);
  expect(h.channel.state.canLockSessionModel, isFalse);
  expect(h.channel.state.modelInventory, isNull);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(h.channel),
        hermesGatewayDirectoryProvider.overrideWith((_) {
          h.disposed = true;
          return h.directory;
        }),
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

Future<void> beginRead(WidgetTester tester, RestorationHarness h) async {
  final before = h.reads.where((uri) => uri.path == '/api/models').length;
  await tester.tap(find.byKey(const ValueKey('hermes-composer-model-chip')));
  await tester.pump();
  final reads = h.reads.where((uri) => uri.path == '/api/models').toList();
  expect(reads.length, before + 1);
  expect(reads.last.queryParameters['profile'], 'coder');
  expect(find.byType(ModelPickerSheet), findsNothing);
}

void expectNoPickerOrFeedback(WidgetTester tester, RestorationHarness h) {
  expect(find.byType(ModelPickerSheet), findsNothing);
  expect(find.byType(SnackBar), findsNothing);
  expect(h.mutations, isEmpty);
  expect(tester.takeException(), isNull);
}

Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  for (final transition in ['profile', 'profile roundtrip', 'reconnect']) {
    for (final outcome in ['success', 'failure']) {
      testWidgets('$transition suppresses obsolete inventory $outcome', (
        tester,
      ) async {
        final h = await mountChat(tester);
        final delayed = Completer<String>();
        h.onRead = (uri) async =>
            uri.path == '/api/models' ? delayed.future : null;
        await beginRead(tester, h);
        h.onRead = (uri) async =>
            uri.path == '/api/models' ? inventory('replacement-model') : null;
        if (transition == 'reconnect') {
          await h.directory.activate(
            target.contactId,
            preferredSessionId: 'older-A',
          );
        } else {
          await h.directory.activate(
            const GatewayContactId(gatewayId: 'alpha', profileId: 'default'),
            preferredSessionId: 'older-A',
          );
          if (transition == 'profile roundtrip') {
            await h.directory.activate(
              target.contactId,
              preferredSessionId: 'older-A',
            );
          }
        }
        // Publish the replacement owner's inventory while the old read remains
        // pending. The production channel must discard its obsolete response.
        await h.channel.loadModels();
        final replacement = h.channel.state.modelInventory;
        expect(replacement?.assignment.activeModel, 'replacement-model');
        await tester.pumpAndSettle();
        if (outcome == 'failure') {
          delayed.completeError(StateError('Synthetic inventory read failed'));
        } else {
          delayed.complete(inventory('obsolete-model'));
        }
        await tester.pumpAndSettle();
        expect(h.channel.state.modelInventory, same(replacement));
        expectNoPickerOrFeedback(tester, h);
        // A fresh explicit request belongs to the current owner and still opens.
        await tester.tap(
          find.byKey(const ValueKey('hermes-composer-model-chip')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ModelPickerSheet), findsOneWidget);
        expect(
          tester
              .widget<ModelPickerSheet>(find.byType(ModelPickerSheet))
              .inventory,
          same(replacement),
        );
        expect(h.mutations, isEmpty);
        await unmount(tester);
      });
    }
  }

  testWidgets('same-owner delayed inventory opens the existing picker', (
    tester,
  ) async {
    final h = await mountChat(tester);
    final delayed = Completer<String>();
    h.onRead = (uri) async => uri.path == '/api/models' ? delayed.future : null;
    await beginRead(tester, h);
    delayed.complete(inventory('current-model'));
    await tester.pumpAndSettle();
    expect(find.byType(ModelPickerSheet), findsOneWidget);
    expect(
      tester.widget<ModelPickerSheet>(find.byType(ModelPickerSheet)).inventory,
      same(h.channel.state.modelInventory),
    );
    expect(
      h.channel.state.modelInventory?.assignment.activeModel,
      'current-model',
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(h.mutations, isEmpty);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('same-owner delayed error remains actionable', (tester) async {
    final h = await mountChat(tester);
    final delayed = Completer<String>();
    h.onRead = (uri) async => uri.path == '/api/models' ? delayed.future : null;
    await beginRead(tester, h);
    delayed.completeError(StateError('Synthetic inventory read failed'));
    await tester.pumpAndSettle();
    expect(find.byType(ModelPickerSheet), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    final context = tester.element(find.byType(HermesChatScreen));
    expect(
      find.text(AppLocalizations.of(context).chatComposerModelsLoadFailed),
      findsOneWidget,
    );
    expect(h.mutations, isEmpty);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
