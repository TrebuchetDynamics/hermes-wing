import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';

import '../../test/features/hermes_chat/support/fake_hermes_channel.dart';

/// In-memory status authority only: no sockets, credentials or inference.
class StatusAccessibilityNativeFixture extends FakeHermesChannel {
  StatusAccessibilityNativeFixture()
    : super(
        profiles: const [
          HermesProfile(
            id: 'synthetic-status',
            displayName: profile,
            revision: 'r1',
            model: model,
          ),
        ],
        selectedProfileId: 'synthetic-status',
        connectedBaseUrl: 'http://127.0.0.1:8642',
      );

  static const profile = 'Synthetic enlarged status inspection profile';
  static const model =
      'synthetic-provider/long-current-model-for-status-inspection';
  static const replacementProfile = 'Synthetic replacement status owner';
  static const replacementModel =
      'synthetic-provider/replacement-model-for-current-owner';
  HermesChannelState? _snapshot;

  @override
  HermesChannelState get state => _snapshot ?? super.state;

  void phase(String phase) {
    _snapshot = switch (phase) {
      'connected' => super.state,
      'recovering' => super.state.copyWith(
        status: HermesConnectionStatus.connecting,
      ),
      'failed' => const HermesChannelState(
        status: HermesConnectionStatus.error,
        errorMessage: 'Synthetic disconnected failure',
      ),
      'replacement' => HermesChannelState(
        status: HermesConnectionStatus.connected,
        connectedBaseUrl: 'http://127.0.0.1:9753',
        profiles: const [
          HermesProfile(
            id: 'synthetic-replacement',
            displayName: replacementProfile,
            revision: 'r2',
            model: replacementModel,
          ),
        ],
        selectedProfileId: 'synthetic-replacement',
      ),
      _ => throw ArgumentError.value(phase),
    };
    notifyListeners();
  }

  Map<String, int> get mutationCounts => {
    'sends': sentTextAttachments.length,
    'creates': createSessionCalls.length + createProfileCalls.length,
    'approvals': respondToApprovalCalls.length,
    'model_writes': assignModelCalls.length + lockSessionModelCalls.length,
    'stops': stopActiveTurnCalls,
    'profile_writes': renameProfileCalls.length + deleteProfileCalls.length,
    'selections': selectSessionCalls.length + selectProfileCalls.length,
  };
}
