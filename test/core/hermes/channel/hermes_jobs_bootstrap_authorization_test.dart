import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/schedules/screens/schedules_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

Map<String, Object?> _catalog(String variant) => {
  'schema_version': variant == 'schema' ? 2 : 1,
  'version': '999.0',
  'features': {'jobs_admin': true, 'admin': true},
  'profile_context': {
    'type': variant.contains('context') ? 'header' : 'query',
    'name': variant == 'context name' ? 'owner' : 'profile',
    'required': variant != 'context optional',
    'default_profile_id': variant == 'context default' ? 'writer' : 'default',
  },
  'auth': {
    'type': 'bearer',
    'required': true,
    'granted_scopes': [
      'profiles:read',
      if (variant != 'missing grant' && variant != 'admin only') 'tasks:read',
      if (variant == 'admin only') 'admin',
      if (variant == 'extra granted') 'additional:read',
      if (variant == 'wildcard') '*',
    ],
  },
  'endpoints': {
    'profiles': {
      'method': 'GET',
      'path': '/api/profiles',
      'required_scopes': ['profiles:read'],
    },
    'models': {'method': 'GET', 'path': '/v1/models'},
    'skills': {'method': 'GET', 'path': '/v1/skills'},
    'toolsets': {'method': 'GET', 'path': '/v1/toolsets'},
    if (variant != 'absent operation')
      (variant == 'wrong operation' ? 'job_read' : 'jobs'): {
        'method': variant == 'method' ? 'POST' : 'GET',
        'path': variant == 'path' ? '/api/other' : '/api/jobs',
        'profile_scoped': !variant.startsWith('unscoped'),
        'required_scopes': [
          if (variant != 'missing declaration') 'tasks:read',
          if (variant.startsWith('extra') || variant == 'wildcard')
            'additional:read',
        ],
      },
  },
};

String _jobs(String id) => jsonEncode({
  'jobs': [
    {'id': id, 'name': '$id task', 'enabled': true},
  ],
});

