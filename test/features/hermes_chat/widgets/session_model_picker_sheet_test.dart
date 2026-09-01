import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_model_options.dart';
import 'package:wing/features/hermes_chat/widgets/session_model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

Widget _app({
  required HermesModelOptions options,
  required Future<void> Function(String provider, String model) onLock,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SessionModelPickerSheet(options: options, onLock: onLock),
  ),
);

void main() {
  testWidgets('locks the selected provider/model without profile assignment', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      _app(
        options: HermesModelOptions(
          currentProvider: 'openrouter',
          currentModel: 'openai/gpt-5',
          providers: const [
            HermesModelOptionProvider(
              slug: 'openrouter',
              label: 'OpenRouter',
              models: ['openai/gpt-5', 'anthropic/claude'],
              isCurrent: true,
            ),
          ],
        ),
        onLock: (provider, model) async => calls.add('$provider/$model'),
      ),
    );

    expect(find.text('Use a model for this session'), findsOneWidget);
    expect(find.text('openai/gpt-5'), findsOneWidget);
    await tester.tap(find.text('Use for session'));
    await tester.pumpAndSettle();

    expect(calls, ['openrouter/openai/gpt-5']);
  });

  testWidgets('does not offer unconfigured provider rows', (tester) async {
    await tester.pumpWidget(
      _app(
        options: HermesModelOptions(
          providers: const [
            HermesModelOptionProvider(
              slug: 'configured',
              label: 'Configured',
              models: ['model-a'],
              isUserDefined: true,
            ),
            HermesModelOptionProvider(
              slug: 'authenticated',
              label: 'Authenticated',
              models: ['model-b'],
              authenticated: true,
            ),
            HermesModelOptionProvider(
              slug: 'unconfigured',
              label: 'Unconfigured',
              models: ['model-c'],
            ),
          ],
        ),
        onLock: (provider, model) async {},
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Configured'), findsWidgets);
    expect(find.text('Authenticated'), findsWidgets);
    expect(find.text('Unconfigured'), findsNothing);
  });
}
