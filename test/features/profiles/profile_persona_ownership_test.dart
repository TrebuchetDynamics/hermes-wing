import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/features/profiles/screens/profiles_screen.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';

import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

HermesCapabilityDocument personaCaps({bool write = true}) =>
    HermesCapabilityDocument.fromJson(personaCapabilityJson(write: write));
Map<String, Object?> personaCapabilityJson({bool write = true}) => {
  'schema_version': 1,
  'profile_context': {
    'type': 'query',
    'name': 'profile',
    'required': true,
    'default_profile_id': 'default',
  },
  'auth': {
    'type': 'bearer',
    'required': true,
    'granted_scopes': ['profiles:read', if (write) 'profiles:write'],
  },
  'endpoints': {
    'profiles': {
      'method': 'GET',
      'path': '/api/profiles',
      'required_scopes': ['profiles:read'],
    },
    'profile_update': {
      'method': 'PATCH',
      'path': '/api/profiles/{name}',
      'required_scopes': ['profiles:write'],
    },
    'profile_soul': {
      'method': 'GET',
      'path': '/api/profiles/{name}/soul',
      'required_scopes': ['profiles:read'],
    },
    'profile_soul_update': {
      'method': 'PUT',
      'path': '/api/profiles/{name}/soul',
      'required_scopes': ['profiles:write'],
    },
  },
};

const profile = HermesProfile(
  id: 'coder',
  displayName: 'Coder',
  revision: 'p1',
);

class PersonaChannel extends FakeHermesChannel {
  PersonaChannel()
    : super(profiles: const [profile], selectedProfileId: 'coder');
  HermesCapabilityDocument caps = personaCaps();
  String origin = 'http://localhost:8642';
  String selected = 'coder';
  bool connected = true;
  bool selecting = false;
  final reads = <Completer<HermesProfileSoul>>[];
  final writes = <Completer<void>>[];
  @override
  HermesChannelState get state => super.state.copyWith(
    profiles: const [profile],
    capabilities: caps,
    connectedBaseUrl: origin,
    selectedProfileId: selected,
    isSelectingProfile: selecting,
    status: connected
        ? HermesConnectionStatus.connected
        : HermesConnectionStatus.disconnected,
  );
  void emit() => notifyListeners();
  @override
  Future<HermesProfileSoul> readProfileSoul(String profileId) {
    readProfileSoulCalls.add(profileId);
    final gate = Completer<HermesProfileSoul>();
    reads.add(gate);
    return gate.future;
  }

  @override
  Future<void> writeProfileSoul({
    required String profileId,
    required String soul,
    required String revision,
  }) {
    writeProfileSoulCalls.add({
      'profileId': profileId,
      'soul': soul,
      'revision': revision,
    });
    final gate = Completer<void>();
    writes.add(gate);
    return gate.future;
  }

  void finish(int index, String text) => reads[index].complete(
    HermesProfileSoul(soul: text, revision: '$text-revision'),
  );
}

