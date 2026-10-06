import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

const _sessions = [
  HermesSession(
    id: 'older-A',
    title: 'Remembered conversation',
    source: 'test',
  ),
  HermesSession(id: 'newer-B', title: 'Other conversation', source: 'test'),
];
const _contact = GatewayContactId(gatewayId: 'synthetic', profileId: 'coder');

class _SelectionChannel extends FakeHermesChannel {
  _SelectionChannel({super.capabilities})
    : super(
        sessions: _sessions,
        activeSessionId: 'newer-B',
        selectedProfileId: 'coder',
      );

  final activeIdsBeforeSelection = <String?>[];
  @override
  Future<void> selectSession(
    String sessionId, {
    bool Function()? canAccept,
  }) async {
    activeIdsBeforeSelection.add(state.activeSessionId);
    await super.selectSession(sessionId, canAccept: canAccept);
  }
}

// Presentation-only seam: directory/channel restoration is tested separately.
class _RestorationDirectory extends HermesGatewayDirectory {
  _RestorationDirectory(this.channel)
    : super(
        store: FakeHermesEndpointStore(),
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );

  final FakeHermesChannel channel;
  bool pending = true;
  String? target = 'older-A';
  GatewaySessionRestorationFailure? failure;
  final retriedTargets = <String?>[];
  int superseded = 0;

  @override
  GatewayContactId? get activeContactId => _contact;
  @override
  bool get isActivating => pending;
  @override
  String? get restoringSessionId => target;
  @override
  GatewaySessionRestorationFailure? get restorationFailure => failure;

  void recover({GatewaySessionRestorationFailure? error, bool busy = false}) {
    pending = busy;
    failure = error;
    target = 'older-A';
    notifyListeners();
  }

  @override
  Future<void> retrySessionRestoration() async {
    retriedTargets.add(target);
    recover(busy: true);
  }

  @override
  void supersedeSessionRestoration() {
    superseded++;
    if (target != null) channel.clearActiveSession();
    target = null;
    failure = null;
    pending = false;
    notifyListeners();
  }

  void complete() {
    pending = false;
    target = null;
    failure = null;
    notifyListeners();
  }
}

