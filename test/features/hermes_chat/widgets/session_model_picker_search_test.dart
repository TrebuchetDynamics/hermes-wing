import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_model_options.dart';
import 'package:wing/features/hermes_chat/widgets/session_model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

HermesModelOptions catalog({
  String currentProvider = 'beta',
  String currentModel = 'shared',
}) => HermesModelOptions(
  currentProvider: currentProvider,
  currentModel: currentModel,
  providers: [
    for (final slug in ['alpha', 'beta', 'gamma'])
      HermesModelOptionProvider(
        slug: slug,
        label: 'Display $slug',
        authenticated: true,
        models: ['shared', for (var i = 0; i < 100; i++) '$slug/model-$i'],
      ),
    const HermesModelOptionProvider(
      slug: 'unconfigured',
      label: 'Forbidden',
      models: ['shared', 'hidden'],
    ),
  ],
);

Widget app(
  HermesModelOptions options,
  Future<void> Function(String, String) lock, {
  double scale = 1,
  double inset = 0,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      viewInsets: EdgeInsets.only(bottom: inset),
      disableAnimations: true,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          builder: (_) =>
              SessionModelPickerSheet(options: options, onLock: lock),
        ),
        child: const Text('Open picker'),
      ),
    ),
  ),
);

Future<void> open(
  WidgetTester tester,
  HermesModelOptions options,
  Future<void> Function(String, String) lock, {
  double scale = 1,
  double inset = 0,
}) async {
  await tester.pumpWidget(app(options, lock, scale: scale, inset: inset));
  await tester.tap(find.text('Open picker'));
  await tester.pumpAndSettle();
}

final search = find.byKey(const ValueKey('session-model-search'));
Finder row(String provider, String model) =>
    find.byKey(ValueKey('session-model-$provider/$model'));
Future<void> confirm(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Use for session'));
  await tester.tap(find.text('Use for session'));
  await tester.pumpAndSettle();
}

