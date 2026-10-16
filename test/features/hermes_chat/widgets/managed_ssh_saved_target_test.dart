import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/ssh/secure_managed_ssh_target_store.dart';
import 'package:wing/core/hermes/ssh/ssh_types.dart';
import 'package:wing/features/hermes_chat/widgets/managed_ssh_connection_form.dart';
import 'managed_ssh_connection_form_test.dart' show labels, field;

const targetLabels = ManagedSshTargetLabels(
  save: 'Save settings',
  load: 'Load settings',
  body: 'No credentials saved. Loading does not connect.',
  saved: 'Saved',
  loaded: 'Loaded',
  missing: 'Missing',
  failure: 'Storage unavailable',
);

class HeldStore extends SecureManagedSshTargetStore {
  final pending = Completer<ManagedSshTarget?>();
  @override
  Future<ManagedSshTarget?> load() => pending.future;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'explicit save/reuse across form recreation restores mode without secrets or submit',
    (tester) async {
      var submissions = 0;
      var mode = true;
      Widget form() => MaterialApp(
        home: Scaffold(
          body: ManagedSshConnectionForm(
            labels: labels,
            targetLabels: targetLabels,
            serveReads: mode,
            onServeReadsLoaded: (value) => mode = value,
            onSubmit: (_) async {
              submissions++;
            },
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpWidget(form());
      await tester.enterText(field('host'), 'example.invalid');
      await tester.enterText(field('username'), 'tester');
      await tester.enterText(field('ssh-port'), '2222');
      await tester.enterText(field('agent-port'), '8643');
      await tester.enterText(field('password'), 'synthetic-password');
      await tester.enterText(field('agent-token'), 'synthetic-token');
      await tester.ensureVisible(find.text(targetLabels.save));
      await tester.tap(find.text(targetLabels.save));
      await tester.pumpAndSettle();
      expect(find.text(targetLabels.saved), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      mode = false;
      await tester.pumpWidget(form());
      expect(
        tester.widget<TextFormField>(field('host')).controller!.text,
        isEmpty,
      );
      await tester.tap(find.text(targetLabels.load));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(field('host')).controller!.text,
        'example.invalid',
      );
      expect(
        tester.widget<TextFormField>(field('ssh-port')).controller!.text,
        '2222',
      );
      expect(
        tester.widget<TextFormField>(field('username')).controller!.text,
        'tester',
      );
      expect(
        tester.widget<TextFormField>(field('agent-port')).controller!.text,
        '8643',
      );
      expect(
        tester.widget<TextFormField>(field('password')).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<TextFormField>(field('agent-token')).controller!.text,
        isEmpty,
      );
      expect(mode, isTrue);
      expect(submissions, 0);
      expect(find.text(targetLabels.loaded), findsOneWidget);
    },
  );

  testWidgets('load replaces draft, clears credentials and never submits', (
    tester,
  ) async {
    await const SecureManagedSshTargetStore().save(
      ManagedSshTarget(
        config: ManagedSshConfig(
          host: 'saved.invalid',
          username: 'tester',
          agentPort: 8642,
        ),
        serveReads: false,
      ),
    );
    var submissions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManagedSshConnectionForm(
            labels: labels,
            targetLabels: targetLabels,
            onSubmit: (_) async {
              submissions++;
            },
            onCancel: () {},
          ),
        ),
      ),
    );
    await tester.enterText(field('host'), 'draft.invalid');
    await tester.enterText(field('password'), 'synthetic-password');
    await tester.enterText(field('agent-token'), 'synthetic-token');
    await tester.ensureVisible(find.text(targetLabels.load));
    await tester.tap(find.text(targetLabels.load));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(field('host')).controller!.text,
      'saved.invalid',
    );
    expect(
      tester.widget<TextFormField>(field('password')).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<TextFormField>(field('agent-token')).controller!.text,
      isEmpty,
    );
    expect(submissions, 0);
  });

  for (final dispose in [false, true]) {
    testWidgets(
      'late load after ${dispose ? 'disposal' : 'cancel'} cannot replace draft or transport',
      (tester) async {
        final store = HeldStore();
        var modeChanges = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ManagedSshConnectionForm(
                labels: labels,
                targetLabels: targetLabels,
                targetStore: store,
                onServeReadsLoaded: (_) => modeChanges++,
                onSubmit: (_) async => fail('unexpected submit'),
                onCancel: () {},
              ),
            ),
          ),
        );
        await tester.enterText(field('host'), 'draft.invalid');
        await tester.tap(find.text(targetLabels.load));
        await tester.pump();
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        if (dispose) {
          await tester.pumpWidget(const SizedBox());
        } else {
          await tester.ensureVisible(find.text(labels.cancel));
          await tester.tap(find.text(labels.cancel));
          await tester.pump();
        }
        store.pending.complete(
          ManagedSshTarget(
            config: ManagedSshConfig(
              host: 'late.invalid',
              username: 'tester',
              agentPort: 8642,
            ),
            serveReads: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(modeChanges, 0);
        if (!dispose) {
          expect(
            tester.widget<TextFormField>(field('host')).controller!.text,
            'draft.invalid',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('new transport intent fences a pending saved-settings load', (
    tester,
  ) async {
    final store = HeldStore();
    var changes = 0;
    Widget form(bool serveReads) => MaterialApp(
      home: Scaffold(
        body: ManagedSshConnectionForm(
          labels: labels,
          targetLabels: targetLabels,
          targetStore: store,
          serveReads: serveReads,
          onServeReadsLoaded: (_) => changes++,
          onSubmit: (_) async => fail('unexpected submit'),
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpWidget(form(false));
    await tester.enterText(field('host'), 'draft.invalid');
    await tester.tap(find.text(targetLabels.load));
    await tester.pump();
    await tester.pumpWidget(form(true));
    store.pending.complete(
      ManagedSshTarget(
        config: ManagedSshConfig(
          host: 'obsolete.invalid',
          username: 'tester',
          agentPort: 8642,
        ),
        serveReads: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(changes, 0);
    expect(
      tester.widget<TextFormField>(field('host')).controller!.text,
      'draft.invalid',
    );
  });

  testWidgets('settings save validates target without requiring credentials', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManagedSshConnectionForm(
            labels: labels,
            targetLabels: targetLabels,
            onSubmit: (_) async => fail('unexpected submit'),
            onCancel: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.text(targetLabels.save));
    await tester.pumpAndSettle();
    expect(await const SecureManagedSshTargetStore().load(), isNull);
    await tester.enterText(field('host'), 'example.invalid');
    await tester.enterText(field('username'), 'tester');
    await tester.ensureVisible(find.text(targetLabels.save));
    await tester.tap(find.text(targetLabels.save));
    await tester.pumpAndSettle();
    expect(find.text(targetLabels.saved), findsOneWidget);
    expect(
      (await const SecureManagedSshTargetStore().load())!.config.host,
      'example.invalid',
    );
    expect(
      tester.widget<TextFormField>(field('password')).controller!.text,
      isEmpty,
    );
  });

  testWidgets(
    'missing settings keeps entered destination and offers manual connection',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManagedSshConnectionForm(
              labels: labels,
              targetLabels: targetLabels,
              onSubmit: (_) async {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.enterText(field('host'), 'draft.invalid');
      await tester.tap(find.text(targetLabels.load));
      await tester.pumpAndSettle();
      expect(find.text(targetLabels.missing), findsOneWidget);
      expect(
        tester.widget<TextFormField>(field('host')).controller!.text,
        'draft.invalid',
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );
}
