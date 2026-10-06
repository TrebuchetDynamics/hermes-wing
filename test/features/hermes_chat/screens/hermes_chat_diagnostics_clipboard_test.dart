import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/features/hermes_chat/diagnostics/hermes_diagnostics_export.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    });
  });
  for (final width in [390.0, 1280.0]) {
    for (final action in [
      'hermes-diagnostics-copy',
      'hermes-raw-logs-status-copy',
    ]) {
      for (final rejected in [false, true]) {
        for (final disposal in ['none', 'closing', 'dialog', 'ui']) {
          testWidgets(
            '$action clipboard ${rejected ? 'rejection' : 'success'} $disposal at $width',
            (tester) async {
              tester.view.physicalSize = Size(width, 900);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
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
                  expect(call.method, isNot('Clipboard.getData'));
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
                final channel = FakeHermesChannel(capabilities: capabilities);
                addTearDown(channel.dispose);
                final originalState = channel.state;
                final expected = action == 'hermes-diagnostics-copy'
                    ? hermesDiagnosticsExport(originalState)
                    : 'Raw diagnostics/log export\nStatus: Deferred\n'
                          'Raw logs, transcripts, credentials, tool payloads, and local paths remain excluded from Hermes Wing mobile diagnostics.\n'
                          'No raw log export control is enabled until a safe Hermes redaction contract exists.';
                await tester.pumpWidget(
                  ProviderScope(
                    overrides: [
                      hermesChannelProvider.overrideWithValue(channel),
                    ],
                    child: MaterialApp(
                      localizationsDelegates:
                          AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      home: const HermesChatScreen(),
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                final screenStrings = AppLocalizations.of(
                  tester.element(find.byType(HermesChatScreen)),
                );
                expect(
                  MediaQuery.sizeOf(
                    tester.element(find.byType(HermesChatScreen)),
                  ).width,
                  width,
                );
                if (width == 390) {
                  await tester.tap(
                    find.byKey(const ValueKey('hermes-more-actions-button')),
                  );
                  await tester.pumpAndSettle();
                  await tester.tap(
                    find.text(screenStrings.chatShellDiagnosticsLabel).last,
                  );
                } else {
                  await tester.tap(
                    find.byKey(const ValueKey('hermes-diagnostics-button')),
                  );
                }
                await tester.pumpAndSettle();
                expect(find.byType(AlertDialog), findsOneWidget);
                expect(
                  tester
                      .widget<SelectableText>(
                        find.byKey(const ValueKey('hermes-diagnostics-text')),
                      )
                      .data,
                  hermesDiagnosticsExport(originalState),
                );
                final copy = find.byKey(ValueKey(action));
                final strings = AppLocalizations.of(tester.element(copy));
                final success = action == 'hermes-diagnostics-copy'
                    ? strings.chatConnectionDiagnosticsCopiedBody
                    : strings.chatConnectionRawLogStatusCopiedBody;
                final failure = strings.diagnosticsCopyFailedNotice;
                expect(failure, 'Could not copy diagnostics. Try again.');
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
                if (disposal == 'dialog' || disposal == 'closing') {
                  final dialogContext = tester.element(copy);
                  await tester.tap(
                    find.descendant(
                      of: find.byType(AlertDialog).last,
                      matching: find.text(strings.closeAction),
                    ),
                  );
                  if (disposal == 'closing') {
                    // A popped route can remain mounted during its exit animation.
                    expect(dialogContext.mounted, isTrue);
                    expect(ModalRoute.of(dialogContext)?.isCurrent, isFalse);
                  } else {
                    await tester.pumpAndSettle();
                    expect(copy, findsNothing);
                  }
                  expect(find.byType(HermesChatScreen), findsOneWidget);
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
                expect(writes, [expected]);
                expect(find.textContaining('private-'), findsNothing);
                expect(logs.join(), isNot(contains('private-')));
                expect(
                  logs.join(),
                  isNot(contains('clipboard-rejected-marker')),
                );
                expect(
                  find.text(success),
                  disposal == 'none' && !rejected
                      ? findsOneWidget
                      : findsNothing,
                );
                expect(
                  find.text(failure),
                  disposal == 'none' && rejected
                      ? findsOneWidget
                      : findsNothing,
                );
                if (disposal == 'none' && rejected) {
                  expect(
                    find.descendant(
                      of: find.byType(AlertDialog),
                      matching: find.text(failure),
                    ),
                    findsOneWidget,
                  );
                  expect(
                    ModalRoute.of(
                      tester.element(find.text(failure)),
                    )?.isCurrent,
                    isTrue,
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
                  await tester.tap(copy);
                  await tester.pumpAndSettle();
                  expect(writes, [expected, expected]);
                  expect(find.text(success), findsOneWidget);
                  expect(find.text(failure), findsNothing);
                  expect(tester.takeException(), isNull);
                }
                expect(identical(channel.state, originalState), isTrue);
                expect(channel.sentVoiceTranscripts, isEmpty);
                expect(channel.createSessionCalls, isEmpty);
                expect(channel.selectProfileCalls, isEmpty);
                expect(channel.respondToApprovalCalls, isEmpty);
                expect(channel.connectCalls, isEmpty);
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
