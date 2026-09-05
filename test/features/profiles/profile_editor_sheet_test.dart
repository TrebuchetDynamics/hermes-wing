import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

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

  testWidgets('delete retains host approval for an explicit retry', (
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
            if (requests.length > 1) return;
            throw WingLinkApprovalRequired(
              approvalId: 'appr_delete_cycle',
              operationId: 'op_delete_cycle',
              idempotencyKey: 'delete-cycle-key',
              expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300,
            );
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
      find.textContaining('wing-link approvals approve appr_delete_cycle'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
      isFalse,
    );
    await tester.ensureVisible(find.text('Retry approved deletion'));
    await tester.tap(find.text('Retry approved deletion'));
    await tester.pumpAndSettle();
    expect(requests, [
      ('cycle', 'rev-1', null),
      ('cycle', 'rev-1', 'delete-cycle-key'),
    ]);
    expect(channel.deleteProfileCalls, isEmpty);
    await tester.pumpWidget(const SizedBox());
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

  testWidgets(
    'approval retry preserves the exact frozen request and idempotency key',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      final calls = <Map<String, String?>>[];
      final expiresAt =
          DateTime.now()
              .add(const Duration(minutes: 1))
              .millisecondsSinceEpoch ~/
          1000;

      await tester.pumpWidget(
        _editorTestApp(
          ProfileEditorSheet(
            channel: channel,
            profiles: const [],
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
                  calls.add({
                    'name': name,
                    'cloneFrom': cloneFrom,
                    'description': description,
                    'provider': provider,
                    'model': model,
                    'providerApiKey': providerApiKey,
                    'idempotencyKey': idempotencyKey,
                  });
                  if (calls.length == 1) {
                    throw WingLinkApprovalRequired(
                      approvalId: 'apr_local_test',
                      operationId: 'op_local_test',
                      idempotencyKey: 'profile-mutation-approved-key',
                      expiresAt: expiresAt,
                    );
                  }
                },
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
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New provider credential'),
        'write-only-fixture',
      );
      final create = find.widgetWithText(FilledButton, 'Create');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pump();

      expect(find.textContaining('Wing Link host'), findsOneWidget);
      expect(find.textContaining('wing-link approvals list'), findsOneWidget);
      expect(
        find.textContaining('wing-link approvals approve apr_local_test'),
        findsOneWidget,
      );
      expect(find.text('Retry approved setup'), findsOneWidget);
      expect(find.text('Cancel setup'), findsOneWidget);
      expect(find.widgetWithText(Text, 'write-only-fixture'), findsNothing);
      for (final field in tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      )) {
        expect(field.enabled, isFalse);
      }

      final retry = find.text('Retry approved setup');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(calls, hasLength(2));
      expect(calls.first['idempotencyKey'], isNull);
      expect(
        calls.last,
        equals({
          ...calls.first,
          'idempotencyKey': 'profile-mutation-approved-key',
        }),
      );
      expect(calls.last['providerApiKey'], 'write-only-fixture');
      expect(find.text('write-only-fixture'), findsNothing);
      final credential = tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'New provider credential'),
          matching: find.byType(EditableText),
        ),
      );
      expect(credential.controller.text, isEmpty);
    },
  );

  testWidgets('expired approval clears the retained credential', (
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
          onCreate:
              ({
                required name,
                cloneFrom,
                description,
                provider,
                model,
                providerApiKey,
                idempotencyKey,
              }) async => throw WingLinkApprovalRequired(
                approvalId: 'apr_expired',
                operationId: 'op_expired',
                idempotencyKey: 'profile-mutation-expired-key',
                expiresAt:
                    DateTime.now()
                        .add(const Duration(seconds: 2))
                        .millisecondsSinceEpoch ~/
                    1000,
              ),
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
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New provider credential'),
      'write-only-fixture',
    );
    final create = find.widgetWithText(FilledButton, 'Create');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pump();

    final credential = tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'New provider credential'),
        matching: find.byType(EditableText),
      ),
    );
    expect(credential.controller.text, 'write-only-fixture');
    expect(find.text('Retry approved setup'), findsOneWidget);
    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.enabled, isFalse);
    }

    await tester.pump(const Duration(seconds: 3));

    expect(find.textContaining('approval expired'), findsOneWidget);
    expect(credential.controller.text, isEmpty);
    expect(find.text('Retry approved setup'), findsNothing);
  });

  testWidgets('cancel and dispose clear an in-memory credential', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    Future<void> approvalRequired({
      required String name,
      String? cloneFrom,
      String? description,
      String? provider,
      String? model,
      String? providerApiKey,
      String? idempotencyKey,
    }) async => throw WingLinkApprovalRequired(
      approvalId: 'appr_cancel',
      operationId: 'op_cancel',
      idempotencyKey: 'profile-mutation-cancel-key',
      expiresAt:
          DateTime.now()
              .add(const Duration(minutes: 1))
              .millisecondsSinceEpoch ~/
          1000,
    );

    await tester.pumpWidget(
      _editorTestApp(
        ProfileEditorSheet(
          channel: channel,
          profiles: const [],
          stableNames: true,
          canConfigure: true,
          onCreate: approvalRequired,
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
    final create = find.widgetWithText(FilledButton, 'Create');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pump();
    final cancel = find.text('Cancel setup');
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
