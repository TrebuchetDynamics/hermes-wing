import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/schedules/screens/schedules_screen.dart';
import 'package:wing/features/tools/screens/tools_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

const _jobs = '/api/jobs';
const _skills = '/v1/skills';
const _toolsets = '/v1/toolsets';
const _optional = [_jobs, _skills, _toolsets];

Map<String, Object?> _catalog(String variant) => {
  'schema_version': variant == 'schema' ? 2 : 1,
  'profile_context': {
    'type': variant == 'context' ? 'header' : 'query',
    'name': 'profile',
    'required': true,
    'default_profile_id': 'default',
  },
  'auth': {
    'type': 'bearer',
    'required': true,
    'granted_scopes': ['profiles:read', 'tasks:read', 'inventory:read'],
  },
  'endpoints': {
    'profiles': {
      'method': 'GET',
      'path': '/api/profiles',
      'required_scopes': ['profiles:read'],
    },
    for (final entry in [
      ('jobs', _jobs),
      ('skills', _skills),
      ('toolsets', _toolsets),
    ])
      if (variant != 'absent' &&
          !(variant == 'skills only' && entry.$1 == 'toolsets') &&
          !(variant == 'toolsets only' && entry.$1 == 'skills'))
        entry.$1: {
          'method': variant == 'method' ? 'POST' : 'GET',
          'path': variant == 'path' ? '/api/unsupported' : entry.$2,
          'profile_scoped': true,
          'required_scopes': [
            if (entry.$1 == 'jobs') 'tasks:read',
            'inventory:read',
            if (variant == 'grant') 'ungranted:read',
          ],
        },
  },
};

String _inventory(String path, String id, {int count = 1}) => jsonEncode({
  path == _jobs ? 'jobs' : 'data': [
    for (var i = 0; i < count; i++)
      if (path == _jobs)
        {
          'id': count == 1 ? id : '${id}_$i',
          'name': '$id task',
          'enabled': true,
        }
      else
        {'name': count == 1 ? id : '${id}_$i', 'enabled': true},
  ],
});

class _Gate {
  final started = Completer<void>();
  final response = Completer<String>();
}

class _Harness {
  _Harness({this.variant = 'allowed', this.count = 1}) {
    channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          reads.add(uri);
          final queue = gates[uri.path];
          if (queue != null && queue.isNotEmpty) {
            final gate = queue.removeAt(0);
            gate.started.complete();
            return gate.response.future;
          }
          if (_optional.contains(uri.path)) {
            if (fail) {
              throw StateError('Failed at /home/fixture/private-inventory');
            }
            return _inventory(
              uri.path,
              uri.queryParameters['profile'] ?? 'none',
              count: count,
            );
          }
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => jsonEncode(_catalog(variant)),
            '/api/sessions' => '{"data":[]}',
            '/api/profiles' =>
              '{"data":[{"id":"default","is_default":true},{"id":"writer"}]}',
            _ => throw StateError('unexpected deterministic GET'),
          };
        },
        post: (uri, headers, body) async {
          mutations.add(uri);
          throw StateError('unexpected deterministic mutation');
        },
      ),
    );
  }

  final String variant;
  final int count;
  late final HermesApiChannel channel;
  final reads = <Uri>[];
  final mutations = <Uri>[];
  final gates = <String, List<_Gate>>{};
  bool fail = false;

  _Gate pause(String path) {
    final gate = _Gate();
    (gates[path] ??= []).add(gate);
    return gate;
  }

  Future<void> connect() => channel.connect(baseUrl: 'http://127.0.0.1:8642');
  Future<void> refresh(String resource) =>
      resource == 'jobs' ? channel.loadJobs() : channel.loadToolInventory();

  List<Uri> get receipts =>
      reads.where((uri) => _optional.contains(uri.path)).toList();
}

