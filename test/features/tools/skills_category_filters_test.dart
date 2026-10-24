import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_skill.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/tools/screens/tools_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import '../hermes_chat/support/fake_hermes_channel.dart';

HermesCapabilityDocument capabilities({bool granted = true}) =>
    HermesCapabilityDocument.fromJson({
      'schema_version': 1,
      'auth': {
        'type': 'bearer',
        'required': true,
        'granted_scopes': [if (granted) 'skills:read', 'tools:read'],
      },
      'endpoints': {
        'skills': {
          'method': 'GET',
          'path': '/v1/skills',
          'required_scopes': ['skills:read'],
        },
        'toolsets': {
          'method': 'GET',
          'path': '/v1/toolsets',
          'required_scopes': ['tools:read'],
        },
      },
    });
const skills = [
  HermesSkill(name: 'review', description: 'Review changes', category: 'code'),
  HermesSkill(name: 'browse', description: 'Review websites', category: 'web'),
  HermesSkill(
    name: 'write',
    description: 'Write documents',
    category: 'writing',
  ),
];

class Channel extends FakeHermesChannel {
  Channel() : super(capabilities: capabilities(), skillDetails: skills);
  HermesChannelState? current;
  @override
  HermesChannelState get state => current ?? super.state;
  void emit(HermesChannelState value) {
    current = value;
    notifyListeners();
  }
}

Widget app(Channel channel, {double scale = 1}) => ProviderScope(
  overrides: [hermesChannelProvider.overrideWithValue(channel)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const ToolsScreen(),
  ),
);
Finder category(String name) =>
    find.byKey(ValueKey('installed-skills-category-$name'));
final search = find.byKey(const ValueKey('installed-skills-search'));
Future<void> choose(WidgetTester tester, String name) async {
  await tester.ensureVisible(category(name));
  await tester.tap(category(name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'category facets OR together and combine with literal search without calls',
    (tester) async {
      final channel = Channel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(app(channel));
      await tester.pumpAndSettle();
      await choose(tester, 'code');
      expect(find.text('review'), findsOneWidget);
      expect(find.text('browse'), findsNothing);
      await choose(tester, 'web');
      expect(find.text('review'), findsOneWidget);
      expect(find.text('browse'), findsOneWidget);
      expect(find.text('write'), findsNothing);
      await tester.enterText(search, 'websites');
      await tester.pumpAndSettle();
      expect(find.text('review'), findsNothing);
      expect(find.text('browse'), findsOneWidget);
      await tester.enterText(search, '[');
      await tester.pumpAndSettle();
      expect(
        find.text('No installed skills match this search.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('installed-skills-clear')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(category('code')).selected, isTrue);
      expect(find.text('write'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('installed-skills-all-categories')),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(category('code')).selected, isFalse);
      expect(find.text('write'), findsOneWidget);
      expect(channel.loadToolInventoryCalls, 0);
      expect(channel.connectCalls, isEmpty);
      expect(channel.createSessionCalls, isEmpty);
    },
  );
  testWidgets('All categories preserves the literal text query', (
    tester,
  ) async {
    final channel = Channel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(app(channel));
    await tester.pumpAndSettle();
    await tester.enterText(search, 'Review');
    await tester.pumpAndSettle();
    await choose(tester, 'code');
    expect(find.text('browse'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('installed-skills-all-categories')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, 'Review');
    expect(find.text('review'), findsOneWidget);
    expect(find.text('browse'), findsOneWidget);
    expect(find.text('write'), findsNothing);
    expect(channel.loadToolInventoryCalls, 0);
  });
  testWidgets(
    'category selection survives tab visits and inventory replacement with recovery for a removed category',
    (tester) async {
      final channel = Channel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(app(channel));
      await tester.pumpAndSettle();
      await choose(tester, 'code');
      await tester.tap(find.byKey(const ValueKey('tools-tab-toolsets')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tools-tab-skills')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(category('code')).selected, isTrue);
      channel.emit(channel.state.copyWith(skillDetails: [skills.last]));
      await tester.pumpAndSettle();
      expect(category('code'), findsOneWidget);
      expect(find.text('write'), findsNothing);
      await choose(tester, 'code');
      expect(find.text('write'), findsOneWidget);
    },
  );
  testWidgets(
    'stale category and All callbacks reject a replaced owner and disposal',
    (tester) async {
      final channel = Channel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(app(channel));
      await tester.pumpAndSettle();
      final toggle = tester.widget<FilterChip>(category('code')).onSelected!;
      final clear = tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('installed-skills-all-categories')),
          )
          .onSelected!;
      channel.emit(channel.state.copyWith(selectedProfileId: 'other'));
      toggle(true);
      clear(true);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(category('code')).selected, isFalse);
      toggle(true);
      clear(true);
      await tester.pumpWidget(const SizedBox.shrink());
      toggle(true);
      clear(true);
      expect(tester.takeException(), isNull);
      expect(channel.loadToolInventoryCalls, 0);
    },
  );
  for (final change in ['profile', 'grant']) {
    testWidgets('category owner resets after same-frame $change roundtrip', (
      tester,
    ) async {
      final channel = Channel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(app(channel));
      await tester.pumpAndSettle();
      await choose(tester, 'code');
      final previous = channel.state;
      channel.emit(
        change == 'profile'
            ? previous.copyWith(selectedProfileId: 'other')
            : previous.copyWith(capabilities: capabilities(granted: false)),
      );
      channel.emit(previous);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(category('code')).selected, isFalse);
      expect(find.text('write'), findsOneWidget);
    });
  }
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'category chips are keyboard operable at $width and 200 percent',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = Channel();
        addTearDown(channel.dispose);
        await tester.pumpWidget(app(channel, scale: 2));
        await tester.pumpAndSettle();
        await tester.ensureVisible(category('code'));
        for (var i = 0; i < 30; i++) {
          var focused = false;
          final c = FocusManager.instance.primaryFocus?.context;
          c?.visitAncestorElements((e) {
            if (e.widget.key ==
                const ValueKey('installed-skills-category-code')) {
              focused = true;
            }
            return !focused;
          });
          if (focused) break;
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(tester.widget<FilterChip>(category('code')).selected, isTrue);
        expect(find.text('browse'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
