import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/features/providers/widgets/model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

HermesCapabilityDocument _capabilities({bool write = true}) =>
    HermesCapabilityDocument.fromJson({
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
        if (write)
          'models_assignment': {
            'method': 'PUT',
            'path': '/api/models/assignment',
            'profile_scoped': true,
            'required_scopes': ['models:write'],
          },
        'models_refresh': {
          'method': 'POST',
          'path': '/api/models/refresh',
          'profile_scoped': true,
          'required_scopes': ['models:write'],
        },
      },
    });

HermesModelInventory _inventory() => HermesModelInventory(
  catalog: HermesModelCatalog.fromJson({
    'providers': {
      'synthetic': {
        'models': [
          {'id': 'synthetic-model'},
        ],
      },
    },
  }),
  assignment: const HermesModelAssignment(
    activeProvider: 'synthetic',
    activeModel: 'synthetic-model',
    revision: 'synthetic-revision',
  ),
);

class _DelayedChannel extends FakeHermesChannel {
  _DelayedChannel()
    : super(
        capabilities: _capabilities(),
        modelInventory: _inventory(),
        selectedProfileId: 'a',
      );

  Completer<void>? refreshGate;
  Completer<void>? assignmentGate;

  @override
  Future<void> refreshModels() async {
    await super.refreshModels();
    await refreshGate?.future;
  }

  @override
  Future<void> assignModel({
    required String scope,
    String? task,
    required String provider,
    required String model,
    required String revision,
  }) async {
    await super.assignModel(
      scope: scope,
      task: task,
      provider: provider,
      model: model,
      revision: revision,
    );
    await assignmentGate?.future;
  }
}

Future<_DelayedChannel> _open(WidgetTester tester) async {
  final channel = _DelayedChannel();
  addTearDown(channel.dispose);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ModelPickerSheet(
                channel: channel,
                inventory: channel.modelInventory!,
              ),
            ),
            child: const Text('Open picker'),
          ),
        ),
      ),
    ),
  );
  expect(channel.state.canWriteModels, isTrue);
  await tester.tap(find.text('Open picker'));
  await tester.pumpAndSettle();
  return channel;
}

void _revoke(_DelayedChannel channel) {
  channel.replaceCapabilitiesAndProfiles(_capabilities(write: false), []);
  expect(channel.state.canReadModels, isTrue);
  expect(channel.state.canWriteModels, isFalse);
}

void _restore(_DelayedChannel channel) {
  channel.replaceCapabilitiesAndProfiles(_capabilities(), []);
  expect(channel.state.canWriteModels, isTrue);
}

Future<void> _assignDenied(WidgetTester tester, _DelayedChannel channel) async {
  await tester.tap(find.text('Assign'));
  await tester.pumpAndSettle();
  expect(channel.assignModelCalls, isEmpty);
  expect(find.byType(ModelPickerSheet), findsOneWidget);
  expect(find.text('The model assignment could not be saved.'), findsOneWidget);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('revoke restore cannot revive the original sheet', (
    tester,
  ) async {
    final channel = await _open(tester);
    final identity = (
      channel.state.connectedBaseUrl,
      channel.state.selectedProfileId,
    );
    _revoke(channel);
    _restore(channel);
    expect((
      channel.state.connectedBaseUrl,
      channel.state.selectedProfileId,
    ), identity);
    await _assignDenied(tester, channel);
  });

  testWidgets('unchanged authorized sheet assigns and closes', (tester) async {
    final channel = await _open(tester);
    // An equivalent authorized notification is not a revocation.
    _restore(channel);
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();
    expect(channel.assignModelCalls.single, {
      'scope': 'main',
      'task': null,
      'provider': 'synthetic',
      'model': 'synthetic-model',
      'revision': 'synthetic-revision',
    });
    expect(find.byType(ModelPickerSheet), findsNothing);
  });

  testWidgets('fresh explicit reopen after restoration can assign', (
    tester,
  ) async {
    final channel = await _open(tester);
    _revoke(channel);
    _restore(channel);
    await _assignDenied(tester, channel);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();
    expect(channel.assignModelCalls, hasLength(1));
    expect(find.byType(ModelPickerSheet), findsNothing);
  });

  testWidgets('still revoked sheet cannot assign', (tester) async {
    final channel = await _open(tester);
    _revoke(channel);
    await _assignDenied(tester, channel);
  });

  testWidgets('profile A B A remains invalid', (tester) async {
    final channel = await _open(tester);
    await channel.selectProfile('b');
    await channel.selectProfile('a');
    await _assignDenied(tester, channel);
  });

  testWidgets('same owner reconnect remains invalid', (tester) async {
    final channel = await _open(tester);
    final origin = channel.state.connectedBaseUrl!;
    await channel.disconnect();
    await channel.connect(baseUrl: origin);
    await channel.selectProfile('a');
    expect(channel.state.canWriteModels, isTrue);
    await _assignDenied(tester, channel);
  });

  testWidgets('transient revoke during refresh prevents later assignment', (
    tester,
  ) async {
    final channel = await _open(tester);
    final gate = channel.refreshGate = Completer<void>();
    await tester.tap(find.text('Refresh catalog'));
    await tester.pump();
    expect(channel.refreshModelsCalls, 1);
    _revoke(channel);
    _restore(channel);
    gate.complete();
    await tester.pumpAndSettle();
    expect(
      find.text('The model assignment could not be saved.'),
      findsOneWidget,
    );
    await _assignDenied(tester, channel);
  });

  testWidgets(
    'transient revoke during assignment denies late success and retry',
    (tester) async {
      final channel = await _open(tester);
      final gate = channel.assignmentGate = Completer<void>();
      await tester.tap(find.text('Assign'));
      await tester.pump();
      expect(channel.assignModelCalls, hasLength(1));
      _revoke(channel);
      _restore(channel);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ModelPickerSheet), findsOneWidget);
      expect(
        find.text('The model assignment could not be saved.'),
        findsOneWidget,
      );
      // The already-issued mutation cannot be undone; deny another attempt and
      // do not present its stale completion as current-owner success.
      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();
      expect(channel.assignModelCalls, hasLength(1));
    },
  );
}
