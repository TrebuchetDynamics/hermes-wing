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

    await tester.tap(find.text('Delete agent'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Coding Agent?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Coding Agent');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete agent'));
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
    expect(find.text('Enter an agent name.'), findsOneWidget);

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

    expect(find.textContaining('This agent changed elsewhere'), findsOneWidget);
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

    expect(find.text('The default agent cannot be deleted.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Delete agent'), findsNothing);
  });
}
