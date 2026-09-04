import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/features/providers/widgets/model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

HermesModelInventory _inventory(List<String> modelIds) => HermesModelInventory(
  catalog: HermesModelCatalog.fromJson({
    'providers': {
      'openai': {
        'models': [
          for (final id in modelIds) {'id': id},
        ],
      },
    },
  }),
  assignment: HermesModelAssignment(
    activeProvider: 'openai',
    activeModel: modelIds.first,
    revision: 'rev-1',
  ),
);

/// A [FakeHermesChannel] whose [refreshModels] swaps in a new catalog on
/// `state.modelInventory`, exercising the "refresh updates the open sheet"
/// behavior. The plain fake's `refreshModels` only counts calls and never
/// touches state, which is not enough to prove `ModelPickerSheet` re-derives
/// its local selection from the channel after a refresh.
final class _TestHermesStatusException implements HermesApiStatusException {
  const _TestHermesStatusException(this.statusCode);

  @override
  final int statusCode;
}

class _ConflictingFakeChannel extends FakeHermesChannel {
  _ConflictingFakeChannel({
    required HermesModelInventory initialInventory,
    required this.refreshedInventory,
    this.conflict = const _TestHermesStatusException(412),
  }) : super(modelInventory: initialInventory, selectedProfileId: 'default');

  final HermesModelInventory refreshedInventory;
  final Object conflict;
  var conflictResolved = false;

  @override
  HermesChannelState get state => conflictResolved
      ? super.state.copyWith(modelInventory: refreshedInventory)
      : super.state;

  @override
  Future<void> assignModel({
    required String scope,
    String? task,
    required String provider,
    required String model,
    required String revision,
  }) async {
    assignModelCalls.add({
      'scope': scope,
      'task': task,
      'provider': provider,
      'model': model,
      'revision': revision,
    });
    if (!conflictResolved) {
      conflictResolved = true;
      throw conflict;
    }
  }
}

class _RefreshingFakeChannel extends FakeHermesChannel {
  _RefreshingFakeChannel({
    required HermesModelInventory initialInventory,
    required this.refreshedInventory,
  }) : super(modelInventory: initialInventory, selectedProfileId: 'default');

  final HermesModelInventory refreshedInventory;
  bool _refreshed = false;

  @override
  Future<void> refreshModels() async {
    await super.refreshModels();
    _refreshed = true;
    notifyListeners();
  }

  @override
  HermesChannelState get state => _refreshed
      ? super.state.copyWith(modelInventory: refreshedInventory)
      : super.state;
}

Widget _testApp(FakeHermesChannel channel, HermesModelInventory inventory) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ModelPickerSheet(channel: channel, inventory: inventory),
      ),
    );

