import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/profiles/screens/profiles_screen.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

const _profile = HermesProfile(
  id: 'coder',
  displayName: 'Coder',
  revision: 'r1',
);
HermesCapabilityDocument _caps({bool write = true}) =>
    HermesCapabilityDocument.fromJson({
      'schema_version': 1,
      'auth': {
        'type': 'bearer',
        'granted_scopes': ['profiles:read', if (write) 'profiles:write'],
      },
      'endpoints': {
        'profiles': {
          'method': 'GET',
          'path': '/api/profiles',
          'required_scopes': ['profiles:read'],
        },
        for (final operation in [
          ('profile_create', 'POST', '/api/profiles'),
          ('profile_update', 'PATCH', '/api/profiles/{name}'),
          ('profile_delete', 'DELETE', '/api/profiles/{name}'),
        ])
          operation.$1: {
            'method': operation.$2,
            'path': operation.$3,
            'required_scopes': ['profiles:write'],
          },
      },
    });

class _HeldChannel extends FakeHermesChannel {
  _HeldChannel() : super(capabilities: _caps(), profiles: const [_profile]);
  final gate = Completer<void>();
  final writes = <String>[];
  @override
  Future<void> createProfile({required String name, String? cloneFrom}) async {
    writes.add('create:$name:$cloneFrom');
    await gate.future;
  }

  @override
  Future<void> renameProfile({
    required String profileId,
    required String name,
    required String revision,
  }) async {
    writes.add('rename:$profileId:$name:$revision');
    await gate.future;
  }

  @override
  Future<void> deleteProfile({
    required String profileId,
    required String revision,
  }) async {
    writes.add('delete:$profileId:$revision');
    await gate.future;
  }
}

final _directoryOwner = Provider<HermesGatewayDirectory>(
  (ref) => throw StateError('Test owner required'),
);

void main() {
  for (final action in ['create', 'rename', 'delete']) {
    for (final transition in [
      'host',
      'roundtrip',
      'authority',
      'channel',
      'directory',
      'dispose',
    ]) {
      for (final submitted in [false, true]) {
        testWidgets(
          '$action ${submitted ? 'late completion' : 'cached control'} is fenced by $transition',
          (tester) async {
            final channel = _HeldChannel();
            final replacement = FakeHermesChannel(
              capabilities: _caps(),
              profiles: const [_profile],
            );
            addTearDown(channel.dispose);
            addTearDown(replacement.dispose);
            HermesGatewayDirectory directory() => directoryFor(
              configs: const [
                HermesEndpointConfig(id: 'A', baseUrl: 'https://a.example'),
                HermesEndpointConfig(id: 'B', baseUrl: 'https://b.example'),
              ],
              loader: FakeGatewaySummaryLoader({
                'A': gatewaySummary(['coder']),
                'B': gatewaySummary(['coder']),
              }),
              activeChannel: channel,
            );
            final owner = directory();
            await owner.refresh();
            await owner.activateGateway('A');
            channel.replaceCapabilitiesAndProfiles(_caps(), const [_profile]);
            final container = ProviderContainer(
              overrides: [
                hermesChannelProvider.overrideWithValue(channel),
                _directoryOwner.overrideWithValue(owner),
                hermesGatewayDirectoryProvider.overrideWith(
                  (ref) => ref.watch(_directoryOwner),
                ),
              ],
            );
            addTearDown(container.dispose);
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: const ProfilesScreen(),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final open = tester
                .widget<ButtonStyleButton>(
                  action == 'create'
                      ? find.widgetWithText(FilledButton, 'New Profile')
                      : find.widgetWithText(OutlinedButton, 'Edit'),
                )
                .onPressed!;
            open();
            await tester.pumpAndSettle();
            VoidCallback? deleteControl;
            if (action != 'delete') {
              await tester.enterText(
                find.widgetWithText(TextFormField, 'Profile name'),
                'Changed',
              );
            } else {
              deleteControl = tester
                  .widget<TextButton>(
                    find.widgetWithText(TextButton, 'Delete profile').last,
                  )
                  .onPressed;
              await tester.tap(
                find.widgetWithText(TextButton, 'Delete profile').last,
              );
              await tester.pumpAndSettle();
              await tester.enterText(
                find.descendant(
                  of: find.byType(AlertDialog),
                  matching: find.byType(TextField),
                ),
                'Coder',
              );
              await tester.pump();
            }
            final submit = tester
                .widget<FilledButton>(
                  find.widgetWithText(
                    FilledButton,
                    action == 'create'
                        ? 'Create'
                        : action == 'rename'
                        ? 'Save'
                        : 'Delete profile',
                  ),
                )
                .onPressed!;
            if (submitted) {
              submit();
              await tester.pump();
              await tester.pump();
              expect(channel.writes, hasLength(1));
            }
            switch (transition) {
              case 'host':
                owner.selectManagementGateway('B');
              case 'roundtrip':
                owner.selectManagementGateway('B');
                owner.selectManagementGateway('A');
              case 'authority':
                channel.replaceCapabilitiesAndProfiles(
                  _caps(write: false),
                  const [_profile],
                );
                channel.replaceCapabilitiesAndProfiles(_caps(), const [
                  _profile,
                ]);
              case 'channel':
                container.updateOverrides([
                  hermesChannelProvider.overrideWithValue(replacement),
                  _directoryOwner.overrideWithValue(owner),
                  hermesGatewayDirectoryProvider.overrideWith(
                    (ref) => ref.watch(_directoryOwner),
                  ),
                ]);
              case 'directory':
                final next = directory();
                await next.refresh();
                container.updateOverrides([
                  hermesChannelProvider.overrideWithValue(channel),
                  _directoryOwner.overrideWithValue(next),
                  hermesGatewayDirectoryProvider.overrideWith(
                    (ref) => ref.watch(_directoryOwner),
                  ),
                ]);
              case 'dispose':
                await tester.pumpWidget(const SizedBox());
            }
            if (!submitted) {
              // Invoke cached public controls before the replacement frame.
              if (transition == 'dispose' && action == 'delete') {
                deleteControl!();
              } else {
                submit();
              }
              open();
            } else {
              channel.gate.complete();
            }
            await tester.pumpAndSettle();
            expect(
              channel.writes,
              submitted
                  ? [
                      action == 'create'
                          ? 'create:Changed:coder'
                          : action == 'rename'
                          ? 'rename:coder:Changed:r1'
                          : 'delete:coder:r1',
                    ]
                  : isEmpty,
            );
            expect(replacement.createProfileCalls, isEmpty);
            expect(replacement.renameProfileCalls, isEmpty);
            expect(replacement.deleteProfileCalls, isEmpty);
            if (transition != 'dispose') {
              expect(find.byType(ProfileEditorSheet), findsOneWidget);
            }
            expect(find.textContaining('could not complete'), findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
