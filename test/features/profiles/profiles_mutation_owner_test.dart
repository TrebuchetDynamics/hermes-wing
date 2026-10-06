import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/profiles/screens/profiles_screen.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

HermesEndpointConfig _host(String id, {bool enrolled = true}) =>
    HermesEndpointConfig(
      id: id,
      label: id,
      baseUrl: 'http://localhost:8642/p/default',
      wingLinkOrigin: 'http://localhost:${id == 'A' ? 8654 : 8655}',
      wingLinkToken: enrolled ? 'synthetic-only' : null,
    );
Map<String, Object?> _row(String name) => {
  'id': 'coder',
  'name': name,
  'topology_revision': 't1',
  'source': 'cli',
  'gateway_state': 'stopped',
  'actions': {
    'rename': {'revision': 'r-coder'},
    'delete': {'revision': 'd-coder'},
  },
};
String _inventory(String host) => jsonEncode({
  'profiles': [_row('$host Coder')],
});
String _renamed() => jsonEncode({
  'profile': {..._row('renamed'), 'id': 'renamed'},
});

final _directoryOwnerProvider = Provider<HermesGatewayDirectory>(
  (ref) => throw StateError('Deterministic directory owner required'),
);

class _Harness {
  FakeHermesChannel channel = FakeHermesChannel(
    status: HermesConnectionStatus.disconnected,
  );
  late HermesGatewayDirectory directory;
  late FakeGatewaySummaryLoader loader;
  late ProviderContainer container;
  late WingLinkClientBuilder builder;
  bool enrolled = true;
  final reads = <String>[];
  final writes = <Map<String, Object?>>[];
  Future<String> Function(String action)? settle;
  bool denyReads = false;

  void replace({
    FakeHermesChannel? channelOwner,
    HermesGatewayDirectory? directoryOwner,
  }) {
    container.updateOverrides([
      hermesChannelProvider.overrideWithValue(channelOwner ?? channel),
      _directoryOwnerProvider.overrideWithValue(directoryOwner ?? directory),
      hermesGatewayDirectoryProvider.overrideWith(
        (ref) => ref.watch(_directoryOwnerProvider),
      ),
      wingLinkClientBuilderProvider.overrideWithValue(builder),
    ]);
  }

  WingLinkClientBuilder factory() =>
      ({required origin, required token, required hostFingerprint}) {
        final host = origin.port == 8654 ? 'A' : 'B';
        return WingLinkClient(
          origin: origin,
          token: token,
          get: (uri, headers) async {
            expect(uri.path, '/v1/profiles');
            reads.add(host);
            if (denyReads) throw const WingLinkHttpException(403);
            return _inventory(host);
          },
          patch: (uri, headers, body) {
            writes.add({
              'host': host,
              'action': 'rename',
              'path': uri.path,
              'body': jsonDecode(body),
            });
            return settle?.call('rename') ?? Future.value(_renamed());
          },
          delete: (uri, headers) {
            writes.add({
              'host': host,
              'action': 'delete',
              'path': uri.path,
              'revision': headers['If-Match'],
              'key': headers['Idempotency-Key'],
            });
            return settle?.call('delete') ?? Future.value('');
          },
        );
      };

  Future<void> mount(WidgetTester tester) async {
    loader = FakeGatewaySummaryLoader({
      'A': gatewaySummary([]),
      'B': gatewaySummary([]),
    });
    directory = HermesGatewayDirectory(
      store: FakeHermesEndpointStore(
        onLoadProfiles: () async => [
          _host('A', enrolled: enrolled),
          _host('B'),
        ],
      ),
      cache: FakeGatewayContactCache(),
      loader: loader,
      activeChannel: channel,
    );
    await directory.refresh();
    builder = factory();
    container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        _directoryOwnerProvider.overrideWithValue(directory),
        hermesGatewayDirectoryProvider.overrideWith(
          (ref) => ref.watch(_directoryOwnerProvider),
        ),
        wingLinkClientBuilderProvider.overrideWithValue(builder),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() => channel.dispose());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfilesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A Coder'), findsOneWidget);
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileEditorSheet), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Profile name'),
      'renamed',
    );
  }

  Future<void> confirm(WidgetTester tester, {bool submit = true}) async {
    final delete = find.descendant(
      of: find.byType(ProfileEditorSheet),
      matching: find.widgetWithText(TextButton, 'Delete profile'),
    );
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'A Coder',
    );
    await tester.pump();
    if (submit) {
      await tester.tap(find.widgetWithText(FilledButton, 'Delete profile'));
      await tester.pump();
      await tester.pump();
    }
  }
}