class _Harness {
  _Harness(this.variant, {this.pathProfile = false}) {
    channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          reads.add(uri);
          final path = pathProfile
              ? uri.path.substring('/p/writer'.length)
              : uri.path;
          if (path == '/api/jobs') {
            final deferred = nextJobs;
            nextJobs = null;
            if (deferred != null) {
              jobsStarted.complete();
              return deferred.future;
            }
            if (failJobs) {
              throw const HermesApiTransportException(
                HermesApiTransportFailureKind.network,
              );
            }
            if (variant == 'bounded') {
              return jsonEncode({
                'jobs': [
                  for (var i = 0; i < 140; i++) {'id': 'job_$i'},
                ],
              });
            }
            return _jobs(uri.queryParameters['profile'] ?? 'unscoped');
          }
          return switch (path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => jsonEncode(_catalog(variant)),
            '/api/sessions' => '{"data":[]}',
            '/api/profiles' =>
              '{"data":[{"id":"default","is_default":true},{"id":"writer"}]}',
            '/v1/models' => '{"data":[{"id":"model-test"}]}',
            '/v1/skills' => '{"data":[{"name":"skill-test"}]}',
            '/v1/toolsets' => '{"data":[{"name":"tools-test","enabled":true}]}',
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
  final bool pathProfile;
  late final HermesApiChannel channel;
  final reads = <Uri>[];
  final mutations = <Uri>[];
  final jobsStarted = Completer<void>();
  Completer<String>? nextJobs;
  bool failJobs = false;

  List<Map<String, String>> get jobsReceipts => [
    for (final uri in reads)
      if (uri.path.endsWith('/api/jobs')) uri.queryParameters,
  ];

  Future<void> connect() => channel.connect(
    baseUrl: pathProfile
        ? 'http://127.0.0.1:8642/p/writer'
        : 'http://127.0.0.1:8642',
  );
}

void _expectOtherInventory(_Harness h) {
  expect(h.channel.state.status, HermesConnectionStatus.connected);
  expect(
    h.channel.state.models,
    h.variant == 'schema' ? isEmpty : ['model-test'],
  );
  expect(
    h.channel.state.skills,
    h.variant == 'schema' ? isEmpty : ['skill-test'],
  );
  expect(
    h.channel.state.enabledToolsets,
    h.variant == 'schema' ? isEmpty : ['tools-test'],
  );
  expect(h.channel.state.errorMessage, isNull);
  expect(h.mutations, isEmpty);
}

void main() {
  const denied = [
    'schema',
    'absent operation',
    'wrong operation',
    'method',
    'path',
    'missing grant',
    'admin only',
    'missing declaration',
    'extra missing',
    'context',
    'context name',
    'context optional',
    'context default',
  ];
  for (final variant in denied) {
    for (final select in [false, true]) {
      test(
        'bootstrap ${select ? 'select' : 'connect'} denies $variant',
        () async {
          final h = _Harness(variant);
          addTearDown(h.channel.dispose);
          await h.connect();
          if (select) {
            if (variant == 'schema' || variant.startsWith('context')) {
              final before = h.reads.length;
              await expectLater(
                h.channel.selectProfile('writer'),
                throwsStateError,
              );
              expect(h.reads.skip(before), isEmpty);
            } else {
              await h.channel.selectProfile('writer');
              expect(h.channel.state.selectedProfileId, 'writer');
              expect(h.channel.state.profiles.map((p) => p.id), [
                'default',
                'writer',
              ]);
            }
          }
          // Absolute request history includes initial connection, not a delta.
          expect(h.jobsReceipts, isEmpty);
          expect(h.channel.state.canReadJobs, isFalse);
          expect(h.channel.state.jobs, isEmpty);
          expect(h.channel.state.optionalResourceErrors, isEmpty);
          _expectOtherInventory(h);
          final before = h.reads.length;
          await expectLater(h.channel.loadJobs(), throwsStateError);
          expect(h.reads.skip(before), isEmpty);
        },
      );
    }
  }

  for (final variant in [
    'context',
    'context name',
    'context optional',
    'context default',
  ]) {
    test('enrolled-path selection denies unsupported jobs $variant', () async {
      final h = _Harness(variant, pathProfile: true);
      addTearDown(h.channel.dispose);
      await h.connect();
      await h.channel.selectProfile('writer');
      expect(h.channel.state.selectedProfileId, 'writer');
      expect(h.channel.state.profiles.map((p) => p.id), ['default', 'writer']);
      expect(h.jobsReceipts, isEmpty);
      expect(h.channel.state.canReadJobs, isFalse);
      expect(h.channel.state.optionalResourceErrors, isEmpty);
      _expectOtherInventory(h);
    });
  }

  test('authorized bootstrap retains the 128-job client bound', () async {
    final h = _Harness('bounded');
    addTearDown(h.channel.dispose);
    await h.connect();
    expect(h.channel.state.jobs, hasLength(128));
    expect(h.channel.state.jobs.last.id, 'job_127');
    await h.channel.selectProfile('writer');
    expect(h.channel.state.jobs, hasLength(128));
    expect(h.jobsReceipts, [
      {'profile': 'default', 'include_disabled': 'true'},
      {'profile': 'writer', 'include_disabled': 'true'},
    ]);
  });

  test(
    'authorized profile bootstrap failure is optional and explicit retry recovers',
    () async {
      final h = _Harness('scoped');
      addTearDown(h.channel.dispose);
      await h.connect();
      h.failJobs = true;
      await h.channel.selectProfile('writer');
      _expectOtherInventory(h);
      expect(h.channel.state.selectedProfileId, 'writer');
      expect(h.channel.state.canReadJobs, isTrue);
      expect(h.channel.state.jobs, isEmpty);
      expect(h.channel.state.optionalResourceErrors.keys, [
        HermesOptionalResource.jobs,
      ]);
      expect(
        h.channel.state.optionalResourceErrors.values.single,
        'Hermes API network connection failed',
      );
      expect(h.jobsReceipts, hasLength(2));
      h.failJobs = false;
      await h.channel.loadJobs();
      expect(h.channel.state.jobs.single.id, 'writer');
      expect(h.channel.state.optionalResourceErrors, isEmpty);
      expect(h.jobsReceipts, [
        {'profile': 'default', 'include_disabled': 'true'},
        {'profile': 'writer', 'include_disabled': 'true'},
        {'profile': 'writer', 'include_disabled': 'true'},
      ]);
    },
  );

  for (final variant in ['scoped', 'unscoped', 'extra granted', 'wildcard']) {
    test(
      'exact $variant bootstrap reads connect and explicit profile',
      () async {
        final h = _Harness(variant);
        addTearDown(h.channel.dispose);
        await h.connect();
        expect(h.channel.state.canReadJobs, isTrue);
        expect(h.channel.state.jobs.single.id, 'default');
        await h.channel.selectProfile('writer');
        expect(h.channel.state.jobs.single.id, 'writer');
        expect(h.channel.state.selectedProfileId, 'writer');
        expect(h.channel.state.profiles.map((p) => p.id), [
          'default',
          'writer',
        ]);
        expect(h.jobsReceipts, [
          {'profile': 'default', 'include_disabled': 'true'},
          {'profile': 'writer', 'include_disabled': 'true'},
        ]);
        _expectOtherInventory(h);
      },
    );
  }

  test(
    'genuinely unscoped jobs do not require supported profile context',
    () async {
      final h = _Harness('unscoped context');
      addTearDown(h.channel.dispose);
      await h.connect();
      expect(h.channel.state.canReadJobs, isTrue);
      expect(h.channel.state.selectedProfileId, isNull);
      expect(h.jobsReceipts, [
        {'include_disabled': 'true'},
      ]);
      expect(h.channel.state.jobs.single.id, 'unscoped');
      await expectLater(h.channel.selectProfile('writer'), throwsStateError);
      expect(h.jobsReceipts, hasLength(1));
      _expectOtherInventory(h);
    },
  );

  for (final failure in [false, true]) {
    for (final transition in ['disconnect', 'reconnect', 'dispose']) {
      test('pending connect $failure fenced by $transition', () async {
        final h = _Harness('scoped');
        final delayed = Completer<String>();
        h.nextJobs = delayed;
        final connecting = h.connect();
        await h.jobsStarted.future;
        if (transition == 'dispose') {
          h.channel.dispose();
        } else {
          addTearDown(h.channel.dispose);
          if (transition == 'disconnect') {
            await h.channel.disconnect();
          } else {
            await h.connect();
          }
        }
        final snapshot = h.channel.state;
        if (failure) {
          delayed.completeError(
            StateError('obsolete private transport details'),
          );
        } else {
          delayed.complete(_jobs('obsolete'));
        }
        await connecting;
        expect(identical(h.channel.state, snapshot), isTrue);
        expect(h.channel.state.jobs.any((j) => j.id == 'obsolete'), isFalse);
        expect(h.channel.state.optionalResourceErrors, isEmpty);
        expect(h.jobsReceipts, hasLength(transition == 'reconnect' ? 2 : 1));
      });
    }

    for (final transition in ['A-B-A', 'disconnect', 'reconnect', 'dispose']) {
      test(
        'pending profile bootstrap $failure fenced by $transition',
        () async {
          final h = _Harness('scoped');
          await h.connect();
          final delayed = Completer<String>();
          h.nextJobs = delayed;
          final selecting = h.channel.selectProfile('writer');
          await h.jobsStarted.future;
          if (transition == 'dispose') {
            h.channel.dispose();
          } else {
            addTearDown(h.channel.dispose);
            if (transition == 'disconnect') {
              await h.channel.disconnect();
            } else if (transition == 'reconnect') {
              await h.connect();
            } else {
              await h.channel.selectProfile('default');
              await h.channel.selectProfile('writer');
            }
          }
          final snapshot = h.channel.state;
          if (failure) {
            delayed.completeError(
              StateError('obsolete private transport details'),
            );
          } else {
            delayed.complete(_jobs('obsolete'));
          }
          await selecting;
          expect(identical(h.channel.state, snapshot), isTrue);
          expect(h.channel.state.jobs.any((j) => j.id == 'obsolete'), isFalse);
          expect(h.channel.state.optionalResourceErrors, isEmpty);
          if (transition == 'A-B-A') {
            expect(h.channel.state.selectedProfileId, 'writer');
            expect(h.channel.state.jobs.single.id, 'writer');
            expect(h.channel.state.profiles.map((p) => p.id), [
              'default',
              'writer',
            ]);
          }
          expect(
            h.jobsReceipts,
            hasLength(
              transition == 'A-B-A'
                  ? 4
                  : transition == 'reconnect'
                  ? 3
                  : 2,
            ),
          );
        },
      );
    }

    test(
      'explicit jobs request generation rejects older completion $failure',
      () async {
        final h = _Harness('scoped');
        addTearDown(h.channel.dispose);
        await h.connect();
        final delayed = Completer<String>();
        h.nextJobs = delayed;
        final old = h.channel.loadJobs();
        final oldResult = failure ? expectLater(old, throwsStateError) : old;
        await h.jobsStarted.future;
        await h.channel.loadJobs();
        final snapshot = h.channel.state;
        if (failure) {
          delayed.completeError(
            StateError('obsolete private transport details'),
          );
        } else {
          delayed.complete(_jobs('obsolete'));
        }
        await oldResult;
        expect(identical(h.channel.state, snapshot), isTrue);
        expect(h.jobsReceipts, hasLength(3));
      },
    );
  }

  for (final width in [390.0, 1280.0]) {
    for (final mode in ['denied', 'failure', 'success']) {
      testWidgets(
        'actual bootstrap Schedules $mode at $width 200% reduced motion',
        (tester) async {
          tester.view.physicalSize = Size(width, 1800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final h = _Harness(mode == 'denied' ? 'extra missing' : 'scoped');
          h.failJobs = mode == 'failure';
          addTearDown(h.channel.dispose);
          await h.connect();
          _expectOtherInventory(h);
          await tester.pumpWidget(
            ProviderScope(
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
                home: const SchedulesScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (mode == 'denied') {
            expect(h.jobsReceipts, isEmpty);
            expect(h.channel.state.canReadJobs, isFalse);
            expect(h.channel.state.optionalResourceErrors, isEmpty);
            expect(find.text('Schedules unavailable'), findsOneWidget);
            expect(find.text('No schedules yet'), findsNothing);
            expect(find.text('Retry'), findsNothing);
            expect(
              find.byKey(const ValueKey('schedules-refresh-button')),
              findsNothing,
            );
            expect(
              find.byKey(const ValueKey('schedules-search')),
              findsNothing,
            );
          } else if (mode == 'failure') {
            expect(h.channel.state.canReadJobs, isTrue);
            expect(h.channel.state.optionalResourceErrors.keys, [
              HermesOptionalResource.jobs,
            ]);
            expect(
              find.text('Schedules could not be loaded from Hermes.'),
              findsOneWidget,
            );
            expect(find.textContaining('private transport'), findsNothing);
            expect(
              find.byKey(const ValueKey('schedules-search')),
              findsNothing,
            );
            expect(h.jobsReceipts, hasLength(1));
            h.failJobs = false;
            await tester.tap(find.text('Retry'));
            await tester.pumpAndSettle();
            expect(h.channel.state.optionalResourceErrors, isEmpty);
            expect(find.text('default task'), findsOneWidget);
            expect(h.jobsReceipts, hasLength(2));
          } else {
            expect(find.text('default task'), findsOneWidget);
            expect(
              find.byKey(const ValueKey('schedules-search')),
              findsOneWidget,
            );
            expect(h.jobsReceipts, hasLength(1));
          }
          expect(tester.takeException(), isNull);
          expect(h.mutations, isEmpty);
        },
      );
    }
  }
}
