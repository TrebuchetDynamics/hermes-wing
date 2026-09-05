import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_model_options.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';
import 'package:wing/features/profiles/widgets/catalog_autocomplete_field.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

void main() {
  test('setup inventory retains unconfigured providers and large catalogs', () {
    final options = HermesModelOptions.fromJson({
      'providers': [
        {
          'slug': 'unconfigured',
          'models': List.generate(400, (i) => 'model-$i'),
        },
        {'slug': 'empty', 'models': <String>[]},
      ],
    });
    expect(options.providers, hasLength(2));
    expect(options.providers.first.models.last, 'model-399');
    expect(options.selectableProviders, isEmpty);
  });

  test(
    'Wing Link catalog uses an exact capability and explicit profile',
    () async {
      final calls = <String>[];
      var supported = true;
      final client = WingLinkClient(
        origin: Uri.parse('https://host.example'),
        token: 'fixture-control',
        get: (uri, headers) async {
          calls.add(uri.path);
          expect(headers['Authorization'], 'Bearer fixture-control');
          return jsonEncode(
            uri.path == '/meta'
                ? {
                    'protocol_generation': 2,
                    'minimum_protocol_generation': 1,
                    'supported_protocol_generations': [1, 2],
                    'version': 'test',
                    'host_fingerprint': 'sha256/test',
                    'capabilities': supported
                        ? ['profiles.model-options.read']
                        : <String>[],
                  }
                : {
                    'providers': [
                      {
                        'slug': 'new',
                        'models': ['new-model'],
                      },
                    ],
                  },
          );
        },
      );
      expect(
        (await client.getProfileModelOptions('default')).providers.single.slug,
        'new',
      );
      expect(calls, ['/meta', '/v1/profiles/default/model-options']);
      supported = false;
      calls.clear();
      await expectLater(
        client.getProfileModelOptions('default'),
        throwsA(isA<WingLinkException>()),
      );
      expect(calls, ['/meta']);
      await expectLater(
        client.getProfileModelOptions('../other'),
        throwsArgumentError,
      );
    },
  );

  testWidgets(
    'autocomplete searches beyond the visible rows and selects by keyboard',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CatalogAutocompleteField(
              controller: controller,
              options: List.generate(400, (i) => 'model-$i'),
              label: 'Model',
              enabled: true,
              validator: (_) => null,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '399');
      await tester.pump();
      expect(find.text('model-399'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(selected, 'model-399');
      expect(find.byType(InkWell), findsNothing);
    },
  );

  testWidgets('freezing a setup payload dismisses open suggestions', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var enabled = true;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return CatalogAutocompleteField(
                controller: controller,
                options: const ['example-model'],
                label: 'Model',
                enabled: enabled,
                validator: (_) => null,
              );
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'example');
    await tester.pump();
    expect(find.text('example-model'), findsOneWidget);
    update(() => enabled = false);
    await tester.pumpAndSettle();
    expect(find.text('example-model'), findsNothing);
    expect(controller.text, 'example');
  });

  testWidgets(
    'profile setup retries catalog, offers unconfigured provider and clears stale model',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileEditorSheet(
              channel: channel,
              canConfigure: true,
              profiles: const [
                HermesProfile(
                  id: 'default',
                  displayName: 'Default',
                  revision: 'r1',
                ),
              ],
              loadModelOptions: (profile) async {
                expect(profile, 'default');
                if (++attempts == 1) throw StateError('fixture failure');
                return HermesModelOptions.fromJson({
                  'providers': [
                    {
                      'slug': 'alpha',
                      'name': 'Example service',
                      'models': ['alpha-model'],
                    },
                    {
                      'slug': 'beta',
                      'models': ['beta-model'],
                    },
                  ],
                });
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry catalog'), findsOneWidget);
      await tester.tap(find.text('Retry catalog'));
      await tester.pumpAndSettle();
      final fields = find.byType(CatalogAutocompleteField);
      final provider = find.descendant(
        of: fields.at(0),
        matching: find.byType(TextFormField),
      );
      final model = find.descendant(
        of: fields.at(1),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(provider, 'Example');
      await tester.pump();
      await tester.tap(find.widgetWithText(InkWell, 'alpha'));
      await tester.pump();
      await tester.enterText(model, 'alpha');
      await tester.pump();
      expect(find.widgetWithText(InkWell, 'alpha-model'), findsOneWidget);
      await tester.tap(find.widgetWithText(InkWell, 'alpha-model'));
      await tester.pump();
      await tester.enterText(provider, 'beta');
      await tester.pump();
      expect(tester.widget<TextFormField>(model).controller!.text, isEmpty);
      await tester.tap(find.widgetWithText(InkWell, 'beta'));
      await tester.pump();
      await tester.enterText(model, 'beta');
      await tester.pump();
      expect(find.widgetWithText(InkWell, 'beta-model'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'alpha-model'), findsNothing);
    },
  );
  testWidgets('OmniRoute discovery selects host service and can recheck', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    var status = 'serving';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileEditorSheet(
            channel: channel,
            canConfigure: true,
            profiles: const [
              HermesProfile(
                id: 'default',
                displayName: 'Default',
                revision: 'r1',
              ),
            ],
            discoverOmniRoute: () async => status,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use OmniRoute'));
    await tester.pumpAndSettle();
    final fields = tester.widgetList<CatalogAutocompleteField>(
      find.byType(CatalogAutocompleteField),
    );
    expect(fields.first.controller.text, 'omniroute');
    status = 'unavailable';
    await tester.tap(find.text('Check for OmniRoute'));
    await tester.pumpAndSettle();
    expect(find.text('Use OmniRoute'), findsNothing);
    expect(
      find.textContaining('No OmniRoute service was found'),
      findsOneWidget,
    );
  });
}
