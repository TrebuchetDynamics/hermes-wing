import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/enrollment/screens/hermes_enrollment_screen.dart';
import '../../features/hermes_chat/providers/hermes_channel_provider.dart';
import '../../features/hermes_chat/providers/managed_ssh_connection_controller.dart';
import '../../core/hermes/channel/hermes_channel.dart';
import '../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../l10n/app_localizations.dart';

/// Resolve secure saved ownership before exposing the connected navigation.
/// The directory remains the owner of restoration; this read never connects.
class ConnectionEntryGate extends ConsumerStatefulWidget {
  const ConnectionEntryGate({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<ConnectionEntryGate> createState() =>
      _ConnectionEntryGateState();
}

class _ConnectionEntryGateState extends ConsumerState<ConnectionEntryGate> {
  late Future<List<HermesEndpointConfig>> _saved;
  HermesChannel? _enteredChannel;
  HermesChannel? _observedChannel;

  @override
  void initState() {
    super.initState();
    _saved = ref.read(hermesEndpointStoreProvider).loadProfiles();
    ref.listenManual(hermesChannelProvider, (_, next) {
      _observedChannel?.removeListener(_observeConnection);
      _enteredChannel = null;
      _observedChannel = next;
      next.addListener(_observeConnection);
      _observeConnection();
    }, fireImmediately: true);
  }

  void _observeConnection() {
    final channel = _observedChannel;
    if (channel?.state.isConnected ?? false) {
      _enteredChannel = channel;
    } else if (channel?.state.status == HermesConnectionStatus.disconnected) {
      // Latch retirement even if reconnect starts before the next frame.
      _enteredChannel = null;
    }
  }

  @override
  void dispose() {
    _observedChannel?.removeListener(_observeConnection);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    ref.watch(hermesChannelStateProvider);
    final channel = ref.watch(hermesChannelProvider);
    if (ref.exists(managedSshConnectionControllerProvider)) {
      final ssh = ref.read(managedSshConnectionControllerProvider);
      // SSH teardown may emit disconnected before publishing its exact
      // interrupted owner. Only that current controller may admit Retry again.
      if (identical(ssh.channel, channel) && ssh.needsSshReconnect) {
        _enteredChannel = channel;
      }
    }
    // First-run gating must not unmount an admitted ephemeral owner's Retry
    // form during error/connecting. This retains presentation only: every
    // operation still uses current channel authority. Explicit disconnect or
    // channel replacement retires this admission; nothing reconnects here.
    if (directory.hasSavedGateways || identical(_enteredChannel, channel)) {
      return widget.child;
    }
    return FutureBuilder<List<HermesEndpointConfig>>(
      future: _saved,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _saved = ref.read(hermesEndpointStoreProvider).loadProfiles();
                }),
                child: Text(AppLocalizations.of(context).welcomeStorageRetry),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data!.isNotEmpty) return widget.child;
        return const HermesEnrollmentScreen();
      },
    );
  }
}
