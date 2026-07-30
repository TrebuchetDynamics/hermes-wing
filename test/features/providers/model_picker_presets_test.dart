import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/providers/widgets/model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

const _presetsKey = 'flutter.wing.hermes.model_presets.v1';

HermesModelInventory _inventory() => HermesModelInventory(
  catalog: HermesModelCatalog.fromJson({
    'providers': {
      'openai': {
        'models': [
          {'id': 'gpt-5'},
          {'id': 'gpt-5-mini'},
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
    revision: 'rev-1',
  ),
);

Widget _testApp(FakeHermesChannel channel, HermesModelInventory inventory) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ModelPickerSheet(channel: channel, inventory: inventory),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('saving a preset persists the current selection under a name', (
    tester,
  ) async {
    final inventory = _inventory();
    final channel = FakeHermesChannel(
      modelInventory: inventory,
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, inventory));
    await tester.pumpAndSettle();

    // Switch the model away from the default before saving.
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('gpt-5-mini').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('model-preset-save')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('model-preset-name-field')),
      'Fast drafts',
    );
    await tester.tap(find.byKey(const ValueKey('model-preset-save-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('model-preset-Fast drafts')),
      findsOneWidget,
    );
    final stored = (await SharedPreferences.getInstance()).getString(
      'wing.hermes.model_presets.v1',
    );
    expect(jsonDecode(stored!), [
      {
        'name': 'Fast drafts',
        'slot': 'main',
        'provider': 'openai',
        'model': 'gpt-5-mini',
      },
    ]);
  });

  testWidgets('an auxiliary-slot preset selects its task slot on apply', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      _presetsKey: jsonEncode([
        {
          'name': 'Vision combo',
          'slot': 'vision',
          'provider': 'anthropic',
          'model': 'claude-sonnet',
        },
      ]),
    });
    final inventory = _inventory();
    final channel = FakeHermesChannel(
      modelInventory: inventory,
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, inventory));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vision combo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(channel.assignModelCalls.single, {
      'scope': 'auxiliary',
      'task': 'vision',
      'provider': 'anthropic',
      'model': 'claude-sonnet',
      'revision': 'rev-1',
    });
  });

  testWidgets('a preset absent from this catalog is disabled but deletable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      _presetsKey: jsonEncode([
        {
          'name': 'Elsewhere',
          'slot': 'main',
          'provider': 'mistral',
          'model': 'mistral-large',
        },
      ]),
    });
    final inventory = _inventory();
    final channel = FakeHermesChannel(
      modelInventory: inventory,
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, inventory));
    await tester.pumpAndSettle();

    final chip = tester.widget<InputChip>(
      find.byKey(const ValueKey('model-preset-Elsewhere')),
    );
    expect(chip.onPressed, isNull);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('model-preset-Elsewhere')), findsNothing);
    final stored = (await SharedPreferences.getInstance()).getString(
      'wing.hermes.model_presets.v1',
    );
    expect(jsonDecode(stored!), isEmpty);
  });

  testWidgets('tapping a saved preset fills the selection for assignment', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      _presetsKey: jsonEncode([
        {
          'name': 'Fast drafts',
          'slot': 'main',
          'provider': 'anthropic',
          'model': 'claude-sonnet',
        },
      ]),
    });
    final inventory = _inventory();
    final channel = FakeHermesChannel(
      modelInventory: inventory,
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, inventory));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fast drafts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(channel.assignModelCalls.single, {
      'scope': 'main',
      'task': null,
      'provider': 'anthropic',
      'model': 'claude-sonnet',
      'revision': 'rev-1',
    });
  });
}
