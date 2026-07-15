import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/channel/hermes_channel.dart';
import 'package:navivox/features/providers/widgets/model_picker_sheet.dart';
import 'package:navivox/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

HermesModelInventory _inventory(List<String> modelIds) => HermesModelInventory(
  catalog: HermesModelCatalog.fromJson({
    'providers': {
      'openai': {
        'models': [for (final id in modelIds) {'id': id}],
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
  testWidgets(
    'refresh updates the open sheet with the newly fetched catalog',
    (tester) async {
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
      // there is no auxiliary slot, so no slot dropdown precedes it) and
      // confirm the freshly-fetched model id is now selectable without
      // closing/reopening the sheet.
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();

      expect(find.text('gpt-5.1-new'), findsWidgets);
    },
  );
}
