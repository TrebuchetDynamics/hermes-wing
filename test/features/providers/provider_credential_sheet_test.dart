import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/models/hermes_provider.dart';
import 'package:navivox/features/providers/widgets/provider_credential_sheet.dart';
import 'package:navivox/l10n/app_localizations.dart';

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

void main() {
  testWidgets('never renders a stored key even when configured', (
    tester,
  ) async {
    final channel = FakeHermesChannel(providers: const [_configuredProvider]);
    addTearDown(channel.dispose);

    await tester.pumpWidget(_hostSheet(channel, _configuredProvider));
    await tester.pumpAndSettle();

    // The masked hint is the single sanctioned derived disclosure.
    expect(find.textContaining('····k9z8'), findsOneWidget);

    // No rendered text anywhere contains a full stored key.
    for (final text in _allRenderedText(tester)) {
      expect(text.contains(_sentinelStoredKey), isFalse);
      expect(text.contains('k9z8') && !text.contains('····'), isFalse);
    }
  });

  testWidgets('the obscured value input starts empty', (tester) async {
    final channel = FakeHermesChannel(providers: const [_configuredProvider]);
    addTearDown(channel.dispose);

    await tester.pumpWidget(_hostSheet(channel, _configuredProvider));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
    expect(field.controller?.text ?? '', isEmpty);
  });

  testWidgets('set forwards the typed value via setProviderCredential', (
    tester,
  ) async {
    final channel = FakeHermesChannel(providers: const [_configuredProvider]);
    addTearDown(channel.dispose);

    await tester.pumpWidget(_hostSheet(channel, _configuredProvider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'typed-new-secret-xyz');
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    expect(channel.setProviderCredentialCalls, isNotEmpty);
    expect(channel.setProviderCredentialCalls.last, {
      'slug': 'openai',
      'envVar': 'OPENAI_API_KEY',
      'value': 'typed-new-secret-xyz',
    });
  });

  testWidgets('remove calls removeProviderCredential', (tester) async {
    final channel = FakeHermesChannel(providers: const [_configuredProvider]);
    addTearDown(channel.dispose);

    await tester.pumpWidget(_hostSheet(channel, _configuredProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(channel.removeProviderCredentialCalls, [
      {'slug': 'openai', 'envVar': 'OPENAI_API_KEY'},
    ]);
  });

  testWidgets('validate calls validateProviderCredential and shows detail', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      providers: const [_configuredProvider],
      validateProviderResult: const HermesCredentialProbe(
        ok: true,
        detail: 'Credential accepted.',
      ),
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_hostSheet(channel, _configuredProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Validate'));
    await tester.pumpAndSettle();

    expect(channel.validateProviderCredentialCalls, ['openai']);
    expect(find.textContaining('Credential accepted.'), findsOneWidget);
  });
}
