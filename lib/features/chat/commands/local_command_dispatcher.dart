import '../../../core/channel/navivox_channel.dart';
import '../../../core/protocol/navivox_voice_run.dart';
import '../../../router/app_routes.dart';
import 'local_command_intent.dart';

class LocalCommandDispatchResult {
  const LocalCommandDispatchResult({
    required this.consumed,
    this.enterCommandMode = false,
    this.cancelPendingVoice = false,
    this.routeLocation,
    this.message,
  });

  const LocalCommandDispatchResult.notConsumed() : this(consumed: false);

  final bool consumed;
  final bool enterCommandMode;
  final bool cancelPendingVoice;
  final String? routeLocation;
  final String? message;
}

class LocalCommandDispatcher {
  const LocalCommandDispatcher();

  LocalCommandDispatchResult dispatch(
    NavivoxChannel channel,
    LocalCommandIntent intent,
  ) {
    switch (intent.action) {
      case LocalCommandAction.none:
        return const LocalCommandDispatchResult.notConsumed();
      case LocalCommandAction.enterCommandMode:
        return const LocalCommandDispatchResult(
          consumed: true,
          enterCommandMode: true,
        );
      case LocalCommandAction.cancel:
        if (channel.state.activeVoiceRun?.status ==
            NavivoxVoiceRunStatus.pendingSend) {
          return const LocalCommandDispatchResult(
            consumed: true,
            cancelPendingVoice: true,
          );
        }
        channel.cancelActiveTurn();
        return LocalCommandDispatchResult(
          consumed: true,
          message: intent.message,
        );
      case LocalCommandAction.stop:
        channel.stopActiveTurn();
        return LocalCommandDispatchResult(
          consumed: true,
          message: intent.message,
        );
      case LocalCommandAction.openSettings:
        return const LocalCommandDispatchResult(
          consumed: true,
          routeLocation: AppRoutes.settings,
        );
      case LocalCommandAction.switchProfile:
        final contact = intent.target;
        if (contact == null) {
          return const LocalCommandDispatchResult(consumed: true);
        }
        channel.selectProfileContact(
          serverId: contact.serverId,
          profileId: contact.profileId,
        );
        return LocalCommandDispatchResult(
          consumed: true,
          routeLocation: AppRoutes.chatLocation(
            serverId: contact.serverId,
            profileId: contact.profileId,
          ),
          message: intent.message,
        );
      case LocalCommandAction.showMessage:
      case LocalCommandAction.disambiguateProfile:
      case LocalCommandAction.profileSwitchingDisabled:
      case LocalCommandAction.unknown:
        return LocalCommandDispatchResult(
          consumed: true,
          message: intent.message,
        );
    }
  }
}
