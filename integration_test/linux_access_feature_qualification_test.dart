import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/linux_access_feature_fixture.dart';
import 'support/linux_test_isolation.dart';
import 'support/profile_footer_native_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final root = requireLinuxTestRoot('wing-linux-qualification-');
  if (!Platform.isLinux ||
      Platform.environment['HOME'] != '$root/home' ||
      Platform.environment['XDG_DATA_HOME'] != '$root/data' ||
      Platform.environment['XDG_CACHE_HOME'] != '$root/cache') {
    throw StateError('Use the isolated access qualification lane.');
  }
  final receipts = LinuxAccessReceipts(root);
  final expected = {
    'access-footer',
    'access-status',
    'access-keyboard',
    for (final boundary in AccessVoiceBoundary.values)
      'access-voice-${boundary.name}',
    'access-host-command',
    'access-export',
  };
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    });
    final strategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = strategy);
  });
  void accessCase(String id, Future<void> Function(WidgetTester) body) {
    testWidgets(id, (tester) async {
      final fatal = WidgetController.hitTestWarningShouldBeFatal;
      WidgetController.hitTestWarningShouldBeFatal = true;
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        WidgetController.hitTestWarningShouldBeFatal = fatal;
      }
    });
  }

  tearDownAll(() async {
    expect(receipts.ids, expected, reason: 'Every planned case must finish.');
    receipts.publish();
    // Keep the GTK process alive for the campaign's PID/group observation.
    await Future<void>.delayed(const Duration(seconds: 2));
  });
  accessCase('access-footer', (tester) async {
    final evidence = await runProfileFooterJourney(
      tester,
      binding.setSurfaceSize,
    );
    receipts.add(
      'access-footer',
      ['HD-SHELL', 'HD-ACCESS'],
      ['/hermes', '/profiles', '/tools'],
      4,
      {'sends': 0, 'mutations': 0},
      evidence,
    );
  });
  accessCase('access-status', (tester) async {
    receipts.add(
      'access-status',
      ['HD-SHELL', 'HD-ACCESS'],
      ['/hermes'],
      4,
      {'mutations': 0},
      await qualifyAccessStatus(tester, binding.setSurfaceSize),
    );
  });
  accessCase('access-keyboard', (tester) async {
    receipts.add(
      'access-keyboard',
      ['HD-ACCESS', 'HD-NATIVE'],
      ['/hermes'],
      4,
      {'sends': 0, 'model_writes': 0},
      await qualifyAccessKeyboard(tester, binding.setSurfaceSize),
    );
  });
  for (final boundary in AccessVoiceBoundary.values) {
    accessCase('access-voice-${boundary.name}', (tester) async {
      final result = await qualifyVoiceBoundary(
        tester,
        boundary,
        binding.setSurfaceSize,
      );
      receipts.add(
        'access-voice-${boundary.name}',
        ['HD-VOICE', 'HD-ACCESS'],
        ['/hermes'],
        boundary == AccessVoiceBoundary.owner ? 2 : 1,
        result.counts,
        result.evidence,
      );
    });
  }
  accessCase('access-host-command', (tester) async {
    receipts.add(
      'access-host-command',
      ['HD-NATIVE', 'HD-ACCESS'],
      ['/hermes', '/settings'],
      1,
      {'route_changes': 2, 'sends': 0},
      await qualifyHostCommand(tester),
      input: 'framework platform message and Ctrl+,; not OS menu activation',
    );
  });
  accessCase('access-export', (tester) async {
    receipts.add(
      'access-export',
      ['HD-NATIVE', 'HD-EXPORT'],
      ['/hermes'],
      1,
      {
        'clipboard_writes': 1,
        'file_writes': 1,
        'chooser_cancels': 1,
        'sends': 0,
      },
      await qualifyNativeExport(tester, root, binding.setSurfaceSize),
      input: 'framework action taps; OS-injected X11 GTK chooser keys',
      storage: 'owned GTK clipboard and UTF-8 file; mock preferences',
    );
  });
}
