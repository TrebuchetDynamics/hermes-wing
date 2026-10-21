// Isolated OS-input fixture. Uses production Chat with synthetic Agent state.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../test/features/hermes_chat/support/fake_hermes_channel.dart';
import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../test/features/hermes_chat/support/fake_hermes_gateway_directory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isAndroid ||
      !const bool.fromEnvironment('WING_ANDROID_OS_INPUT_QA')) {
    throw StateError('Explicit isolated Android OS-input QA required');
  }
  final channel = FakeHermesChannel.disconnected();
  final directory = directoryFor(
    configs: const [
      HermesEndpointConfig(
        id: 'qa',
        label: 'Input QA',
        baseUrl: 'https://qa.example.invalid',
      ),
    ],
    loader: FakeGatewaySummaryLoader({
      'qa': gatewaySummary(['default']),
    }),
    activeChannel: channel,
  );
  await directory.refresh();
  await directory.activateGateway('qa');
  runApp(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(
          FakeHermesEndpointStore(),
        ),
        hermesGatewayDirectoryProvider.overrideWith((_) => directory),
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HermesChatScreen(),
      ),
    ),
  );
}
