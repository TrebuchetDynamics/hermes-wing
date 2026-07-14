part of '../hermes_chat_screen.dart';

/// Wires the on-device voice-command router (Needle) into the chat screen:
/// instant-tier commands dispatch immediately with a snackbar, confirm-tier
/// commands show a [VoiceCommandChip], and the confirm/decline/timeout
/// resolutions feed back into the app's Hermes/settings/navigation surface
/// via [voiceCommandDispatcherProvider].
///
/// See docs/superpowers/plans/2026-07-13-needle-router.md, Task 10, for the
/// re-arm rule implemented by [_rearmContinuousVoiceIfNeeded].
extension _HermesChatScreenVoiceCommands on _HermesChatScreenState {
  Future<VoiceRouteResult?> _routeTranscript(String transcript) async {
    final router = ref.read(voiceCommandRouterProvider);
    if (router == null) return null;
    final result = await router.route(transcript);
    if (!mounted) return result;
    // Suspension hint (spec requirement): checked after every routing
    // resolution — not only when a command was actually routed — so the
    // operator finds out the moment the router goes quiet, not the next
    // time they happen to say something that would have matched a tool.
    if (router.suspended && !_suspensionNoticeShown) {
      _suspensionNoticeShown = true;
      ref.read(voiceCommandNoticeProvider.notifier).state =
          'On-device commands paused after repeated errors. They resume on '
          'app restart.';
    }
    return result;
  }

  void _onRoutedCommand(VoiceRouteResult result, {required bool autoSend}) {
    if (result.tier == VoiceCommandTier.instant) {
      unawaited(_dispatchInstantVoiceCommand(result, autoSend: autoSend));
      return;
    }
    // One chip at a time: a new confirm-tier result replaces whatever was
    // showing (its own timer/state resets via VoiceCommandChip's
    // didUpdateWidget).
    _setState(() {
      _pendingVoiceCommand = result;
      _pendingVoiceCommandAutoSend = autoSend;
    });
  }

  Future<void> _dispatchInstantVoiceCommand(
    VoiceRouteResult result, {
    required bool autoSend,
  }) async {
    await ref.read(voiceCommandDispatcherProvider).dispatch(result);
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(result.describe())));
    _rearmContinuousVoiceIfNeeded(result);
  }

  void _confirmVoiceCommand() {
    final result = _pendingVoiceCommand;
    if (result == null) return;
    _setState(() => _pendingVoiceCommand = null);
    unawaited(_dispatchConfirmedVoiceCommand(result));
  }

  Future<void> _dispatchConfirmedVoiceCommand(VoiceRouteResult result) async {
    await ref.read(voiceCommandDispatcherProvider).dispatch(result);
    if (!mounted) return;
    _rearmContinuousVoiceIfNeeded(result);
  }

  void _declineVoiceCommand() {
    final result = _pendingVoiceCommand;
    if (result == null) return;
    final autoSend = _pendingVoiceCommandAutoSend;
    _setState(() => _pendingVoiceCommand = null);
    if (autoSend) {
      // Declined continuous commands send as plain text: the transcript was
      // already consumed as a candidate command instead of drafted, so
      // sending it now is the only way it still reaches the conversation.
      unawaited(_sendDeclinedVoiceTranscript(result));
    } else {
      _appendVoiceDraft(result.transcript);
      _rearmContinuousVoiceIfNeeded(result);
    }
  }

  Future<void> _sendDeclinedVoiceTranscript(VoiceRouteResult result) async {
    await ref.read(hermesChannelProvider).sendText(result.transcript);
    if (!mounted) return;
    _rearmContinuousVoiceIfNeeded(result);
  }

  /// Re-arm rule: a routed command consumes the transcript instead of
  /// submitting a voice run, so no Hermes reply follows to drive
  /// `maybeContinue()`'s own re-arm. Without this, every routed command
  /// would silently end hands-free capture. Restart continuous capture
  /// ourselves after every resolution — instant dispatch, chip confirm,
  /// chip decline, chip timeout — while continuous mode is still on.
  ///
  /// Two commands are one-shot exceptions and must NOT re-arm:
  /// `stop_voice_run` (the operator just asked the loop to stop — its
  /// dispatch already calls `voiceController.pause()`, which is exactly why
  /// `continuousEnabled` reads false below) and `toggle_continuous_mode`
  /// with `enabled: false` (the operator asked to turn continuous mode off).
  void _rearmContinuousVoiceIfNeeded(VoiceRouteResult result) {
    if (result.command == VoiceCommandId.stopVoiceRun) return;
    if (result.command == VoiceCommandId.toggleContinuousMode &&
        result.args['enabled'] == false) {
      return;
    }
    if (!_voiceInputController.continuousEnabled) return;
    unawaited(_voiceInputController.enableContinuous());
  }
}
