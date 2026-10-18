import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/ssh/secure_managed_ssh_target_store.dart';
import 'package:wing/core/hermes/ssh/ssh_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const slot = 'hermes_wing.managed_ssh.target.v1';
  final values = <String, String>{};
  final calls = <String>[];
  var fail = false;
  var loseWrite = false;
  setUp(() {
    values.clear();
    calls.clear();
    fail = false;
    loseWrite = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (fail) throw PlatformException(code: 'synthetic-storage-failure');
          final key = call.arguments['key'] as String;
          expect(key, slot);
          if (call.method == 'read') return values[key];
          if (call.method == 'write' && !loseWrite) {
            values[key] = call.arguments['value'] as String;
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  final target = ManagedSshTarget(
    config: ManagedSshConfig(
      host: 'example.invalid',
      sshPort: 2222,
      username: 'tester',
      agentPort: 8643,
    ),
    serveReads: true,
  );

  test(
    'profile destination survives recreation and cannot inherit root selection',
    () async {
      const store = SecureManagedSshTargetStore();
      final profiled = ManagedSshTarget(
        config: ManagedSshConfig(
          host: target.config.host,
          sshPort: 2222,
          username: 'tester',
          agentPort: 8643,
          agentProfile: 'demo',
        ),
        serveReads: false,
      );
      await store.save(target);
      final legacy = values[slot];
      expect((await store.load())!.config.agentProfile, isNull);
      await store.rememberSelection(profiled);
      expect(values[slot], legacy);
      await store.save(profiled);
      final reopened = await store.load();
      expect(reopened!.config.agentProfile, 'demo');
      expect(reopened.selection, isNull);
      expect(reopened.sameDestination(target), isFalse);
      expect((jsonDecode(values[slot]!) as List).last, 'demo');
    },
  );

  test(
    'recreated store restores destination and mode, not a forwarded endpoint',
    () async {
      expect(await const SecureManagedSshTargetStore().load(), isNull);
      await const SecureManagedSshTargetStore().save(target);
      final restored = await const SecureManagedSshTargetStore().load();
      expect(restored!.config.host, target.config.host);
      expect(restored.config.sshPort, 2222);
      expect(restored.config.username, 'tester');
      expect(restored.config.agentPort, 8643);
      expect(restored.serveReads, isTrue);
      expect(jsonDecode(values[slot]!), [
        'example.invalid',
        2222,
        'tester',
        8643,
        true,
      ]);
      expect(restored.toString(), isNot(contains('example.invalid')));
    },
  );

  test('corrupt, unbounded or wrong-shaped records stay untouched', () async {
    for (final raw in [
      'x' * 1025,
      'not json',
      '{}',
      jsonEncode(['https://example.invalid', 22, 'tester', 8642, false]),
      jsonEncode(['example.invalid', 0, 'tester', 8642, false]),
      jsonEncode(['example.invalid', 22, 'tester', 8642, 'false']),
      jsonEncode(['example.invalid', 22, 'tester', 8642, false, 'extra']),
      jsonEncode([
        'example.invalid',
        22,
        'tester',
        8642,
        false,
        null,
        'orphan',
        'demo',
      ]),
      jsonEncode([
        'example.invalid',
        22,
        'tester',
        8642,
        false,
        null,
        null,
        '../demo',
      ]),
      jsonEncode([
        'example.invalid',
        22,
        'tester',
        8642,
        true,
        null,
        null,
        'demo',
      ]),
    ]) {
      values[slot] = raw;
      await expectLater(
        const SecureManagedSshTargetStore().load(),
        throwsFormatException,
      );
      expect(values[slot], raw);
    }
    expect(calls, everyElement('read'));
  });

  test(
    'only an exact explicitly saved destination remembers its owner',
    () async {
      final selected = ManagedSshTarget(
        config: target.config,
        serveReads: true,
        selection: (profile: 'demo', session: 'demo-session'),
      );
      const store = SecureManagedSshTargetStore();
      await store.rememberSelection(selected);
      expect(values, isEmpty);
      await store.save(target);
      await store.rememberSelection(selected);
      expect(
        (await const SecureManagedSshTargetStore().load())!.selection,
        selected.selection,
      );
      final raw = values[slot];
      await store.rememberSelection(
        ManagedSshTarget(
          config: ManagedSshConfig(
            host: 'other.invalid',
            username: 'tester',
            agentPort: 8642,
          ),
          serveReads: true,
          selection: (profile: 'other', session: null),
        ),
      );
      expect(values[slot], raw);
      await store.save(
        ManagedSshTarget(config: target.config, serveReads: false),
      );
      await store.rememberSelection(selected);
      expect((await store.load())!.selection, isNull);
    },
  );

  test(
    'invalid owner extensions fail closed without touching saved bytes',
    () async {
      const store = SecureManagedSshTargetStore();
      for (final selection in [
        (profile: '', session: 'session'),
        (profile: 'demo', session: '../session'),
        (profile: 'x' * 129, session: null),
      ]) {
        final raw = jsonEncode([
          'example.invalid',
          22,
          'tester',
          8642,
          true,
          selection.profile,
          selection.session,
        ]);
        values[slot] = raw;
        await expectLater(store.load(), throwsFormatException);
        await expectLater(
          store.save(
            ManagedSshTarget(
              config: target.config,
              serveReads: true,
              selection: selection,
            ),
          ),
          throwsFormatException,
        );
        expect(values[slot], raw);
      }
    },
  );

  test(
    'secure storage failure and failed readback never report save success',
    () async {
      fail = true;
      await expectLater(
        const SecureManagedSshTargetStore().save(target),
        throwsFormatException,
      );
      await expectLater(
        const SecureManagedSshTargetStore().load(),
        throwsFormatException,
      );
      fail = false;
      loseWrite = true;
      await expectLater(
        const SecureManagedSshTargetStore().save(target),
        throwsFormatException,
      );
      expect(values, isEmpty);
    },
  );
}