void _expectInventory(_Harness h, String id) {
  expect(h.channel.state.jobs.single.id, id);
  expect(h.channel.state.skills, [id]);
  expect(h.channel.state.toolsets.single.name, id);
  expect(h.channel.state.enabledToolsets, [id]);
  expect(h.channel.state.optionalResourceErrors, isEmpty);
  expect(h.mutations, isEmpty);
}

Future<void> _expectRejected(_Harness h, String message) async {
  final state = h.channel.state;
  final before = h.reads.length;
  var publications = 0;
  void listener() => publications++;
  h.channel.addListener(listener);
  try {
    final outcomes = <Object?>[];
    for (final resource in ['jobs', 'tools']) {
      try {
        await h.refresh(resource);
        outcomes.add(null);
      } catch (error) {
        outcomes.add(error);
      }
    }
    if (outcomes.any((error) => error is! StateError)) {
      // Record deterministic request receipts when admission regresses.
      // ignore: avoid_print
      print(
        jsonEncode({
          'admission_outcomes': outcomes.map((e) => e?.toString()).toList(),
          'unexpected_explicit_reads': h.reads
              .skip(before)
              .map((u) => {'path': u.path, 'query': u.queryParameters})
              .toList(),
          'publications': publications,
        }),
      );
    }
    for (final outcome in outcomes) {
      expect(
        outcome,
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains(message),
        ),
      );
    }
    expect(h.reads.skip(before), isEmpty);
    expect(identical(h.channel.state, state), isTrue);
    expect(publications, 0);
    expect(h.mutations, isEmpty);
  } finally {
    h.channel.removeListener(listener);
  }
}

Widget _app(_Harness h, String resource) => ProviderScope(
  overrides: [hermesChannelProvider.overrideWithValue(h.channel)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: resource == 'jobs' ? const SchedulesScreen() : const ToolsScreen(),
  ),
);

