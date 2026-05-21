import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    final extensionFile = File('../.pi/extensions/navivox-delivery-loop.ts');
    expect(
      extensionFile.existsSync(),
      isTrue,
      reason:
          'The project-local Pi extension must live at .pi/extensions/navivox-delivery-loop.ts.',
    );
    source = extensionFile.readAsStringSync();
  });

  test('registers the navivox-loop slash command', () {
    expect(source, contains('registerCommand("navivox-loop"'));
    expect(source, contains('/navivox-loop'));
  });

  test('iteration prompt embeds recent loop logs', () {
    expect(source, contains('RECENT_LOG_LIMIT'));
    expect(source, contains('readRecentLogs'));
    expect(source, contains('Latest navivox-loop JSONL log records'));
  });

  test('iteration prompt requires project workflows and skills', () {
    expect(source, contains('scope lock'));
    expect(source, contains('repo preflight'));
    expect(source, contains('using-superpowers'));
    expect(source, contains('test-driven-development'));
    expect(source, contains('verification-before-completion'));
    expect(source, contains('one vertical slice'));
  });

  test('iteration prompt includes the full Navivox CI gate', () {
    expect(source, contains('flutter analyze'));
    expect(source, contains('flutter test'));
    expect(source, contains('git diff --check'));
  });

  test('iteration prompt and enforcement require CI_GREEN', () {
    expect(source, contains('CI_GREEN: yes'));
    expect(source, contains('ci_gate_missing'));
    expect(source, contains('LOOP_DECISION: continue'));
    expect(source, contains('LOOP_DECISION: blocked'));
    expect(source, contains('LOOP_DECISION: done'));
  });

  test('active default start reports status without replacing state', () {
    expect(source, contains('ACTIVE_START_POLICY'));
    expect(source, contains('status-only-no-replace'));
    expect(source, contains('Loop already active'));
  });

  test('restart is explicit and confirmed before replacing active state', () {
    expect(source, contains('RESTART_POLICY'));
    expect(source, contains('explicit-confirm-before-replace'));
    expect(source, contains('Replace active navivox-loop state?'));
    expect(source, contains('ctx.ui.confirm'));
  });
}
