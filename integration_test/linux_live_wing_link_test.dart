import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/features/profiles/widgets/catalog_autocomplete_field.dart';
import 'package:wing/l10n/app_localizations.dart';

// Runs only with credentials issued by real local pairing. No service override
// or canned provider response is installed by this test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Linux real Wing Link catalog, discovery and profile UI lifecycle',
    (tester) async {
      final path = Platform.environment['WING_LIVE_LINK_MANIFEST'];
      if (path == null) {
        throw TestFailure('A private live Wing Link manifest is required');
      }
      final data =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final client = WingLinkClient(
        origin: Uri.parse(data['wing_link_origin'] as String),
        token: data['wing_link_token'] as String,
      );
      final channel = HermesApiChannel();
      final name = 'winglinux${DateTime.now().millisecondsSinceEpoch}';
      WingLinkProfile? created;
      var catalogLoaded = false;
      var providerOption = '';
      var modelOption = '';
      var discoveryLoaded = false;
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        debugPrint('Live checkpoint: reading profile inventory');
        final inventory = await client.listProfiles();
        debugPrint('Live checkpoint: inventory loaded');
        expect(inventory.any((p) => p.id == 'default'), isTrue);
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ProfileEditorSheet(
                channel: channel,
                stableNames: true,
                canConfigure: true,
                profiles: [
                  for (final p in inventory)
                    HermesProfile(
                      id: p.id,
                      displayName: p.name,
                      revision: p.revision,
                    ),
                ],
                loadModelOptions: (id) async {
                  debugPrint('Live checkpoint: catalog requested');
                  final catalog = await client
                      .getProfileModelOptions(id)
                      .catchError((Object error) {
                        debugPrint(
                          'Live catalog error type: ${error.runtimeType}',
                        );
                        throw error;
                      });
                  debugPrint(
                    'Live checkpoint: catalog loaded (${catalog.providers.length})',
                  );
                  final withModels = catalog.providers
                      .where((p) => p.models.isNotEmpty)
                      .firstOrNull;
                  providerOption = withModels?.slug ?? '';
                  modelOption = withModels?.models.first ?? '';
                  catalogLoaded = true;
                  return catalog;
                },
                discoverOmniRoute: () async {
                  final status = await client.discoverOmniRoute().catchError((
                    Object error,
                  ) {
                    debugPrint(
                      'Live discovery error type: ${error.runtimeType}',
                    );
                    throw error;
                  });
                  debugPrint('Live checkpoint: discovery loaded');
                  discoveryLoaded = true;
                  return status;
                },
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
                      debugPrint('Live checkpoint: creating profile');
                      created = await client.createProfile(
                        name: name,
                        cloneFrom: cloneFrom,
                        description: description,
                        provider: provider,
                        model: model,
                        providerApiKey: providerApiKey,
                        idempotencyKey: idempotencyKey,
                      );
                    },
              ),
            ),
          ),
        );
        await _until(tester, () => catalogLoaded && discoveryLoaded);
        debugPrint('Live checkpoint: setup data visible');
        expect(providerOption.isNotEmpty && modelOption.isNotEmpty, isTrue);
        final fields = find.byType(CatalogAutocompleteField);
        final providerField = find.descendant(
          of: fields.at(0),
          matching: find.byType(TextFormField),
        );
        final modelField = find.descendant(
          of: fields.at(1),
          matching: find.byType(TextFormField),
        );
        await tester.ensureVisible(providerField);
        await tester.enterText(providerField, providerOption);
        await tester.pump();
        await tester.tap(find.widgetWithText(InkWell, providerOption));
        await tester.pump();
        expect(find.widgetWithText(InkWell, providerOption), findsNothing);
        await tester.ensureVisible(modelField);
        await tester.enterText(modelField, modelOption);
        await tester.pump();
        await tester.tap(find.widgetWithText(InkWell, modelOption));
        await tester.pump();
        expect(find.widgetWithText(InkWell, modelOption), findsNothing);
        expect(
          tester.widget<TextFormField>(modelField).controller!.text ==
              modelOption,
          isTrue,
        );
        // This lifecycle clones the working configuration. Selecting another
        // catalog entry above exercises suggestions without provisioning a
        // different external provider or pretending its credentials exist.
        await tester.enterText(providerField, '');
        await tester.pump();
        expect(
          tester.widget<TextFormField>(modelField).controller!.text.isEmpty,
          isTrue,
        );
        debugPrint('Live checkpoint: provider and model suggestions selected');
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Profile name'),
          name,
        );
        final create = find.widgetWithText(FilledButton, 'Create');
        await tester.ensureVisible(create);
        await tester.tap(create);
        await _until(tester, () => created != null);
        expect((await client.listProfiles()).any((p) => p.id == name), isTrue);
        final renamed = await client.renameProfile(
          id: name,
          name: '${name}r',
          revision: created!.renameRevision ?? created!.revision,
        );
        created = renamed;
        expect(
          (await client.listProfiles()).any((p) => p.id == renamed.id),
          isTrue,
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        if (created != null) {
          final row = (await client.listProfiles()).singleWhere(
            (p) => p.id == created!.id,
          );
          Future<void> remove(String? key) => client.deleteProfile(
            id: row.id,
            revision: row.deleteRevision ?? row.revision,
            idempotencyKey: key,
          );
          try {
            await remove(null);
          } on WingLinkApprovalRequired catch (approval) {
            final binary = Platform.environment['WING_LIVE_LINK_BINARY'];
            final state = Platform.environment['WING_LINK_STATE'];
            if (binary == null || state == null) {
              throw TestFailure('Local deletion approval is required');
            }
            final result = await Process.run(
              binary,
              ['approvals', 'approve', approval.approvalId],
              environment: {'WING_LINK_STATE': state},
            );
            if (result.exitCode != 0) {
              throw TestFailure('Local deletion approval failed');
            }
            await remove(approval.idempotencyKey);
          }
          expect(
            (await client.listProfiles()).any((p) => p.id == row.id),
            isFalse,
          );
        }
        channel.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('Live UI operation timed out');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  await tester.pump();
}
