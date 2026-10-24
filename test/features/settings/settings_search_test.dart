import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'settings search selects supported category without Agent calls at $width',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'wing.appearance.avatar_variation.v1': 5,
        });
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = FakeHermesChannel();
        addTearDown(channel.dispose);
        String? selected;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [hermesChannelProvider.overrideWithValue(channel)],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: SettingsScreen(
                onCategoryChanged: (value) => selected = value,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('wing-avatar-family-0')),
          findsNothing,
        );
        await tester.tap(find.byKey(const ValueKey('settings-search')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'no.match.[literal]');
        await tester.pumpAndSettle();
        expect(find.text('No matching settings'), findsOneWidget);
        expect(selected, isNull);
        await tester.enterText(find.byType(TextField), 'VOICE');
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('settings-search-result-voice')),
        );
        await tester.pumpAndSettle();
        expect(selected, 'config:voice');
        expect(
          find.byKey(const ValueKey('settings-content-voice')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('settings-search')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'dark theme');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('settings-search-result-appearance')),
          findsOneWidget,
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(selected, 'config:voice');
        expect(channel.connectCalls, isEmpty);
        expect(channel.selectProfileCalls, isEmpty);
        expect(channel.setProviderCredentialCalls, isEmpty);
        expect(channel.loadProvidersCalls, 0);
        expect(channel.loadModelsCalls, 0);
        expect(
          (await SharedPreferences.getInstance()).getInt(
            'wing.appearance.avatar_variation.v1',
          ),
          5,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
