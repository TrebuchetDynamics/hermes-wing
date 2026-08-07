import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/features/agents/widgets/profile_editor_sheet.dart';
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
          onRename: (id, name, revision) async =>
              renames.add('$id:$name:$revision'),
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