Future<(_RestorationDirectory, FakeHermesChannel)> _pumpRecovery(
  WidgetTester tester, {
  GatewaySessionRestorationFailure? failure,
  bool pending = true,
  bool unsupportedSchema = false,
  bool largeText = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final channel = _SelectionChannel(
    capabilities: unsupportedSchema
        ? HermesCapabilityDocument.fromJson(const {'schema_version': 999})
        : null,
  );
  final directory = _RestorationDirectory(channel)
    ..pending = pending
    ..failure = failure;
  addTearDown(channel.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesGatewayDirectoryProvider.overrideWith((_) => directory),
        hermesEndpointStoreProvider.overrideWithValue(
          FakeHermesEndpointStore(),
        ),
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(largeText ? 2 : 1),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (directory, channel);
}

const _recoveryKey = ValueKey('hermes-session-restoration');
const _retryKey = ValueKey('hermes-session-restoration-retry');
const _chooseKey = ValueKey('hermes-session-restoration-choose');
const _composerKey = ValueKey('hermes-composer-field');

void recoveryTest(String name, WidgetTesterCallback callback) {
  testWidgets(
    name,
    callback,
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  recoveryTest('pending recovery is accessible without writable temporary B', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    final (directory, channel) = await _pumpRecovery(tester);
    expect(find.byKey(_recoveryKey), findsOneWidget);
    expect(find.text('Restoring your conversation'), findsOneWidget);
    expect(find.byKey(_composerKey), findsNothing);
    expect(find.byKey(const ValueKey('hermes-send-button')), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byKey(_retryKey)).onPressed,
      isNull,
    );
    expect(
      tester.getSemantics(find.text('Restoring your conversation')),
      matchesSemantics(
        isHeader: true,
        isLiveRegion: true,
        label: 'Restoring your conversation',
        textDirection: TextDirection.ltr,
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(channel.createSessionCalls, isEmpty);
    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(channel.state.activeSessionId, 'newer-B');
    expect(directory.target, 'older-A');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final failure in GatewaySessionRestorationFailure.values) {
    recoveryTest('$failure has bounded recovery at 390px and 200% text', (
      tester,
    ) async {
      final (directory, channel) = await _pumpRecovery(
        tester,
        failure: failure,
        pending: false,
        unsupportedSchema:
            failure == GatewaySessionRestorationFailure.unsupported,
      );
      expect(find.byKey(_recoveryKey), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hermes-unsupported-capability-schema')),
        findsNothing,
      );
      expect(find.text('Conversation not restored'), findsOneWidget);
      expect(find.byKey(_chooseKey), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(_retryKey)).onPressed,
        isNotNull,
      );
      await tester.ensureVisible(find.byKey(_retryKey));
      await tester.tap(find.byKey(_retryKey));
      await tester.pumpAndSettle();
      expect(directory.retriedTargets, ['older-A']);
      expect(find.text('Restoring your conversation'), findsOneWidget);
      expect(channel.createSessionCalls, isEmpty);
      expect(channel.sentVoiceTranscripts, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  recoveryTest('keyboard Choose and cancelling retain remembered ownership', (
    tester,
  ) async {
    final (directory, channel) = await _pumpRecovery(tester);
    final chooseFocus = Focus.of(tester.element(find.text('Choose session')));
    chooseFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hermes-session-search-field')),
      findsOneWidget,
    );
    expect(directory.target, 'older-A');
    expect(directory.superseded, 0);
    expect(channel.state.activeSessionId, 'newer-B');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_recoveryKey), findsOneWidget);
    expect(directory.target, 'older-A');
    expect(directory.superseded, 0);
    expect(chooseFocus.hasFocus, isTrue);
    expect(channel.selectSessionCalls, isEmpty);
    expect(channel.createSessionCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  recoveryTest('keyboard Retry retains A and stale Send cannot target B', (
    tester,
  ) async {
    final (directory, channel) = await _pumpRecovery(tester, largeText: false);
    directory.complete();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(_composerKey), 'Synthetic draft B');
    await tester.pump();
    final staleSend = tester
        .widget<IconButton>(find.byKey(const ValueKey('hermes-send-button')))
        .onPressed!;
    directory.recover(error: GatewaySessionRestorationFailure.transient);
    staleSend();
    await tester.pumpAndSettle();
    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(find.byKey(_composerKey), findsNothing);
    final retryFocus = Focus.of(tester.element(find.text('Retry')));
    retryFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(directory.retriedTargets, ['older-A']);
    expect(directory.target, 'older-A');
    expect(channel.createSessionCalls, isEmpty);
    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  recoveryTest(
    'explicit picker choice transfers ownership before selecting B',
    (tester) async {
      final (directory, channel) = await _pumpRecovery(
        tester,
        largeText: false,
      );
      await tester.tap(find.byKey(_chooseKey));
      await tester.pumpAndSettle();
      expect(directory.target, 'older-A');
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-title-newer-B')),
      );
      await tester.pumpAndSettle();
      expect(directory.superseded, 1);
      expect(directory.target, isNull);
      expect(channel.selectSessionCalls, ['newer-B']);
      expect((channel as _SelectionChannel).activeIdsBeforeSelection, [null]);
      expect(find.byKey(_recoveryKey), findsNothing);
      final composer = tester.widget<TextField>(find.byKey(_composerKey));
      expect(composer.enabled, isTrue);
      expect(composer.controller!.text, isEmpty);
      expect(composer.focusNode!.hasFocus, isTrue);
      expect(channel.createSessionCalls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  recoveryTest(
    'restoration hides B draft and restores only A draft on completion',
    (tester) async {
      final (directory, channel) = await _pumpRecovery(
        tester,
        largeText: false,
      );
      directory.complete();
      await channel.selectSession('older-A');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_composerKey), 'Synthetic draft A');
      await channel.selectSession('newer-B');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_composerKey), 'Synthetic draft B');
      directory.recover(busy: true);
      await tester.pumpAndSettle();
      expect(find.byKey(_composerKey), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(channel.sentVoiceTranscripts, isEmpty);
      await channel.selectSession('older-A');
      directory.complete();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byKey(_composerKey)).controller!.text,
        'Synthetic draft A',
      );
      expect(channel.sentVoiceTranscripts, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
