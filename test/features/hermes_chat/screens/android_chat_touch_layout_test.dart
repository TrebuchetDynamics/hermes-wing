import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';
import 'package:wing/theme/wing_theme.dart';

import '../support/fake_hermes_channel.dart';

Finder control(String name) => find.byKey(ValueKey(name));
const _sizes = [
  Size(320, 480),
  Size(390, 844),
  Size(844, 390),
  Size(1280, 900),
];
final _boundary = GlobalKey();

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    });
  });

  // Removing the picker's scrollable header/footer must fail at the short,
  // enlarged-text keyboard viewport, not merely change a screenshot.
  testWidgets('profile switcher stays operable above the keyboard at all sizes', (
    tester,
  ) async {
    for (final size in _sizes) {
      for (final brightness in Brightness.values) {
        for (final scale in [1.0, 2.0]) {
          final channel = _channel();
          await _mount(tester, channel, size, brightness, scale);
          final label =
              '${size.width.toInt()}-${size.height.toInt()}-${brightness.name}-${scale.toInt()}';
          await _capture(tester, '$label-idle');
          final field = control('hermes-composer-field');
          await tester.enterText(field, 'Retained draft\nSecond line');
          await tester.pump();
          await _capture(tester, '$label-draft');
          final editor = tester.widget<TextField>(field);
          final draft = editor.controller!.value;
          channel.replaceTranscript([
            for (var i = 0; i < 24; i++)
              HermesChatTurn(
                id: 'turn-$i',
                sessionId: 'sess_1',
                author: i.isEven
                    ? HermesTurnAuthor.user
                    : HermesTurnAuthor.assistant,
                createdAt: DateTime.utc(2026, 1, 1),
                text: 'Fixture message $i: review the current results.',
              ),
          ]);
          await tester.pumpAndSettle();
          final transcript = control('hermes-transcript');
          final transcriptRect = tester.getRect(transcript);
          expect(transcriptRect.height, greaterThanOrEqualTo(64));
          expect(transcriptRect.top, greaterThanOrEqualTo(24));
          expect(transcriptRect.bottom, lessThanOrEqualTo(size.height - 24));
          final scrollable = tester.state<ScrollableState>(
            find
                .descendant(of: transcript, matching: find.byType(Scrollable))
                .first,
          );
          await tester.drag(transcript, const Offset(0, 100));
          await tester.pumpAndSettle();
          final offset = scrollable.position.pixels;
          expect(offset, greaterThan(0));
          final callerFocus = FocusManager.instance.primaryFocus;
          await tester.tap(control('hermes-profile-switcher'));
          await tester.pumpAndSettle();
          tester.view.viewInsets = FakeViewPadding(
            bottom: size.height < 500 ? 140 : 280,
          );
          await tester.pumpAndSettle();
          await _capture(tester, '$label-switcher');
          expect(
            tester.getRect(find.byType(BottomSheet)).top,
            greaterThanOrEqualTo(24),
          );
          _aboveKeyboard(tester, control('chat-profile-viewport'), size);
          expect(tester.takeException(), isNull, reason: label);
          final search = control('chat-profile-search');
          await tester.enterText(search, 'Research');
          await tester.pumpAndSettle();
          _aboveKeyboard(tester, search, size);
          await tester.tap(control('chat-profile-clear'));
          await tester.pumpAndSettle();
          _aboveKeyboard(tester, search, size);
          await tester.enterText(search, 'no matching profile');
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('No matching profiles'));
          await tester.pumpAndSettle();
          await _capture(tester, '$label-no-match');
          await tester.ensureVisible(control('chat-profile-clear'));
          await tester.tap(control('chat-profile-clear'));
          await tester.pumpAndSettle();
          final row = control('chat-profile-row-default');
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          _aboveKeyboard(tester, row, size);
          expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
          expect(row.hitTestable(), findsOneWidget);
          await _capture(tester, '$label-selected-visible');
          final manage = control('chat-profile-manage');
          await tester.ensureVisible(manage);
          await tester.pumpAndSettle();
          _aboveKeyboard(tester, manage, size);
          expect(tester.getSize(manage).height, greaterThanOrEqualTo(48));
          expect(manage.hitTestable(), findsOneWidget);
          await _capture(tester, '$label-manage-visible');
          // Platform Back cancels the sheet, never the caller or its draft.
          await tester.binding.handlePopRoute();
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          expect(editor.controller!.value, draft);
          expect(FocusManager.instance.primaryFocus, callerFocus);
          expect(scrollable.position.pixels, offset);
          expect(channel.selectProfileCalls, isEmpty);
          expect(channel.sentImageDataUrls, isEmpty);
          expect(channel.stopActiveTurnCalls, 0);
          expect(channel.respondToApprovalCalls, isEmpty);
          expect(tester.takeException(), isNull, reason: label);
          await _captureStates(tester, channel, label);
          await tester.pumpWidget(const SizedBox.shrink());
          channel.dispose();
        }
      }
    }
    debugDefaultTargetPlatformOverride = null;
  });

  // Padding only the search field still leaves the session-list viewport and
  // its last actions behind the IME. Check the whole viewport's lower bound.
  testWidgets('session picker viewport excludes keyboard and system insets', (
    tester,
  ) async {
    final channel = _channel();
    addTearDown(channel.dispose);
    const size = Size(390, 844);
    await _mount(tester, channel, size, Brightness.dark, 2);
    await tester.enterText(control('hermes-composer-field'), 'Keep this draft');
    await tester.tap(control('hermes-more-actions-button'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sessions').last);
    await tester.pumpAndSettle();
    await tester.tap(control('hermes-session-search-field'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await _capture(tester, 'sessions-keyboard');
    expect(
      tester.getRect(find.byType(BottomSheet)).top,
      greaterThanOrEqualTo(24),
    );
    _aboveKeyboard(tester, control('hermes-sessions-list'), size);
    await tester.enterText(control('hermes-session-search-field'), 'Second');
    await tester.pumpAndSettle();
    final row = find.text('Second conversation');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    _aboveKeyboard(tester, row, size);
    await tester.binding.handlePopRoute();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(control('hermes-composer-field'))
          .controller!
          .text,
      'Keep this draft',
    );
    expect(channel.selectSessionCalls, isEmpty);
    expect(channel.sentImageDataUrls, isEmpty);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}

FakeHermesChannel _channel() => FakeHermesChannel(
  sessions: const [
    HermesSession(id: 'sess_1', title: 'Review the release', source: 'desktop'),
    HermesSession(
      id: 'sess_2',
      title: 'Second conversation',
      source: 'desktop',
    ),
  ],
  profiles: const [
    HermesProfile(
      id: 'default',
      displayName: 'Research',
      model: 'Fixture model',
      revision: '1',
    ),
    HermesProfile(
      id: 'builder',
      displayName: 'Builder',
      model: 'Fixture model',
      revision: '1',
    ),
  ],
  selectedProfileId: 'default',
);

Future<void> _mount(
  WidgetTester tester,
  FakeHermesChannel channel,
  Size size,
  Brightness brightness,
  double scale,
) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewInsets);
  // Optional readable captures use SDK Roboto instead of the widget-test Ahem.
  final fontRoot = Platform.environment['WING_TOUCH_FONT_ROOT'];
  if (fontRoot != null) {
    await tester.runAsync(() async {
      for (final family in ['Segoe UI', 'Roboto', 'sans-serif', 'Ahem']) {
        await (FontLoader(family)..addFont(
              File(
                '$fontRoot/Roboto-Regular.ttf',
              ).readAsBytes().then(ByteData.sublistView),
            ))
            .load();
      }
      await (FontLoader('MaterialIcons')..addFont(
            File(
              '$fontRoot/MaterialIcons-Regular.otf',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    });
  }
  final theme = wingThemeFor(WingThemePalette.wing, brightness);
  final captureTheme = fontRoot == null
      ? theme
      : theme.copyWith(
          chipTheme: theme.chipTheme.copyWith(
            labelStyle: theme.chipTheme.labelStyle?.copyWith(
              fontFamily: 'Roboto',
            ),
          ),
          listTileTheme: theme.listTileTheme.copyWith(
            titleTextStyle: theme.listTileTheme.titleTextStyle?.copyWith(
              fontFamily: 'Roboto',
            ),
            subtitleTextStyle: theme.listTileTheme.subtitleTextStyle?.copyWith(
              fontFamily: 'Roboto',
            ),
          ),
        );
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
      ],
      child: RepaintBoundary(
        key: _boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: captureTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const AppShellSessionNavigation(child: HermesChatScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _aboveKeyboard(WidgetTester tester, Finder finder, Size size) {
  final rect = tester.getRect(finder);
  expect(rect.top, greaterThanOrEqualTo(24));
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(size.width));
  expect(
    rect.bottom,
    lessThanOrEqualTo(size.height - tester.view.viewInsets.bottom - 24),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  final output = Platform.environment['WING_TOUCH_CAPTURE'];
  if (output == null) return;
  await tester.runAsync(() async {
    final image =
        await (_boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(output).create(recursive: true);
    await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _captureStates(
  WidgetTester tester,
  FakeHermesChannel channel,
  String label,
) async {
  if (Platform.environment['WING_TOUCH_CAPTURE'] == null) return;
  channel.beginStreamingTurn('Summarize the fixture checks');
  channel.appendStreamingTurnText('Checking the latest results.');
  final turns = channel.state.activeMessages;
  channel.replaceTranscript([
    ...turns.take(turns.length - 1),
    HermesChatTurn(
      id: 'tool-1',
      sessionId: 'sess_1',
      author: HermesTurnAuthor.system,
      createdAt: DateTime.utc(2026, 1, 1),
      kind: HermesTurnKind.toolCall,
      toolCall: const HermesToolCall(name: 'fixture_check', status: 'running'),
    ),
    turns.last,
  ]);
  await tester.pump(const Duration(milliseconds: 300));
  final latest = control('hermes-transcript-latest');
  if (latest.evaluate().isNotEmpty) {
    await tester.tap(latest);
    await tester.pump(const Duration(milliseconds: 300));
  }
  await _capture(tester, '$label-tools');
  final target = channel.activeTurnInterruptionTarget!;
  channel.emitApprovalRequest(
    HermesApprovalRequest(
      id: 'approval-1',
      toolCallId: 'tool-1',
      prompt: 'Run the fixture check?',
      choices: {HermesApprovalDecision.once, HermesApprovalDecision.deny},
      runId: target.runId,
      sessionId: target.sessionId,
      profileId: target.profileId,
      connectionGeneration: target.connectionGeneration,
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await _capture(tester, '$label-approval');
  channel.completeStreamingTurn();
  channel.addFailedExchange(
    'Fixture request',
    errorMessage:
        'Connection interrupted. Reconnect to check the conversation.',
  );
  await tester.pump(const Duration(milliseconds: 300));
  await _capture(tester, '$label-error');
  await channel.disconnect();
  await tester.pumpAndSettle();
  await _capture(tester, '$label-disconnected');
}