void main() {
  for (final transition in ['same', 'writer', 'A-B-A']) {
    for (final phase in ['/api/profiles', '/api/sessions', 'bootstrap']) {
      test(
        'explicit admission rejects $transition during $phase without I/O or publication',
        () async {
          final h = _Harness();
          addTearDown(h.channel.dispose);
          await h.connect();
          if (transition == 'A-B-A') await h.channel.selectProfile('writer');
          final target = transition == 'writer' ? 'writer' : 'default';
          final gate = h.pause(phase == 'bootstrap' ? _jobs : phase);
          final selection = h.channel.selectProfile(target);
          await gate.started.future;
          expect(h.channel.state.isSelectingProfile, isTrue);
          final before = h.receipts.length;
          try {
            await _expectRejected(h, 'selection is still in progress');
            expect(h.receipts, hasLength(before));
          } finally {
            gate.response.complete(
              phase == '/api/profiles'
                  ? '{"data":[{"id":"default","is_default":true},{"id":"writer"}]}'
                  : phase == 'bootstrap'
                  ? _inventory(_jobs, target)
                  : '{"data":[]}',
            );
            await selection;
          }
          _expectInventory(h, target);
          final start = h.receipts.length;
          await h.channel.loadJobs();
          await h.channel.loadToolInventory();
          expect(
            h.receipts.skip(start).map((u) => [u.path, u.queryParameters]),
            [
              [
                _jobs,
                {'profile': target, 'include_disabled': 'true'},
              ],
              [
                _skills,
                {'profile': target},
              ],
              [
                _toolsets,
                {'profile': target},
              ],
            ],
          );
        },
      );
    }
  }

  for (final reconnect in [false, true]) {
    for (final phase in [
      '/health',
      '/v1/capabilities',
      '/api/sessions',
      'bootstrap',
    ]) {
      test(
        'explicit admission rejects ${reconnect ? 'reconnecting' : 'initial'} $phase',
        () async {
          final h = _Harness();
          addTearDown(h.channel.dispose);
          if (reconnect) await h.connect();
          final gate = h.pause(phase == 'bootstrap' ? _jobs : phase);
          final connecting = h.connect();
          await gate.started.future;
          expect(h.channel.state.status, HermesConnectionStatus.connecting);
          await _expectRejected(h, 'not connected');
          gate.response.complete(switch (phase) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => jsonEncode(_catalog('allowed')),
            'bootstrap' => _inventory(_jobs, 'default'),
            _ => '{"data":[]}',
          });
          await connecting;
          _expectInventory(h, 'default');
        },
      );
    }
  }

  test(
    'disconnected and failed connection reject without optional I/O',
    () async {
      final h = _Harness();
      addTearDown(h.channel.dispose);
      await _expectRejected(h, 'not connected');
      final gate = h.pause('/health');
      final connecting = h.connect();
      await gate.started.future;
      gate.response.completeError(StateError('obsolete transport detail'));
      await connecting;
      expect(h.channel.state.status, HermesConnectionStatus.error);
      await _expectRejected(h, 'not connected');
      await h.channel.disconnect();
      await _expectRejected(h, 'not connected');
    },
  );

  for (final variant in [
    'schema',
    'absent',
    'method',
    'path',
    'context',
    'grant',
  ]) {
    test(
      'settled exact inventory authority denies $variant without I/O',
      () async {
        final h = _Harness(variant: variant);
        addTearDown(h.channel.dispose);
        await h.connect();
        expect(h.channel.state.status, HermesConnectionStatus.connected);
        await _expectRejected(h, 'did not advertise');
      },
    );
  }

  for (final variant in ['allowed', 'skills only', 'toolsets only']) {
    test(
      'settled $variant refresh retains explicit query and 128 row bounds',
      () async {
        final h = _Harness(variant: variant, count: 140);
        addTearDown(h.channel.dispose);
        await h.connect();
        await h.channel.selectProfile('writer');
        final before = h.receipts.length;
        await h.channel.loadJobs();
        await h.channel.loadToolInventory();
        expect(
          h.receipts.skip(before).map((u) => [u.path, u.queryParameters]),
          [
            [
              _jobs,
              {'profile': 'writer', 'include_disabled': 'true'},
            ],
            if (variant != 'toolsets only')
              [
                _skills,
                {'profile': 'writer'},
              ],
            if (variant != 'skills only')
              [
                _toolsets,
                {'profile': 'writer'},
              ],
          ],
        );
        expect(h.channel.state.jobs, hasLength(128));
        expect(
          h.channel.state.skills,
          hasLength(variant == 'toolsets only' ? 0 : 128),
        );
        expect(
          h.channel.state.toolsets,
          hasLength(variant == 'skills only' ? 0 : 128),
        );
        expect(h.channel.state.optionalResourceErrors, isEmpty);
        expect(h.mutations, isEmpty);
      },
    );
  }

  for (final transition in [
    'pending same',
    'pending writer',
    'settled same',
    'A-B-A pending',
    'A-B-A',
    'reconnect pending',
    'reconnected',
    'disconnect',
    'dispose',
  ]) {
    for (final fails in [false, true]) {
      test(
        'independent jobs/tools stale ${fails ? 'failure' : 'success'} after $transition',
        () async {
          final h = _Harness();
          var disposed = false;
          addTearDown(() {
            if (!disposed) h.channel.dispose();
          });
          await h.connect();
          final jobs = h.pause(_jobs);
          final skills = h.pause(_skills);
          final toolsets = h.pause(_toolsets);
          final oldJobs = h.channel.loadJobs();
          final oldJobsObserved = fails
              ? expectLater(oldJobs, throwsStateError)
              : oldJobs;
          final oldTools = h.channel.loadToolInventory();
          await Future.wait([
            jobs.started.future,
            skills.started.future,
            toolsets.started.future,
          ]);
          _Gate? selectionGate;
          Future<void>? pending;
          if (transition.startsWith('pending') ||
              transition == 'A-B-A pending') {
            if (transition == 'A-B-A pending') {
              await h.channel.selectProfile('writer');
            }
            selectionGate = h.pause('/api/sessions');
            pending = h.channel.selectProfile(
              transition == 'pending writer' ? 'writer' : 'default',
            );
            await selectionGate.started.future;
            await _expectRejected(h, 'selection is still in progress');
          } else if (transition == 'settled same') {
            await h.channel.selectProfile('default');
          } else if (transition == 'A-B-A') {
            await h.channel.selectProfile('writer');
            await h.channel.selectProfile('default');
          } else if (transition == 'reconnect pending') {
            selectionGate = h.pause('/health');
            pending = h.connect();
            await selectionGate.started.future;
            await _expectRejected(h, 'not connected');
          } else if (transition == 'reconnected') {
            await h.connect();
          } else if (transition == 'disconnect') {
            await h.channel.disconnect();
          } else {
            h.channel.dispose();
            disposed = true;
          }
          final current = h.channel.state;
          for (final (path, gate) in [
            (_jobs, jobs),
            (_skills, skills),
            (_toolsets, toolsets),
          ]) {
            if (fails) {
              gate.response.completeError(
                StateError('obsolete transport detail'),
              );
            } else {
              gate.response.complete(_inventory(path, 'obsolete'));
            }
          }
          await Future.wait([oldJobsObserved, oldTools]);
          expect(identical(h.channel.state, current), isTrue);
          if (selectionGate != null) {
            selectionGate.response.complete(
              transition == 'reconnect pending'
                  ? '{"status":"ok"}'
                  : '{"data":[]}',
            );
            await pending;
          }
          if (!disposed && h.channel.state.isConnected) {
            _expectInventory(
              h,
              transition == 'pending writer' ? 'writer' : 'default',
            );
          }
          expect(h.mutations, isEmpty);
        },
      );
    }
  }

  for (final fails in [false, true]) {
    test(
      'rejected pending calls cannot steal replacement jobs/tools ownership $fails',
      () async {
        final h = _Harness();
        addTearDown(h.channel.dispose);
        await h.connect();
        final selectionGate = h.pause('/api/sessions');
        final selecting = h.channel.selectProfile('default');
        await selectionGate.started.future;
        await _expectRejected(h, 'selection is still in progress');
        selectionGate.response.complete('{"data":[]}');
        await selecting;
        final jobs = h.pause(_jobs);
        final skills = h.pause(_skills);
        final oldJobs = h.channel.loadJobs();
        final observed = fails
            ? expectLater(oldJobs, throwsStateError)
            : oldJobs;
        final oldTools = h.channel.loadToolInventory();
        await Future.wait([jobs.started.future, skills.started.future]);
        await h.channel.loadJobs();
        await h.channel.loadToolInventory();
        final current = h.channel.state;
        if (fails) {
          jobs.response.completeError(StateError('obsolete transport detail'));
          skills.response.completeError(
            StateError('obsolete transport detail'),
          );
        } else {
          jobs.response.complete(_inventory(_jobs, 'obsolete'));
          skills.response.complete(_inventory(_skills, 'obsolete'));
        }
        await Future.wait([observed, oldTools]);
        expect(identical(h.channel.state, current), isTrue);
        _expectInventory(h, 'default');
      },
    );
  }

  for (final resource in ['jobs', 'tools']) {
    test(
      'settled $resource error is sanitized and explicit retry recovers',
      () async {
        final h = _Harness();
        addTearDown(h.channel.dispose);
        await h.connect();
        h.fail = true;
        if (resource == 'jobs') {
          await expectLater(h.refresh(resource), throwsStateError);
          expect(h.channel.state.jobs, isEmpty);
        } else {
          await h.refresh(resource);
          expect(h.channel.state.skills, isEmpty);
          expect(h.channel.state.toolsets, isEmpty);
        }
        expect(h.channel.state.optionalResourceErrors.values, isNotEmpty);
        expect(
          h.channel.state.optionalResourceErrors.values.join(),
          isNot(contains('/home/fixture/private-inventory')),
        );
        h.fail = false;
        await h.refresh(resource);
        _expectInventory(h, 'default');
      },
    );
  }

  for (final width in [390.0, 1280.0]) {
    for (final transition in ['same', 'A-B-A']) {
      for (final fails in [false, true]) {
        testWidgets(
          'actual Tools stale $fails cannot steal new $transition refresh at $width',
          (tester) async {
            tester.view.physicalSize = Size(width, 1200);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final h = _Harness();
            addTearDown(h.channel.dispose);
            await h.connect();
            await tester.pumpWidget(_app(h, 'tools'));
            await tester.pumpAndSettle();
            const key = ValueKey('tools-refresh');
            final oldSkills = h.pause(_skills);
            final oldTools = h.pause(_toolsets);
            final cached = tester
                .widget<IconButton>(find.byKey(key))
                .onPressed!;
            cached();
            cached();
            await tester.pump();
            await Future.wait([
              oldSkills.started.future,
              oldTools.started.future,
            ]);
            if (transition == 'A-B-A') await h.channel.selectProfile('writer');
            await h.channel.selectProfile('default');
            await tester.pumpAndSettle();
            final before = h.receipts.length;
            cached();
            expect(h.receipts, hasLength(before));
            final currentSkills = h.pause(_skills);
            final currentTools = h.pause(_toolsets);
            tester.widget<IconButton>(find.byKey(key)).onPressed!();
            await tester.pump();
            await Future.wait([
              currentSkills.started.future,
              currentTools.started.future,
            ]);
            final current = h.channel.state;
            for (final (path, gate) in [
              (_skills, oldSkills),
              (_toolsets, oldTools),
            ]) {
              if (fails) {
                gate.response.completeError(
                  StateError('obsolete transport detail'),
                );
              } else {
                gate.response.complete(_inventory(path, 'obsolete'));
              }
            }
            await tester.pump();
            expect(identical(h.channel.state, current), isTrue);
            expect(
              tester.widget<IconButton>(find.byKey(key)).onPressed,
              isNull,
            );
            expect(
              find.text('Tool inventory could not be refreshed.'),
              findsNothing,
            );
            currentSkills.response.complete(_inventory(_skills, 'fresh'));
            currentTools.response.complete(_inventory(_toolsets, 'fresh'));
            await tester.pumpAndSettle();
            expect(h.channel.state.skills, ['fresh']);
            expect(h.channel.state.toolsets.single.name, 'fresh');
            expect(h.channel.state.optionalResourceErrors, isEmpty);
            expect(h.receipts.skip(before).map((u) => u.path), [
              _skills,
              _toolsets,
            ]);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets(
      'cached Tools refresh rejects same-identity replacement client at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final old = _Harness();
        final replacement = _Harness();
        addTearDown(old.channel.dispose);
        addTearDown(replacement.channel.dispose);
        await old.connect();
        await replacement.connect();
        await tester.pumpWidget(_app(old, 'tools'));
        await tester.pumpAndSettle();
        const key = ValueKey('tools-refresh');
        final cached = tester.widget<IconButton>(find.byKey(key)).onPressed!;
        final oldBefore = old.reads.length;
        final newBefore = replacement.reads.length;
        await tester.pumpWidget(_app(replacement, 'tools'));
        cached();
        await tester.pumpAndSettle();
        expect(old.reads.skip(oldBefore), isEmpty);
        expect(replacement.reads.skip(newBefore), isEmpty);
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
        expect(replacement.reads.skip(newBefore).map((u) => u.path), [
          _skills,
          _toolsets,
        ]);
        expect(tester.takeException(), isNull);
      },
    );

    for (final variant in ['skills only', 'toolsets only']) {
      testWidgets('actual Tools $variant refresh and recovery at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = _Harness(variant: variant);
        addTearDown(h.channel.dispose);
        await h.connect();
        await tester.pumpWidget(_app(h, 'tools'));
        await tester.pumpAndSettle();
        const key = ValueKey('tools-refresh');
        final before = h.receipts.length;
        h.fail = true;
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
        expect(h.channel.state.optionalResourceErrors, hasLength(1));
        h.fail = false;
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
        final path = variant == 'skills only' ? _skills : _toolsets;
        expect(h.receipts.skip(before).map((u) => u.path), [path, path]);
        expect(h.channel.state.optionalResourceErrors, isEmpty);
        expect(h.mutations, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }

    for (final transition in ['same', 'A-B-A']) {
      testWidgets(
        'cached Tools refresh rejects settled $transition owner at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final h = _Harness();
          addTearDown(h.channel.dispose);
          await h.connect();
          await tester.pumpWidget(_app(h, 'tools'));
          await tester.pumpAndSettle();
          const key = ValueKey('tools-refresh');
          final cached = tester.widget<IconButton>(find.byKey(key)).onPressed!;
          if (transition == 'A-B-A') await h.channel.selectProfile('writer');
          await h.channel.selectProfile('default');
          await tester.pumpAndSettle();
          final before = h.receipts.length;
          cached();
          await tester.pumpAndSettle();
          expect(h.receipts.skip(before), isEmpty);
          expect(
            find.text('Tool inventory could not be refreshed.'),
            findsNothing,
          );
          await tester.tap(find.byKey(key));
          await tester.pumpAndSettle();
          expect(h.receipts.skip(before).map((u) => u.path), [
            _skills,
            _toolsets,
          ]);
          expect(h.mutations, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final resource in ['jobs', 'tools']) {
      testWidgets(
        'actual $resource selecting/error/explicit recovery at $width / 200% reduced motion',
        (tester) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final h = _Harness();
          addTearDown(h.channel.dispose);
          await h.connect();
          await tester.pumpWidget(_app(h, resource));
          await tester.pumpAndSettle();
          final key = ValueKey(
            resource == 'jobs' ? 'schedules-refresh-button' : 'tools-refresh',
          );
          final cached = tester.widget<IconButton>(find.byKey(key)).onPressed!;
          final gate = h.pause('/api/sessions');
          final selecting = h.channel.selectProfile('default');
          await gate.started.future;
          final before = h.receipts.length;
          cached();
          await tester.pumpAndSettle();
          expect(h.receipts, hasLength(before));
          expect(h.channel.state.isSelectingProfile, isTrue);
          gate.response.complete('{"data":[]}');
          await selecting;
          await tester.pumpAndSettle();
          h.fail = true;
          await tester.tap(find.byKey(key));
          await tester.pumpAndSettle();
          expect(
            find.text(
              resource == 'jobs'
                  ? 'Schedules could not be loaded from Hermes.'
                  : 'Installed skills could not be loaded from Hermes.',
            ),
            findsOneWidget,
          );
          h.fail = false;
          if (resource == 'jobs') {
            await tester.tap(find.text('Retry'));
          } else {
            await tester.tap(find.byKey(key));
          }
          await tester.pumpAndSettle();
          _expectInventory(h, 'default');
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'actual $resource unavailable at $width / 200% reduced motion',
        (tester) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final h = _Harness(variant: 'absent');
          addTearDown(h.channel.dispose);
          await h.connect();
          await tester.pumpWidget(_app(h, resource));
          await tester.pumpAndSettle();
          expect(
            find.byKey(
              ValueKey(
                resource == 'jobs'
                    ? 'schedules-refresh-button'
                    : 'tools-refresh',
              ),
            ),
            findsNothing,
          );
          expect(h.receipts, isEmpty);
          expect(h.channel.state.optionalResourceErrors, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
