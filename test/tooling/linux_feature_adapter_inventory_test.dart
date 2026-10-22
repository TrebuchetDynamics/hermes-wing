import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native adapter registers current Bot Chat, timestamp and export suites once',
    () {
      final required = {
        'test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart',
        'test/features/hermes_chat/screens/hermes_chat_slash_commands_test.dart',
        'test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart',
        for (final root in [
          'test/features/hermes_chat/bots',
          'test/features/hermes_chat/export',
        ])
          for (final file in Directory(root).listSync(recursive: true))
            if (file is File && file.path.endsWith('_test.dart'))
              file.path.replaceAll(Platform.pathSeparator, '/'),
      };
      final source = File(
        'integration_test/linux_feature_regression_test.dart',
      ).readAsStringSync();
      final imports = RegExp(
        r"import\s+'\.\./(test/[^']+_test\.dart)'\s+as\s+(\w+)\s*;",
      ).allMatches(source).toList();
      final registrations = RegExp(
        r"group\(\s*'(test/[^']+_test\.dart)'\s*,\s*(?:\(\)\s*=>\s*)?(\w+)\.main\b",
      ).allMatches(source).toList();
      final paths = imports.map((match) => match[1]!).toList();
      expect(
        paths,
        containsAll(required),
        reason:
            'Current Bot Chat, timestamp and export suites must not be omitted.',
      );
      expect(
        paths.toSet(),
        hasLength(paths.length),
        reason: 'No duplicate suites.',
      );
      expect(
        paths.where((path) => !File(path).existsSync()),
        isEmpty,
        reason: 'No stale suite imports.',
      );
      expect(
        registrations.map((match) => '${match[1]}:${match[2]}'),
        unorderedEquals(imports.map((match) => '${match[1]}:${match[2]}')),
        reason:
            'Each imported suite must register main under its exact source path.',
      );
      expect(
        imports.map((match) => match[2]).toSet(),
        hasLength(imports.length),
        reason: 'Suite aliases must be unique.',
      );
      final unselected = [
        for (final root in [
          'test/app',
          'test/features',
          'test/router',
          'test/shared',
        ])
          for (final file in Directory(root).listSync(recursive: true))
            if (file is File && file.path.endsWith('_test.dart'))
              file.path.replaceAll(Platform.pathSeparator, '/'),
      ].where((path) => !paths.contains(path)).toList()..sort();
      // Retain exact selection/gaps in the campaign's machine-reporter log.
      // ignore: avoid_print
      print(
        jsonEncode({
          'kind': 'linux-adapter-inventory',
          'selected_suites': paths..sort(),
          'unselected_suites': unselected,
        }),
      );
    },
  );
}
