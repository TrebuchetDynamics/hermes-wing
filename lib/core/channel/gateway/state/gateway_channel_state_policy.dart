import '../../../protocol/navivox_event.dart';
import '../../../protocol/navivox_voice_run.dart';
import '../../contracts/navivox_channel.dart';

/// Shared state update policy for gateway transcript and voice-run maps.
///
/// Gateway event handlers, local user turns, safety notices, and voice-run
/// lifecycle updates all upsert keyed entities into immutable channel state.
/// Keeping the copy-on-write contract here prevents those paths from drifting.
NavivoxChannelState navivoxStateWithGatewayMessage({
  required NavivoxChannelState state,
  required NavivoxChatMessage message,
}) {
  final messages = Map<String, NavivoxChatMessage>.from(state.messages);
  messages[message.id] = message;
  return state.copyWith(messages: messages);
}

NavivoxChannelState navivoxStateWithGatewayVoiceRun({
  required NavivoxChannelState state,
  required NavivoxVoiceRun run,
  required bool active,
}) {
  final runs = Map<String, NavivoxVoiceRun>.from(state.voiceRuns);
  runs[run.id] = run;
  return state.copyWith(
    voiceRuns: runs,
    activeVoiceRunId: active ? run.id : state.activeVoiceRunId,
  );
}

bool navivoxShouldAppendGatewaySystemMessage({
  required NavivoxChannelState state,
  required String text,
}) {
  final messages = state.messagesList;
  final lastMessage = messages.isEmpty ? null : messages.last;
  return !(lastMessage?.author == NavivoxMessageAuthor.system &&
      lastMessage?.kind == NavivoxMessageKind.text &&
      lastMessage?.text == text);
}
