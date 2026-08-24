import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

Widget _editorTestApp(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
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
                }) async {
                  submitted = {
                    'name': name,
                    'cloneFrom': cloneFrom,
                    'description': description,
                    'provider': provider,
                    'model': model,
                    'providerApiKey': providerApiKey,
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
      });
      expect(find.text('write-only-secret'), findsNothing);
    },
  );

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
              }) async {
                submitted = {
                  'name': name,
                  'cloneFrom': cloneFrom,
                  'description': description,
                  'provider': provider,
                  'model': model,
                  'providerApiKey': providerApiKey,
                };
              },
        ),
      ),
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
    });
  });

  testWidgets('editing a persona writes the loaded SOUL revision', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
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
    final channel = FakeHermesChannel(renameProfileFails: true);
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
