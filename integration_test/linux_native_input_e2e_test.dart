import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/features/voice/services/platform/default_voice_capture_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.shouldPropagateDevicePointerEvents = true;
  WidgetController.hitTestWarningShouldBeFatal = true;
  final sample = Platform.environment['WING_NATIVE_PICK_FILE'];
  if (Platform.environment['WING_ISOLATED_NATIVE_INPUT'] != '1' ||
      sample == null ||
      !sample.startsWith('/tmp/wing-linux-native.')) {
    throw StateError('Use the isolated native-input launcher.');
  }
  testWidgets('Linux real X11 keyboard and GTK file picker', (tester) async {
    // Do not register testTextInput: the GTK host must deliver real key events.
    final text = TextEditingController();
    addTearDown(text.dispose);
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(controller: text),
              TextButton(
                onPressed: () async {
                  final file = await openFile(
                    acceptedTypeGroups: [
                      const XTypeGroup(label: 'Text', extensions: ['txt']),
                    ],
                  );
                  picked = file == null ? null : await file.readAsString();
                },
                child: const Text('Open real file picker'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    Future<void> drive(String mode) async {
      final result = await Process.run('/usr/bin/python3', [
        'scripts/linux_native_input.py',
        mode,
      ]);
      expect(
        result.exitCode,
        0,
        reason: 'Native input helper failed: ${result.stderr}',
      );
    }

    await drive('type');
    final typingDeadline = DateTime.now().add(const Duration(seconds: 10));
    while (text.text != 'native keyboard input' &&
        DateTime.now().isBefore(typingDeadline)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(text.text, 'native keyboard input');
    await tester.tap(find.text('Open real file picker'));
    await tester.pump();
    await drive('pick');
    final pickerDeadline = DateTime.now().add(const Duration(seconds: 10));
    while (picked == null && DateTime.now().isBefore(pickerDeadline)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(picked, 'synthetic picker content\n');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Linux capture support boundary is explicit', (_) async {
    expect(Platform.isLinux, isTrue);
    expect(createDefaultVoiceCaptureService(), isNull);
  });
  testWidgets('Linux GTK IME commit and cancellation preserve text', (
    tester,
  ) async {
    final text = TextEditingController();
    addTearDown(text.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(controller: text)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    for (final mode in ['type', 'compose', 'compose_cancel']) {
      final result = await Process.run('/usr/bin/python3', [
        'scripts/linux_native_input.py',
        mode,
      ]);
      expect(result.exitCode, 0);
      await tester.pumpAndSettle();
      expect(
        text.text,
        mode == 'type' ? 'native keyboard input' : 'native keyboard input😀',
      );
      expect(text.value.composing.isCollapsed, isTrue);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Linux native window minimize restore preserves draft', (
    tester,
  ) async {
    final probe = _LifecycleProbe();
    binding.addObserver(probe);
    addTearDown(() => binding.removeObserver(probe));
    final text = TextEditingController(text: 'unsent synthetic draft');
    addTearDown(text.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(controller: text)),
      ),
    );
    await tester.pumpAndSettle();
    final result = await Process.run('/usr/bin/python3', [
      'scripts/linux_native_input.py',
      'lifecycle',
    ]);
    expect(result.exitCode, 0);
    await tester.pumpAndSettle();
    expect(probe.events, contains(AppLifecycleState.hidden));
    final hidden = probe.events.indexOf(AppLifecycleState.hidden);
    expect(probe.events.skip(hidden + 1), contains(AppLifecycleState.resumed));
    expect(text.text, 'unsent synthetic draft');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _LifecycleProbe extends WidgetsBindingObserver {
  final events = <AppLifecycleState>[];
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => events.add(state);
}
