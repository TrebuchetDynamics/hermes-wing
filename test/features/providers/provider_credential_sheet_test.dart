import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/features/providers/widgets/provider_credential_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

/// A full secret value that must NEVER appear anywhere in the widget tree.
/// The server contract is write-only: the sheet only ever knows presence
/// (`configured`) and a masked last-4 hint — never a raw key.
const _sentinelStoredKey = 'sk-SENTINEL-STORED-KEY-DO-NOT-RENDER-0001';

const _configuredProvider = HermesProvider(
  slug: 'openai',
  label: 'OpenAI',
  authType: 'api_key',
  envVars: ['OPENAI_API_KEY'],
  configured: true,
  keyHint: '····k9z8',
);

Widget _hostSheet(FakeHermesChannel channel, HermesProvider provider) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ProviderCredentialSheet(channel: channel, provider: provider),
      ),
    );

Iterable<String> _allRenderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
    .toList();

HermesCapabilityDocument _credentialCapabilities({String? only}) =>
    HermesCapabilityDocument.fromJson({
      'schema_version': 1,
      'profile_context': {'type': 'query', 'name': 'profile', 'required': true},
      'auth': {
        'granted_scopes': ['providers:write'],
      },
      'endpoints': {
        if (only == null || only == 'set')
          'provider_credential_set': {
            'method': 'PUT',
            'path': '/api/providers/{slug}/credential',
            'required_scopes': ['providers:write'],
          },
        if (only == null || only == 'delete')
          'provider_credential_delete': {
            'method': 'DELETE',
            'path': '/api/providers/{slug}/credential',
            'required_scopes': ['providers:write'],
          },
        if (only == null || only == 'validate')
          'provider_credential_validate': {
            'method': 'POST',
            'path': '/api/providers/{slug}/credential/validate',
            'required_scopes': ['providers:write'],
          },
      },
    });

void main() {
  for (final only in [null, 'set', 'delete', 'validate', 'none']) {
    testWidgets('legacy credential contract never collects secrets: $only', (
      tester,
    ) async {
      final channel = FakeHermesChannel(
        capabilities: _credentialCapabilities(only: only),
        providers: const [_configuredProvider],
      );
      addTearDown(channel.dispose);
      await tester.pumpWidget(_hostSheet(channel, _configuredProvider));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      for (final label in ['Set', 'Remove', 'Validate']) {
        expect(find.text(label), findsNothing);
      }
      expect(
        find.textContaining('Manage credentials directly in Hermes Agent'),
        findsOneWidget,
      );
      expect(
        _allRenderedText(tester).join(),
        isNot(contains(_sentinelStoredKey)),
      );
      expect(channel.setProviderCredentialCalls, isEmpty);
      expect(channel.removeProviderCredentialCalls, isEmpty);
      expect(channel.validateProviderCredentialCalls, isEmpty);
    });
  }
  testWidgets(
    'unavailable credential explanation fits enlarged compact layout',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: ProviderCredentialSheet(
                channel: channel,
                provider: _configuredProvider,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    },
  );
}