Widget app(
  HermesChannel channel, {
  HermesProfile row = profile,
  double scale = 1,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: Scaffold(
    body: ProfileEditorSheet(
      channel: channel,
      profiles: const [profile],
      profile: row,
      canEditSoul: true,
      soulOnly: true,
    ),
  ),
);
final field = find.byType(TextFormField).last;
final save = find.widgetWithText(FilledButton, 'Save');
Future<void> load(
  WidgetTester tester,
  PersonaChannel channel,
  String text,
) async {
  await tester.pumpWidget(app(channel));
  await tester.pump();
  channel.finish(0, text);
  await tester.pumpAndSettle();
}

final class Conflict implements HermesApiStatusException {
  @override
  int get statusCode => 412;
}

void main() {
  for (final kind in [
    'method',
    'path',
    'write method',
    'write path',
    'read operation',
    'write operation',
    'extra scope',
    'write extra scope',
    'read grant',
    'profile context',
    'schema',
  ]) {
    testWidgets(
      'exact $kind loss/restoration discards draft and denies operations',
      (tester) async {
        final c = PersonaChannel();
        addTearDown(c.dispose);
        await load(tester, c, 'old');
        await tester.enterText(field, 'draft');
        final json = personaCapabilityJson();
        final endpoints = json['endpoints']! as Map<String, Object?>;
        final read = endpoints['profile_soul']! as Map<String, Object?>;
        final write = endpoints['profile_soul_update']! as Map<String, Object?>;
        switch (kind) {
          case 'method':
            read['method'] = 'POST';
          case 'path':
            read['path'] = '/api/wrong';
          case 'write method':
            write['method'] = 'POST';
          case 'write path':
            write['path'] = '/api/wrong';
          case 'read operation':
            endpoints.remove('profile_soul');
          case 'write operation':
            endpoints.remove('profile_soul_update');
          case 'extra scope':
            read['required_scopes'] = ['profiles:read', 'profiles:admin'];
          case 'write extra scope':
            write['required_scopes'] = ['profiles:write', 'profiles:admin'];
          case 'read grant':
            (json['auth']! as Map<String, Object?>)['granted_scopes'] = [
              'profiles:write',
            ];
          case 'profile context':
            json.remove('profile_context');
          case 'schema':
            json['schema_version'] = 99;
        }
        c.caps = HermesCapabilityDocument.fromJson(json);
        c.emit();
        await tester.pump();
        expect(find.text('draft'), findsNothing);
        expect(c.reads, hasLength(1));
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        c.caps = personaCaps();
        c.emit();
        await tester.pump();
        await tester.pump();
        expect(c.reads, hasLength(2));
        c.finish(1, 'fresh');
        await tester.pumpAndSettle();
        expect(c.writes, isEmpty);
      },
    );
  }
  testWidgets('persona payload cannot be retargeted after awaited rename', (
    tester,
  ) async {
    final a = PersonaChannel();
    final b = PersonaChannel();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    final renameGate = Completer<void>();
    Widget editor(PersonaChannel c) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ProfileEditorSheet(
          channel: c,
          profiles: const [profile],
          profile: profile,
          canEditSoul: true,
          onRename: ({required profileId, required name, required revision}) =>
              renameGate.future,
        ),
      ),
    );
    await tester.pumpWidget(editor(a));
    await tester.pump();
    a.finish(0, 'A');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Renamed');
    await tester.enterText(field, 'A draft');
    await tester.tap(save);
    await tester.pump();
    await tester.pumpWidget(editor(b));
    await tester.pump();
    b.finish(0, 'B');
    await tester.pumpAndSettle();
    renameGate.complete();
    await tester.pumpAndSettle();
    expect(a.writes, isEmpty);
    expect(b.writes, isEmpty);
    expect(find.text('B'), findsOneWidget);
  });
  testWidgets('Profiles modal invalidates same-frame management source', (
    tester,
  ) async {
    final c = PersonaChannel();
    addTearDown(c.dispose);
    final directory = directoryFor(
      configs: [
        const HermesEndpointConfig(
          id: 'A',
          label: 'A',
          baseUrl: 'http://localhost:8642',
        ),
        const HermesEndpointConfig(
          id: 'B',
          label: 'B',
          baseUrl: 'http://localhost:8643',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'A': gatewaySummary(['coder']),
        'B': gatewaySummary(['coder']),
      }),
      activeChannel: c,
    );
    await directory.refresh();
    await directory.activateGateway('A');
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(c),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
      ],
    );
    addTearDown(container.dispose);
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
    final edit = find.widgetWithText(OutlinedButton, 'Edit');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    c.finish(0, 'A');
    await tester.pumpAndSettle();
    await tester.enterText(field, 'A draft');
    directory.selectManagementGateway('B');
    directory.selectManagementGateway('A');
    await tester.pumpAndSettle();
    expect(find.text('A draft'), findsNothing);
    expect(c.reads, hasLength(1));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(c.writes, isEmpty);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('same ID channel replacement discards the loaded edited draft', (
    tester,
  ) async {
    final a = PersonaChannel();
    final b = PersonaChannel();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    await load(tester, a, 'A');
    await tester.enterText(field, 'A draft');
    await tester.pumpWidget(app(b));
    await tester.pump();
    expect(find.text('A draft'), findsNothing);
    expect(b.reads, hasLength(1));
    b.finish(0, 'B');
    await tester.pumpAndSettle();
    await tester.enterText(field, 'B draft');
    await tester.tap(save);
    await tester.pump();
    expect(b.writeProfileSoulCalls.single, {
      'profileId': 'coder',
      'soul': 'B draft',
      'revision': 'B-revision',
    });
    expect(a.writes, isEmpty);
  });
  for (final fails in [false, true]) {
    testWidgets(
      'stale deferred read ${fails ? 'failure' : 'success'} cannot enter replacement',
      (tester) async {
        final a = PersonaChannel();
        final b = PersonaChannel();
        addTearDown(a.dispose);
        addTearDown(b.dispose);
        await tester.pumpWidget(app(a));
        await tester.pump();
        await tester.pumpWidget(app(b));
        await tester.pump();
        expect(b.reads, hasLength(1));
        b.finish(0, 'B');
        await tester.pumpAndSettle();
        if (fails) {
          a.reads[0].completeError(StateError('private raw error'));
        } else {
          a.finish(0, 'A');
        }
        await tester.pumpAndSettle();
        expect(find.text('B'), findsOneWidget);
        expect(find.textContaining('could not complete'), findsNothing);
        expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      },
    );
  }

  final changes = <String, void Function(PersonaChannel)>{
    'host': (c) {
      c.origin = 'http://localhost:8643';
    },
    'profile': (c) {
      c.selected = 'other';
    },
    'selecting': (c) {
      c.selecting = true;
    },
    'disconnect': (c) {
      c.connected = false;
    },
    'grant': (c) {
      c.caps = personaCaps(write: false);
    },
  };
  for (final entry in changes.entries) {
    for (final fails in [false, true]) {
      testWidgets(
        '${entry.key} same-frame roundtrip fences deferred read $fails',
        (tester) async {
          final c = PersonaChannel();
          addTearDown(c.dispose);
          await tester.pumpWidget(app(c));
          await tester.pump();
          entry.value(c);
          c.emit();
          c.origin = 'http://localhost:8642';
          c.selected = 'coder';
          c.selecting = false;
          c.connected = true;
          c.caps = personaCaps();
          c.emit();
          if (fails) {
            c.reads[0].completeError(StateError('private raw error'));
          } else {
            c.finish(0, 'stale');
          }
          await tester.pump();
          await tester.pump();
          expect(c.reads, hasLength(2));
          expect(find.text('stale'), findsNothing);
          expect(find.textContaining('could not complete'), findsNothing);
          c.finish(1, 'current');
          await tester.pumpAndSettle();
          expect(find.text('current'), findsOneWidget);
          expect(c.writes, isEmpty);
        },
      );
    }
    testWidgets(
      '${entry.key} drops edited draft but ordinary notifications retain it',
      (tester) async {
        final c = PersonaChannel();
        addTearDown(c.dispose);
        await load(tester, c, 'initial');
        await tester.enterText(field, 'draft');
        c.caps = personaCaps();
        c.emit();
        await tester.pump();
        await tester.pumpWidget(
          app(
            c,
            row: const HermesProfile(
              id: 'coder',
              displayName: 'Coder',
              revision: 'ordinary-new-revision',
            ),
          ),
        );
        expect(find.text('draft'), findsOneWidget);
        expect(c.reads, hasLength(1));
        entry.value(c);
        c.emit();
        c.origin = 'http://localhost:8642';
        c.selected = 'coder';
        c.selecting = false;
        c.connected = true;
        c.caps = personaCaps();
        c.emit();
        await tester.pump();
        await tester.pump();
        expect(find.text('draft'), findsNothing);
        expect(c.reads, hasLength(2));
        c.finish(1, 'current');
        await tester.pumpAndSettle();
        expect(c.writes, isEmpty);
      },
    );
  }
  for (final outcome in ['success', 'failure', 'conflict']) {
    testWidgets(
      'stale save $outcome neither pops replacement nor changes its state',
      (tester) async {
        final a = PersonaChannel();
        final b = PersonaChannel();
        addTearDown(a.dispose);
        addTearDown(b.dispose);
        final current = ValueNotifier<PersonaChannel>(a);
        addTearDown(current.dispose);
        late BuildContext routeContext;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                routeContext = context;
                return const Scaffold(body: Text('underlying route'));
              },
            ),
          ),
        );
        unawaited(
          Navigator.of(routeContext).push<void>(
            MaterialPageRoute(
              builder: (_) => ValueListenableBuilder<PersonaChannel>(
                valueListenable: current,
                builder: (_, c, _) => Scaffold(
                  body: ProfileEditorSheet(
                    channel: c,
                    profiles: const [profile],
                    profile: profile,
                    canEditSoul: true,
                    soulOnly: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        a.finish(0, 'A');
        await tester.pumpAndSettle();
        await tester.enterText(field, 'A draft');
        final action = tester.widget<FilledButton>(save).onPressed!;
        action();
        action();
        await tester.pump();
        expect(a.writes, hasLength(1));
        current.value = b;
        await tester.pump();
        await tester.pump();
        b.finish(0, 'B');
        await tester.pumpAndSettle();
        await tester.enterText(field, 'B draft');
        if (outcome == 'success') {
          a.writes[0].complete();
        } else {
          a.writes[0].completeError(
            outcome == 'conflict' ? Conflict() : StateError('private'),
          );
        }
        await tester.pumpAndSettle();
        expect(find.text('B draft'), findsOneWidget);
        expect(find.text('underlying route'), findsNothing);
        expect(find.textContaining('could not complete'), findsNothing);
        expect(b.writes, isEmpty);
        expect(a.reads, hasLength(1));
        expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      },
    );
  }
  testWidgets(
    'conflict reload failure clears stale writable draft and supports explicit retry',
    (tester) async {
      final c = PersonaChannel();
      addTearDown(c.dispose);
      await load(tester, c, 'old');
      await tester.enterText(field, 'draft');
      await tester.tap(save);
      await tester.pump();
      c.writes[0].completeError(Conflict());
      await tester.pump();
      expect(c.reads, hasLength(2));
      c.reads[1].completeError(StateError('private read'));
      await tester.pumpAndSettle();
      expect(find.text('draft'), findsNothing);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(tester.widget<TextFormField>(field).enabled, isFalse);
      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pump();
      c.finish(2, 'new');
      await tester.pumpAndSettle();
      await tester.enterText(field, 'explicit');
      await tester.tap(save);
      await tester.pump();
      expect(c.writeProfileSoulCalls.last['revision'], 'new-revision');
      expect(c.writes, hasLength(2));
    },
  );
  testWidgets(
    'owner changes during conflict reload fence content and conflict error',
    (tester) async {
      final c = PersonaChannel();
      addTearDown(c.dispose);
      await load(tester, c, 'old');
      await tester.enterText(field, 'draft');
      await tester.tap(save);
      await tester.pump();
      c.writes[0].completeError(Conflict());
      await tester.pump();
      c.origin = 'http://localhost:8643';
      c.emit();
      await tester.pump();
      await tester.pump();
      c.finish(2, 'B');
      await tester.pumpAndSettle();
      c.finish(1, 'stale conflict');
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
      expect(find.textContaining('changed elsewhere'), findsNothing);
    },
  );
  testWidgets('profile argument change and disposal fence deferred reads', (
    tester,
  ) async {
    final c = PersonaChannel();
    addTearDown(c.dispose);
    await tester.pumpWidget(app(c));
    await tester.pump();
    await tester.pumpWidget(
      app(
        c,
        row: const HermesProfile(
          id: 'other',
          displayName: 'Other',
          revision: 'p2',
        ),
      ),
    );
    await tester.pump();
    expect(c.readProfileSoulCalls, ['coder', 'other']);
    c.finish(0, 'stale');
    await tester.pump();
    expect(find.text('stale'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.finish(1, 'disposed');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(c.writes, isEmpty);
  });
  testWidgets('unsupported grant yields zero reads and writes', (tester) async {
    final c = PersonaChannel()..caps = personaCaps(write: false);
    addTearDown(c.dispose);
    await tester.pumpWidget(app(c));
    await tester.pump();
    expect(c.reads, isEmpty);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    c.caps = personaCaps();
    c.emit();
    await tester.pump();
    await tester.pump();
    expect(c.reads, hasLength(1));
  });
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'accessible persona edit and error recovery at $width 200 percent reduced motion',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final c = PersonaChannel();
        addTearDown(c.dispose);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(app(c, scale: 2));
        await tester.pump();
        c.reads[0].completeError(StateError('private'));
        await tester.pumpAndSettle();
        final retry = find.widgetWithText(TextButton, 'Retry');
        await tester.ensureVisible(retry);
        expect(retry.hitTestable(), findsOneWidget);
        final retryFocus = Focus.of(
          tester.element(
            find.descendant(of: retry, matching: find.text('Retry')),
          ),
        );
        for (var i = 0; i < 10 && !retryFocus.hasFocus; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        expect(retryFocus.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        c.finish(1, 'inert persona');
        await tester.pumpAndSettle();
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pump();
        expect(
          tester.widget<TextFormField>(field).controller!.selection.isValid,
          isTrue,
        );
        expect(
          tester.getSemantics(field).getSemanticsData().label,
          contains('Persona'),
        );
        await tester.enterText(field, 'accessible draft');
        await tester.ensureVisible(save);
        expect(save.hitTestable(), findsOneWidget);
        final saveFocus = Focus.of(
          tester.element(
            find.descendant(of: save, matching: find.text('Save')),
          ),
        );
        for (var i = 0; i < 10 && !saveFocus.hasFocus; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        expect(saveFocus.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(c.writeProfileSoulCalls.single['soul'], 'accessible draft');
        final pendingSave = tester.getSemantics(find.byType(FilledButton).last);
        expect(pendingSave.label, 'Save');
        expect(pendingSave.flagsCollection.isButton, isTrue);
        expect(pendingSave.flagsCollection.isEnabled, Tristate.isFalse);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
