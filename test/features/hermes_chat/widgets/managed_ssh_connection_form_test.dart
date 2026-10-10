import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/widgets/managed_ssh_connection_form.dart';

const labels = ManagedSshConnectionLabels(
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
);

Future<void> showForm(
  WidgetTester tester, {
  Future<void> Function(SshConnectionRequest)? submit,
  VoidCallback? cancel,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ManagedSshConnectionForm(
          labels: labels,
          onSubmit: submit ?? (_) async {},
          onCancel: cancel ?? () {},
        ),
      ),
    ),
  );
}

Finder field(String id) => find.byKey(ValueKey('managed-ssh-$id'));

Future<void> fillValid(WidgetTester tester) async {
  await tester.enterText(field('host'), 'ssh.example.invalid');
  await tester.enterText(field('username'), 'test-user');
  await tester.enterText(field('password'), 'synthetic-password');
}

Future<void> connect(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byType(FilledButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text(labels.connect));
  await tester.pump();
}

void main() {
  testWidgets('username and credential validation are bounded', (tester) async {
    var calls = 0;
    await showForm(
      tester,
      submit: (_) async {
        calls++;
      },
    );
    await fillValid(tester);
    for (final entry in <(String, String, String)>[
      ('username', '-option', labels.invalidUsername),
      ('username', 'u' * 65, labels.invalidUsername),
      ('password', '', labels.invalidPassword),
      ('password', 'p' * 4097, labels.invalidPassword),
      ('password', 'p\u0000', labels.invalidPassword),
      ('agent-token', 't' * 4097, labels.invalidToken),
      ('agent-token', 'token with whitespace', labels.invalidToken),
    ]) {
      await fillValid(tester);
      await tester.enterText(field('agent-token'), '');
      await tester.enterText(field(entry.$1), entry.$2);
      await connect(tester);
      expect(find.text(entry.$3), findsOneWidget);
      expect(calls, 0);
    }
  });
  testWidgets(
    'dispose clears secret controller references and late completion is safe',
    (tester) async {
      final pending = Completer<void>();
      await showForm(tester, submit: (_) => pending.future);
      await fillValid(tester);
      await tester.enterText(field('agent-token'), 'synthetic-token');
      final password = tester
          .widget<TextFormField>(field('password'))
          .controller!;
      final token = tester
          .widget<TextFormField>(field('agent-token'))
          .controller!;
      await connect(tester);
      await tester.pumpWidget(const SizedBox());
      expect(password.text, isEmpty);
      expect(token.text, isEmpty);
      pending.completeError(StateError('synthetic secret'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('caller error clears secrets and preserves non-secret draft', (
    tester,
  ) async {
    Widget form(String? error, bool busy) => MaterialApp(
      home: Scaffold(
        body: ManagedSshConnectionForm(
          labels: labels,
          sanitizedError: error,
          busy: busy,
          onSubmit: (_) async {},
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpWidget(form(null, false));
    await fillValid(tester);
    await tester.enterText(field('agent-token'), 'synthetic-token');
    await tester.pumpWidget(form('Host key review declined.', false));
    expect(find.text('Host key review declined.'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(field('password')).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<TextFormField>(field('agent-token')).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<TextFormField>(field('host')).controller!.text,
      'ssh.example.invalid',
    );
    await tester.pumpWidget(form(null, true));
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
  testWidgets(
    'busy send is latched and cancel clears secrets and ignores late failure',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      var cancels = 0;
      await showForm(
        tester,
        submit: (_) {
          calls++;
          return pending.future;
        },
        cancel: () {
          cancels++;
        },
      );
      await fillValid(tester);
      await tester.enterText(field('agent-token'), 'synthetic-token');
      final staleSend = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      await connect(tester);
      staleSend();
      await tester.pump();
      expect(find.text(labels.connecting), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(tester.widget<TextFormField>(field('host')).enabled, isFalse);
      await tester.tap(find.text(labels.connecting));
      await tester.pump();
      expect(calls, 1);
      await tester.ensureVisible(find.text(labels.cancel));
      await tester.tap(find.text(labels.cancel));
      await tester.pump();
      expect(cancels, 1);
      for (final id in ['password', 'agent-token']) {
        expect(
          tester.widget<TextFormField>(field(id)).controller!.text,
          isEmpty,
        );
      }
      expect(
        tester.widget<TextFormField>(field('host')).controller!.text,
        'ssh.example.invalid',
      );
      pending.completeError(StateError('raw synthetic-password'));
      await tester.pump();
      expect(find.text(labels.failure), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'raw callback exception is replaced by safe error and draft survives',
    (tester) async {
      await showForm(
        tester,
        submit: (_) async {
          throw StateError('raw synthetic-password');
        },
      );
      await fillValid(tester);
      await connect(tester);
      await tester.pump();
      expect(find.text(labels.failure), findsOneWidget);
      expect(find.textContaining('raw synthetic'), findsNothing);
      expect(
        tester.widget<TextFormField>(field('host')).controller!.text,
        'ssh.example.invalid',
      );
      expect(
        tester.widget<TextFormField>(field('password')).controller!.text,
        isEmpty,
      );
    },
  );
  testWidgets('compact enlarged text keyboard reaches all fields and actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var cancels = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: ManagedSshConnectionForm(
              labels: labels,
              onSubmit: (_) async {},
              onCancel: () {
                cancels++;
              },
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(field('agent-token'));
    await tester.pumpAndSettle();
    final tokenLabel = tester.renderObject<RenderParagraph>(
      find.text(labels.agentToken),
    );
    expect(
      tokenLabel.didExceedMaxLines,
      isFalse,
      reason: 'Optional Agent credential label must remain readable.',
    );
    await tester.ensureVisible(field('host'));
    await tester.pumpAndSettle();
    await tester.tap(field('host'));
    await tester.pump();
    for (final id in [
      'ssh-port',
      'username',
      'password',
      'agent-port',
      'agent-token',
    ]) {
      if (id == 'password') {
        // Authentication choices are keyboard-operable before the password.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(field('password'), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(field('password'), findsOneWidget);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final editable = tester.widget<EditableText>(
        find.descendant(of: field(id), matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isTrue, reason: id);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(labels.invalidHost), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(cancels, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('wide form pairs host and SSH port without changing tab order', (
    tester,
  ) async {
    await showForm(tester);
    expect(
      tester.getTopLeft(field('host')).dy,
      tester.getTopLeft(field('ssh-port')).dy,
    );
    await tester.tap(field('host'));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: field('ssh-port'),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
  });
  testWidgets(
    'deliberate submission has typed ports and separate credentials',
    (tester) async {
      final inputs = <SshConnectionRequest>[];
      await showForm(
        tester,
        submit: (input) async {
          inputs.add(input);
        },
      );
      await fillValid(tester);
      await tester.enterText(field('agent-token'), 'synthetic-token');
      expect(inputs, isEmpty);
      await connect(tester);
      expect(inputs, hasLength(1));
      final input = inputs.single;
      expect(input.host, 'ssh.example.invalid');
      expect(input.username, 'test-user');
      expect(input.sshPort, 22);
      expect(input.agentPort, 8642);
      expect(input.password, 'synthetic-password');
      expect(input.agentBearerToken, 'synthetic-token');
      expect(input.toString(), isNot(contains('synthetic')));
    },
  );
  testWidgets('invalid host and ports reject rather than default or truncate', (
    tester,
  ) async {
    var calls = 0;
    await showForm(
      tester,
      submit: (_) async {
        calls++;
      },
    );
    await fillValid(tester);
    for (final host in [
      'https://ssh.example.invalid',
      'host/path',
      '-option',
      '999.1.1.1',
      'a b',
      '',
    ]) {
      await tester.enterText(field('host'), host);
      await connect(tester);
      expect(find.text(labels.invalidHost), findsOneWidget);
      expect(calls, 0);
    }
    await tester.enterText(field('host'), 'ssh.example.invalid');
    for (final id in ['ssh-port', 'agent-port']) {
      for (final value in ['', '0', '65536', '22x', '-1']) {
        await tester.enterText(field(id), value);
        await connect(tester);
        expect(find.text(labels.invalidPort), findsWidgets);
        expect(calls, 0);
      }
      await tester.enterText(field(id), '22');
    }
  });
  testWidgets('shows separate SSH and Agent fields with default ports', (
    tester,
  ) async {
    await showForm(tester);
    final semantics = tester.ensureSemantics();
    for (final label in [
      labels.host,
      labels.sshPort,
      labels.username,
      labels.password,
      labels.agentPort,
      labels.agentToken,
    ]) {
      expect(find.bySemanticsLabel(label), findsWidgets);
    }
    semantics.dispose();
    for (final id in [
      'host',
      'ssh-port',
      'username',
      'password',
      'agent-port',
      'agent-token',
    ]) {
      expect(field(id), findsOneWidget);
    }
    expect(
      tester.widget<TextFormField>(field('ssh-port')).controller!.text,
      '22',
    );
    expect(
      tester.widget<TextFormField>(field('agent-port')).controller!.text,
      '8642',
    );
    expect(
      find.byKey(const ValueKey('managed-ssh-auth-private-key')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('managed-ssh-auth-password')),
      findsOneWidget,
    );
    for (final id in ['password', 'agent-token']) {
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: field(id),
                matching: find.byType(EditableText),
              ),
            )
            .obscureText,
        isTrue,
      );
    }
  });
}
