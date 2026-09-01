import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/local_wing_link_platform_io.dart' as io;

void main() {
  test('bounded runner times out and confirms child exit', () async {
    final executable = await _sleepingExecutable();
    final stopwatch = Stopwatch()..start();

    final result = await io.runLocalWingLink(
      executable,
      const [],
      timeout: const Duration(milliseconds: 100),
    );

    expect(result.exitCode, 124);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 3)));
  });

  test('setup output is bounded before line buffering', () async {
    if (!Platform.isLinux) return;
    final directory = await Directory.systemTemp.createTemp(
      'wing-link-output-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final executable = File('${directory.path}/wing-link')
      ..writeAsStringSync(
        '#!/usr/bin/python3\n'
        'import sys\n'
        'import time\n'
        "sys.stdout.write('x' * 262145)\n"
        'sys.stdout.flush()\n'
        'time.sleep(60)\n',
      );
    final chmod = await Process.run('chmod', ['0755', executable.path]);
    expect(chmod.exitCode, 0);

    final operation = await io.startLocalWingLinkSetup(
      executable.path,
      (_) {},
      timeout: const Duration(seconds: 3),
    );
    final result = await operation.result;

    expect(result.exitCode, 125);
  });

  test('setup operation times out and confirms child exit', () async {
    final executable = await _sleepingExecutable();
    final stopwatch = Stopwatch()..start();

    final operation = await io.startLocalWingLinkSetup(
      executable,
      (_) {},
      timeout: const Duration(milliseconds: 100),
    );
    final result = await operation.result;

    expect(result.exitCode, 124);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 3)));
  });
}

Future<String> _sleepingExecutable() async {
  final directory = await Directory.systemTemp.createTemp('wing-link-timeout-');
  addTearDown(() => directory.delete(recursive: true));
  final executable = File('${directory.path}/wing-link')
    ..writeAsStringSync('#!/bin/sh\nexec sleep 60\n');
  final chmod = await Process.run('chmod', ['0755', executable.path]);
  expect(chmod.exitCode, 0);
  return executable.path;
}