Future<void> filter(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    '303 selectable rows, current first, case-insensitive ID and provider search',
    (tester) async {
      final calls = <String>[];
      await open(tester, catalog(), (p, m) async => calls.add('$p/$m'));
      expect(find.text('303 matching models'), findsOneWidget);
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(tiles.first.key, const ValueKey('session-model-beta/shared'));
      expect(tiles.length, lessThan(20));
      await tester.enterText(search, 'ALPHA/MODEL-99');
      await tester.pumpAndSettle();
      expect(row('alpha', 'alpha/model-99'), findsOneWidget);
      expect(find.text('1 matching model'), findsOneWidget);
      expect(
        find.text('Selected: Display beta (beta) — shared'),
        findsOneWidget,
      );
      await tester.enterText(search, 'DISPLAY GAMMA');
      await tester.pumpAndSettle();
      expect(find.text('101 matching models'), findsOneWidget);
      await tester.enterText(search, 'BeTa');
      await tester.pumpAndSettle();
      expect(find.text('101 matching models'), findsOneWidget);
      expect(calls, isEmpty);
    },
  );

  testWidgets(
    'combined provider filter, no results, clear and reset never change draft',
    (tester) async {
      final calls = <String>[];
      await open(tester, catalog(), (p, m) async => calls.add('$p/$m'));
      await filter(tester, 'Display alpha');
      await tester.enterText(search, 'gamma');
      await tester.pumpAndSettle();
      expect(find.text('No matching models'), findsOneWidget);
      expect(
        find.textContaining('No matching selectable models.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Clear model search'));
      await tester.pumpAndSettle();
      expect(find.text('101 matching models'), findsOneWidget);
      await tester.tap(find.text('Reset filters'));
      await tester.pumpAndSettle();
      expect(find.text('303 matching models'), findsOneWidget);
      await confirm(tester);
      expect(calls, ['beta/shared']);
      expect(find.text('Use a model for this session'), findsNothing);
    },
  );

  testWidgets(
    'duplicate IDs distinguished by provider, hidden providers cannot be searched or selected',
    (tester) async {
      final calls = <String>[];
      await open(tester, catalog(), (p, m) async => calls.add('$p/$m'));
      await tester.enterText(search, 'shared');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('Display alpha (alpha)'), findsOneWidget);
      await tester.tap(row('gamma', 'shared'));
      await tester.pump();
      await tester.enterText(search, 'Forbidden');
      await tester.pumpAndSettle();
      expect(find.text('No matching models'), findsOneWidget);
      await confirm(tester);
      expect(calls, ['gamma/shared']);
    },
  );

  testWidgets(
    'pending double submission, selection, cancel and Escape are blocked; failure preserves query and retry',
    (tester) async {
      var pending = Completer<void>();
      final calls = <String>[];
      await open(tester, catalog(), (p, m) {
        calls.add('$p/$m');
        return pending.future;
      });
      await filter(tester, 'Display alpha');
      await tester.enterText(search, 'MODEL-99');
      await tester.pumpAndSettle();
      await tester.tap(row('alpha', 'alpha/model-99'));
      await tester.pump();
      await tester.ensureVisible(find.text('Use for session'));
      await tester.tap(find.text('Use for session'));
      await tester.tap(find.text('Use for session'));
      await tester.pump();
      expect(calls, ['alpha/alpha/model-99']);
      expect(tester.widget<TextField>(search).enabled, isFalse);
      expect(
        tester.widget<ListTile>(row('alpha', 'alpha/model-99')).enabled,
        isFalse,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Use a model for this session'), findsOneWidget);
      pending.completeError(StateError('sensitive upstream details'));
      await tester.pumpAndSettle();
      expect(
        find.text('Hermes could not confirm this session model.'),
        findsOneWidget,
      );
      expect(find.textContaining('sensitive upstream'), findsNothing);
      expect(tester.widget<TextField>(search).controller!.text, 'MODEL-99');
      expect(find.text('Display alpha'), findsOneWidget);
      pending = Completer<void>();
      await tester.ensureVisible(find.text('Use for session'));
      await tester.tap(find.text('Use for session'));
      await tester.pump();
      pending.complete();
      await tester.pumpAndSettle();
      expect(calls, ['alpha/alpha/model-99', 'alpha/alpha/model-99']);
      expect(find.text('Use a model for this session'), findsNothing);
    },
  );

  testWidgets(
    'desktop search focus, Tab selection and Escape cancel without mutation',
    (tester) async {
      final calls = <String>[];
      await open(tester, catalog(), (p, m) async => calls.add('$p/$m'));
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.enterText(search, 'shared');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Use a model for this session'), findsNothing);
      expect(calls, isEmpty);
    },
  );

  testWidgets(
    '390px with keyboard inset, 200 percent text, selected semantics and reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await open(tester, catalog(), (p, m) async {}, scale: 2, inset: 300);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
      await tester.ensureVisible(search);
      await tester.enterText(search, 'shared');
      await tester.pumpAndSettle();
      await tester.ensureVisible(row('beta', 'shared'));
      expect(
        tester
            .getSemantics(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics && widget.properties.selected == true,
              ),
            )
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      await tester.ensureVisible(find.text('Use for session'));
      expect(
        tester.getRect(find.text('Use for session')).bottom,
        lessThanOrEqualTo(544),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'fallback, empty catalog and stale inventory do not silently change identity',
    (tester) async {
      final options = ValueNotifier(
        catalog(currentProvider: 'absent', currentModel: 'absent'),
      );
      addTearDown(options.dispose);
      final calls = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ValueListenableBuilder<HermesModelOptions>(
              valueListenable: options,
              builder: (_, value, _) => SessionModelPickerSheet(
                options: value,
                onLock: (p, m) async => calls.add('$p/$m'),
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('Selected: Display alpha (alpha) — shared'),
        findsOneWidget,
      );
      options.value = HermesModelOptions(providers: [catalog().providers[1]]);
      await tester.pumpAndSettle();
      expect(find.textContaining('no longer available'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      options.value = const HermesModelOptions(providers: []);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No selectable session models are available from Hermes Agent.',
        ),
        findsOneWidget,
      );
      expect(calls, isEmpty);
    },
  );

  testWidgets('keyboard traversal selects and confirms a raw model identity', (
    tester,
  ) async {
    final calls = <String>[];
    await open(tester, catalog(), (p, m) async => calls.add('$p/$m'));
    await tester.enterText(search, 'alpha/model-99');
    await tester.pumpAndSettle();
    bool rowFocused() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ListTile>()
            ?.key ==
        const ValueKey('session-model-alpha/alpha/model-99');
    for (var i = 0; i < 12 && !rowFocused(); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(rowFocused(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      find.text('Selected: Display alpha (alpha) — alpha/model-99'),
      findsOneWidget,
    );
    bool confirmationFocused() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<FilledButton>() !=
        null;
    for (var i = 0; i < 8 && !confirmationFocused(); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(confirmationFocused(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, ['alpha/alpha/model-99']);
  });

  testWidgets(
    'inventory replacement during pending completion cannot close as saved',
    (tester) async {
      final options = ValueNotifier(catalog());
      final pending = Completer<void>();
      addTearDown(options.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ValueListenableBuilder<HermesModelOptions>(
              valueListenable: options,
              builder: (_, value, _) => SessionModelPickerSheet(
                options: value,
                onLock: (_, _) => pending.future,
              ),
            ),
          ),
        ),
      );
      await confirm(tester);
      options.value = catalog();
      await tester.pump();
      pending.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('Hermes could not confirm this session model.'),
        findsOneWidget,
      );
      expect(find.text('Use a model for this session'), findsOneWidget);
    },
  );

  testWidgets('disposal during confirmation is safe and cannot claim success', (
    tester,
  ) async {
    final pending = Completer<void>();
    await open(tester, catalog(), (p, m) => pending.future);
    await confirm(tester);
    await tester.pumpWidget(const SizedBox());
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
