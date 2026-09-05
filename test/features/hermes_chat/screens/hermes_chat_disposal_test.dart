import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('leaving chat restores shell navigation after unmount', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    final showChat = ValueNotifier(true);
    addTearDown(showChat.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ValueListenableBuilder<bool>(
            valueListenable: appShellNavigationVisible,
            builder: (context, visible, _) => Column(
              children: [
                Text(visible ? 'Navigation visible' : 'Navigation hidden'),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: showChat,
                    builder: (_, show, _) =>
                        show ? const HermesChatScreen() : const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    appShellNavigationVisible.value = false;
    await tester.pump();
    showChat.value = false;
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Navigation visible'), findsOneWidget);
  });

  testWidgets(
    'completed reply during route disposal does not read a dead ref',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      channel.beginStreamingTurn('Finish while leaving.');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: _DisposalEmitter(channel: channel),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      channel.emitStaleActiveSessionChange();
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}

class _DisposalEmitter extends StatefulWidget {
  const _DisposalEmitter({required this.channel});

  final FakeHermesChannel channel;

  @override
  State<_DisposalEmitter> createState() => _DisposalEmitterState();
}

class _DisposalEmitterState extends State<_DisposalEmitter> {
  @override
  void dispose() {
    widget.channel.completeStreamingTurn(text: 'Finished.');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const HermesChatScreen();
}
