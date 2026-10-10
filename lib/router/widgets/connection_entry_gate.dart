import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/enrollment/screens/hermes_enrollment_screen.dart';
import '../../features/hermes_chat/providers/hermes_channel_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _saved = ref.read(hermesEndpointStoreProvider).loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    final state = ref.watch(hermesChannelStateProvider);
    if (directory.hasSavedGateways || state.isConnected) return widget.child;
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
