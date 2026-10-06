import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/session_model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'hermes_chat_session_picker_test.dart' show PickerChannel, app;

class _DelayedCatalogChannel extends PickerChannel {
  Completer<void>? catalogGate;
  int catalogReads = 0;

  @override
  Future<void> loadModelOptions({bool refresh = false}) async {
    catalogReads++;
    await catalogGate?.future;
    // Deliberately publish even an obsolete success: caller admission, not
    // transport response fencing, is the boundary under test.
    replace(state.copyWith(modelOptions: modelOptions));
  }
}

final _modelControl = find.byKey(const ValueKey('hermes-composer-model-chip'));

Future<_DelayedCatalogChannel> _beginRead(WidgetTester tester) async {
  final channel = _DelayedCatalogChannel()..catalogGate = Completer<void>();
  addTearDown(channel.dispose);
  channel.replace(channel.state.copyWith(clearModelOptions: true));
  await tester.pumpWidget(app(channel));
  await tester.pumpAndSettle();
  await tester.tap(_modelControl);
  await tester.pump();
  expect(channel.catalogReads, 1);
  expect(channel.state.modelOptions, isNull);
  expect(find.byType(SessionModelPickerSheet), findsNothing);
  return channel;
}

void _expectNoWrites(_DelayedCatalogChannel channel) {
  expect(channel.submissions, 0);
  expect(channel.lockSessionModelCalls, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
}

void _expectSilent(WidgetTester tester, _DelayedCatalogChannel channel) {
  expect(find.byType(SessionModelPickerSheet), findsNothing);
  expect(find.byType(SnackBar), findsNothing);
  _expectNoWrites(channel);
  expect(tester.takeException(), isNull);
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void _complete(_DelayedCatalogChannel channel, String outcome) {
  if (outcome == 'failure') {
    channel.catalogGate!.completeError(StateError('Synthetic catalog failure'));
  } else {
    channel.catalogGate!.complete();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final transition in [
    'profile',
    'profile roundtrip',
    'session',
    'reconnect',
  ]) {
    for (final outcome in ['success', 'failure']) {
      testWidgets('$transition suppresses obsolete session catalog $outcome', (
        tester,
      ) async {
        final channel = await _beginRead(tester);
        final original = channel.state;
        switch (transition) {
          case 'profile':
            channel.replace(original.copyWith(selectedProfileId: 'other'));
          case 'profile roundtrip':
            channel.replace(original.copyWith(selectedProfileId: 'other'));
            channel.replace(original);
          case 'session':
            channel.replace(
              original.copyWith(activeSessionId: 'other-session'),
            );
          case 'reconnect':
            channel.replace(
              original.copyWith(status: HermesConnectionStatus.disconnected),
            );
            channel.replace(original);
        }
        await tester.pumpAndSettle();
        _complete(channel, outcome);
        await tester.pumpAndSettle();
        _expectSilent(tester, channel);

        // A new explicit open captures the current owner, with a fresh read
        // where the failed request did not populate the catalog.
        channel.catalogGate = null;
        await tester.tap(_modelControl);
        await tester.pumpAndSettle();
        expect(find.byType(SessionModelPickerSheet), findsOneWidget);
        expect(channel.catalogReads, outcome == 'failure' ? 2 : 1);
        expect(find.byType(SnackBar), findsNothing);
        _expectNoWrites(channel);
        expect(tester.takeException(), isNull);
        await _unmount(tester);
      });
    }
  }

  testWidgets('current-owner delayed session catalog opens picker', (
    tester,
  ) async {
    final channel = await _beginRead(tester);
    _complete(channel, 'success');
    await tester.pumpAndSettle();
    expect(find.byType(SessionModelPickerSheet), findsOneWidget);
    expect(
      tester
          .widget<SessionModelPickerSheet>(find.byType(SessionModelPickerSheet))
          .options,
      same(channel.state.modelOptions),
    );
    expect(find.byType(SnackBar), findsNothing);
    _expectNoWrites(channel);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('current-owner delayed catalog failure keeps generic feedback', (
    tester,
  ) async {
    final channel = await _beginRead(tester);
    final strings = AppLocalizations.of(
      tester.element(find.byType(HermesChatScreen)),
    );
    _complete(channel, 'failure');
    await tester.pumpAndSettle();
    expect(find.byType(SessionModelPickerSheet), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(strings.chatComposerModelsLoadFailed), findsOneWidget);
    expect(find.textContaining('Synthetic catalog failure'), findsNothing);
    _expectNoWrites(channel);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  for (final outcome in ['success', 'failure']) {
    testWidgets('unmount suppresses pending session catalog $outcome', (
      tester,
    ) async {
      final channel = await _beginRead(tester);
      await _unmount(tester);
      _complete(channel, outcome);
      await tester.pumpAndSettle();
      _expectSilent(tester, channel);
    });
  }
}