void main() {
  for (final replace in ['channel', 'directory', 'factory']) {
    testWidgets('cached rename rejects $replace replacement before a frame', (
      tester,
    ) async {
      final h = _Harness();
      await h.mount(tester);
      await h.open(tester);
      final editor = tester.widget<ProfileEditorSheet>(
        find.byType(ProfileEditorSheet),
      );
      if (replace == 'channel') {
        final replacement = FakeHermesChannel(
          status: HermesConnectionStatus.disconnected,
        );
        addTearDown(replacement.dispose);
        h.replace(channelOwner: replacement);
      } else if (replace == 'directory') {
        final replacement = directoryFor(
          configs: [_host('A'), _host('B')],
          loader: FakeGatewaySummaryLoader({
            'A': gatewaySummary([]),
            'B': gatewaySummary([]),
          }),
          activeChannel: h.channel,
        );
        await replacement.refresh();
        h.replace(directoryOwner: replacement);
      } else {
        h.builder = h.factory();
        h.replace();
      }
      await editor.onRename!(
        profileId: 'coder',
        name: 'renamed',
        revision: 't1',
      );
      expect(h.writes, isEmpty);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  for (final action in ['rename', 'delete']) {
    testWidgets(
      '$action authority denial discards pending UI and denies cached retry',
      (tester) async {
        final h = _Harness();
        await h.mount(tester);
        await h.open(tester);
        final save = tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed!;
        h.denyReads = true;
        h.settle = (_) async => throw const WingLinkHttpException(412);
        if (action == 'rename') {
          save();
        } else {
          await h.confirm(tester);
        }
        await tester.pumpAndSettle();
        expect(h.writes, hasLength(1));
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
              .onPressed,
          isNotNull,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        save();
        await tester.pumpAndSettle();
        expect(h.writes, hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('same-owner $action conflict permits exact explicit retry', (
      tester,
    ) async {
      final h = _Harness();
      h.settle = (_) async {
        if (h.writes.length == 1) throw const WingLinkHttpException(412);
        return action == 'rename' ? _renamed() : '';
      };
      await h.mount(tester);
      await h.open(tester);
      if (action == 'rename') {
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      } else {
        await h.confirm(tester);
      }
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This profile changed elsewhere'),
        findsOneWidget,
      );
      expect(h.writes, hasLength(1));
      if (action == 'rename') {
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      } else {
        await h.confirm(tester);
      }
      await tester.pumpAndSettle();
      expect(h.writes, hasLength(2));
      expect(
        h.writes.every(
          (w) => w['host'] == 'A' && w['path'] == '/v1/profiles/coder',
        ),
        isTrue,
      );
      if (action == 'rename') {
        expect(h.writes.last['body'], {
          'name': 'renamed',
          'revision': 'r-coder',
        });
      } else {
        expect(h.writes.last['revision'], 'd-coder');
        expect(h.writes.last['key'], isNot(h.writes.first['key']));
      }
      expect(find.byType(ProfileEditorSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  for (final transition in [
    'B',
    'A-B-A',
    'same-frame',
    'factory',
    'channel',
    'directory',
    'enrollment',
  ]) {
    for (final action in ['rename', 'delete']) {
      testWidgets('$action cached intent is fenced after $transition', (
        tester,
      ) async {
        final h = _Harness();
        await h.mount(tester);
        final oldOpen = tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Edit'))
            .onPressed!;
        await h.open(tester);
        final oldEditor = tester.widget<ProfileEditorSheet>(
          find.byType(ProfileEditorSheet),
        );
        final oldSave = tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed!;
        if (action == 'delete') await h.confirm(tester, submit: false);
        switch (transition) {
          case 'B':
            h.directory.selectManagementGateway('B');
          case 'A-B-A':
            h.directory.selectManagementGateway('B');
            await tester.pumpAndSettle();
            h.directory.selectManagementGateway('A');
          case 'same-frame':
            h.directory.selectManagementGateway('B');
            h.directory.selectManagementGateway('A');
          case 'factory':
            h.builder = h.factory();
            h.replace();
          case 'channel':
            final replacement = FakeHermesChannel(
              status: HermesConnectionStatus.disconnected,
            );
            addTearDown(replacement.dispose);
            h.replace(channelOwner: replacement);
          case 'directory':
            final replacement = directoryFor(
              configs: [_host('A'), _host('B')],
              loader: FakeGatewaySummaryLoader({
                'A': gatewaySummary([]),
                'B': gatewaySummary([]),
              }),
              activeChannel: h.channel,
            );
            await replacement.refresh();
            h.replace(directoryOwner: replacement);
            expect(
              h.container.read(hermesGatewayDirectoryProvider),
              same(replacement),
            );
          case 'enrollment':
            h.enrolled = false;
            await h.directory.refresh();
        }
        await tester.pumpAndSettle();
        if (action == 'delete') {
          await tester.tap(find.widgetWithText(FilledButton, 'Delete profile'));
          await tester.pumpAndSettle();
          await oldEditor.onDelete!(
            'coder',
            't1',
            idempotencyKey: 'obsolete-key',
          );
        } else {
          oldSave();
          await oldEditor.onRename!(
            profileId: 'coder',
            name: 'renamed',
            revision: 't1',
          );
        }
        oldOpen();
        await tester.pumpAndSettle();
        expect(h.writes, isEmpty);
        expect(find.byType(ProfileEditorSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final action in ['rename', 'delete']) {
    for (final outcome in ['success', 'failure', 'conflict', 'approval']) {
      testWidgets(
        'delayed $action $outcome has no obsolete follow-on effects',
        (tester) async {
          final h = _Harness();
          final gate = Completer<String>();
          h.settle = (_) => gate.future;
          await h.mount(tester);
          await h.open(tester);
          if (action == 'rename') {
            await tester.tap(find.widgetWithText(FilledButton, 'Save'));
            await tester.pump();
          } else {
            await h.confirm(tester);
          }
          expect(h.writes, hasLength(1));
          expect(h.writes.single['host'], 'A');
          h.directory.selectManagementGateway('B');
          await tester.pumpAndSettle();
          final readsBefore = List<String>.of(h.reads);
          final loaderCallsBefore = List<String>.of(h.loader.calls);
          switch (outcome) {
            case 'success':
              gate.complete(action == 'rename' ? _renamed() : '');
            case 'failure':
              gate.completeError(StateError('synthetic failure'));
            case 'conflict':
              gate.completeError(const WingLinkHttpException(412));
            case 'approval':
              gate.completeError(
                WingLinkApprovalRequired(
                  approvalId: 'appr_synthetic',
                  operationId: 'op_synthetic',
                  idempotencyKey: 'synthetic-key',
                  expiresAt:
                      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300,
                ),
              );
          }
          await tester.pumpAndSettle();
          expect(h.writes, hasLength(1));
          expect(h.reads, readsBefore);
          expect(h.loader.calls, loaderCallsBefore);
          expect(h.directory.managementGatewayId, 'B');
          expect(find.byType(ProfileEditorSheet), findsOneWidget);
          expect(find.textContaining('could not complete'), findsNothing);
          expect(find.textContaining('changed elsewhere'), findsNothing);
          expect(
            find.textContaining('wing-link approvals approve'),
            findsNothing,
          );
          expect(h.channel.connectCalls, isEmpty);
          expect(h.channel.renameProfileCalls, isEmpty);
          expect(h.channel.deleteProfileCalls, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final action in ['rename', 'delete']) {
    testWidgets(
      'disposed route rejects cached $action and delayed settlement',
      (tester) async {
        final h = _Harness();
        final gate = Completer<String>();
        h.settle = (_) => gate.future;
        await h.mount(tester);
        await h.open(tester);
        final editor = tester.widget<ProfileEditorSheet>(
          find.byType(ProfileEditorSheet),
        );
        if (action == 'rename') {
          await tester.tap(find.widgetWithText(FilledButton, 'Save'));
          await tester.pump();
        } else {
          await h.confirm(tester);
        }
        await tester.pumpWidget(const SizedBox());
        final readsBefore = List<String>.of(h.reads);
        await editor.onRename!(
          profileId: 'coder',
          name: 'renamed',
          revision: 't1',
        );
        await editor.onDelete!('coder', 't1');
        gate.complete(action == 'rename' ? _renamed() : '');
        await tester.pumpAndSettle();
        expect(h.writes, hasLength(1));
        expect(h.reads, readsBefore);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final changed in [false, true]) {
    testWidgets(
      'pending delete approval ${changed ? 'invalidated' : 'retries exact intent'}',
      (tester) async {
        final h = _Harness();
        h.settle = (_) async {
          if (h.writes.length > 1) return '';
          throw WingLinkApprovalRequired(
            approvalId: 'appr_synthetic',
            operationId: 'op_synthetic',
            idempotencyKey: h.writes.single['key']! as String,
            expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300,
          );
        };
        await h.mount(tester);
        await h.open(tester);
        await h.confirm(tester);
        expect(find.text('Retry approved deletion'), findsOneWidget);
        final retry = tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Retry approved deletion'),
            )
            .onPressed!;
        if (changed) {
          h.directory.selectManagementGateway('B');
          h.directory.selectManagementGateway('A');
          await tester.pumpAndSettle();
          expect(find.text('Retry approved deletion'), findsNothing);
        }
        retry();
        await tester.pumpAndSettle();
        expect(h.writes, hasLength(changed ? 1 : 2));
        final first = h.writes.first;
        expect(first['host'], 'A');
        expect(first['path'], '/v1/profiles/coder');
        expect(first['revision'], 'd-coder');
        if (!changed) expect(h.writes.last, first);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('obsolete delete confirmation cannot settle or submit', (
    tester,
  ) async {
    final h = _Harness();
    await h.mount(tester);
    await h.open(tester);
    await h.confirm(tester, submit: false);
    h.directory.selectManagementGateway('B');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete profile'));
    await tester.pumpAndSettle();
    expect(h.writes, isEmpty);
    expect(find.byType(ProfileEditorSheet), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('obsolete A rename editor cannot submit through B client', (
    tester,
  ) async {
    final h = _Harness();
    await h.mount(tester);
    await h.open(tester);
    h.directory.selectManagementGateway('B');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(h.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
