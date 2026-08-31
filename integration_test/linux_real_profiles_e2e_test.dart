import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final manifestPath = Platform.environment['WING_LIVE_PROFILE_MANIFEST'];
  if (manifestPath == null || manifestPath.trim().isEmpty) {
    testWidgets(
      'native Linux real-profile E2E requires an ephemeral credential manifest',
      (_) async {},
      skip: true,
    );
    return;
  }

  final profiles = _readProfiles(manifestPath);
  for (var index = 0; index < profiles.length; index++) {
    final profile = profiles[index];
    testWidgets(
      'native Linux profile ${index + 1} creates a session and receives a provider reply',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final channel = HermesApiChannel();
        String? generatedSessionId;
        try {
          await channel.connect(baseUrl: profile.origin, apiKey: profile.token);
          if (!channel.state.isConnected) {
            throw TestFailure(
              'Profile ${index + 1} could not connect (${_errorKind(channel.state.errorMessage)}).',
            );
          }

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                hermesChannelProvider.overrideWithValue(channel),
                hermesEndpointStoreProvider.overrideWithValue(
                  const EmptyHermesEndpointStore(),
                ),
              ],
              child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: HermesChatScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final priorSessionId = channel.state.activeSessionId;
          final newSession = find.byKey(const ValueKey('hermes-new-session'));
          expect(newSession, findsOneWidget);
          await tester.tap(newSession);
          await _waitUntil(
            tester,
            () =>
                channel.state.activeSessionId != null &&
                channel.state.activeSessionId != priorSessionId,
            timeout: const Duration(seconds: 30),
          );
          generatedSessionId = channel.state.activeSessionId;
          await channel.renameSession(
            sessionId: generatedSessionId!,
            title:
                'wing-linux-native-e2e-${DateTime.now().millisecondsSinceEpoch}-${index + 1}',
          );

          final composer = find.byKey(const ValueKey('hermes-composer-field'));
          expect(composer, findsOneWidget);
          await tester.enterText(
            composer,
            'Reply with exactly HI in uppercase. No punctuation and no other words.',
          );
          await tester.pump();
          final send = find.byKey(const ValueKey('hermes-send-button'));
          expect(send, findsOneWidget);
          await tester.tap(send);

          await _waitUntil(tester, () {
            if (channel.state.errorMessage != null) return true;
            final turns = channel.state.activeMessages;
            if (turns.isEmpty) return false;
            final last = turns.last;
            return last.author == HermesTurnAuthor.assistant &&
                last.status != HermesTurnStatus.streaming;
          }, timeout: const Duration(minutes: 3));

          final error = channel.state.errorMessage;
          if (error != null) {
            throw TestFailure(
              'Profile ${index + 1} provider turn failed (${_errorKind(error)}).',
            );
          }
          final assistant = channel.state.activeMessages.lastWhere(
            (turn) => turn.author == HermesTurnAuthor.assistant,
          );
          expect(
            assistant.text.trim(),
            'HI',
            reason: 'Profile ${index + 1} returned an unexpected reply.',
          );
        } finally {
          if (generatedSessionId != null) {
            try {
              await channel.deleteSession(generatedSessionId);
            } catch (_) {
              // The outer cleanup audit removes any session the UI could not delete.
            }
          }
          channel.dispose();
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}

List<_LiveProfile> _readProfiles(String path) {
  final file = File(path);
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! List || decoded.isEmpty) {
    throw StateError('The live profile manifest is empty or invalid.');
  }
  return decoded.indexed
      .map((entry) {
        final value = entry.$2;
        if (value is! Map) {
          throw StateError('Profile ${entry.$1 + 1} is invalid.');
        }
        final origin = value['origin'];
        final token = value['token'];
        if (origin is! String || token is! String || token.isEmpty) {
          throw StateError('Profile ${entry.$1 + 1} is incomplete.');
        }
        final uri = Uri.tryParse(origin);
        if (uri == null ||
            !uri.hasAuthority ||
            (uri.scheme != 'http' && uri.scheme != 'https')) {
          throw StateError('Profile ${entry.$1 + 1} has an invalid origin.');
        }
        return _LiveProfile(origin: origin, token: token);
      })
      .toList(growable: false);
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() predicate, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('The native Linux E2E operation timed out.');
    }
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  await tester.pump();
}

String _errorKind(String? error) {
  final lower = error?.toLowerCase() ?? '';
  if (lower.contains('authentication') || lower.contains('api key')) {
    return 'authentication';
  }
  if (lower.contains('provider') || lower.contains('model')) {
    return 'provider';
  }
  if (lower.contains('still active')) return 'still_active';
  if (lower.contains('run failed')) return 'run_failed';
  if (lower.contains('stream')) return 'stream';
  if (lower.contains('timed out')) return 'timeout';
  return 'other';
}

class _LiveProfile {
  const _LiveProfile({required this.origin, required this.token});

  final String origin;
  final String token;
}
