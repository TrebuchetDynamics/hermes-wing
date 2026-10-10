import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/widgets/managed_ssh_host_key_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester, List<bool> answers) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answers.add(
                await reviewManagedSshHostKey(
                  context,
                  host: 'ssh.example.invalid',
                  port: 22,
                  algorithm: 'ssh-ed25519',
                  fingerprint: 'SHA256:TEST_ONLY_FINGERPRINT',
                  title: 'Verify SSH host',
                  explanation:
                      'Compare this fingerprint with the host before trusting it.',
                  cancelLabel: 'Cancel',
                  trustLabel: 'Trust this connection',
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('host key review requires deliberate trust', (tester) async {
    final answers = <bool>[];
    await open(tester, answers);
    expect(find.text('ssh.example.invalid:22'), findsOneWidget);
    expect(find.text('ssh-ed25519'), findsOneWidget);
    expect(find.text('SHA256:TEST_ONLY_FINGERPRINT'), findsOneWidget);
    expect(answers, isEmpty);
    await tester.tap(find.text('Trust this connection'));
    await tester.pumpAndSettle();
    expect(answers, [true]);
  });

  testWidgets('cancel and dismissal refuse host trust', (tester) async {
    final answers = <bool>[];
    await open(tester, answers);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(answers, [false]);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(answers, [false, false]);
  });
}
