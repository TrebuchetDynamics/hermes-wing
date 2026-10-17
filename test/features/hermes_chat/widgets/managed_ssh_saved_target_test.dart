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

// Serve transport is offered only when its labels are supplied (Android).
const serveLabels = ManagedSshConnectionLabels(
  privateKey: 'Private key',
  passwordChoice: 'Password',
  passphrase: 'Private-key passphrase',
  passphraseRequired: 'Enter a passphrase.',
  unlockFailed: 'Could not unlock key.',
  keyUnreadable: 'Unreadable key.',
  keyTooLarge: 'Key too large.',
  keyUnsupportedFormat: 'Unsupported format.',
  keyInvalid: 'Invalid key.',
  selectedKey: 'Selected private key',
  selectKey: 'Select private key',
  keyRequired: 'Select a private key.',
  host: 'SSH host',
  sshPort: 'SSH port',
  username: 'Username',
  password: 'SSH password',
  agentPort: 'Agent loopback port',
  agentToken: 'Agent bearer token (optional)',
  connect: 'Connect',
  connecting: 'Connecting',
  cancel: 'Cancel',
  invalidHost: 'Enter a host, not a URL.',
  invalidPort: 'Port must be 1–65535.',
  invalidUsername: 'Enter a valid username.',
  invalidPassword: 'Enter a password.',
  invalidToken: 'Enter a bounded bearer token.',
  failure: 'Connection failed.',
  serveReads: 'Use Hermes serve reads',
  serveToken: 'Hermes serve session token',
);

final serveChoice = find.byKey(const ValueKey('managed-ssh-serve-reads'));

bool serveSelected(WidgetTester tester) =>
    tester.widget<CheckboxListTile>(serveChoice).value!;

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
      Widget form() => MaterialApp(
        home: Scaffold(
          body: ManagedSshConnectionForm(
            labels: serveLabels,
            targetLabels: targetLabels,
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
      await tester.ensureVisible(serveChoice);
      await tester.tap(serveChoice);
      await tester.pumpAndSettle();
      await tester.enterText(field('agent-token'), 'synthetic-token');
      await tester.ensureVisible(find.text(targetLabels.save));
      await tester.tap(find.text(targetLabels.save));
      await tester.pumpAndSettle();
      expect(find.text(targetLabels.saved), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(form());
      expect(serveSelected(tester), isFalse);
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
      expect(serveSelected(tester), isTrue);
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
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ManagedSshConnectionForm(
                labels: serveLabels,
                targetLabels: targetLabels,
                targetStore: store,
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
        if (!dispose) {
          expect(serveSelected(tester), isFalse);
          expect(
            tester.widget<TextFormField>(field('host')).controller!.text,
            'draft.invalid',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('new connection intent fences a pending saved-settings load', (
    tester,
  ) async {
    final store = HeldStore();
    Widget form(bool busy) => MaterialApp(
      home: Scaffold(
        body: ManagedSshConnectionForm(
          labels: serveLabels,
          targetLabels: targetLabels,
          targetStore: store,
          busy: busy,
          onSubmit: (_) async => fail('unexpected submit'),
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpWidget(form(false));
    await tester.enterText(field('host'), 'draft.invalid');
    await tester.tap(find.text(targetLabels.load));
    await tester.pump();
    // The serve choice is disabled while loading; a parent attempt fences it.
    expect(tester.widget<CheckboxListTile>(serveChoice).onChanged, isNull);
    await tester.pumpWidget(form(true));
    store.pending.complete(
      ManagedSshTarget(
        config: ManagedSshConfig(
          host: 'obsolete.invalid',
          username: 'tester',
          agentPort: 8642,
        ),
        serveReads: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(serveSelected(tester), isFalse);
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
