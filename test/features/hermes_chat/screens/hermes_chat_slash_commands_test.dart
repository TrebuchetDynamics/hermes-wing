import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_health.dart';
import 'package:wing/core/hermes/models/hermes_model_assignment.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/models/hermes_run.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/routes/app_routes.dart';

import '../support/fake_hermes_channel.dart';

Widget _testApp(FakeHermesChannel channel, {double textScale = 1}) =>
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const HermesChatScreen(),
      ),
    );

Widget _routerTestApp(FakeHermesChannel channel) {
  final router = GoRouter(
    initialLocation: AppRoutes.hermes,
    routes: [
      GoRoute(
        path: AppRoutes.hermes,
        builder: (_, _) => const HermesChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.office,
        builder: (_, _) => const Scaffold(body: Text('Office destination')),
      ),
      GoRoute(
        path: AppRoutes.tools,
        builder: (_, _) => const Scaffold(body: Text('Tools destination')),
      ),
      GoRoute(
        path: AppRoutes.gateway,
        builder: (_, _) => const Scaffold(body: Text('Gateway destination')),
      ),
      GoRoute(
        path: AppRoutes.agents,
        builder: (_, _) => const Scaffold(body: Text('Profiles destination')),
      ),
      GoRoute(
        path: AppRoutes.providers,
        builder: (_, _) => const Scaffold(body: Text('Providers destination')),
      ),
      GoRoute(
        path: AppRoutes.schedules,
        builder: (_, _) => const Scaffold(body: Text('Schedules destination')),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const Scaffold(body: Text('Settings destination')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [hermesChannelProvider.overrideWithValue(channel)],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('composer model chip opens the profile model picker', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: HermesCapabilityDocument.fromJson(const {
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
          'granted_scopes': ['models:read', 'models:write'],
        },
        'endpoints': {
          'models': {
            'method': 'GET',
            'path': '/api/models',
            'required_scopes': ['models:read'],
          },
          'models_assignment': {
            'method': 'PUT',
            'path': '/api/models/assignment',
            'required_scopes': ['models:write'],
          },
        },
      }),
      modelInventory: HermesModelInventory(
        catalog: HermesModelCatalog.fromJson(const {
          'providers': {
            'openai': {
              'models': [
                {'id': 'gpt-5', 'description': 'Flagship'},
              ],
            },
          },
        }),
        assignment: const HermesModelAssignment(
          activeProvider: 'openai',
          activeModel: 'gpt-5',
          revision: 'models-rev-1',
        ),
      ),
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-composer-model-chip')));
    await tester.pumpAndSettle();

    expect(find.text('Select model'), findsOneWidget);
    expect(find.text('gpt-5'), findsWidgets);
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(channel.assignModelCalls.single, {
      'scope': 'main',
      'task': null,
      'provider': 'openai',
      'model': 'gpt-5',
      'revision': 'models-rev-1',
    });
  });

  testWidgets(
    'composer model chip stays disabled without model assignment capability',
    (tester) async {
      final channel = FakeHermesChannel(
        models: const ['gpt-5'],
        capabilities: HermesCapabilityDocument.fromJson(const {
          'schema_version': 1,
          'model': 'hermes-agent',
        }),
      );
      addTearDown(channel.dispose);
      await tester.pumpWidget(_testApp(channel));
      await tester.pumpAndSettle();

      final chip = tester.widget<ActionChip>(
        find.byKey(const ValueKey('hermes-composer-model-chip')),
      );
      expect(chip.onPressed, isNull);
      expect((chip.label as Text).data, 'Hermes model');
      expect(find.text('Select model'), findsNothing);
      expect(channel.assignModelCalls, isEmpty);
    },
  );

  testWidgets(
    'desktop keyboard wraps, selects, and executes a slash suggestion without sending',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final semantics = tester.ensureSemantics();
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(_routerTestApp(channel));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        '/set',
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      final selected = tester.getSemantics(
        find.byKey(const ValueKey('hermes-local-command-tools')),
      );
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Tools destination'), findsOneWidget);
      expect(
        channel.state.activeMessages.where((turn) => turn.text == '/set'),
        isEmpty,
      );
      semantics.dispose();
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('desktop keyboard keeps the selected slash command visible', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/',
    );
    await tester.pump();
    final suggestions = find.byKey(
      const ValueKey('hermes-local-command-suggestions'),
    );
    final verticalScrollable = find.descendant(
      of: suggestions,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    expect(verticalScrollable, findsOneWidget);
    final position = tester.state<ScrollableState>(verticalScrollable).position;
    expect(position.pixels, 0);

    for (var index = 0; index < 8; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }

    expect(position.pixels, greaterThan(0));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop keyboard reveals a slash selection that wraps upward', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/',
    );
    await tester.pump();
    final verticalScrollable = find.descendant(
      of: find.byKey(const ValueKey('hermes-local-command-suggestions')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    final position = tester.state<ScrollableState>(verticalScrollable).position;

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(position.pixels, greaterThan(0));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Tab executes the selected desktop slash suggestion', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/sett',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('hermes-local-command-settings')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(find.text('Settings destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/sett'),
      isEmpty,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop slash suggestions advertise keyboard controls', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/s',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-keyboard-hints')),
      findsOneWidget,
    );
    expect(
      find.text('↑↓ navigate  •  Enter select  •  Tab complete'),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('slash suggestions match a command-name substring', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/ett',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-settings')),
      findsOneWidget,
    );
    expect(channel.state.activeMessages, isEmpty);
  });

  testWidgets('slash suggestions search descriptions after name prefixes', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/set',
    );
    await tester.pump();

    final settings = find.byKey(
      const ValueKey('hermes-local-command-settings'),
    );
    final tools = find.byKey(const ValueKey('hermes-local-command-tools'));
    expect(settings, findsOneWidget);
    expect(tools, findsOneWidget);
    expect(
      tester.getTopLeft(settings).dy,
      lessThan(tester.getTopLeft(tools).dy),
    );
  });

  testWidgets('desktop Enter sends the composer draft', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final composer = find.byKey(const ValueKey('hermes-composer-field'));
    await tester.enterText(composer, 'send from keyboard');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      channel.state.activeMessages.where(
        (turn) => turn.text == 'send from keyboard',
      ),
      hasLength(1),
    );
    expect(tester.widget<TextField>(composer).controller?.text, isEmpty);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop Shift+Enter keeps a multiline draft', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final composer = find.byKey(const ValueKey('hermes-composer-field'));
    await tester.enterText(composer, 'first line');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(channel.state.activeMessages, isEmpty);
    expect(tester.widget<TextField>(composer).controller?.text, 'first line\n');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop Enter waits for IME composition to finish', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final composer = find.byKey(const ValueKey('hermes-composer-field'));
    final controller = tester.widget<TextField>(composer).controller!;
    controller.value = const TextEditingValue(
      text: 'に',
      selection: TextSelection.collapsed(offset: 1),
      composing: TextRange(start: 0, end: 1),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(channel.state.activeMessages, isEmpty);
    expect(controller.text, 'に');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('soft keyboard submit waits for IME composition to finish', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final composer = find.byKey(const ValueKey('hermes-composer-field'));
    await tester.tap(composer);
    await tester.pump();
    final controller = tester.widget<TextField>(composer).controller!;
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '안녕하세',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange(start: 0, end: 4),
      ),
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(channel.state.activeMessages, isEmpty);
    expect(controller.text, '안녕하세');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('soft keyboard submits full text after composition ends', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final composer = find.byKey(const ValueKey('hermes-composer-field'));
    await tester.tap(composer);
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '안녕하세',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange(start: 0, end: 4),
      ),
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.tap(composer);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '안녕하세요',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      channel.state.activeMessages.where((turn) => turn.text == '안녕하세요'),
      hasLength(1),
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('composer enables an available native spellchecker by default', (
    tester,
  ) async {
    tester.platformDispatcher.nativeSpellCheckServiceDefinedTestValue = true;
    addTearDown(tester.platformDispatcher.clearNativeSpellCheckServiceDefined);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(composer.spellCheckConfiguration?.spellCheckEnabled, isTrue);
  });

  testWidgets('stored preference disables composer spellcheck', (tester) async {
    SharedPreferences.setMockInitialValues({
      'wing.chat.spellcheck_enabled': false,
    });
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(
      composer.spellCheckConfiguration,
      const SpellCheckConfiguration.disabled(),
    );
  });

  testWidgets('desktop prompt history restores the unfinished draft', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final composer = find.byKey(const ValueKey('hermes-composer-field'));
    await tester.enterText(composer, 'first prompt');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();
    await tester.enterText(composer, 'unfinished draft');
    expect(
      tester.widget<TextField>(composer).controller?.text,
      'unfinished draft',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(tester.widget<TextField>(composer).controller?.text, 'first prompt');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      tester.widget<TextField>(composer).controller?.text,
      'unfinished draft',
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Escape dismisses slash suggestions without clearing the draft', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/s',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('hermes-local-command-suggestions')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-suggestions')),
      findsNothing,
    );
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(field.controller?.text, '/s');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Escape dismisses slash suggestions after composer focus moves', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/s',
    );
    await tester.pump();
    composer.focusNode!.unfocus();
    await tester.pump();
    expect(composer.focusNode!.hasFocus, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-suggestions')),
      findsNothing,
    );
    expect(composer.controller?.text, '/s');
    expect(composer.focusNode!.hasFocus, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Escape closes a dialog before slash suggestions', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final composerFinder = find.byKey(const ValueKey('hermes-composer-field'));
    final composer = tester.widget<TextField>(composerFinder);
    await tester.enterText(composerFinder, '/s');
    await tester.pump();
    composer.focusNode!.unfocus();
    await tester.pump();
    final dialogResult = showDialog<void>(
      context: tester.element(composerFinder),
      builder: (_) => const AlertDialog(title: Text('Keyboard dialog')),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await dialogResult;

    expect(find.text('Keyboard dialog'), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-local-command-suggestions')),
      findsOneWidget,
    );
    expect(composer.controller?.text, '/s');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('slash suggestions execute the local new-session command', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/n',
    );
    await tester.pump();

    expect(find.text('Wing commands'), findsOneWidget);
    expect(find.text('/new'), findsOneWidget);
    expect(find.text('/sessions'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-local-command-new')));
    await tester.pumpAndSettle();

    expect(channel.createSessionCalls, [null]);
    expect(channel.sentVoiceTranscripts, isEmpty);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('new-session command requires every declared write scope', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {
          'type': 'bearer',
          'required': true,
          'granted_scopes': ['chat:write'],
        },
        'features': {'session_chat_streaming': true},
        'endpoints': {
          'session_chat_stream': {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/chat/stream',
            'required_scopes': ['chat:write'],
          },
          'session_create': {
            'method': 'POST',
            'path': '/api/sessions',
            'required_scopes': ['sessions:write'],
          },
        },
      }),
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/new',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-new')),
      findsNothing,
    );
    expect(channel.createSessionCalls, isEmpty);
  });

  testWidgets('slash suggestions remain usable at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel, textScale: 2));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/s',
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('/sessions'), findsOneWidget);
    expect(find.text('/settings'), findsOneWidget);
    expect(find.text('/new'), findsOneWidget);
  });

  testWidgets('exact local clear command never reaches Hermes', (tester) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/clear',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(channel.sentVoiceTranscripts, isEmpty);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('local help command lists Wing-owned commands at 200% scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel, textScale: 2));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/help',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-local-command-help')));
    await tester.pumpAndSettle();

    expect(find.text('Wing commands'), findsOneWidget);
    expect(find.text('/new'), findsOneWidget);
    expect(find.text('/usage'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/help'),
      isEmpty,
    );
  });

  testWidgets('local office command opens the accessible Office surface', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/office',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Office destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/office'),
      isEmpty,
    );
  });

  testWidgets('local tools command opens the implemented Tools surface', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/tools',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tools destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/tools'),
      isEmpty,
    );
  });

  testWidgets('local skills command opens installed skill inventory', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/skills',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tools destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/skills'),
      isEmpty,
    );
  });

  testWidgets('local agents command opens the implemented Agents surface', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/profiles',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Profiles destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/profiles'),
      isEmpty,
    );
  });

  testWidgets('advertised persona command reads the selected profile SOUL', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {
          'type': 'bearer',
          'required': true,
          'granted_scopes': ['profiles:read'],
        },
        'features': {'session_chat_streaming': true},
        'endpoints': {
          'session_chat_stream': {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/chat/stream',
          },
          'profile_soul': {
            'method': 'GET',
            'path': '/api/profiles/{name}/soul',
            'required_scopes': ['profiles:read'],
          },
        },
      }),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coder', revision: 'profile-1'),
      ],
      selectedProfileId: 'coder',
      profileSoul: const HermesProfileSoul(
        soul: 'Be concise and verify every claim.',
        revision: 'soul-1',
      ),
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/persona',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('hermes-local-command-persona')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('hermes-local-command-persona')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coder persona'), findsOneWidget);
    expect(find.text('Be concise and verify every claim.'), findsOneWidget);
    expect(channel.readProfileSoulCalls, ['coder']);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/persona'),
      isEmpty,
    );
  });

  testWidgets('persona control requires the granted profiles read scope', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {
          'type': 'bearer',
          'required': true,
          'granted_scopes': <String>[],
        },
        'features': {'session_chat_streaming': true},
        'endpoints': {
          'session_chat_stream': {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/chat/stream',
          },
          'profile_soul': {
            'method': 'GET',
            'path': '/api/profiles/{name}/soul',
            'required_scopes': ['profiles:read'],
          },
        },
      }),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coder', revision: 'p1'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/persona',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-persona')),
      findsNothing,
    );
    expect(channel.readProfileSoulCalls, isEmpty);
  });

  testWidgets('unadvertised persona command stays server-owned', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/persona',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-persona')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(channel.readProfileSoulCalls, isEmpty);
    expect(
      channel.state.activeMessages.any((turn) => turn.text == '/persona'),
      isTrue,
    );
  });

  testWidgets('advertised version command reports bounded gateway version', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {
          'type': 'bearer',
          'required': true,
          'granted_scopes': ['gateway:read'],
        },
        'features': {'session_chat_streaming': true},
        'endpoints': {
          'session_chat_stream': {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/chat/stream',
          },
          'health_detailed': {
            'method': 'GET',
            'path': '/health/detailed',
            'required_scopes': ['gateway:read'],
          },
        },
      }),
      detailedHealth: const HermesHealthStatus(
        status: 'ok',
        platform: 'hermes-agent',
        version: '0.18.0',
      ),
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/version',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('hermes-local-command-version')),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Gateway version: hermes-agent 0.18.0'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/version'),
      isEmpty,
    );
  });

  testWidgets('local model command opens provider and model management', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/model',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Providers destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/model'),
      isEmpty,
    );
  });

  testWidgets(
    'local providers command opens the implemented Providers surface',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(_routerTestApp(channel));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        '/providers',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      await tester.pumpAndSettle();

      expect(find.text('Providers destination'), findsOneWidget);
      expect(
        channel.state.activeMessages.where((turn) => turn.text == '/providers'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'local schedules command opens the implemented Schedules surface',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(_routerTestApp(channel));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        '/schedules',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      await tester.pumpAndSettle();

      expect(find.text('Schedules destination'), findsOneWidget);
      expect(
        channel.state.activeMessages.where((turn) => turn.text == '/schedules'),
        isEmpty,
      );
    },
  );

  testWidgets('local settings command opens Wing settings without sending', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/settings',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Settings destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/settings'),
      isEmpty,
    );
  });

  testWidgets('local gateway command opens the implemented Gateway surface', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/gateway',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Gateway destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/gateway'),
      isEmpty,
    );
  });

  testWidgets('local usage command reports the latest server token counts', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Measure it.');
    channel.completeStreamingTurn(
      text: 'Measured.',
      usage: const HermesRunUsage(
        inputTokens: 12,
        outputTokens: 7,
        totalTokens: 19,
      ),
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/usage',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(
          'Latest Hermes run · 12 input · 7 output · 19 total',
        ),
      ),
      findsOneWidget,
    );
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/usage'),
      isEmpty,
    );
  });

  testWidgets('local usage command explains when metadata is unavailable', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/usage',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text('No server-reported Hermes run usage is available yet.'),
      findsOneWidget,
    );
    expect(channel.state.activeMessages, isEmpty);
  });

  testWidgets('local commands cannot bypass an active run', (tester) async {
    final channel = FakeHermesChannel()..beginStreamingTurn('Running work');
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/new',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-suggestions')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    expect(channel.createSessionCalls, isEmpty);
    final queue = find.byKey(const ValueKey('hermes-queued-follow-up'));
    expect(queue, findsOneWidget);

    channel.setCapabilities(
      HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {'type': 'none', 'required': false},
        'features': <String, Object?>{},
        'endpoints': <String, Object?>{},
      }),
    );
    await tester.pump();

    final strings = AppLocalizations.of(
      tester.element(find.byType(HermesChatScreen)),
    );
    expect(
      find.text(
        '${strings.chatQueuedSummary(1, '/new')} '
        '${strings.chatQueuedWaitingForTransport}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('plain follow-up steers an active advertised run', (
    tester,
  ) async {
    final channel = FakeHermesChannel()..beginStreamingTurn('Running work');
    channel.setCapabilities(
      HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {'type': 'none', 'required': false},
        'features': {'run_steer': true, 'session_chat_streaming': true},
        'endpoints': {
          'run_steer': {'method': 'POST', 'path': '/v1/runs/{run_id}/steer'},
          'session_chat_stream': {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/chat/stream',
          },
        },
      }),
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'Keep going with the next step',
    );
    await tester.pump();
    final sendButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('hermes-send-button')),
    );
    expect(sendButton.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    expect(channel.steerActiveTurnCalls, ['Keep going with the next step']);
    expect(find.byKey(const ValueKey('hermes-queued-follow-up')), findsNothing);
  });

  testWidgets('operator can cancel one queued follow-up', (tester) async {
    final channel = FakeHermesChannel()..beginStreamingTurn('Running work');
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pump();

    final composer = find.byKey(const ValueKey('hermes-composer-field'));
    final send = find.byKey(const ValueKey('hermes-send-button'));
    for (final text in ['First follow-up', 'Second follow-up']) {
      await tester.enterText(composer, text);
      await tester.pump();
      await tester.tap(send);
      await tester.pump();
    }

    await tester.tap(
      find.byKey(const ValueKey('hermes-queued-follow-up-manage')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final strings = AppLocalizations.of(
      tester.element(find.byType(HermesChatScreen)),
    );
    expect(find.text(strings.chatQueuedManageTitle(2)), findsOneWidget);
    expect(find.text('First follow-up'), findsOneWidget);
    expect(find.text('Second follow-up'), findsOneWidget);
    final removeFirst = find.byKey(
      const ValueKey('hermes-queued-follow-up-remove-0'),
    );
    final removeLabel = tester.getSemantics(removeFirst).label;
    expect(removeLabel, contains('First follow-up'));
    expect(removeLabel, contains(strings.chatQueuedCancelOneAction));

    await tester.tap(removeFirst);
    await tester.pump();

    expect(find.text('First follow-up'), findsNothing);
    expect(find.text('Second follow-up'), findsOneWidget);
    expect(find.text(strings.chatQueuedManageTitle(1)), findsOneWidget);
  });

  testWidgets('queue manager stays usable at 200% text on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel()..beginStreamingTurn('Running work');
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel, textScale: 2));
    await tester.pump();

    final composer = find.byKey(const ValueKey('hermes-composer-field'));
    await tester.tap(composer);
    for (var index = 0; index < 5; index++) {
      await tester.enterText(
        composer,
        'Queued follow-up $index with a long readable preview',
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
    final moreActions = find.byKey(
      const ValueKey('hermes-queued-follow-up-more-actions'),
    );
    final strings = AppLocalizations.of(
      tester.element(find.byType(HermesChatScreen)),
    );
    expect(
      tester.getSemantics(moreActions).label,
      contains(strings.chatQueuedMoreActions),
    );

    await tester.tap(moreActions);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(strings.chatLayoutCopyAction), findsOneWidget);
    expect(find.text(strings.chatLayoutCancelAllAction), findsOneWidget);
    final sendNowItem = tester.widget<PopupMenuItem<dynamic>>(
      find.ancestor(
        of: find.text(strings.chatLayoutSendNowAction),
        matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
      ),
    );
    expect(sendNowItem.enabled, isFalse);

    await tester.tap(find.text(strings.chatLayoutCopyAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(strings.chatLayoutFollowUpsCopiedBody), findsOneWidget);

    await tester.tap(moreActions);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(strings.chatLayoutCancelAllAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up-clear-dialog')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(const ValueKey('hermes-queued-follow-up-clear-keep')),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('hermes-queued-follow-up-manage')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final dialog = find.byKey(
      const ValueKey('hermes-queued-follow-up-manage-dialog'),
    );
    expect(dialog, findsOneWidget);
    expect(tester.takeException(), isNull);

    final removeLast = find.byKey(
      const ValueKey('hermes-queued-follow-up-remove-4'),
    );
    final queueList = find.descendant(
      of: dialog,
      matching: find.byType(Scrollable),
    );
    await tester.drag(queueList, const Offset(0, -240));
    await tester.pump();
    await tester.tap(removeLast);
    await tester.pump();

    expect(find.text(strings.chatQueuedManageTitle(4)), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('full follow-up queue announces localized guidance', (
    tester,
  ) async {
    final channel = FakeHermesChannel()..beginStreamingTurn('Running work');
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pump();

    final composer = find.byKey(const ValueKey('hermes-composer-field'));
    final send = find.byKey(const ValueKey('hermes-send-button'));
    for (var index = 0; index < 6; index++) {
      final text = index == 0
          ? 'Follow-up 0 token=secret-sentinel'
          : 'Follow-up $index';
      await tester.enterText(composer, text);
      await tester.pump();
      await tester.tap(send);
      await tester.pump();
    }

    final strings = AppLocalizations.of(
      tester.element(find.byType(HermesChatScreen)),
    );
    final queue = find.byKey(const ValueKey('hermes-queued-follow-up'));
    final queueText = tester.widget<Text>(
      find.descendant(of: queue, matching: find.byType(Text)).first,
    );
    expect(
      queueText.data,
      '${strings.chatQueuedSummary(5, 'Follow-up 0 token=[redacted] • Follow-up 1')} '
      '• ${strings.chatQueuedMore(3)}',
    );
    expect(queueText.data, isNot(contains('secret-sentinel')));
    final error = find.byKey(const ValueKey('hermes-queued-follow-up-error'));
    expect(error, findsOneWidget);
    final semantics = tester.getSemantics(error);
    expect(semantics.label, strings.chatQueuedFullError(5));
    expect(semantics.flagsCollection.isLiveRegion, isTrue);
  });

  testWidgets('unknown slash commands remain server-owned messages', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/retry',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-suggestions')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(
      channel.state.activeMessages.any((turn) => turn.text == '/retry'),
      isTrue,
    );
  });
  testWidgets('unreconciled run disables the composer', (tester) async {
    final channel = FakeHermesChannel(hasUnreconciledRun: true);
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(field.enabled, isFalse);
    expect(find.text('Retry last message'), findsNothing);
  });
}
