import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
