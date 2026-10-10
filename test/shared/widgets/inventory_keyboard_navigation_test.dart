import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';

import '../../features/hermes_chat/support/fake_hermes_endpoint_store.dart';

void main() {
  for (final route in ['/tools', '/tasks', '/providers', '/profiles']) {
    for (final width in [390.0, 1280.0]) {
      testWidgets('shell keyboard semantics survive $route at $width / 200%', (
        tester,
      ) async {
        tester.view.physicalSize = Size(
          width,
          route == '/profiles' ? 1400 : 900,
        );
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final reads = <Uri>[];
        final channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, _) async {
              reads.add(uri);
              return jsonEncode(switch (uri.path) {
                '/health' => {'status': 'ok'},
                '/v1/capabilities' => {
                  'schema_version': 1,
                  'profile_context': {
                    'type': 'query',
                    'name': 'profile',
                    'required': true,
                    'default_profile_id': 'default',
                  },
                  'auth': {
                    'granted_scopes': [
                      'tasks:read',
                      if (route == '/profiles') 'profiles:read',
                      if (route == '/providers') ...[
                        'providers:read',
                        'models:read',
                      ],
                    ],
                  },
                  'endpoints': {
                    if (route == '/profiles')
                      'profiles': {
                        'method': 'GET',
                        'path': '/api/profiles',
                        'profile_scoped': false,
                        'required_scopes': ['profiles:read'],
                      },
                    if (route == '/providers') ...{
                      'providers': {
                        'method': 'GET',
                        'path': '/api/providers',
                        'profile_scoped': true,
                        'required_scopes': ['providers:read'],
                      },
                      'models': {
                        'method': 'GET',
                        'path': '/api/models',
                        'profile_scoped': true,
                        'required_scopes': ['models:read'],
                      },
                    },
                    'jobs': {
                      'method': 'GET',
                      'path': '/api/jobs',
                      'profile_scoped': true,
                      'required_scopes': ['tasks:read'],
                    },
                    'skills': {
                      'method': 'GET',
                      'path': '/v1/skills',
                      'profile_scoped': true,
                    },
                    'toolsets': {
                      'method': 'GET',
                      'path': '/v1/toolsets',
                      'profile_scoped': true,
                    },
                  },
                },
                '/api/sessions' => {'data': <Object>[]},
                '/api/profiles' => {
                  'data': [
                    {
                      'id': 'default',
                      'name': 'Fixture profile',
                      'revision': 'fixture-revision',
                    },
                  ],
                },
                '/api/providers' => {
                  'data': [
                    {
                      'slug': 'fixture-provider',
                      'label': 'Fixture provider',
                      'configured': true,
                    },
                  ],
                },
                '/api/models' => {
                  'active': {
                    'provider': 'fixture-provider',
                    'model': 'fixture-model',
                  },
                  'auxiliary': <Object>[],
                  'revision': 'fixture-revision',
                },
                '/v1/skills' => {
                  'data': [
                    {'name': 'fixture-skill', 'description': 'Synthetic skill'},
                  ],
                },
                '/v1/toolsets' => {
                  'data': [
                    {
                      'name': 'fixture-tools',
                      'label': 'Fixture tools',
                      'tools': ['read_file'],
                    },
                  ],
                },
                '/api/jobs' => {
                  'jobs': [
                    {
                      'id': 'fixture-job',
                      'name': 'Fixture job',
                      'enabled': true,
                    },
                  ],
                },
                _ => throw StateError('unexpected deterministic read'),
              });
            },
            post: (_, _, _) => throw StateError('unexpected mutation'),
          ),
        );
        addTearDown(channel.dispose);
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        // Explicit already-default inventory bootstrap, before keyboard actions.
        if (route == '/profiles') await channel.selectProfile('default');
        final initial = reads.length;
        final container = ProviderContainer(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesEndpointStoreProvider.overrideWithValue(
              FakeHermesEndpointStore(profiles: const []),
            ),
          ],
        );
        addTearDown(container.dispose);
        final router = container.read(routerProvider)..go(route);
        addTearDown(router.dispose);
        final semantics = tester.ensureSemantics();
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
        await tester.pumpAndSettle();
        if (route == '/providers') {
          expect(
            reads.skip(initial).map((uri) => uri.path),
            unorderedEquals(['/api/providers', '/api/models']),
          );
          for (final uri in reads.skip(initial)) {
            expect(uri.queryParameters, {'profile': 'default'});
          }
          expect(find.text('fixture-provider / fixture-model'), findsOneWidget);
        }
        final beforeKeys = reads.length;
        if (route == '/profiles') {
          final inventoryReads = reads.where(
            (uri) => uri.path == '/api/profiles',
          );
          expect(inventoryReads, hasLength(1));
          // The administrative collection belongs to the connected host, not
          // a profile query; only profile-owned reads carry that query.
          expect(inventoryReads.single.queryParameters, isEmpty);
          expect(channel.state.profiles.single.displayName, 'Fixture profile');
          expect(channel.state.profiles.single.revision, 'fixture-revision');
          expect(channel.state.selectedProfileId, 'default');
        }
        var chatFocusable = false;
        void inspect(SemanticsNode node) {
          if (node.label.split('\n').first == 'Chat' &&
              node.flagsCollection.isFocused.toBoolOrNull() != null) {
            chatFocusable = true;
          }
          node.visitChildren((child) {
            inspect(child);
            return true;
          });
        }

        tester.binding.rootPipelineOwner.visitChildren((owner) {
          final root = owner.semanticsOwner?.rootSemanticsNode;
          if (root != null) inspect(root);
        });
        if (route == '/profiles') {
          // Profiles is a modal destination: the background shell must not be
          // exposed to semantics or keyboard traversal while it is open.
          expect(chatFocusable, isFalse);
          final close = find.byKey(
            const ValueKey('chat-workspace-overlay-close'),
          );
          expect(tester.getSemantics(close).tooltip, 'Close');
          expect(
            tester.getSemantics(close).flagsCollection.isFocused.toBoolOrNull(),
            isTrue,
          );
        } else {
          expect(chatFocusable, isTrue);
        }
        semantics.dispose();
        // Traverse from the actual route focus scope, not requested editor focus.
        var reachedEditor = false;
        for (var step = 0; step < 32; step++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          final editor = find.byType(EditableText).first;
          if (tester.widget<EditableText>(editor).focusNode.hasFocus) {
            reachedEditor = true;
            break;
          }
        }
        expect(reachedEditor, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).first)
              .focusNode
              .hasFocus,
          isFalse,
        );
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).first)
              .focusNode
              .hasFocus,
          isTrue,
        );
        expect(reads.skip(beforeKeys), isEmpty);
        if (route == '/profiles') {
          expect(channel.state.selectedProfileId, 'default');
          expect(channel.state.profiles.single.id, 'default');
          expect(router.routeInformationProvider.value.uri.path, '/profiles');
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('chat-workspace-overlay-close')),
            findsNothing,
          );
          expect(router.routeInformationProvider.value.uri.path, '/hermes');
          expect(channel.state.selectedProfileId, 'default');
          expect(reads.skip(beforeKeys), isEmpty);
        }
        if (route != '/providers') expect(reads.skip(initial), isEmpty);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
