import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_provider.dart';

class _RecordingForward extends ManagedSshForward {
  int disposals = 0;

  @override
  Future<void> dispose() async {
    disposals++;
    await super.dispose();
  }
}

void main() {
  test(
    'screen listener removal retains transport until app disposal',
    () async {
      final forward = _RecordingForward();
      final container = ProviderContainer(
        overrides: [
          managedSshForwardFactoryProvider.overrideWithValue(() => forward),
        ],
      );
      final listener = container.listen(managedSshForwardProvider, (_, _) {});
      expect(listener.read(), same(forward));
      listener.close();
      await Future<void>.delayed(Duration.zero);
      expect(forward.disposals, 0);
      expect(container.read(managedSshForwardProvider), same(forward));
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(forward.disposals, 1);
    },
  );

  test('app containers never share an SSH transport', () async {
    final first = _RecordingForward();
    final second = _RecordingForward();
    final a = ProviderContainer(
      overrides: [
        managedSshForwardFactoryProvider.overrideWithValue(() => first),
      ],
    );
    final b = ProviderContainer(
      overrides: [
        managedSshForwardFactoryProvider.overrideWithValue(() => second),
      ],
    );
    expect(a.read(managedSshForwardProvider), same(first));
    expect(b.read(managedSshForwardProvider), same(second));
    a.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(first.disposals, 1);
    expect(second.disposals, 0);
    b.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(second.disposals, 1);
  });
}
