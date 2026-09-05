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
            assistant.text.trim() == 'HI',
            isTrue,
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
    testWidgets(
      'native Linux profile ${index + 1} reconciles session CRUD, fork, and inventories',
      (tester) async {
        final channel = HermesApiChannel();
        final created = <String>{};
        try {
          await channel.connect(baseUrl: profile.origin, apiKey: profile.token);
          expect(channel.state.isConnected, isTrue);
          await channel.loadDetailedHealth();
          expect(channel.state.detailedHealth != null, isTrue);
          await channel.loadToolInventory();
          expect(channel.state.optionalResourceErrors.isEmpty, isTrue);
          await channel.loadModelOptions();
          expect(channel.state.modelOptions != null, isTrue);

          await channel.createSession(title: 'Wing Linux lifecycle test');
          final original = channel.state.activeSessionId!;
          created.add(original);
          await channel.renameSession(
            sessionId: original,
            title: 'Wing Linux renamed',
          );
          expect(channel.state.activeSession?.title, 'Wing Linux renamed');
          await channel.forkSession(original, title: 'Wing Linux fork');
          final fork = channel.state.activeSessionId!;
          expect(fork != original, isTrue);
          created.add(fork);
          await channel.selectSession(original);
          expect(channel.state.activeSessionId == original, isTrue);
          await channel.disconnect();
          expect(channel.state.isConnected, isFalse);
          await channel.connect(baseUrl: profile.origin, apiKey: profile.token);
          await channel.selectSession(original);
          await channel.reconcileActiveSession();
          expect(channel.state.activeSession?.title, 'Wing Linux renamed');
          await channel.deleteSession(fork);
          created.remove(fork);
          expect(channel.state.sessions.any((s) => s.id == fork), isFalse);
          await channel.deleteSession(original);
          created.remove(original);
          expect(channel.state.sessions.any((s) => s.id == original), isFalse);
        } finally {
          for (final id in created) {
            await channel.deleteSession(id);
          }
          channel.dispose();
        }
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
    testWidgets(
      'native Linux profile ${index + 1} steers and stops an accepted run without replay',
      (tester) async {
        final channel = HermesApiChannel();
        String? session;
        try {
          await channel.connect(baseUrl: profile.origin, apiKey: profile.token);
          expect(channel.state.isConnected, isTrue);
          await channel.createSession(title: 'Wing Linux cancellation test');
          session = channel.state.activeSessionId!;
          final sending = channel.sendText(
            'Wing Linux stop test: respond slowly with a long list.',
          );
          await _waitUntil(
            tester,
            () => channel.activeTurnInterruptionTarget?.runId != null,
            timeout: const Duration(seconds: 30),
          );
          expect(channel.canSteerActiveTurn, isTrue);
          await channel.steerActiveTurn('Keep the response bounded.');
          final target = channel.activeTurnInterruptionTarget!;
          expect(await channel.stopTurn(target), isTrue);
          await sending;
          await channel.disconnect();
          await channel.connect(baseUrl: profile.origin, apiKey: profile.token);
          await channel.selectSession(session);
          await channel.reconcileActiveSession();
          expect(channel.state.isSessionStreaming(session), isFalse);
          expect(
            channel.state.activeMessages
                .where(
                  (t) =>
                      t.author == HermesTurnAuthor.user &&
                      t.text.contains('Wing Linux stop test'),
                )
                .length,
            1,
          );
        } finally {
          if (session != null) await channel.deleteSession(session);
          channel.dispose();
        }
      },
      timeout: const Timeout(Duration(minutes: 3)),
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
