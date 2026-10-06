import 'dart:async';
import 'dart:convert';
import 'dart:ui' show SemanticsRole, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';

import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../profiles/profile_persona_ownership_test.dart'
    show personaCapabilityJson, Conflict;

const _initial = '\n\t Inert original café 東京. \n\n';
const _draft = '\n\t Inert draft 🪽 e\u0301.\n  Padded line. \t\n\n';
final _field = find.byType(TextFormField).last;
final _cancel = find.widgetWithText(TextButton, 'Cancel');
final _save = find.widgetWithText(FilledButton, 'Save');

// Real production channel/client, directory and router; only transport is inert.
class _Fixture {
  String document = _initial;
  String revision = 'r1';
  final reads = <Uri>[];
  final writes = <Map<String, Object?>>[];
  Completer<String>? readGate;
  Completer<String>? writeGate;
  late final channel = HermesApiChannel(
    clientBuilder: (config) => HermesApiClient(
      config: config,
      get: (uri, _) async {
        reads.add(uri);
        if (uri.path == '/api/profiles/coder/soul') {
          return readGate?.future ??
              jsonEncode({'soul': document, 'revision': revision});
        }
        return switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => jsonEncode(personaCapabilityJson()),
          '/api/profiles' =>
            '{"data":[{"id":"coder","name":"Coder","revision":"p1"}]}',
          '/api/sessions' => '{"data":[]}',
          _ => throw StateError('Unexpected deterministic read'),
        };
      },
      put: (uri, headers, body) async {
        writes.add({
          'origin': uri.origin,
          'path': uri.path,
          'query': uri.queryParameters,
          'revision': headers['If-Match'],
          'body': jsonDecode(body),
        });
        if (writeGate != null) return writeGate!.future;
        document = (jsonDecode(body) as Map<String, dynamic>)['soul'] as String;
        revision = revision == 'r2' ? 'r3' : 'r2';
        return jsonEncode({'soul': document, 'revision': revision});
      },
      post: (_, _, _) => throw StateError('Unexpected mutation'),
    ),
  );
  late ProviderContainer container;
  late GoRouter router;
  Object? owner;

  Future<void> open(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await channel.connect(baseUrl: 'http://localhost:8642');
    await channel.selectProfile('coder');
    container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(
          FakeHermesEndpointStore(profiles: const []),
        ),
      ],
    );
    router = container.read(routerProvider)..go('/soul');
    addTearDown(channel.dispose);
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
      ),
    );
    if (readGate == null) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
    owner = currentOwner;
    expect(router.canPop(), isFalse);
  }

  Object get currentOwner {
    final state = channel.state;
    final directory = container.read(hermesGatewayDirectoryProvider);
    return (
      state.selectedProfileId,
      state.activeSessionId,
      state.modelInventory?.assignment.activeProvider,
      state.modelInventory?.assignment.activeModel,
      state.status,
      directory.managementGatewayId,
      directory.activeContactId,
    );
  }

  String text(WidgetTester tester) =>
      tester.widget<TextFormField>(_field).controller!.text;
  void expectProfiles() {
    expect(router.routeInformationProvider.value.uri.path, '/profiles');
    expect(find.byType(ProfileEditorSheet), findsNothing);
    expect(currentOwner, owner);
  }

  Future<void> reopen(WidgetTester tester) async {
    router.go('/soul');
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final width in [390.0, 1280.0]) {
    for (final conflict in [false, true]) {
      testWidgets(
        'actual router Persona rejected write conflict=$conflict stays open until explicit retry at $width / 200%',
        (tester) async {
          final f = _Fixture();
          await f.open(tester, width);
          await tester.enterText(_field, _draft);
          final gate = Completer<String>();
          f.writeGate = gate;
          await tester.tap(_save);
          await tester.pump();
          if (conflict) {
            f.document = '\n  Newer authoritative café. \n\n';
            f.revision = 'r2';
            gate.completeError(Conflict());
          } else {
            gate.completeError(StateError('synthetic private failure'));
          }
          await tester.pumpAndSettle();
          expect(f.router.routeInformationProvider.value.uri.path, '/soul');
          expect(f.text(tester), conflict ? f.document : _draft);
          expect(f.writes, hasLength(1));
          expect(find.textContaining('synthetic private'), findsNothing);
          expect(
            find.textContaining(
              conflict ? 'changed elsewhere' : 'could not complete',
            ),
            findsOneWidget,
          );
          if (conflict) await tester.enterText(_field, _draft);
          f.writeGate = null;
          await tester.tap(_save);
          await tester.pumpAndSettle();
          f.expectProfiles();
          expect(
            f.writes.map((w) => w['revision']),
            conflict ? ['r1', 'r2'] : ['r1', 'r1'],
          );
          await f.reopen(tester);
          expect(f.text(tester), _draft);
          expect(f.writes, hasLength(2));
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      'actual router unchanged Persona save completes without write at $width / 200%',
      (tester) async {
        final f = _Fixture();
        await f.open(tester, width);
        await tester.tap(_save);
        await tester.pumpAndSettle();
        f.expectProfiles();
        await f.reopen(tester);
        expect(f.text(tester), _initial);
        expect(f.writes, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
    for (final failure in [false, true]) {
      testWidgets(
        'actual router cancelled pending Persona read late failure=$failure at $width / 200%',
        (tester) async {
          final gate = Completer<String>();
          final f = _Fixture()..readGate = gate;
          await f.open(tester, width);
          await tester.tap(_cancel);
          await tester.pumpAndSettle();
          f.expectProfiles();
          if (failure) {
            gate.completeError(StateError('synthetic private failure'));
          } else {
            gate.complete(
              jsonEncode({'soul': 'Stale read', 'revision': 'old'}),
            );
          }
          await tester.pumpAndSettle();
          f.expectProfiles();
          f.readGate = null;
          await f.reopen(tester);
          expect(f.text(tester), _initial);
          expect(f.writes, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final outcome in ['success', 'failure', 'conflict']) {
      testWidgets(
        'actual router stale Persona write $outcome cannot complete newer owner at $width / 200%',
        (tester) async {
          final f = _Fixture();
          await f.open(tester, width);
          await tester.enterText(_field, _draft);
          f.writeGate = Completer<String>();
          await tester.tap(_save);
          await tester.pump();
          await f.channel.connect(baseUrl: 'http://127.0.0.1:8643');
          await f.channel.selectProfile('coder');
          f.document = 'New owner';
          await tester.pumpAndSettle();
          await tester.enterText(_field, 'New owner draft');
          final count = f.reads.length;
          switch (outcome) {
            case 'success':
              f.writeGate!.complete(
                jsonEncode({'soul': _draft, 'revision': 'old-saved'}),
              );
            case 'failure':
              f.writeGate!.completeError(
                StateError('synthetic private failure'),
              );
            case 'conflict':
              f.writeGate!.completeError(Conflict());
          }
          await tester.pumpAndSettle();
          expect(f.router.routeInformationProvider.value.uri.path, '/soul');
          expect(f.text(tester), 'New owner draft');
          expect(f.reads.length, count);
          expect(f.writes, hasLength(1));
          expect(f.writes.single['origin'], 'http://localhost:8642');
          expect(find.textContaining('changed elsewhere'), findsNothing);
          expect(find.textContaining('could not complete'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final action in ['Cancel', 'Save']) {
      testWidgets(
        'actual Profiles modal $action dismisses only modal at $width / 200%',
        (tester) async {
          final f = _Fixture();
          await f.open(tester, width);
          f.router.go('/profiles');
          await tester.pumpAndSettle();
          final edit = find.widgetWithText(OutlinedButton, 'Edit');
          await tester.ensureVisible(edit);
          await tester.tap(edit);
          await tester.pumpAndSettle();
          expect(find.byType(ProfileEditorSheet), findsOneWidget);
          await tester.enterText(_field, _draft);
          await tester.tap(action == 'Cancel' ? _cancel : _save);
          await tester.pumpAndSettle();
          f.expectProfiles();
          expect(f.writes, hasLength(action == 'Cancel' ? 0 : 1));
          expect(f.document, action == 'Cancel' ? _initial : _draft);
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      'actual router pending Persona write cannot redirect after route exit at $width / 200%',
      (tester) async {
        final f = _Fixture();
        await f.open(tester, width);
        await tester.enterText(_field, _draft);
        f.writeGate = Completer<String>();
        await tester.tap(_save);
        await tester.pump();
        f.router.go('/tools');
        await tester.pump();
        f.writeGate!.complete(jsonEncode({'soul': _draft, 'revision': 'r2'}));
        await tester.pumpAndSettle();
        expect(f.router.routeInformationProvider.value.uri.path, '/tools');
        expect(find.byType(ProfileEditorSheet), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'actual router Persona changed save completes only after persistence at $width / 200%',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final f = _Fixture();
        await f.open(tester, width);
        await tester.enterText(_field, _draft);
        f.writeGate = Completer<String>();
        final activate = tester.widget<FilledButton>(_save).onPressed!;
        activate();
        activate();
        await tester.pump();
        expect(f.writes, [
          {
            'origin': 'http://localhost:8642',
            'path': '/api/profiles/coder/soul',
            'query': {'profile': 'coder'},
            'revision': 'r1',
            'body': {'soul': _draft},
          },
        ]);
        expect(f.router.routeInformationProvider.value.uri.path, '/soul');
        expect(tester.widget<TextButton>(_cancel).onPressed, isNull);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
          isNull,
        );
        expect(f.document, _initial);
        final pendingSave = tester.getSemantics(find.byType(FilledButton).last);
        expect(pendingSave.label, 'Save');
        expect(pendingSave.flagsCollection.isButton, isTrue);
        expect(pendingSave.flagsCollection.isEnabled, Tristate.isFalse);
        expect(
          pendingSave.getSemanticsData().role,
          SemanticsRole.none,
          reason:
              'Decorative spinner must not replace the named disabled Save button',
        );
        f.document = _draft;
        f.revision = 'r2';
        f.writeGate!.complete(
          jsonEncode({'soul': f.document, 'revision': f.revision}),
        );
        await tester.pumpAndSettle();
        f.expectProfiles();
        await f.reopen(tester);
        expect(f.text(tester), _draft);
        expect(utf8.encode(f.document), utf8.encode(_draft));
        expect(f.reads.where((u) => u.path.endsWith('/soul')), hasLength(2));
        expect(f.writes, hasLength(1));
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
    testWidgets(
      'actual router Persona cancel discards draft at $width / 200%',
      (tester) async {
        final f = _Fixture();
        await f.open(tester, width);
        expect(f.text(tester), _initial);
        await tester.enterText(_field, _draft);
        await tester.tap(_cancel);
        await tester.pumpAndSettle();
        f.expectProfiles();
        expect(f.writes, isEmpty);
        await f.reopen(tester);
        expect(f.text(tester), _initial);
        expect(f.reads.where((u) => u.path.endsWith('/soul')), hasLength(2));
        expect(f.writes, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
