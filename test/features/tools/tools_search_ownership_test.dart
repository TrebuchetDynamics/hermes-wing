import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/tools/screens/tools_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

const _skillsSearch = ValueKey('installed-skills-search');
const _toolsetsSearch = ValueKey('toolsets-search');
const _skillsClear = ValueKey('installed-skills-clear');
const _toolsetsClear = ValueKey('toolsets-clear');

HermesCapabilityDocument _capabilities({bool granted = true}) =>
    HermesCapabilityDocument.fromJson({
      'schema_version': 1,
      'auth': {
        'type': 'bearer',
        'required': true,
        'granted_scopes': granted ? ['skills:read', 'tools:read'] : <String>[],
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

HermesChannelState _inventory({
  String host = 'https://alpha.invalid',
  String profile = 'default',
}) => HermesChannelState(
  status: HermesConnectionStatus.connected,
  connectedBaseUrl: host,
  selectedProfileId: profile,
  capabilities: _capabilities(),
  skillDetails: const [
    HermesSkill(name: 'zulu', description: 'Source review', category: 'code'),
    HermesSkill(name: 'alpha', description: 'Browser session', category: 'web'),
  ],
  toolsets: const [
    HermesToolset(name: 'zulu-set', label: 'Zulu Tools', tools: ['terminal']),
    HermesToolset(
      name: 'alpha-set',
      label: 'Alpha Tools',
      tools: ['web_search'],
    ),
  ],
);

class _Channel extends FakeHermesChannel {
  _Channel() : current = _inventory();
  HermesChannelState current;
  final gates = <Completer<void>>[];
  @override
  HermesChannelState get state => current;

  void emit(HermesChannelState next) {
    current = next;
    notifyListeners();
  }

  @override
  Future<void> loadToolInventory() {
    loadToolInventoryCalls++;
    final gate = Completer<void>();
    gates.add(gate);
    return gate.future;
  }
}

Widget _app(HermesChannel channel, {double scale = 1}) => ProviderScope(
  overrides: [hermesChannelProvider.overrideWithValue(channel)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: child!,
    ),
    home: const SelectionArea(child: ToolsScreen()),
  ),
);

Future<void> _query(WidgetTester tester, Key key, String value) async {
  final field = find.byKey(key);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).controller!.text;

void _expectCleared(WidgetTester tester) {
  expect(_text(tester, _skillsSearch), '');
  expect(_text(tester, _toolsetsSearch), '');
  expect(find.text('alpha'), findsOneWidget);
  expect(find.text('Zulu Tools'), findsOneWidget);
  expect(find.textContaining('private-query'), findsNothing);
}

void main() {
  for (final transition in ['host', 'profile']) {
    for (final fails in [false, true]) {
      testWidgets(
        'actual channel old read $fails after $transition roundtrip is ignored',
        (tester) async {
          final gates = {
            '/v1/skills': Completer<String>(),
            '/v1/toolsets': Completer<String>(),
          };
          final started = <String>[];
          var delayReads = false;
          final channel = HermesApiChannel(
            clientBuilder: (config) => HermesApiClient(
              config: config,
              get: (uri, headers) async {
                if (delayReads && gates.containsKey(uri.path)) {
                  started.add(uri.path);
                  return gates[uri.path]!.future;
                }
                return switch (uri.path) {
                  '/health' => '{"status":"ok"}',
                  '/v1/capabilities' => jsonEncode({
                    'object': 'hermes.api_server.capabilities',
                    'platform': 'test',
                    'model': 'test',
                    'schema_version': 1,
                    'profile_context': {
                      'type': 'query',
                      'name': 'profile',
                      'required': true,
                      'default_profile_id': 'default',
                    },
                    'auth': {
                      'type': 'bearer',
                      'required': true,
                      'granted_scopes': [
                        'skills:read',
                        'tools:read',
                        'profiles:read',
                      ],
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
                      'profiles': {
                        'method': 'GET',
                        'path': '/api/profiles',
                        'required_scopes': ['profiles:read'],
                      },
                    },
                  }),
                  '/api/profiles' =>
                    '{"data":[{"id":"default","name":"Default","is_default":true},{"id":"writer","name":"Writer"}]}',
                  '/api/sessions' => '{"data":[]}',
                  '/v1/skills' =>
                    '{"data":[{"name":"current-skill","description":"current metadata"}]}',
                  '/v1/toolsets' =>
                    '{"data":[{"name":"current-tools","label":"Current Tools","tools":["current_tool"]}]}',
                  _ => throw StateError(
                    'Unexpected deterministic read ${uri.path}',
                  ),
                };
              },
            ),
          );
          addTearDown(channel.dispose);
          await channel.connect(baseUrl: 'http://127.0.0.1:8642');
          expect(channel.state.status, HermesConnectionStatus.connected);
          await tester.pumpWidget(_app(channel));
          await tester.pumpAndSettle();
          await _query(tester, _skillsSearch, 'private-query');
          await _query(tester, _toolsetsSearch, 'private-query');
          delayReads = true;
          await tester.tap(find.byKey(const ValueKey('tools-refresh')));
          await tester.pump();
          expect(started, containsAll(['/v1/skills', '/v1/toolsets']));
          delayReads = false;
          if (transition == 'host') {
            await channel.connect(baseUrl: 'http://127.0.0.1:8643');
          } else {
            await channel.selectProfile('writer');
          }
          await tester.pumpAndSettle();
          expect(_text(tester, _skillsSearch), '');
          expect(_text(tester, _toolsetsSearch), '');
          if (transition == 'host') {
            await channel.connect(baseUrl: 'http://127.0.0.1:8642');
          } else {
            await channel.selectProfile('default');
          }
          await tester.pumpAndSettle();
          await _query(tester, _skillsSearch, 'current');
          await _query(tester, _toolsetsSearch, 'current');
          for (final entry in gates.entries) {
            if (fails) {
              entry.value.completeError(
                StateError('old synthetic transport failure'),
              );
            } else {
              entry.value.complete('{"data":[{"name":"obsolete-inventory"}]}');
            }
          }
          await tester.pumpAndSettle();
          expect(channel.state.skillDetails.single.name, 'current-skill');
          expect(channel.state.toolsets.single.name, 'current-tools');
          expect(channel.state.optionalResourceErrors, isEmpty);
          expect(_text(tester, _skillsSearch), 'current');
          expect(_text(tester, _toolsetsSearch), 'current');
          expect(find.textContaining('obsolete'), findsNothing);
          expect(
            find.text('Tool inventory could not be refreshed.'),
            findsNothing,
          );
        },
      );
    }
  }

  for (final transition in ['host roundtrip', 'profile roundtrip']) {
    testWidgets('direct connected $transition discards both private queries', (
      tester,
    ) async {
      final channel = _Channel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(channel));
      await tester.pumpAndSettle();
      await _query(tester, _skillsSearch, 'private-query-skills');
      await _query(tester, _toolsetsSearch, 'private-query-toolsets');
      channel.emit(
        transition == 'host roundtrip'
            ? _inventory(host: 'https://beta.invalid')
            : _inventory(profile: 'writer'),
      );
      await tester.pumpAndSettle();
      _expectCleared(tester);
      await _query(tester, _skillsSearch, 'private-query-beta');
      await _query(tester, _toolsetsSearch, 'private-query-beta');
      channel.emit(_inventory());
      await tester.pumpAndSettle();
      _expectCleared(tester);
      expect(channel.loadToolInventoryCalls, 0);
    });
  }

  testWidgets(
    'distinct channel with identical host/profile IDs resets search',
    (tester) async {
      final alpha = _Channel();
      final beta = _Channel();
      // Even the same capability object does not identify the owning client.
      beta.current = alpha.current;
      addTearDown(alpha.dispose);
      addTearDown(beta.dispose);
      await tester.pumpWidget(_app(alpha));
      await tester.pumpAndSettle();
      await _query(tester, _skillsSearch, 'private-query-alpha');
      await _query(tester, _toolsetsSearch, 'private-query-alpha');
      await tester.pumpWidget(_app(beta));
      await tester.pumpAndSettle();
      _expectCleared(tester);
    },
  );

  testWidgets(
    'late refresh from replaced client cannot affect current feedback',
    (tester) async {
      final alpha = _Channel();
      final beta = _Channel();
      beta.current = alpha.current;
      addTearDown(alpha.dispose);
      addTearDown(beta.dispose);
      await tester.pumpWidget(_app(alpha));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tools-refresh')));
      await tester.pump();
      await tester.pumpWidget(_app(beta));
      await tester.pumpAndSettle();
      final refresh = find.byKey(const ValueKey('tools-refresh'));
      expect(tester.widget<IconButton>(refresh).onPressed, isNotNull);
      await tester.tap(refresh);
      await tester.pump();
      alpha.gates.single.completeError(
        StateError('old synthetic client failure'),
      );
      await tester.pump();
      expect(find.text('Tool inventory could not be refreshed.'), findsNothing);
      expect(tester.widget<IconButton>(refresh).onPressed, isNull);
      beta.gates.single.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('losing one inventory grant resets only that section', (
    tester,
  ) async {
    final channel = _Channel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_app(channel));
    await tester.pumpAndSettle();
    await _query(tester, _skillsSearch, 'source');
    await _query(tester, _toolsetsSearch, 'terminal');
    final granted = channel.state;
    channel.emit(
      granted.copyWith(
        capabilities: HermesCapabilityDocument.fromJson({
          'schema_version': 1,
          'auth': {
            'type': 'bearer',
            'required': true,
            'granted_scopes': ['tools:read'],
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
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_skillsSearch), findsNothing);
    expect(_text(tester, _toolsetsSearch), 'terminal');
    channel.emit(granted);
    await tester.pumpAndSettle();
    expect(_text(tester, _skillsSearch), '');
    expect(_text(tester, _toolsetsSearch), 'terminal');
  });

  testWidgets(
    'empty and name-only inventories remain distinct from no matches',
    (tester) async {
      final channel = _Channel();
      addTearDown(channel.dispose);
      channel.current = channel.current.copyWith(
        skillDetails: [],
        toolsets: [],
      );
      await tester.pumpWidget(_app(channel));
      await tester.pumpAndSettle();
      expect(find.text('No installed skills were reported.'), findsOneWidget);
      expect(find.text('No toolsets were reported.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      channel.emit(
        channel.current.copyWith(
          skills: ['zulu', 'alpha'],
          enabledToolsets: ['web', 'default'],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      final chips = tester.widgetList<Chip>(find.byType(Chip));
      expect(chips.map((chip) => (chip.label as Text).data), [
        'alpha',
        'zulu',
        'default',
        'web',
      ]);
      expect(find.textContaining('resolved tools'), findsNothing);
    },
  );

  for (final loss in ['grant', 'operation', 'disconnected', 'error']) {
    testWidgets('$loss loss hides controls; return does not restore search', (
      tester,
    ) async {
      final channel = _Channel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(channel));
      await tester.pumpAndSettle();
      await _query(tester, _skillsSearch, 'private-query');
      await _query(tester, _toolsetsSearch, 'private-query');
      final original = channel.state;
      channel.emit(switch (loss) {
        'grant' => original.copyWith(
          capabilities: _capabilities(granted: false),
        ),
        'operation' => original.copyWith(
          capabilities: HermesCapabilityDocument.fromJson({
            'schema_version': 1,
            'auth': {'type': 'bearer', 'required': true},
            'endpoints': <String, Object>{},
          }),
        ),
        'error' => original.copyWith(status: HermesConnectionStatus.error),
        _ => original.copyWith(status: HermesConnectionStatus.disconnected),
      });
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(_skillsClear), findsNothing);
      expect(find.byKey(_toolsetsClear), findsNothing);
      expect(find.text('alpha'), findsNothing);
      expect(find.text('Zulu Tools'), findsNothing);
      channel.emit(original);
      await tester.pumpAndSettle();
      _expectCleared(tester);
    });
  }

  testWidgets(
    'same-owner updates and refresh errors retain independent queries',
    (tester) async {
      final channel = _Channel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(channel));
      await tester.pumpAndSettle();
      await _query(tester, _skillsSearch, 'sOuRcE');
      await _query(tester, _toolsetsSearch, 'TERMINAL');
      channel.emit(
        channel.state.copyWith(
          capabilities: _capabilities(),
          skillDetails: const [
            HermesSkill(name: 'fresh', description: 'Source review'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(_text(tester, _skillsSearch), 'sOuRcE');
      expect(_text(tester, _toolsetsSearch), 'TERMINAL');
      expect(find.text('fresh'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tools-refresh')));
      await tester.pump();
      channel.gates.single.completeError(
        StateError('bounded synthetic failure'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Tool inventory could not be refreshed.'),
        findsOneWidget,
      );
      expect(_text(tester, _skillsSearch), 'sOuRcE');
      expect(_text(tester, _toolsetsSearch), 'TERMINAL');
      channel.emit(
        channel.state.copyWith(
          optionalResourceErrors: {
            HermesOptionalResource.skills: 'synthetic',
            HermesOptionalResource.toolsets: 'synthetic',
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('No installed skills match this search.'), findsNothing);
      expect(
        find.text('Installed skills could not be loaded from Hermes.'),
        findsOneWidget,
      );
      expect(
        find.text('Enabled toolsets could not be loaded from Hermes.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('late old refresh cannot affect a new owner query or feedback', (
    tester,
  ) async {
    final channel = _Channel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_app(channel));
    await tester.pumpAndSettle();
    await _query(tester, _skillsSearch, 'private-query');
    await _query(tester, _toolsetsSearch, 'private-query');
    await tester.tap(find.byKey(const ValueKey('tools-refresh')));
    await tester.pump();
    channel.emit(_inventory(host: 'https://beta.invalid'));
    await tester.pumpAndSettle();
    _expectCleared(tester);
    await _query(tester, _skillsSearch, 'browser');
    await _query(tester, _toolsetsSearch, 'web_search');
    await tester.tap(find.byKey(const ValueKey('tools-refresh')));
    await tester.pump();
    channel.gates.first.completeError(StateError('old synthetic failure'));
    await tester.pump();
    expect(find.text('Tool inventory could not be refreshed.'), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('tools-refresh')))
          .onPressed,
      isNull,
    );
    expect(_text(tester, _skillsSearch), 'browser');
    expect(_text(tester, _toolsetsSearch), 'web_search');
    channel.gates.last.complete();
    await tester.pumpAndSettle();
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'independent keyboard clear, semantics and disclosure at $width px / 200%',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final channel = _Channel();
        addTearDown(channel.dispose);
        await tester.pumpWidget(_app(channel, scale: 2));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('Search installed skills'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Search toolsets and resolved tools'),
          findsOneWidget,
        );
        expect(find.byKey(_skillsClear), findsNothing);
        expect(find.byKey(_toolsetsClear), findsNothing);
        await _query(tester, _skillsSearch, '.*');
        expect(
          find.bySemanticsLabel('Search installed skills'),
          findsOneWidget,
        );
        await _query(tester, _toolsetsSearch, 'terminal');
        expect(
          tester.getSemantics(find.bySemanticsLabel(RegExp('^Zulu Tools'))),
          isSemantics(isFocusable: true, hasTapAction: true),
        );
        expect(
          find.text('No installed skills match this search.'),
          findsOneWidget,
        );
        expect(find.text('Zulu Tools'), findsOneWidget);
        expect(find.text('Alpha Tools'), findsNothing);
        for (final entry in [
          (_skillsSearch, _skillsClear, 'Clear installed skills search'),
          (_toolsetsSearch, _toolsetsClear, 'Clear toolsets search'),
        ]) {
          await tester.ensureVisible(find.byKey(entry.$1));
          await tester.tap(find.byKey(entry.$1));
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(
            tester.getSemantics(find.byKey(entry.$2)),
            matchesSemantics(
              tooltip: entry.$3,
              isButton: true,
              isFocusable: true,
              isFocused: true,
              hasEnabledState: true,
              isEnabled: true,
              hasTapAction: true,
              hasFocusAction: true,
            ),
          );
          expect(find.byTooltip(entry.$3), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(_text(tester, entry.$1), '');
          if (entry.$1 == _skillsSearch) {
            expect(_text(tester, _toolsetsSearch), 'terminal');
            expect(find.text('alpha'), findsOneWidget);
            final tiles = tester
                .widgetList<ListTile>(find.byType(ListTile))
                .toList();
            expect((tiles.first.title! as Text).data, 'alpha');
          }
        }
        await tester.ensureVisible(find.text('Alpha Tools'));
        Focus.of(tester.element(find.text('Alpha Tools'))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(Chip, 'web_search'), findsOneWidget);
        expect(channel.loadToolInventoryCalls, 0);
        expect(channel.sentVoiceTranscripts, isEmpty);
        semantics.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
