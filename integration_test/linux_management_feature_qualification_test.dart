import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/features/providers/widgets/model_picker_sheet.dart';
import 'package:wing/features/providers/widgets/provider_credential_sheet.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';

import 'support/linux_management_feature_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final cases = ManagementCases();
  setUp(() {
    cases.requireIsolation();
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
  });

  testWidgets(
    'Persona keeps failed draft, rejects revision conflict and ignores stale completion',
    (tester) async {
      final f = ManagementFixture();
      await f.open(tester, '/soul');
      final field = find.byType(TextFormField).last;
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.enterText(field, 'Synthetic draft');
      f.failures.add('PUT /api/profiles/coder/soul');
      await managementTap(tester, save);
      expect(
        tester.widget<TextFormField>(field).controller!.text,
        'Synthetic draft',
      );
      expect(find.textContaining('could not complete'), findsOneWidget);
      expect(find.textContaining('synthetic-private-failure'), findsNothing);
      f.failures.clear();
      f.conflict = true;
      f.soul = 'Synthetic authoritative revision';
      f.soulRevision = 's2';
      await managementTap(tester, save);
      expect(
        tester.widget<TextFormField>(field).controller!.text,
        'Synthetic authoritative revision',
      );
      expect(find.textContaining('changed elsewhere'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(f.writes, 2);
      f.conflict = false;
      await tester.enterText(field, 'Synthetic deliberate retry');
      await managementTap(tester, save);
      expect(f.router.routeInformationProvider.value.uri.path, '/profiles');
      expect(f.soul, 'Synthetic deliberate retry');
      expect(
        f.requests.where((r) => r.method == 'PUT').map((r) => r.revision),
        ['s1', 's1', 's2'],
      );
      for (final r in f.requests.where((r) => r.method == 'PUT')) {
        expect(r.uri.path, '/api/profiles/coder/soul');
      }
      await f.go(tester, '/soul');
      await tester.enterText(field, 'Old owner draft');
      f.pendingWrite = Completer<String>();
      await tester.tap(save);
      await tester.pump();
      await f.channel.connect(baseUrl: 'http://127.0.0.1:8643');
      await f.channel.selectProfile('coder');
      await tester.pumpAndSettle();
      await tester.enterText(field, 'Replacement owner draft');
      final reads = f.requests.length;
      f.pendingWrite!.completeError(ManagementConflict());
      await tester.pumpAndSettle();
      expect(f.requests, hasLength(reads));
      expect(f.channel.state.selectedProfileId, 'coder');
      expect(
        tester.widget<TextFormField>(field).controller!.text,
        'Replacement owner draft',
      );
      expect(find.textContaining('changed elsewhere'), findsNothing);
      expect(f.writes, 4);
      expect(tester.takeException(), isNull);
      cases.record(
        'persona-revision-recovery',
        ['HD-PROFILE'],
        ['/soul', '/profiles'],
        f,
        owners: 2,
      );
    },
  );

  testWidgets(
    'Profiles route preserves exact lifecycle requests and fences obsolete editors',
    (tester) async {
      final f = ManagementFixture();
      await f.open(tester, '/profiles');
      final reads = f.requests.length;
      await tester.enterText(managementKey('profiles-search'), 'no-match');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, 'Edit'), findsNothing);
      await managementTap(tester, find.byTooltip('Clear profile search'));
      expect(f.requests, hasLength(reads));
      await managementTap(
        tester,
        find.widgetWithText(FilledButton, 'New Profile'),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Profile name'),
        'created',
      );
      await managementTap(tester, find.widgetWithText(FilledButton, 'Create'));
      expect(f.channel.state.profiles.map((p) => p.id), contains('created'));
      expect(f.requests.singleWhere((r) => r.method == 'POST').body, {
        'name': 'created',
        'clone_from': 'default',
      });
      Future<void> edit(String label) async {
        final card = find.ancestor(
          of: find.text(label),
          matching: find.byType(Card),
        );
        await managementTap(
          tester,
          find.descendant(
            of: card,
            matching: find.widgetWithText(OutlinedButton, 'Edit'),
          ),
        );
      }

      await edit('Coder');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Profile name'),
        'Renamed coder',
      );
      await managementTap(tester, find.widgetWithText(FilledButton, 'Save'));
      final rename = f.requests.singleWhere((r) => r.method == 'PATCH');
      expect(rename.uri.path, '/api/profiles/coder');
      expect(rename.revision, 'p1');
      expect(rename.body, {'name': 'Renamed coder'});
      expect(
        f.channel.state.profiles
            .singleWhere((p) => p.id == 'coder')
            .displayName,
        'Renamed coder',
      );
      await edit('created');
      await managementTap(
        tester,
        find.widgetWithText(TextButton, 'Delete profile').last,
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'created',
      );
      await managementTap(
        tester,
        find.widgetWithText(FilledButton, 'Delete profile'),
      );
      final deletion = f.requests.singleWhere((r) => r.method == 'DELETE');
      expect(deletion.uri.path, '/api/profiles/created');
      expect(deletion.revision, 'c1');
      expect(
        f.channel.state.profiles.map((p) => p.id),
        isNot(contains('created')),
      );
      await edit('Renamed coder');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Profile name'),
        'Do not persist',
      );
      await f.channel.connect(baseUrl: 'http://127.0.0.1:8643');
      await f.channel.selectProfile('coder');
      await tester.pumpAndSettle();
      await managementTap(tester, find.widgetWithText(FilledButton, 'Save'));
      expect(f.writes, 3);
      expect(find.byType(ProfileEditorSheet), findsOneWidget);
      await managementTap(tester, find.widgetWithText(TextButton, 'Cancel'));
      await edit('Renamed coder');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Profile name'),
        'Pending old name',
      );
      f.pendingWrite = Completer<String>();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      expect(f.writes, 4);
      await f.channel.connect(baseUrl: 'http://localhost:8644');
      await f.channel.selectProfile('coder');
      await tester.pumpAndSettle();
      final current = f.channel.state.profiles;
      final before = f.requests.length;
      f.pendingWrite!.complete(
        '{"id":"coder","name":"Obsolete completion","revision":"p3"}',
      );
      await tester.pumpAndSettle();
      expect(f.channel.state.profiles, current);
      expect(f.requests, hasLength(before));
      expect(find.byType(ProfileEditorSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      cases.record(
        'profiles-lifecycle-owner',
        ['HD-PROFILE'],
        ['/profiles'],
        f,
        owners: 3,
      );
    },
  );

  testWidgets(
    'Provider sheet never reads a secret and retries Set only on explicit input',
    (tester) async {
      final f = ManagementFixture();
      await f.open(tester, '/providers');
      final reads = f.requests.length;
      await tester.enterText(managementKey('providers-search'), 'no-match');
      await tester.pumpAndSettle();
      expect(find.text('Synthetic provider'), findsNothing);
      await managementTap(tester, find.byTooltip('Clear provider search'));
      expect(f.requests, hasLength(reads));
      expect(find.textContaining('synthetic-stored-secret'), findsNothing);
      Future<void> open() async {
        await managementTap(
          tester,
          find.widgetWithText(TextButton, 'Manage credential'),
        );
        final field = tester.widget<TextField>(
          find.descendant(
            of: find.byType(ProviderCredentialSheet),
            matching: find.byType(TextField),
          ),
        );
        expect(field.obscureText, isTrue);
        expect(field.controller!.text, isEmpty);
        expect(find.textContaining('synthetic-stored-secret'), findsNothing);
      }

      await open();
      await tester.enterText(
        find.descendant(
          of: find.byType(ProviderCredentialSheet),
          matching: find.byType(TextField),
        ),
        'synthetic-new-secret',
      );
      f.failures.add('PUT /api/providers/synthetic/credential');
      await managementTap(tester, find.widgetWithText(FilledButton, 'Set'));
      expect(find.byType(ProviderCredentialSheet), findsOneWidget);
      f.failures.clear();
      await tester.pump(const Duration(seconds: 1));
      expect(f.writes, 1);
      await managementTap(tester, find.widgetWithText(FilledButton, 'Set'));
      expect(find.byType(ProviderCredentialSheet), findsNothing);
      expect(f.writes, 2);
      for (final r in f.requests.where((r) => r.method == 'PUT')) {
        expect(r.uri.path, '/api/providers/synthetic/credential');
        expect(r.uri.queryParameters, {'profile': 'coder'});
        expect(r.body, {
          'env_var': 'SYNTHETIC_API_KEY',
          'value': 'synthetic-new-secret',
        });
        expect(r.uri.toString(), isNot(contains('secret')));
      }
      expect(
        f.channel.state.providers
            .singleWhere((p) => p.slug == 'synthetic')
            .keyHint,
        '····0001',
      );
      await open();
      await managementTap(
        tester,
        find.widgetWithText(OutlinedButton, 'Validate'),
      );
      expect(find.textContaining('Synthetic accepted'), findsOneWidget);
      expect(find.textContaining('redact-me'), findsNothing);
      expect(find.textContaining('/home/example/private'), findsNothing);
      expect(f.writes, 3);
      final validate = f.requests.singleWhere((r) => r.method == 'POST');
      expect(validate.uri.path, '/api/providers/synthetic/credential/validate');
      expect(validate.uri.queryParameters, {'profile': 'coder'});
      await managementTap(tester, find.widgetWithText(TextButton, 'Remove'));
      expect(f.writes, 4);
      expect(
        f.channel.state.providers
            .singleWhere((p) => p.slug == 'synthetic')
            .configured,
        isFalse,
      );
      expect(
        f.requests.singleWhere((r) => r.method == 'DELETE').uri.queryParameters,
        {'profile': 'coder', 'env_var': 'SYNTHETIC_API_KEY'},
      );
      expect(tester.takeException(), isNull);
      cases.record(
        'provider-secret-recovery',
        ['HD-PROVIDER'],
        ['/providers'],
        f,
      );
    },
  );

  testWidgets(
    'Provider sheet rejects stale submission and late old-owner completion',
    (tester) async {
      final f = ManagementFixture();
      await f.open(tester, '/providers');
      final manage = find.widgetWithText(TextButton, 'Manage credential');
      await managementTap(tester, manage);
      final input = find.descendant(
        of: find.byType(ProviderCredentialSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(input, 'synthetic-stale-secret');
      await f.channel.selectProfile('other');
      await tester.pumpAndSettle();
      await managementTap(tester, find.widgetWithText(FilledButton, 'Set'));
      expect(f.writes, 0);
      await managementTap(tester, find.widgetWithText(TextButton, 'Cancel'));
      await managementTap(tester, manage);
      await tester.enterText(input, 'synthetic-pending-secret');
      f.pendingWrite = Completer<String>();
      await tester.tap(find.widgetWithText(FilledButton, 'Set'));
      await tester.pump();
      expect(f.writes, 1);
      await f.channel.selectProfile('coder');
      await tester.pumpAndSettle();
      final current = f.channel.state.providers;
      f.pendingWrite!.complete(
        jsonEncode({
          'data': {
            'slug': 'synthetic',
            'configured': false,
            'key_hint': '····9999',
          },
        }),
      );
      await tester.pumpAndSettle();
      expect(f.channel.state.providers, current);
      expect(find.byType(ProviderCredentialSheet), findsOneWidget);
      expect(
        f.requests.singleWhere((r) => r.method == 'PUT').uri.queryParameters,
        {'profile': 'other'},
      );
      expect(f.writes, 1);
      expect(tester.takeException(), isNull);
      cases.record(
        'provider-stale-owner',
        ['HD-PROVIDER'],
        ['/providers'],
        f,
        owners: 3,
      );
    },
  );

  testWidgets(
    'Models use revisioned main and auxiliary assignments, with local presets',
    (tester) async {
      final f = ManagementFixture();
      await f.open(tester, '/providers');
      await managementTap(
        tester,
        find.widgetWithText(FilledButton, 'Choose model'),
      );
      final reads = f.requests.length;
      await managementTap(tester, managementKey('model-preset-save'));
      await tester.enterText(
        managementKey('model-preset-name-field'),
        'Synthetic preset',
      );
      await managementTap(tester, managementKey('model-preset-save-confirm'));
      await managementTap(
        tester,
        find
            .descendant(
              of: find.byType(ModelPickerSheet),
              matching: find.text('synthetic-model'),
            )
            .last,
      );
      await managementTap(tester, find.text('synthetic-alternate').last);
      await managementTap(
        tester,
        managementKey('model-preset-Synthetic preset'),
      );
      expect(
        find.descendant(
          of: find.byType(ModelPickerSheet),
          matching: find.text('synthetic-model'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ModelPickerSheet),
          matching: find.text('synthetic-alternate'),
        ),
        findsNothing,
      );
      await managementTap(
        tester,
        find.descendant(
          of: managementKey('model-preset-Synthetic preset'),
          matching: find.byTooltip('Delete'),
        ),
      );
      expect(find.text('Synthetic preset'), findsNothing);
      expect(f.requests, hasLength(reads));
      await managementTap(
        tester,
        find.widgetWithText(TextButton, 'Refresh catalog'),
      );
      f.failures.add('PUT /api/models/assignment');
      await managementTap(tester, find.widgetWithText(FilledButton, 'Assign'));
      expect(find.byType(ModelPickerSheet), findsOneWidget);
      f.failures.clear();
      await tester.pump(const Duration(seconds: 1));
      expect(f.writes, 2);
      await managementTap(tester, find.widgetWithText(FilledButton, 'Assign'));
      expect(find.byType(ModelPickerSheet), findsNothing);
      final assignments = f.requests.where(
        (r) => r.uri.path == '/api/models/assignment',
      );
      expect(assignments.map((r) => r.revision), ['m1', 'm1']);
      for (final r in assignments) {
        expect(r.uri.queryParameters, {'profile': 'coder'});
        expect(r.body, {
          'scope': 'main',
          'provider': 'synthetic',
          'model': 'synthetic-model',
        });
      }
      expect(f.channel.state.modelInventory!.assignment.revision, 'm2');
      await managementTap(
        tester,
        find.widgetWithText(FilledButton, 'Choose model'),
      );
      await managementTap(tester, find.text('Main'));
      await managementTap(tester, find.text('Vision').last);
      await managementTap(
        tester,
        find
            .descendant(
              of: find.byType(ModelPickerSheet),
              matching: find.text('synthetic-model'),
            )
            .last,
      );
      await managementTap(tester, find.text('synthetic-alternate').last);
      await managementTap(tester, find.widgetWithText(FilledButton, 'Assign'));
      final last = f.requests.lastWhere((r) => r.method == 'PUT');
      expect(last.revision, 'm2');
      expect(last.uri.queryParameters, {'profile': 'coder'});
      expect(last.body, {
        'scope': 'auxiliary',
        'task': 'vision',
        'provider': 'synthetic',
        'model': 'synthetic-alternate',
      });
      expect(
        f.channel.state.modelInventory!.assignment.activeModel,
        'synthetic-model',
      );
      expect(
        f.channel.state.modelInventory!.assignment.auxiliary.single.model,
        'synthetic-alternate',
      );
      expect(tester.takeException(), isNull);
      cases.record(
        'model-explicit-assignment',
        ['HD-MODEL'],
        ['/providers'],
        f,
      );
    },
  );

  testWidgets(
    'Tools and Schedules search without reads and recover through exact-scoped refresh',
    (tester) async {
      final f = ManagementFixture();
      await f.open(tester, '/tools');
      expect(find.text('synthetic-skill'), findsOneWidget);
      final start = f.requests.length;
      await tester.enterText(
        managementKey('installed-skills-search'),
        'absent',
      );
      await tester.pumpAndSettle();
      expect(find.text('synthetic-skill'), findsNothing);
      await managementTap(tester, managementKey('installed-skills-clear'));
      await managementTap(tester, managementKey('tools-tab-toolsets'));
      await tester.enterText(managementKey('toolsets-search'), 'absent');
      await tester.pumpAndSettle();
      expect(find.text('synthetic-tools'), findsNothing);
      await managementTap(tester, managementKey('toolsets-clear'));
      await managementTap(tester, find.text('synthetic-tools'));
      expect(find.text('synthetic-read'), findsOneWidget);
      expect(f.requests, hasLength(start));
      f.failures.add('GET /v1/skills');
      await managementTap(tester, managementKey('tools-refresh'));
      expect(f.requests, hasLength(start + 2));
      await managementTap(tester, managementKey('tools-tab-skills'));
      expect(
        find.text('Installed skills could not be loaded from Hermes.'),
        findsOneWidget,
      );
      expect(find.textContaining('synthetic-private-failure'), findsNothing);
      f.failures.clear();
      f.skill = 'synthetic-recovered-skill';
      await managementTap(tester, managementKey('tools-refresh'));
      expect(find.text('synthetic-recovered-skill'), findsOneWidget);
      await f.go(tester, '/tasks');
      var before = f.requests.length;
      await managementTap(tester, find.widgetWithText(ChoiceChip, 'Disabled'));
      expect(find.text('Synthetic routine'), findsNothing);
      await managementTap(tester, find.widgetWithText(ChoiceChip, 'Enabled'));
      expect(find.text('Synthetic routine'), findsOneWidget);
      await tester.enterText(managementKey('schedules-search'), 'absent');
      await tester.pumpAndSettle();
      expect(find.text('Synthetic routine'), findsNothing);
      await managementTap(tester, managementKey('schedules-clear-filters'));
      expect(f.requests, hasLength(before));
      before = f.requests.length;
      f.failures.add('GET /api/jobs');
      await managementTap(tester, managementKey('schedules-refresh-button'));
      expect(f.requests, hasLength(before + 1));
      expect(find.textContaining('synthetic-private-failure'), findsNothing);
      f.failures.clear();
      await managementTap(tester, find.text('Retry'));
      expect(f.requests, hasLength(before + 2));
      expect(find.text('Synthetic routine'), findsOneWidget);
      for (final r
          in f.requests
              .skip(start)
              .where(
                (r) => [
                  '/api/jobs',
                  '/v1/skills',
                  '/v1/toolsets',
                ].contains(r.uri.path),
              )) {
        expect(r.method, 'GET');
        expect(r.uri.queryParameters, {
          'profile': 'coder',
          if (r.uri.path == '/api/jobs') 'include_disabled': 'true',
        });
      }
      expect(f.writes, 0);
      expect(tester.takeException(), isNull);
      cases.record(
        'read-only-inventory-recovery',
        ['HD-SKILLS', 'HD-SCHEDULE'],
        ['/tools', '/tasks'],
        f,
      );
    },
  );

  testWidgets('Connections health Retry preserves Chat owner without writes', (
    tester,
  ) async {
    final f = ManagementFixture();
    await f.open(tester, '/gateway');
    final owner = (
      f.channel.state.connectedBaseUrl,
      f.channel.state.selectedProfileId,
      f.channel.state.activeSessionId,
    );
    f.failures.add('GET /health/detailed');
    await managementTap(tester, managementKey('gateway-refresh-button'));
    expect(find.textContaining('synthetic-private-failure'), findsNothing);
    f.failures.clear();
    await managementTap(tester, managementKey('gateway-status-inline-retry'));
    expect((
      f.channel.state.connectedBaseUrl,
      f.channel.state.selectedProfileId,
      f.channel.state.activeSessionId,
    ), owner);
    final health = f.requests.where((r) => r.uri.path == '/health/detailed');
    expect(health, hasLength(3));
    for (final r in health) {
      expect(r.method, 'GET');
      expect(r.uri.origin, 'http://localhost:8642');
      expect(r.uri.queryParameters, isEmpty);
    }
    expect(f.writes, 0);
    expect(tester.takeException(), isNull);
    cases.record(
      'connections-health-recovery',
      ['HD-GATEWAY'],
      ['/gateway'],
      f,
    );
  });

  for (final authority in ['missing', 'denied', 'read-only']) {
    testWidgets(
      '$authority contracts reject every management write before dispatch',
      (tester) async {
        final f = ManagementFixture(authority: authority);
        await f.open(tester, '/profiles');
        expect(find.text('New Profile'), findsNothing);
        final before = f.requests.length;
        for (final operation in <Future<void> Function()>[
          () => f.channel.createProfile(name: 'forbidden'),
          () => f.channel.renameProfile(
            profileId: 'coder',
            name: 'forbidden',
            revision: 'p1',
          ),
          () => f.channel.deleteProfile(profileId: 'other', revision: 'o1'),
          () => f.channel.writeProfileSoul(
            profileId: 'coder',
            soul: 'forbidden',
            revision: 's1',
          ),
          () => f.channel.setProviderCredential(
            slug: 'synthetic',
            envVar: 'SYNTHETIC_API_KEY',
            value: 'synthetic-forbidden',
          ),
          () => f.channel.removeProviderCredential(
            slug: 'synthetic',
            envVar: 'SYNTHETIC_API_KEY',
          ),
          () => f.channel.validateProviderCredential(slug: 'synthetic'),
          () => f.channel.assignModel(
            scope: 'main',
            provider: 'synthetic',
            model: 'synthetic-model',
            revision: 'm1',
          ),
          () => f.channel.refreshModels(),
        ]) {
          await expectLater(operation(), throwsStateError);
        }
        expect(f.requests, hasLength(before));
        for (final route in [
          '/providers',
          '/tools',
          '/tasks',
          '/gateway',
          '/soul',
        ]) {
          await f.go(tester, route);
          expect(
            find.widgetWithText(TextButton, 'Manage credential'),
            findsNothing,
          );
          expect(
            find.widgetWithText(FilledButton, 'Choose model'),
            findsNothing,
          );
          expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
          if (authority == 'read-only' && route == '/providers') {
            expect(find.text('Synthetic provider'), findsOneWidget);
            expect(f.channel.state.modelInventory!.assignment.revision, 'm1');
          }
        }
        expect(f.writes, 0);
        expect(
          f.requests.where(
            (r) => [
              '/api/providers',
              '/api/models',
              '/api/jobs',
              '/v1/skills',
              '/v1/toolsets',
              '/health/detailed',
            ].contains(r.uri.path),
          ),
          authority == 'read-only' ? isNotEmpty : isEmpty,
        );
        expect(tester.takeException(), isNull);
        cases.record(
          'authority-$authority',
          [
            'HD-PROFILE',
            'HD-PROVIDER',
            'HD-MODEL',
            'HD-SKILLS',
            'HD-SCHEDULE',
            'HD-GATEWAY',
          ],
          ['/profiles', '/providers', '/tools', '/tasks', '/gateway', '/soul'],
          f,
        );
      },
    );
  }

  testWidgets(
    'Settings persist local choices and diagnostic Copy redacts hostile metadata on retry',
    (tester) async {
      final f = ManagementFixture();
      await f.open(tester, '/settings');
      await managementTap(tester, find.text('Dark'));
      await managementTap(tester, managementKey('settings-theme-forest'));
      await managementTap(
        tester,
        managementKey('settings-chat-text-scale-125'),
      );
      await managementTap(tester, managementKey('wing-avatar-family-2'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('wing.theme.mode'), 'dark');
      expect(prefs.getString('wing.theme.palette'), 'forest');
      expect(prefs.getDouble('wing.chat.transcript_text_scale'), 1.25);
      expect(prefs.getInt('wing.appearance.avatar_variation.v1'), 2);
      // No conditional pass: GTK has no supported native spellcheck service.
      expect(managementKey('settings-category-chat'), findsNothing);
      await managementTap(
        tester,
        managementKey('settings-category-connections'),
      );
      await managementTap(tester, managementKey('settings-connections-link'));
      expect(f.router.routeInformationProvider.value.uri.path, '/gateway');
      await f.go(tester, '/settings');
      await managementTap(tester, managementKey('settings-category-voice'));
      await managementTap(tester, managementKey('settings-voice-link'));
      expect(find.byType(VoiceSettingsScreen), findsOneWidget);
      const keys = [
        'voice-continuous-enabled',
        'voice-speak-replies-enabled',
        'voice-completion-sound-enabled',
      ];
      final values = <bool>[];
      for (final key in keys) {
        final old = tester.widget<SwitchListTile>(managementKey(key)).value;
        await managementTap(tester, managementKey(key));
        expect(tester.widget<SwitchListTile>(managementKey(key)).value, !old);
        values.add(!old);
      }
      await managementTap(tester, managementKey('voice-advanced-expansion'));
      await managementTap(
        tester,
        find.descendant(
          of: managementKey('voice-language-mode'),
          matching: find.byType(DropdownButton<VoiceLanguageMode>),
        ),
      );
      await managementTap(tester, find.text('Español').last);
      await managementTap(tester, managementKey('settings-command-word'));
      await tester.enterText(
        managementKey('settings-command-word-field'),
        '   ',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(managementKey('settings-command-word-save'))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        managementKey('settings-command-word-field'),
        'synthetic',
      );
      await tester.pump();
      await managementTap(tester, managementKey('settings-command-word-save'));
      expect(prefs.getString('wing.voice.command_word'), 'synthetic');
      expect(prefs.getString('wing.voice.language_mode'), 'spanish');
      await f.go(tester, '/settings');
      await f.go(tester, '/settings/voice');
      expect([
        for (final key in keys)
          tester.widget<SwitchListTile>(managementKey(key)).value,
      ], values);
      expect([
        prefs.getBool('wing.voice.continuous_enabled'),
        prefs.getBool('wing.voice.speak_replies_enabled'),
        prefs.getBool('wing.voice.completion_sound_enabled'),
      ], values);
      f.hostileHealth = true;
      await f.channel.loadDetailedHealth();
      await f.go(tester, '/settings');
      await managementTap(
        tester,
        managementKey('settings-category-connections'),
      );
      await managementTap(tester, managementKey('settings-diagnostics-link'));
      expect(find.byType(DiagnosticsSettingsScreen), findsOneWidget);
      String? copied;
      var clipboardFails = true;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          if (clipboardFails) {
            throw PlatformException(code: 'synthetic-unavailable');
          }
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await managementTap(tester, managementKey('settings-copy-diagnostics'));
      expect(copied, isNull);
      expect(find.text('Could not copy diagnostics. Try again.'), findsWidgets);
      clipboardFails = false;
      await managementTap(tester, managementKey('settings-copy-diagnostics'));
      expect(copied, contains('Hermes Wing diagnostics'));
      expect(copied, contains('Secrets: excluded'));
      for (final value in [
        'localhost',
        'synthetic-stored-secret',
        'diagnostic-credential',
        'diagnostic-private',
        'diagnostic-user',
        'diagnostic-password',
      ]) {
        expect(copied, isNot(contains(value)));
      }
      expect(
        copied,
        contains(
          'Version: Synthetic diagnostic Bearer [redacted] [redacted-path]',
        ),
      );
      final version = copied!
          .split('\n')
          .singleWhere((line) => line.startsWith('Version:'));
      expect(version.length, lessThanOrEqualTo(130));
      expect(version, endsWith('…'));
      expect(f.writes, 0);
      expect(tester.takeException(), isNull);
      cases.record(
        'settings-diagnostics',
        ['HD-SETTINGS', 'HD-DIAG'],
        ['/settings', '/settings/voice', '/settings/diagnostics', '/gateway'],
        f,
      );
    },
  );

  testWidgets(
    'Missing destinations recover to Chat without inventing administration',
    (tester) async {
      final f = ManagementFixture();
      await f.open(tester, '/agents');
      expect(f.router.routeInformationProvider.value.uri.path, '/profiles');
      cases.record(
        'legacy-agents-alias',
        ['HD-PROFILE'],
        ['/agents', '/profiles'],
        f,
      );
      const absent = {
        'HD-OAUTH': '/oauth',
        'HD-PROJECT': '/projects',
        'HD-MCP': '/mcp',
        'HD-MEMORY': '/memory',
        'HD-KANBAN': '/kanban',
        'HD-ARTIFACTS': '/artifacts',
        'HD-PREVIEW': '/preview',
        'HD-TERMINAL': '/terminal',
        'HD-CLOUD': '/cloud',
        'HD-ACCOUNT': '/account',
        'HD-IMPORT': '/import',
        'HD-STARMAP': '/starmap',
        'HD-GUIDE': '/guide',
        'HD-PLUGINS': '/plugins',
        'HD-RADIO': '/radio',
        'HD-VAULT': '/vault',
        'HD-PLUGIN-PACKAGES': '/packages',
        'HD-SCREEN': '/screen',
        'HD-PETS': '/pets',
        'HD-SKILLS': '/discover',
      };
      for (final entry in absent.entries) {
        final before = f.requests.length;
        await f.go(tester, entry.value);
        expect(find.text('Page not found'), findsOneWidget);
        expect(f.requests, hasLength(before));
        await managementTap(tester, find.text('Return to chat'));
        expect(f.router.routeInformationProvider.value.uri.path, '/hermes');
        expect(f.writes, 0);
        cases.record(
          'absent-${entry.key}',
          [entry.key],
          [entry.value],
          f,
          counts: {'route_open_requests': 0, 'writes': 0},
          unsupported:
              'No composed destination; asserted not-found and explicit Chat recovery. Negative evidence only.',
        );
      }
      for (final route in [
        '/profiles',
        '/providers',
        '/tools',
        '/tasks',
        '/gateway',
      ]) {
        await f.go(tester, route);
        for (final label in [
          'Create Project',
          'Sign in with OAuth',
          'Add MCP server',
          'Create schedule',
          'Run now',
          'Restart Agent',
          'Install plugin',
        ]) {
          expect(find.text(label), findsNothing);
        }
        if (route == '/providers') {
          expect(
            find.text(
              'Sign in on the Hermes host. This Agent does not advertise remote OAuth setup.',
            ),
            findsOneWidget,
          );
          final oauth = find.ancestor(
            of: find.text('Host sign-in'),
            matching: find.byType(Card),
          );
          expect(
            find.descendant(
              of: oauth,
              matching: find.widgetWithText(TextButton, 'Manage credential'),
            ),
            findsNothing,
          );
        }
      }
      expect(f.writes, 0);
      expect(tester.takeException(), isNull);
      cases.record(
        'unavailable-administration',
        [
          'HD-OAUTH',
          'HD-PROJECT',
          'HD-MCP',
          'HD-SCHEDULE',
          'HD-GATEWAY',
          'HD-PLUGINS',
        ],
        ['/profiles', '/providers', '/tools', '/tasks', '/gateway'],
        f,
        unsupported:
            'OAuth, Project, MCP, job mutation, plugin installation and host lifecycle controls remain unavailable; inventory is not positive administration parity.',
      );
      expect(
        cases.rows.map((r) => r['id']).toSet(),
        hasLength(cases.rows.length),
      );
      expect(cases.rows, hasLength(33));
      await cases.publish(tester);
    },
  );
}
