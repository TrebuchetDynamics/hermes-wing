import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';

import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/profiles/screens/profiles_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

final _search = find.byKey(const ValueKey('profiles-search'));
HermesCapabilityDocument _caps({
  bool read = true,
  List<String> requiredScopes = const ['profiles:read'],
  List<String>? grantedScopes,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'auth': {
    'type': 'bearer',
    'granted_scopes': grantedScopes ?? (read ? ['profiles:read'] : []),
  },
  'endpoints': {
    'profiles': {
      'method': 'GET',
      'path': '/api/profiles',
      'required_scopes': requiredScopes,
    },
  },
});
const _native = [
  HermesProfile(id: 'native', displayName: 'Native', revision: 'n1'),
];
Widget _app(ProviderContainer container, {double scale = 1}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const ProfilesScreen(),
      ),
    );
ProviderContainer _container(
  FakeHermesChannel channel,
  HermesGatewayDirectory directory,
) => ProviderContainer(
  overrides: [
    hermesChannelProvider.overrideWithValue(channel),
    hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
  ],
);
Future<void> _query(WidgetTester tester, String value) async {
  await tester.ensureVisible(_search);
  await tester.enterText(_search, value);
  await tester.pumpAndSettle();
}

String _queryValue(WidgetTester tester) =>
    tester.widget<TextField>(_search).controller!.text;

void main() {
  for (final sameFrame in [false, true]) {
    testWidgets(
      'additional native read grant loss ${sameFrame ? 'same-frame' : 'visible'} discards query without resurrection',
      (tester) async {
        final allowed = _caps(
          requiredScopes: ['profiles:read', 'profiles:write'],
          grantedScopes: ['profiles:read', 'profiles:write'],
        );
        final denied = _caps(
          requiredScopes: ['profiles:read', 'profiles:write'],
          grantedScopes: ['profiles:read'],
        );
        final channel = FakeHermesChannel(
          capabilities: allowed,
          profiles: _native,
          selectedProfileId: 'native',
        );
        final directory = directoryFor(
          configs: [],
          loader: FakeGatewaySummaryLoader({}),
          activeChannel: channel,
        );
        final container = _container(channel, directory);
        addTearDown(container.dispose);
        addTearDown(channel.dispose);
        await tester.pumpWidget(_app(container));
        await tester.pumpAndSettle();
        await _query(tester, 'native');
        channel.replaceCapabilitiesAndProfiles(denied, _native);
        if (!sameFrame) {
          await tester.pumpAndSettle();
          expect(_search, findsNothing);
          expect(find.text('Native'), findsNothing);
          expect(find.text('Profiles unavailable'), findsOneWidget);
        }
        channel.replaceCapabilitiesAndProfiles(allowed, _native);
        await tester.pumpAndSettle();
        expect(_queryValue(tester), isEmpty);
        expect(find.text('Native'), findsOneWidget);
        expect(channel.state.selectedProfileId, 'native');
        expect(channel.selectProfileCalls, isEmpty);
        expect(channel.connectCalls, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'authorized same-owner native required-scope updates preserve query',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _caps(),
        profiles: _native,
      );
      final directory = directoryFor(
        configs: [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      final container = _container(channel, directory);
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _query(tester, 'native');
      for (final scopes in [
        ['profiles:read', 'profiles:write'],
        ['*'],
      ]) {
        channel.replaceCapabilitiesAndProfiles(
          _caps(
            requiredScopes: ['profiles:read', 'profiles:write'],
            grantedScopes: scopes,
          ),
          _native,
        );
        await tester.pumpAndSettle();
        expect(_queryValue(tester), 'native');
        expect(find.text('Native'), findsOneWidget);
      }
      expect(channel.selectProfileCalls, isEmpty);
      expect(channel.connectCalls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'replacement Agent client with same IDs discards search and listens to the new client',
    (tester) async {
      final first = FakeHermesChannel(capabilities: _caps(), profiles: _native);
      final second = FakeHermesChannel(
        capabilities: _caps(),
        profiles: _native,
      );
      final directory = directoryFor(
        configs: [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: first,
      );
      final container = _container(first, directory);
      addTearDown(container.dispose);
      // The ChangeNotifier provider owns directory disposal.
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _query(tester, 'old private');
      container.updateOverrides([
        hermesChannelProvider.overrideWithValue(second),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
      ]);
      await tester.pumpAndSettle();
      expect(_queryValue(tester), isEmpty);
      await _query(tester, 'native');
      second.replaceCapabilitiesAndProfiles(_caps(read: false), _native);
      second.replaceCapabilitiesAndProfiles(_caps(), _native);
      await tester.pumpAndSettle();
      expect(_queryValue(tester), isEmpty);
    },
  );

  testWidgets(
    'visible search action selects exact native ID without changing hidden active owner first',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _caps(),
        selectedProfileId: 'home',
        profiles: const [
          HermesProfile(id: 'home', displayName: 'Same label', revision: 'r1'),
          HermesProfile(
            id: 'target',
            displayName: 'Same label',
            revision: 'r2',
          ),
        ],
      );
      final directory = directoryFor(
        configs: [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      final container = _container(channel, directory);
      addTearDown(container.dispose);
      // The ChangeNotifier provider owns directory disposal.
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _query(tester, 'TARGET');
      expect(channel.state.selectedProfileId, 'home');
      expect(channel.selectProfileCalls, isEmpty);
      expect(find.text('Active chat'), findsNothing);
      final button = find.byKey(const ValueKey('agent-chat-target'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(channel.selectProfileCalls, ['target']);
      expect(channel.state.selectedProfileId, 'target');
    },
  );
}
