import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/router/app_router.dart';
import 'package:navivox/testing/connect_and_talk_channel.dart';

void main() {
  testWidgets('connect-info lands on chat and sends a text turn', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connect to Gormes'), findsOneWidget);
    expect(find.text('Connect and talk'), findsOneWidget);
    expect(find.textContaining('gormes navivox connect-info'), findsWidgets);
    expect(find.textContaining('Android emulator'), findsOneWidget);
    expect(find.textContaining('10.0.2.2'), findsOneWidget);
    expect(find.textContaining('physical Android device'), findsOneWidget);
    expect(_caseInsensitiveText('telephony'), findsNothing);
    expect(_caseInsensitiveText('fake'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Gateway base URL'),
      'http://127.0.0.1:8765',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Pairing token'),
      'nvbx_test_token',
    );
    await tester.tap(find.text('Connect and talk'));
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'http://127.0.0.1:8765');
    expect(find.text('Gormes Gateway'), findsOneWidget);
    expect(find.textContaining('Gateway online'), findsOneWidget);
    expect(find.text('Default profile'), findsOneWidget);

    await tester.tap(find.text('Default profile'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Gormes'),
      'hello gateway',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(channel.sentTexts, ['hello gateway']);
    expect(find.text('hello gateway'), findsOneWidget);
    expect(find.text('hello from gateway'), findsOneWidget);
    expect(_caseInsensitiveText('telephony'), findsNothing);
  });

  testWidgets(
    'connect failure gives connect-info guidance without token leak',
    (tester) async {
      final channel = FailingConnectChannel();
      addTearDown(channel.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const _RouterTestApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Gateway base URL'),
        'http://127.0.0.1:8765',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Pairing token'),
        'nvbx_secret_should_not_render',
      );
      await tester.tap(find.text('Connect and talk'));
      await tester.pumpAndSettle();

      expect(find.text('Could not connect to Gormes gateway.'), findsOneWidget);
      expect(find.textContaining('gormes navivox connect-info'), findsWidgets);
      expect(
        _caseInsensitiveText('nvbx_secret_should_not_render'),
        findsNothing,
      );
      expect(_caseInsensitiveText('telephony'), findsNothing);
    },
  );
}

Finder _caseInsensitiveText(String needle) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    final data = widget.data;
    if (data == null) return false;
    return data.toLowerCase().contains(needle.toLowerCase());
  });
}

class _RouterTestApp extends ConsumerWidget {
  const _RouterTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}
