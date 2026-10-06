import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';

import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/security/wing_redaction.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    });
  });
  for (final width in [390.0, 1280.0]) {
    for (final caller in ['run', 'connection']) {
      for (final rejected in [false, true]) {
        for (final dismissal in ['none', 'close', 'back', 'ui']) {
          testWidgets(
            '$caller clipboard ${rejected ? 'rejection' : 'success'} $dismissal at $width',
            (tester) async {
              await tester.binding.setSurfaceSize(Size(width, 900));
              addTearDown(() => tester.binding.setSurfaceSize(null));
              final semantics = tester.ensureSemantics();
              final previousPrint = debugPrint;
              final logs = <String>[];
              debugPrint = (message, {wrapWidth}) {
                if (message != null) logs.add(message);
              };
              try {
                final error =
                    'Synthetic failure <tool_result>hidden-marker</tool_result> ${List.filled(1500, 'x').join()}';
                final expected = wingRedactedPreview(
                  wingRedactSensitiveText(error),
                  maxLength: 1200,
                );
                final channel = FakeHermesChannel(
                  status: caller == 'run'
                      ? HermesConnectionStatus.connected
                      : HermesConnectionStatus.error,
                  errorMessage: caller == 'connection' ? error : null,
                );
                if (caller == 'run') {
                  channel.addFailedExchange(
                    'Synthetic request',
                    errorMessage: error,
                  );
                }
                addTearDown(channel.dispose);
                await tester.pumpWidget(
                  ProviderScope(
                    overrides: [
                      hermesChannelProvider.overrideWithValue(channel),
                      hermesEndpointStoreProvider.overrideWithValue(
                        FakeHermesEndpointStore(),
                      ),
                    ],
                    child: MaterialApp(
                      localizationsDelegates:
                          AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      home: HermesChatScreen(
                        initiallyEditingConnection: caller == 'connection',
                      ),
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                final originalState = channel.state;
                final details = find.byKey(
                  ValueKey(
                    caller == 'run'
                        ? 'hermes-chat-error-details'
                        : 'hermes-connect-error-details',
                  ),
                );
                await tester.ensureVisible(details);
                await tester.tap(details);
                await tester.pumpAndSettle();
                final sheet = find.byKey(
                  const ValueKey('hermes-error-details-sheet'),
                );
                final copy = find.byKey(
                  const ValueKey('hermes-error-details-copy'),
                );
                final strings = AppLocalizations.of(tester.element(copy));
                final success = strings.chatErrorCopiedRedactedDetailsBody;
                final failure = strings.diagnosticsCopyFailedNotice;
                expect(failure, 'Could not copy diagnostics. Try again.');
                expect(
                  tester
                      .widget<SelectableText>(
                        find.byKey(const ValueKey('hermes-error-details-text')),
                      )
                      .data,
                  expected,
                );
                expect(expected, isNot(contains('hidden-marker')));
                expect(expected.length, lessThanOrEqualTo(1201));
                final writes = <String>[];
                final completion = Completer<void>();
                final messenger = tester.binding.defaultBinaryMessenger;
                messenger.setMockMethodCallHandler(SystemChannels.platform, (
                  call,
                ) async {
                  if (call.method == 'Clipboard.setData') {
                    writes.add((call.arguments as Map)['text'] as String);
                    if (writes.length == 1) await completion.future;
                  } else if (call.method.startsWith('Clipboard.')) {
                    fail('Unexpected clipboard operation: ${call.method}');
                  }
                  return null;
                });
                addTearDown(
                  () => messenger.setMockMethodCallHandler(
                    SystemChannels.platform,
                    null,
                  ),
                );
                await tester.ensureVisible(copy);
                await tester.tap(copy);
                await tester.pump();
                expect(writes, [expected]);
                final prematureSuccess = find
                    .text(success)
                    .evaluate()
                    .isNotEmpty;
                final prematureFailure = find
                    .text(failure)
                    .evaluate()
                    .isNotEmpty;
                if (dismissal == 'close') {
                  await tester.tap(
                    find.byKey(const ValueKey('hermes-error-details-close')),
                  );
                  await tester.pump();
                } else if (dismissal == 'back') {
                  await tester.binding.handlePopRoute();
                  await tester.pump();
                } else if (dismissal == 'ui') {
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
                expect(writes, [expected]);
                expect(
                  find.textContaining('private-diagnostic-marker'),
                  findsNothing,
                );
                expect(
                  find.textContaining('private-details-marker'),
                  findsNothing,
                );
                expect(
                  find.textContaining('clipboard-rejected-marker'),
                  findsNothing,
                );
                expect(logs.join(), isNot(contains('private-')));
                expect(
                  logs.join(),
                  isNot(contains('clipboard-rejected-marker')),
                );
                expect(
                  find.text(success),
                  dismissal == 'none' && !rejected
                      ? findsOneWidget
                      : findsNothing,
                );
                expect(
                  find.text(failure),
                  dismissal == 'none' && rejected
                      ? findsOneWidget
                      : findsNothing,
                );
                if (dismissal == 'none' && rejected) {
                  expect(
                    find.descendant(of: sheet, matching: find.text(failure)),
                    findsOneWidget,
                  );
                  expect(
                    tester
                        .getSemantics(find.text(failure))
                        .flagsCollection
                        .isLiveRegion,
                    isTrue,
                  );
                  await tester.pump(const Duration(seconds: 5));
                  await tester.pumpAndSettle();
                  expect(writes, [expected]);
                  await tester.ensureVisible(copy);
                  await tester.tap(copy);
                  await tester.pumpAndSettle();
                  expect(writes, [expected, expected]);
                  expect(find.text(success), findsOneWidget);
                  expect(find.text(failure), findsNothing);
                  expect(tester.takeException(), isNull);
                }
                if (dismissal != 'none') {
                  expect(sheet, findsNothing);
                  expect(
                    find.byType(HermesChatScreen),
                    dismissal == 'ui' ? findsNothing : findsOneWidget,
                  );
                }
                expect(identical(channel.state, originalState), isTrue);
                expect(channel.sentVoiceTranscripts, isEmpty);
                expect(channel.createSessionCalls, isEmpty);
                expect(channel.selectProfileCalls, isEmpty);
                expect(channel.respondToApprovalCalls, isEmpty);
                expect(channel.connectCalls, isEmpty);
                expect(channel.disconnectCalls, 0);
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
}
