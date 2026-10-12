import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import 'profile_persona_ownership_test.dart' show personaCaps;

Widget _editorTestApp(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

final class _TestHermesStatusException implements HermesApiStatusException {
  const _TestHermesStatusException(this.statusCode);

  @override
  final int statusCode;
}

void main() {
  testWidgets('create owner roundtrip ignores late completion without replay', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    final ownerChanges = ValueNotifier<Object>(Object());
    addTearDown(ownerChanges.dispose);
    var ownerCurrent = true;
    var saved = 0;
    var writes = 0;
    final gate = Completer<void>();
    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [],
          ownerChanges: ownerChanges,
          isOwnerCurrent: () => ownerCurrent,
          onSaved: () => saved++,
          onCreate:
              ({
                required name,
                cloneFrom,
                description,
                provider,
                model,
                providerApiKey,
                idempotencyKey,
              }) async {
                writes++;
                await gate.future;
              },
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Profile name'),
      'Writer',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();
    ownerCurrent = false;
    ownerChanges.value = Object();
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Create'))
          .onPressed,
      isNull,
    );
    ownerCurrent = true;
    ownerChanges.value = Object();
    gate.complete();
    await tester.pumpAndSettle();
    expect(saved, 0);
    expect(writes, 1);
    expect(channel.createProfileCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clone selection fits a narrow screen with a long profile name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [
            HermesProfile(
              id: 'default',
              displayName:
                  'A profile with a very long descriptive name for a specialized task',
              revision: 'r',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start fresh').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete requires typing the agent display name', (tester) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [],
          profile: const HermesProfile(
            id: 'coder',
            displayName: 'Coding Agent',
            revision: 'rev-1',
          ),
          canDelete: true,
        ),
      ),
    );

    await tester.tap(find.text('Delete profile'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Coding Agent?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Coding Agent');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete profile'));
    await tester.pumpAndSettle();

    expect(channel.deleteProfileCalls, [
      {'profileId': 'coder', 'revision': 'rev-1'},
    ]);
  });

  for (final failure in [
    const _TestHermesStatusException(412),
    const _TestHermesStatusException(403),
    const {'approval_id': 'unknown', 'idempotency_key': 'not-authority'},
  ]) {
    testWidgets('failed delete needs fresh typed confirmation: $failure', (
      tester,
    ) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      final requests = <(String, String, String?)>[];
      await tester.pumpWidget(
        _editorTestApp(
          ProfileEditorSheet(
            channel: channel,
            profiles: const [],
            profile: const HermesProfile(
              id: 'cycle',
              displayName: 'cycle',
              revision: 'rev-1',
            ),
            canDelete: true,
            onDelete: (id, revision, {idempotencyKey}) async {
              requests.add((id, revision, idempotencyKey));
              if (requests.length == 1) throw failure;
            },
          ),
        ),
      );
      await tester.tap(find.text('Delete profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'cycle');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete profile'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          failure is HermesApiStatusException && failure.statusCode == 412
              ? 'This profile changed elsewhere'
              : 'Hermes could not complete that profile change.',
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(minutes: 6));
      expect(requests, [('cycle', 'rev-1', null)]);
      // Save is never an approval shortcut to deletion.
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      await tester.tap(find.text('Delete profile'));
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(FilledButton, 'Delete profile');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      expect(requests, hasLength(1));
      await tester.enterText(find.byType(TextField).last, 'cycle');
      await tester.pump();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(requests, [('cycle', 'rev-1', null), ('cycle', 'rev-1', null)]);
      expect(channel.deleteProfileCalls, isEmpty);
    });
  }

  testWidgets('create validates a name and clones from the selected agent', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [
            HermesProfile(
              id: 'default',
              displayName: 'Hermes One',
              revision: 'rev-default',
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(find.text('Enter a profile name.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Coding Agent');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(channel.createProfileCalls, [
      {'name': 'Coding Agent', 'cloneFrom': 'default'},
    ]);
  });

  testWidgets(
    'configured fresh create requires provider and model and keeps credential write-only',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      Map<String, String?>? submitted;

      await tester.pumpWidget(
        _editorTestApp(
          ProfileEditorSheet(
            channel: channel,
            profiles: const [
              HermesProfile(
                id: 'default',
                displayName: 'default',
                revision: 'rev-default',
              ),
            ],
            stableNames: true,
            canConfigure: true,
            onCreate:
                ({
                  required name,
                  cloneFrom,
                  description,
                  provider,
                  model,
                  providerApiKey,
                  idempotencyKey,
                }) async {
                  submitted = {
                    'name': name,
                    'cloneFrom': cloneFrom,
                    'description': description,
                    'provider': provider,
                    'model': model,
                    'providerApiKey': providerApiKey,
                    'idempotencyKey': idempotencyKey,
                  };
                },
          ),
        ),
      );

      final credentialField = find.widgetWithText(
        TextFormField,
        'New provider credential',
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: credentialField,
                matching: find.byType(EditableText),
              ),
            )
            .obscureText,
        isTrue,
      );
      await tester.tap(find.text('default').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start fresh').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Profile name'),
        'readyqa',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Physical lifecycle profile',
      );
      final initialCreate = find.widgetWithText(FilledButton, 'Create');
      await tester.ensureVisible(initialCreate);
      await tester.tap(initialCreate);
      await tester.pump();
      expect(find.text('Enter a model.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Provider'),
        'openrouter',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Model'),
        'openai/gpt-5.2',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New provider credential'),
        'write-only-secret',
      );
      final createButton = find.widgetWithText(FilledButton, 'Create');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(submitted, {
        'name': 'readyqa',
        'cloneFrom': null,
        'description': 'Physical lifecycle profile',
        'provider': 'openrouter',
        'model': 'openai/gpt-5.2',
        'providerApiKey': 'write-only-secret',
        'idempotencyKey': null,
      });
      expect(find.text('write-only-secret'), findsNothing);
    },
  );

  for (final failure in [
    const _TestHermesStatusException(403),
    const {'approval_id': 'unknown', 'idempotency_key': 'not-authority'},
  ]) {
    testWidgets(
      'create failure clears credential and never replays: $failure',
      (tester) async {
        final channel = FakeHermesChannel();
        addTearDown(channel.dispose);
        final calls = <(String?, String?)>[];
        var saved = 0;
        await tester.pumpWidget(
          _editorTestApp(
            ProfileEditorSheet(
              channel: channel,
              profiles: const [],
              canConfigure: true,
              onSaved: () => saved++,
              onCreate:
                  ({
                    required name,
                    cloneFrom,
                    description,
                    provider,
                    model,
                    providerApiKey,
                    idempotencyKey,
                  }) async {
                    calls.add((providerApiKey, idempotencyKey));
                    if (calls.length == 1) throw failure;
                  },
            ),
          ),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Profile name'),
          'writer',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Provider'),
          'fixture-provider',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Model'),
          'fixture-model',
        );
        final field = find.widgetWithText(
          TextFormField,
          'New provider credential',
        );
        await tester.enterText(field, 'write-only-fixture');
        final create = find.widgetWithText(FilledButton, 'Create');
        await tester.ensureVisible(create);
        await tester.tap(create);
        await tester.pumpAndSettle();
        expect(
          find.text('Hermes could not complete that profile change.'),
          findsOneWidget,
        );
        expect(tester.widget<TextFormField>(field).controller!.text, isEmpty);
        expect(saved, 0);
        await tester.pump(const Duration(minutes: 6));
        expect(calls, [('write-only-fixture', null)]);
        await tester.tap(create);
        await tester.pumpAndSettle();
        expect(calls, [('write-only-fixture', null), (null, null)]);
        expect(saved, 1);
      },
    );
  }

  testWidgets(
    'owner loss clears credential immediately and fences late failure',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      final changes = ValueNotifier<Object>(Object());
      addTearDown(changes.dispose);
      var current = true;
      var writes = 0;
      final gate = Completer<void>();
      await tester.pumpWidget(
        _editorTestApp(
          ProfileEditorSheet(
            channel: channel,
            profiles: const [],
            canConfigure: true,
            ownerChanges: changes,
            isOwnerCurrent: () => current,
            onCreate:
                ({
                  required name,
                  cloneFrom,
                  description,
                  provider,
                  model,
                  providerApiKey,
                  idempotencyKey,
                }) {
                  writes++;
                  return gate.future;
                },
          ),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Profile name'),
        'writer',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Provider'),
        'fixture-provider',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Model'),
        'fixture-model',
      );
      final field = find.widgetWithText(
        TextFormField,
        'New provider credential',
      );
      await tester.enterText(field, 'write-only-fixture');
      final controller = tester.widget<TextFormField>(field).controller!;
      final create = find.widgetWithText(FilledButton, 'Create');
      await tester.ensureVisible(create);
      final staleCreate = tester.widget<FilledButton>(create).onPressed!;
      await tester.tap(create);
      await tester.pump();
      current = false;
      changes.value = Object();
      expect(controller.text, isEmpty);
      // Exercise the previously rendered callback before the next frame.
      staleCreate();
      expect(writes, 1);
      current = true;
      changes.value = Object();
      gate.completeError(const _TestHermesStatusException(403));
      await tester.pumpAndSettle();
      expect(
        find.text('Hermes could not complete that profile change.'),
        findsNothing,
      );
      expect(writes, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancel and dispose clear an in-memory credential', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [],
          stableNames: true,
          canConfigure: true,
          onCancel: () {},
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Profile name'),
      'readyqa',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Provider'),
      'openrouter',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Model'),
      'openai/gpt-5.2',
    );
    final credentialField = find.widgetWithText(
      TextFormField,
      'New provider credential',
    );
    await tester.enterText(credentialField, 'write-only-fixture');
    final credentialController = tester
        .widget<EditableText>(
          find.descendant(
            of: credentialField,
            matching: find.byType(EditableText),
          ),
        )
        .controller;
    final cancel = find.widgetWithText(TextButton, 'Cancel');
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pump();
    expect(credentialController.text, isEmpty);

    await tester.enterText(credentialField, 'discard-on-dispose');
    await tester.pumpWidget(const SizedBox());
    expect(credentialController.text, isEmpty);
  });

  testWidgets('completed save does not touch controllers after disposal', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    final save = Completer<void>();

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [],
          onCreate:
              ({
                required name,
                cloneFrom,
                description,
                provider,
                model,
                providerApiKey,
                idempotencyKey,
              }) => save.future,
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'readyqa');
    await tester.tap(find.text('Create'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    save.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('configured clone can inherit provider and model', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    Map<String, String?>? submitted;

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [
            HermesProfile(
              id: 'link',
              displayName: 'link',
              revision: 'rev-link',
            ),
          ],
          stableNames: true,
          canConfigure: true,
          onCreate:
              ({
                required name,
                cloneFrom,
                description,
                provider,
                model,
                providerApiKey,
                idempotencyKey,
              }) async {
                submitted = {
                  'name': name,
                  'cloneFrom': cloneFrom,
                  'description': description,
                  'provider': provider,
                  'model': model,
                  'providerApiKey': providerApiKey,
                  'idempotencyKey': idempotencyKey,
                };
              },
        ),
      ),
    );

    expect(
      find.textContaining('Leave provider and model blank to inherit them'),
      findsOneWidget,
    );
    expect(
      find.text('Use 1–64 lowercase letters, numbers, _ or -.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Profile name'),
      'device-wing-e2e',
    );
    final createButton = find.widgetWithText(FilledButton, 'Create');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(submitted, {
      'name': 'device-wing-e2e',
      'cloneFrom': 'link',
      'description': '',
      'provider': '',
      'model': '',
      'providerApiKey': null,
      'idempotencyKey': null,
    });
  });

  testWidgets('editing a persona writes the loaded SOUL revision', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: personaCaps(),
      profileSoul: const HermesProfileSoul(soul: 'Be helpful.', revision: 's1'),
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [],
          profile: const HermesProfile(
            id: 'coder',
            displayName: 'Coding Agent',
            revision: 'rev-1',
          ),
          canEditSoul: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(channel.readProfileSoulCalls, ['coder']);
    await tester.enterText(find.byType(TextFormField).last, 'Be terse.');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(channel.writeProfileSoulCalls, [
      {'profileId': 'coder', 'soul': 'Be terse.', 'revision': 's1'},
    ]);
    // The display name was untouched, so no rename was attempted.
    expect(channel.renameProfileCalls, isEmpty);
  });

  testWidgets('stable rename writes changed persona to the new id', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: personaCaps(),
      profileSoul: const HermesProfileSoul(soul: 'Old.', revision: 's1'),
    );
    addTearDown(channel.dispose);
    final renames = <String>[];

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [],
          profile: const HermesProfile(
            id: 'coder',
            displayName: 'coder',
            revision: 'rev-1',
          ),
          stableNames: true,
          canEditSoul: true,
          onRename:
              ({
                required profileId,
                required name,
                required revision,
                description,
                provider,
                model,
                providerApiKey,
              }) async => renames.add('$profileId:$name:$revision'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'renamed');
    await tester.enterText(find.byType(TextFormField).last, 'New.');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(renames, ['coder:renamed:rev-1']);
    expect(channel.writeProfileSoulCalls, [
      {'profileId': 'renamed', 'soul': 'New.', 'revision': 's1'},
    ]);
  });

  testWidgets('a revision conflict surfaces the conflict message', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      renameProfileFails: true,
      profileMutationFailure: const _TestHermesStatusException(412),
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [],
          profile: const HermesProfile(
            id: 'coder',
            displayName: 'Coding Agent',
            revision: 'rev-1',
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Renamed');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('This profile changed elsewhere'),
      findsOneWidget,
    );
  });

  testWidgets('a SOUL revision conflict reloads server content before retry', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: personaCaps(),
      writeProfileSoulFails: true,
      profileMutationFailure: const _TestHermesStatusException(412),
      profileSoul: const HermesProfileSoul(
        soul: 'Server version',
        revision: 'server-rev',
      ),
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [],
          profile: const HermesProfile(
            id: 'coder',
            displayName: 'Coding Agent',
            revision: 'rev-1',
          ),
          canEditSoul: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).last, 'Local version');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(channel.readProfileSoulCalls, ['coder', 'coder']);
    expect(find.text('Server version'), findsOneWidget);
    expect(
      find.textContaining('This profile changed elsewhere'),
      findsOneWidget,
    );
  });

  testWidgets('a non-conflict mutation failure shows the generic message', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      renameProfileFails: true,
      profileMutationFailureMessage: 'stale response dropped',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [],
          profile: const HermesProfile(
            id: 'coder',
            displayName: 'Coding Agent',
            revision: 'rev-1',
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Renamed');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('Hermes could not complete that profile change.'),
      findsOneWidget,
    );
  });

  testWidgets('the default agent shows no delete affordance in the editor', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [],
          profile: const HermesProfile(
            id: 'default',
            displayName: 'Hermes One',
            revision: 'rev-d',
          ),
          canDelete: true,
        ),
      ),
    );

    expect(find.text('The default profile cannot be deleted.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Delete profile'), findsNothing);
  });
}
