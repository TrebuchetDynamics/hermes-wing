import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/features/hermes_chat/widgets/session_model_picker_sheet.dart';
import 'package:wing/features/providers/widgets/model_picker_sheet.dart';

import 'hermes_chat_session_picker_test.dart' show PickerChannel, app;

final _modelControl = find.byKey(const ValueKey('hermes-composer-model-chip'));

class _OpeningChannel extends PickerChannel {
  _OpeningChannel({required this.sessionOnly}) {
    replace(
      state.copyWith(
        clearModelOptions: true,
        capabilities: sessionOnly ? state.capabilities : _legacyCapabilities,
      ),
    );
  }

  final bool sessionOnly;
  Completer<void>? readGate;
  int reads = 0;

  static final _legacyCapabilities = HermesCapabilityDocument.fromJson({
    'schema_version': 1,
    'profile_context': {
      'type': 'query',
      'name': 'profile',
      'required': true,
      'default_profile_id': 'default',
    },
    'auth': {
      'granted_scopes': ['models:read', 'models:write'],
    },
    'endpoints': {
      'models': {
        'method': 'GET',
        'path': '/api/models',
        'profile_scoped': true,
        'required_scopes': ['models:read'],
      },
      'models_assignment': {
        'method': 'PUT',
        'path': '/api/models/assignment',
        'profile_scoped': true,
        'required_scopes': ['models:write'],
      },
    },
  });

  static final _inventory = HermesModelInventory(
    catalog: HermesModelCatalog.fromJson({
      'providers': {
        'synthetic': {
          'models': [
            {'id': 'model-a'},
          ],
        },
      },
    }),
    assignment: const HermesModelAssignment(
      activeProvider: 'synthetic',
      activeModel: 'model-a',
      revision: 'synthetic-revision',
    ),
  );

  @override
  Future<void> loadModelOptions({bool refresh = false}) async {
    expect(sessionOnly, isTrue);
    reads++;
    await readGate?.future;
    replace(state.copyWith(modelOptions: modelOptions));
  }

  @override
  Future<void> loadModels({bool refresh = false}) async {
    expect(sessionOnly, isFalse);
    reads++;
    await readGate?.future;
    replace(state.copyWith(modelInventory: _inventory));
  }
}

Finder _sheets(bool sessionOnly) => find.byType(
  sessionOnly ? SessionModelPickerSheet : ModelPickerSheet,
  skipOffstage: false,
);

void _expectNoWrites(_OpeningChannel channel) {
  expect(channel.submissions, 0);
  expect(channel.lockSessionModelCalls, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
}

Future<void> _cancel(WidgetTester tester, bool sessionOnly) async {
  await tester.ensureVisible(find.text('Cancel'));
  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();
  // Include offstage routes: one Cancel must not expose a second hidden sheet.
  expect(_sheets(sessionOnly), findsNothing);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final sessionOnly in [true, false]) {
    final branch = sessionOnly ? 'session' : 'legacy';
    for (final outcome in ['success', 'failure']) {
      testWidgets('$branch capability roundtrip during pending $outcome', (
        tester,
      ) async {
        final channel = _OpeningChannel(sessionOnly: sessionOnly);
        addTearDown(channel.dispose);
        final gate = channel.readGate = Completer<void>();
        await tester.pumpWidget(app(channel));
        await tester.pumpAndSettle();
        await tester.tap(_modelControl);
        await tester.pump();
        final original = channel.state;
        channel.replace(
          original.copyWith(
            capabilities: HermesCapabilityDocument.fromJson({
              'schema_version': 1,
              'auth': {'granted_scopes': []},
              'endpoints': <String, Object?>{},
            }),
          ),
        );
        expect(channel.state.canLockSessionModel, isFalse);
        expect(channel.state.canWriteModels, isFalse);
        channel.replace(original);
        // Returning to the same capability identity must not revive the read.
        if (outcome == 'failure') {
          gate.completeError(StateError('Synthetic catalog failure'));
        } else {
          gate.complete();
        }
        await tester.pumpAndSettle();
        expect(_sheets(sessionOnly), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(channel.reads, 1);
        _expectNoWrites(channel);
        channel.readGate = null;
        await tester.tap(_modelControl);
        await tester.pumpAndSettle();
        expect(_sheets(sessionOnly), findsOneWidget);
        expect(channel.reads, outcome == 'failure' ? 2 : 1);
        await _cancel(tester, sessionOnly);
        _expectNoWrites(channel);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });

      testWidgets('$branch repeated pending activation / $outcome / reopen', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = _OpeningChannel(sessionOnly: sessionOnly);
        addTearDown(channel.dispose);
        final gate = channel.readGate = Completer<void>();
        await tester.pumpWidget(app(channel));
        await tester.pumpAndSettle();
        expect(channel.state.canLockSessionModel, sessionOnly);
        expect(channel.state.canWriteModels, !sessionOnly);
        for (var activation = 0; activation < 3; activation++) {
          await tester.tap(_modelControl);
          await tester.pump();
        }
        expect(_sheets(sessionOnly), findsNothing);
        final admittedReads = channel.reads;
        if (outcome == 'failure') {
          gate.completeError(StateError('Synthetic catalog failure'));
        } else {
          gate.complete();
        }
        await tester.pumpAndSettle();
        _expectNoWrites(channel);
        expect(tester.takeException(), isNull);
        if (outcome == 'success') {
          expect(_sheets(sessionOnly), findsOneWidget);
          expect(find.byType(SnackBar), findsNothing);
          await _cancel(tester, sessionOnly);
        } else {
          expect(_sheets(sessionOnly), findsNothing);
          expect(find.byType(SnackBar), findsOneWidget);
          expect(
            find.textContaining('Synthetic catalog failure'),
            findsNothing,
          );
          // A duplicated snackbar queued by redundant continuations would
          // become visible after the first feedback's normal lifetime.
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();
          expect(find.byType(SnackBar), findsNothing);
        }
        expect(admittedReads, 1);
        channel.readGate = null;
        await tester.tap(_modelControl);
        await tester.pumpAndSettle();
        expect(_sheets(sessionOnly), findsOneWidget);
        expect(channel.reads, outcome == 'failure' ? 2 : 1);
        await _cancel(tester, sessionOnly);
        _expectNoWrites(channel);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
