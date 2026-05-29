import '../../../core/channel/navivox_channel.dart';
import 'config_apply_flow_model.dart';

class ConfigApplyDispatcher {
  const ConfigApplyDispatcher();

  ConfigApplyDispatchResult dispatch({
    required ConfigApplyFlowModel flow,
    required NavivoxChannel channel,
  }) {
    if (!flow.hasPendingChanges) {
      return const ConfigApplyDispatchResult.skipped(
        'No pending config changes.',
      );
    }
    if (!flow.canApply) {
      return const ConfigApplyDispatchResult.skipped(
        'Config changes are invalid.',
      );
    }

    final appliedPaths = <String>[];
    for (final change in flow.changes) {
      if (change.isSecret) {
        channel.sendConfigSecretSet(
          name: change.path,
          secret: change.applyValue.toString(),
        );
      } else {
        channel.sendConfigSet(field: change.path, value: change.applyValue);
      }
      appliedPaths.add(change.path);
    }

    return ConfigApplyDispatchResult.dispatched(appliedPaths);
  }
}

class ConfigApplyDispatchResult {
  const ConfigApplyDispatchResult._({
    required this.appliedPaths,
    this.skippedReason,
  });

  const ConfigApplyDispatchResult.skipped(String reason)
    : this._(appliedPaths: const [], skippedReason: reason);

  factory ConfigApplyDispatchResult.dispatched(List<String> appliedPaths) {
    return ConfigApplyDispatchResult._(
      appliedPaths: List.unmodifiable(appliedPaths),
    );
  }

  final List<String> appliedPaths;
  final String? skippedReason;

  bool get wasDispatched => appliedPaths.isNotEmpty;
}