void main() {
  testWidgets('revoked capability prevents assignment from an open picker', (
    tester,
  ) async {
    final inventory = _inventory(['synthetic-model']);
    final channel = FakeHermesChannel(modelInventory: inventory);
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel, inventory));
    await tester.pumpAndSettle();
    channel.replaceCapabilitiesAndProfiles(
      HermesCapabilityDocument.fromJson({}),
      [],
    );
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();
    expect(channel.assignModelCalls, isEmpty);
  });

  testWidgets('assignment rejects profile A B A while picker stays open', (
    tester,
  ) async {
    final inventory = _inventory(['synthetic-model']);
    final channel = FakeHermesChannel(
      modelInventory: inventory,
      selectedProfileId: 'a',
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel, inventory));
    await tester.pumpAndSettle();
    await channel.selectProfile('b');
    await channel.selectProfile('a');
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();
    expect(channel.assignModelCalls, isEmpty);
  });

  testWidgets('selecting an auxiliary slot preserves its assigned model', (
    tester,
  ) async {
    final inventory = HermesModelInventory(
      catalog: HermesModelCatalog.fromJson({
        'providers': {
          'openai': {
            'models': [
              {'id': 'gpt-5'},
            ],
          },
          'anthropic': {
            'models': [
              {'id': 'claude-sonnet'},
            ],
          },
        },
      }),
      assignment: const HermesModelAssignment(
        activeProvider: 'openai',
        activeModel: 'gpt-5',
        auxiliary: [
          HermesAuxiliaryModel(
            task: 'title_generation',
            provider: 'anthropic',
            model: 'claude-sonnet',
          ),
          HermesAuxiliaryModel(
            task: 'future_task',
            provider: 'anthropic',
            model: 'claude-sonnet',
          ),
        ],
        revision: 'rev-1',
      ),
    );
    final channel = FakeHermesChannel(
      modelInventory: inventory,
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, inventory));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();
    expect(find.text('future_task'), findsOneWidget);
    await tester.tap(find.text('Title generation').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(channel.assignModelCalls.single, {
      'scope': 'auxiliary',
      'task': 'title_generation',
      'provider': 'anthropic',
      'model': 'claude-sonnet',
      'revision': 'rev-1',
    });
  });

  testWidgets('can assign a previously unconfigured auxiliary task', (
    tester,
  ) async {
    final inventory = _inventory(const ['gpt-5']);
    final channel = FakeHermesChannel(
      modelInventory: inventory,
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, inventory));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();
    expect(find.text('Vision'), findsOneWidget);
    expect(find.text('Title generation'), findsOneWidget);
    await tester.tap(find.text('Title generation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(channel.assignModelCalls.single, {
      'scope': 'auxiliary',
      'task': 'title_generation',
      'provider': 'openai',
      'model': 'gpt-5',
      'revision': 'rev-1',
    });
  });

  testWidgets('shows the selected model description', (tester) async {
    final inventory = HermesModelInventory(
      catalog: HermesModelCatalog.fromJson(const {
        'providers': {
          'openai': {
            'models': [
              {'id': 'gpt-5', 'description': 'Flagship reasoning model'},
            ],
          },
        },
      }),
      assignment: const HermesModelAssignment(
        activeProvider: 'openai',
        activeModel: 'gpt-5',
        revision: 'rev-1',
      ),
    );
    final channel = FakeHermesChannel(
      modelInventory: inventory,
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, inventory));
    await tester.pumpAndSettle();

    expect(find.text('Flagship reasoning model'), findsOneWidget);
  });

  testWidgets('revision conflicts refresh the open sheet before retry', (
    tester,
  ) async {
    final initial = _inventory(const ['gpt-5']);
    final refreshed = HermesModelInventory(
      catalog: initial.catalog,
      assignment: const HermesModelAssignment(
        activeProvider: 'openai',
        activeModel: 'gpt-5',
        revision: 'rev-2',
      ),
    );
    final channel = _ConflictingFakeChannel(
      initialInventory: initial,
      refreshedInventory: refreshed,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, initial));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The model selection changed elsewhere. Reopen the picker to try again.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(channel.assignModelCalls.map((call) => call['revision']), [
      'rev-1',
      'rev-2',
    ]);
  });

  testWidgets('does not infer a conflict from arbitrary 412 text', (
    tester,
  ) async {
    final initial = _inventory(const ['gpt-5']);
    final channel = _ConflictingFakeChannel(
      initialInventory: initial,
      refreshedInventory: initial,
      conflict: StateError('Hermes API returned HTTP 412'),
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, initial));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(
      find.text('The model assignment could not be saved.'),
      findsOneWidget,
    );
    expect(find.textContaining('changed elsewhere'), findsNothing);
  });

  testWidgets('refresh updates the open sheet with the newly fetched catalog', (
    tester,
  ) async {
    final initial = _inventory(const ['gpt-5']);
    final refreshed = _inventory(const ['gpt-5', 'gpt-5.1-new']);
    final channel = _RefreshingFakeChannel(
      initialInventory: initial,
      refreshedInventory: refreshed,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, initial));
    await tester.pumpAndSettle();

    // Not visible before refresh: the sheet only knows the construction
    // snapshot.
    expect(find.text('gpt-5.1-new'), findsNothing);

    await tester.tap(find.text('Refresh catalog'));
    await tester.pumpAndSettle();

    expect(channel.refreshModelsCalls, 1);

    // Open the model dropdown (the second DropdownButtonFormField<String>;
    // the slot picker uses a different generic type) and confirm the freshly
    // fetched model id is selectable without closing/reopening the sheet.
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();

    expect(find.text('gpt-5.1-new'), findsWidgets);
  });
}
