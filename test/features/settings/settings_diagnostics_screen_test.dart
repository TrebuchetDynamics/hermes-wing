import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

void main() {
  testWidgets('shows bounded inventory failures without raw errors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel(
      errorMessage: 'https://private-host.example/internal stack trace',
      optionalResourceErrors: const {
        HermesOptionalResource.skills: 'Authorization: Bearer private-value',
        HermesOptionalResource.models: '/home/operator/private-models',
      },
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DiagnosticsSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inventory warnings'), findsOneWidget);
    expect(find.text('Models, skills unavailable'), findsOneWidget);
    expect(find.textContaining('private-value'), findsNothing);
    expect(find.textContaining('private-host'), findsNothing);
    expect(find.text('No health details yet'), findsOneWidget);
    expect(find.textContaining('/home/operator'), findsNothing);
  });

  testWidgets('reserves edge-to-edge navigation inset below diagnostics', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.zero,
              viewPadding: const EdgeInsets.only(bottom: 32),
            ),
            child: child!,
          ),
          home: const DiagnosticsSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final list = tester.widget<ListView>(find.byType(ListView));
    final padding = list.padding! as EdgeInsets;
    expect(padding.bottom, 48);
  });

  testWidgets('copies the bounded Hermes diagnostics snapshot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.connected,
      models: const ['hermes-3'],
    );
    addTearDown(channel.dispose);
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DiagnosticsSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final copy = find.byKey(const ValueKey('settings-copy-diagnostics'));
    await tester.scrollUntilVisible(copy, 300);
    await tester.tap(copy);
    await tester.pump();

    expect(copiedText, contains('Hermes Wing diagnostics'));
    expect(copiedText, contains('Models: hermes-3'));
    expect(copiedText, contains('Secrets: excluded'));
    expect(find.text('Hermes diagnostics copied'), findsOneWidget);
  });

  testWidgets('blocks duplicate copies while the clipboard is pending', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    final clipboardGate = Completer<void>();
    var copyCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copyCalls += 1;
            await clipboardGate.future;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DiagnosticsSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final copy = find.byKey(const ValueKey('settings-copy-diagnostics'));
    await tester.scrollUntilVisible(copy, 300);
    await tester.tap(copy);
    await tester.pump();

    expect(copyCalls, 1);
    expect(tester.widget<ListTile>(copy).onTap, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    clipboardGate.complete();
    await tester.pumpAndSettle();
    expect(copyCalls, 1);
    expect(find.text('Hermes diagnostics copied'), findsOneWidget);
  });

  testWidgets('reports clipboard failure without claiming success', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'clipboard-unavailable');
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DiagnosticsSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final copy = find.byKey(const ValueKey('settings-copy-diagnostics'));
    await tester.scrollUntilVisible(copy, 300);
    await tester.tap(copy);
    await tester.pump();

    expect(find.text('Could not copy diagnostics. Try again.'), findsOneWidget);
    expect(find.text('Hermes diagnostics copied'), findsNothing);
  });
}
