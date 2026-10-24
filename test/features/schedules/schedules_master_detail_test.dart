import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_job.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/schedules/screens/schedules_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import '../hermes_chat/support/fake_hermes_channel.dart';

const jobs = [
  HermesJob(
    id: 'zebra',
    name: 'Zebra review',
    enabled: true,
    scheduleDisplay: 'Daily at 09:00',
  ),
  HermesJob(
    id: 'alpha',
    name: 'Alpha report',
    state: 'paused',
    scheduleDisplay: 'Weekly on Friday',
  ),
];
final capabilities = HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'auth': {
    'type': 'bearer',
    'required': true,
    'granted_scopes': ['tasks:read'],
  },
  'endpoints': {
    'jobs': {
      'method': 'GET',
      'path': '/api/jobs',
      'required_scopes': ['tasks:read'],
    },
  },
});

class Channel extends FakeHermesChannel {
  Channel() : super(capabilities: capabilities, jobs: jobs);
  HermesChannelState? current;
  @override
  HermesChannelState get state => current ?? super.state;
  void emit(HermesChannelState next) {
    current = next;
    notifyListeners();
  }
}

Widget app(Channel channel, {double scale = 1}) => ProviderScope(
  overrides: [hermesChannelProvider.overrideWithValue(channel)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const SchedulesScreen(),
  ),
);
Finder row(String id) => find.byKey(ValueKey('schedule-row-$id'));
Finder detail = find.byKey(const ValueKey('schedule-selected-detail'));
void viewport(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'wide list is alphabetical and selecting a row changes only its detail',
    (tester) async {
      viewport(tester, 1280);
      final channel = Channel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(app(channel));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(row('alpha')).dy,
        lessThan(tester.getTopLeft(row('zebra')).dy),
      );
      expect(
        find.descendant(of: detail, matching: find.text('Alpha report')),
        findsOneWidget,
      );
      await tester.tap(row('zebra'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: detail, matching: find.text('Zebra review')),
        findsOneWidget,
      );
      expect(tester.widget<ListTile>(row('zebra')).selected, isTrue);
      expect(channel.loadJobsCalls, 0);
      expect(channel.createSessionCalls, isEmpty);
      expect(channel.connectCalls, isEmpty);
    },
  );
  testWidgets(
    'selection survives filtering and same-owner inventory updates but resets across profiles',
    (tester) async {
      viewport(tester, 1280);
      final channel = Channel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(app(channel));
      await tester.pumpAndSettle();
      await tester.tap(row('zebra'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('schedules-search')),
        'Alpha',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: detail, matching: find.text('Alpha report')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('schedules-search')),
        '',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: detail, matching: find.text('Zebra review')),
        findsOneWidget,
      );
      channel.emit(
        channel.state.copyWith(
          jobs: [
            jobs.first,
            const HermesJob(id: 'alpha', name: 'Alpha updated'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: detail, matching: find.text('Zebra review')),
        findsOneWidget,
      );
      channel.emit(channel.state.copyWith(selectedProfileId: 'other'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: detail, matching: find.text('Alpha updated')),
        findsOneWidget,
      );
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'compact list opens one detail and keyboard Back restores query at $scale',
      (tester) async {
        viewport(tester, 390);
        final channel = Channel();
        addTearDown(channel.dispose);
        await tester.pumpWidget(app(channel, scale: scale));
        await tester.pumpAndSettle();
        expect(detail, findsNothing);
        await tester.enterText(
          find.byKey(const ValueKey('schedules-search')),
          'review',
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          row('zebra'),
          150,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(row('zebra'));
        await tester.pumpAndSettle();
        expect(detail, findsOneWidget);
        expect(find.byKey(const ValueKey('schedules-search')), findsNothing);
        final back = find.byKey(const ValueKey('schedule-detail-back'));
        await tester.ensureVisible(back);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(detail, findsNothing);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('schedules-search')))
              .controller!
              .text,
          'review',
        );
        expect(row('zebra'), findsOneWidget);
        expect(row('alpha'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'compact detail returns to inventory when selected job disappears',
    (tester) async {
      viewport(tester, 390);
      final channel = Channel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(app(channel));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        row('zebra'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(row('zebra'));
      await tester.pumpAndSettle();
      expect(detail, findsOneWidget);
      channel.emit(channel.state.copyWith(jobs: [jobs.last]));
      await tester.pumpAndSettle();
      expect(detail, findsNothing);
      expect(row('alpha'), findsOneWidget);
      expect(find.text('Zebra review'), findsNothing);
    },
  );
  testWidgets(
    'keyboard activation selects a schedule and stale row callback cannot select another owner',
    (tester) async {
      viewport(tester, 1280);
      final channel = Channel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(app(channel));
      await tester.pumpAndSettle();
      final cached = tester.widget<ListTile>(row('zebra')).onTap!;
      channel.emit(channel.state.copyWith(selectedProfileId: 'other'));
      cached();
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: detail, matching: find.text('Alpha report')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        row('zebra'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      for (var i = 0; i < 30; i++) {
        final c = FocusManager.instance.primaryFocus?.context;
        var focused = false;
        c?.visitAncestorElements((e) {
          if (e.widget.key == const ValueKey('schedule-row-zebra')) {
            focused = true;
          }
          return !focused;
        });
        if (focused) break;
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: detail, matching: find.text('Zebra review')),
        findsOneWidget,
      );
    },
  );
}
