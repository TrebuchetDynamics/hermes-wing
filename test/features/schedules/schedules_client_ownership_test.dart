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
import 'package:wing/l10n/app_localizations.dart';

const _refresh = ValueKey('schedules-refresh-button');

String _capabilities({String rejection = ''}) => jsonEncode({
  'schema_version': rejection == 'schema' ? 2 : 1,
  'profile_context': {
    'type': rejection == 'context' ? 'header' : 'query',
    'name': 'profile',
    'required': true,
    'default_profile_id': 'default',
  },
  'auth': {
    'type': 'bearer',
    'required': true,
    'granted_scopes': ['tasks:read', 'profiles:read'],
  },
  'endpoints': {
    'profiles': {
      'method': 'GET',
      'path': '/api/profiles',
      'required_scopes': ['profiles:read'],
    },
    'jobs': {
      'method': rejection == 'method' ? 'POST' : 'GET',
      'path': rejection == 'path' ? '/api/other' : '/api/jobs',
      'profile_scoped': true,
      'required_scopes': [
        'tasks:read',
        if (rejection == 'extra grant') 'ungranted:read',
      ],
    },
  },
});

Widget _app(HermesApiChannel channel) => ProviderScope(
  overrides: [hermesChannelProvider.overrideWithValue(channel)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const SchedulesScreen(),
  ),
);

void main() {
  for (final rejection in [
    'schema',
    'context',
    'method',
    'path',
    'extra grant',
  ]) {
    testWidgets(
      'actual explicit jobs admission rejects $rejection without jobs I/O',
      (tester) async {
        final reads = <Uri>[];
        final channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async {
              reads.add(uri);
              return switch (uri.path) {
                '/health' => '{"status":"ok"}',
                '/v1/capabilities' => _capabilities(rejection: rejection),
                '/api/sessions' => '{"data":[]}',
                '/api/profiles' =>
                  '{"data":[{"id":"default","is_default":true}]}',
                _ => throw StateError('unexpected deterministic read'),
              };
            },
          ),
        );
        addTearDown(channel.dispose);
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        await tester.pumpWidget(_app(channel));
        await tester.pumpAndSettle();
        expect(find.byKey(_refresh), findsNothing);
        final before = reads.length;
        await expectLater(channel.loadJobs(), throwsStateError);
        expect(reads.skip(before), isEmpty);
      },
    );
  }

  for (final fails in [false, true]) {
    testWidgets(
      'actual jobs profile transition fences callbacks/completion $fails',
      (tester) async {
        final oldJobs = Completer<String>();
        final currentJobs = Completer<String>();
        final selecting = Completer<String>();
        final receipts = <Map<String, String>>[];
        var deferOld = false;
        var deferCurrent = false;
        var deferSelection = false;
        final channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async {
              if (uri.path == '/api/jobs') {
                receipts.add(uri.queryParameters);
                if (deferOld) {
                  deferOld = false;
                  return oldJobs.future;
                }
                if (deferCurrent) {
                  deferCurrent = false;
                  return currentJobs.future;
                }
                return '{"jobs":[{"id":"current","name":"Current task","enabled":true}]}';
              }
              if (uri.path == '/api/sessions' && deferSelection) {
                deferSelection = false;
                return selecting.future;
              }
              return switch (uri.path) {
                '/health' => '{"status":"ok"}',
                '/v1/capabilities' => _capabilities(),
                '/api/profiles' =>
                  '{"data":[{"id":"default","is_default":true},{"id":"writer"}]}',
                '/api/sessions' => '{"data":[]}',
                _ => throw StateError('unexpected deterministic read'),
              };
            },
          ),
        );
        addTearDown(channel.dispose);
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        expect(channel.state.status, HermesConnectionStatus.connected);
        await tester.pumpWidget(_app(channel));
        await tester.pumpAndSettle();
        final cachedButton = tester
            .widget<IconButton>(find.byKey(_refresh))
            .onPressed!;
        final cachedPull = tester
            .widget<RefreshIndicator>(find.byType(RefreshIndicator))
            .onRefresh;
        deferOld = true;
        cachedButton();
        await tester.pump();
        expect(receipts, hasLength(2));
        deferSelection = true;
        final switchProfile = channel.selectProfile('writer');
        expect(channel.state.isSelectingProfile, isTrue);
        cachedButton();
        await cachedPull();
        expect(receipts, hasLength(2));
        selecting.complete('{"data":[]}');
        await switchProfile;
        await channel.selectProfile('default');
        await tester.pumpAndSettle();
        expect(
          receipts,
          hasLength(4),
        ); // Bootstrap reads for each selected profile.
        cachedButton();
        await cachedPull();
        expect(receipts, hasLength(4));
        deferCurrent = true;
        tester.widget<IconButton>(find.byKey(_refresh)).onPressed!();
        await tester.pump();
        expect(receipts, hasLength(5));
        if (fails) {
          oldJobs.completeError(
            StateError('obsolete private transport failure'),
          );
        } else {
          oldJobs.complete(
            '{"jobs":[{"id":"obsolete","name":"Obsolete task"}]}',
          );
        }
        await tester.pump();
        expect(channel.state.jobs.single.id, 'current');
        expect(channel.state.optionalResourceErrors, isEmpty);
        expect(
          tester.widget<IconButton>(find.byKey(_refresh)).onPressed,
          isNull,
        );
        expect(
          find.text('Schedules could not be loaded from Hermes.'),
          findsNothing,
        );
        currentJobs.complete(
          '{"jobs":[{"id":"fresh","name":"Fresh task","enabled":true}]}',
        );
        await tester.pumpAndSettle();
        expect(channel.state.jobs.single.id, 'fresh');
        expect(find.text('Fresh task'), findsOneWidget);
        expect(receipts, [
          {'profile': 'default', 'include_disabled': 'true'},
          {'profile': 'default', 'include_disabled': 'true'},
          {'profile': 'writer', 'include_disabled': 'true'},
          {'profile': 'default', 'include_disabled': 'true'},
          {'profile': 'default', 'include_disabled': 'true'},
        ]);
      },
    );
  }
}
