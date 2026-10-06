import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/policy/hermes_surface_readiness.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/security/wing_redaction.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    });
  });
  for (final width in [390.0, 1280.0]) {
    for (final rejected in [false, true]) {
      for (final disposal in ['none', 'dialog', 'ui']) {
        testWidgets(
          'surface clipboard ${rejected ? 'rejection' : 'success'} $disposal at $width',
          (tester) async {
            await tester.binding.setSurfaceSize(Size(width, 900));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final semantics = tester.ensureSemantics();
            final previousPrint = debugPrint;
            try {
              final logs = <String>[];
              debugPrint = (message, {wrapWidth}) {
                if (message != null) logs.add(message);
              };
              final writes = <String>[];
              final completion = Completer<void>();
              final messenger = tester.binding.defaultBinaryMessenger;
              messenger.setMockMethodCallHandler(SystemChannels.platform, (
                call,
              ) async {
                if (call.method == 'Clipboard.setData') {
                  writes.add((call.arguments as Map)['text'] as String);
                  if (writes.length == 1) await completion.future;
                }
                return null;
              });
              addTearDown(
                () => messenger.setMockMethodCallHandler(
                  SystemChannels.platform,
                  null,
                ),
              );
              final capabilities = HermesCapabilityDocument.fromJson(const {
                'schema_version': 1,
                'platform': 'linux',
                'model': 'synthetic',
                'features': <String, Object?>{},
                'endpoints': <String, Object?>{},
              });
              final expected = StringBuffer('Hermes surface readiness');
              for (final item in hermesSurfaceReadiness(capabilities)) {
                expected.write(
                  '\n- ${wingRedactedPreview(item.title, maxLength: 80)}: ${item.status.label} — ${wingRedactedPreview(item.detail, maxLength: 240)}',
                );
              }
              final channel = FakeHermesChannel(capabilities: capabilities);
              addTearDown(channel.dispose);
              final originalState = channel.state;
              await tester.pumpWidget(
                ProviderScope(
                  overrides: [hermesChannelProvider.overrideWithValue(channel)],
                  child: MaterialApp(
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: const HermesChatScreen(),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final diagnostics = find.byKey(
                const ValueKey('hermes-diagnostics-button'),
              );
              await tester.ensureVisible(diagnostics);
              await tester.tap(diagnostics);
              await tester.pumpAndSettle();
              final surfaces = find.byKey(
                const ValueKey('hermes-surfaces-chip'),
              );
              await tester.ensureVisible(surfaces);
              await tester.tap(surfaces);
              await tester.pumpAndSettle();
              final copy = find.byKey(const ValueKey('hermes-surfaces-copy'));
              final strings = AppLocalizations.of(tester.element(copy));
              final failure = strings.chatStatusCopySurfaceReadinessFailedBody;
              expect(
                failure,
                'Could not copy Hermes surface readiness summary. Try again.',
              );
              await tester.tap(copy);
              await tester.pump();
              expect(writes, [expected.toString()]);
              final prematureSuccess = find
                  .text(strings.chatStatusCopiedSurfaceReadinessBody)
                  .evaluate()
                  .isNotEmpty;
              final prematureFailure = find.text(failure).evaluate().isNotEmpty;
              if (disposal == 'dialog') {
                await tester.tap(
                  find.descendant(
                    of: find.byType(AlertDialog).last,
                    matching: find.text(strings.closeAction),
                  ),
                );
                await tester.pumpAndSettle();
                expect(find.byType(HermesChatScreen), findsOneWidget);
                expect(copy, findsNothing);
              } else if (disposal == 'ui') {
                await tester.pumpWidget(const SizedBox.shrink());
              }
              if (rejected) {
                completion.completeError(
                  PlatformException(
                    code: 'clipboard-rejected-marker',
                    message: 'private-diagnostic-marker',
                    details: 'private-details-marker',
                  ),
                );
              } else {
                completion.complete();
              }
              await tester.pumpAndSettle();
              expect(
                prematureSuccess,
                isFalse,
                reason: 'Success must await the clipboard write',
              );
              expect(prematureFailure, isFalse);
              expect(tester.takeException(), isNull);
              expect(writes, [expected.toString()]);
              expect(find.textContaining('private-'), findsNothing);
              expect(logs.join(), isNot(contains('private-')));
              expect(logs.join(), isNot(contains('clipboard-rejected-marker')));
              expect(
                find.text(strings.chatStatusCopiedSurfaceReadinessBody),
                disposal == 'none' && !rejected ? findsOneWidget : findsNothing,
              );
              expect(
                find.text(failure),
                disposal == 'none' && rejected ? findsOneWidget : findsNothing,
              );
              if (disposal == 'none' && rejected) {
                expect(
                  tester
                      .getSemantics(find.text(failure))
                      .flagsCollection
                      .isLiveRegion,
                  isTrue,
                );
                await tester.pump(const Duration(seconds: 5));
                await tester.pumpAndSettle();
                expect(writes, [expected.toString()]);
                await tester.tap(copy);
                await tester.pumpAndSettle();
                expect(writes, [expected.toString(), expected.toString()]);
                expect(
                  find.text(strings.chatStatusCopiedSurfaceReadinessBody),
                  findsOneWidget,
                );
                expect(find.text(failure), findsNothing);
                expect(tester.takeException(), isNull);
              }
              expect(identical(channel.state, originalState), isTrue);
              expect(channel.sentVoiceTranscripts, isEmpty);
              expect(channel.createSessionCalls, isEmpty);
              expect(channel.selectProfileCalls, isEmpty);
              expect(channel.respondToApprovalCalls, isEmpty);
            } finally {
              debugPrint = previousPrint;
              semantics.dispose();
            }
          },
        );
      }
    }
  }
}
