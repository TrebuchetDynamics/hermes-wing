import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/settings/providers/chat_preferences_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'chat size persists without rounding saved pinch zoom at $width',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'wing.chat.transcript_text_scale': 1.37,
        });
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const SettingsScreen(initialPage: 'typography'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final custom = find.byKey(
          const ValueKey('settings-chat-text-scale-137'),
        );
        expect(tester.widget<ChoiceChip>(custom).selected, isTrue);
        expect(
          container.read(wingChatPreferencesProvider).transcriptTextScale,
          1.37,
        );
        final target = find.byKey(
          const ValueKey('settings-chat-text-scale-150'),
        );
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(tester.widget<ChoiceChip>(target).selected, isTrue);
        expect(
          container.read(wingChatPreferencesProvider).transcriptTextScale,
          1.5,
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('wing.chat.transcript_text_scale'), 1.5);
        expect(prefs.getString('wing.theme.mode'), isNull);
        final reloaded = ProviderContainer();
        addTearDown(reloaded.dispose);
        reloaded.read(wingChatPreferencesProvider);
        await tester.pumpAndSettle();
        expect(
          reloaded.read(wingChatPreferencesProvider).transcriptTextScale,
          1.5,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
