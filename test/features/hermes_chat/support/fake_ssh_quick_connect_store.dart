import 'package:wing/core/hermes/ssh/secure_ssh_quick_connect_store.dart';

export 'package:wing/features/hermes_chat/widgets/managed_ssh_connection_panel.dart'
    show sshQuickConnectStoreProvider;

/// Connection presentation tests must not wait for a platform keychain.
class FakeSshQuickConnectStore extends SecureSshQuickConnectStore {
  FakeSshQuickConnectStore({this.read});

  final Future<SshQuickConnection?> Function()? read;

  @override
  Future<SshQuickConnection?> load() async =>
      read == null ? null : await read!();

  @override
  Future<void> save(
    SshQuickConnection connection, {
    required bool Function() isCurrent,
  }) async => throw StateError('Unexpected saved-access write.');

  @override
  Future<void> forget() async =>
      throw StateError('Unexpected saved-access deletion.');
}
