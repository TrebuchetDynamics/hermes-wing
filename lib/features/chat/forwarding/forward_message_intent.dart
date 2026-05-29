import '../../../core/channel/navivox_channel.dart';
import '../../../core/protocol/navivox_event.dart';
import '../../../router/app_routes.dart';
import '../presentation/transcript/transcript_message_plain_text_presentation.dart';

class ForwardMessageResult {
  const ForwardMessageResult({
    required this.forwarded,
    required this.text,
    this.routeLocation,
    this.snackbarMessage,
  });

  const ForwardMessageResult.notForwarded(String text)
    : this(forwarded: false, text: text);

  final bool forwarded;
  final String text;
  final String? routeLocation;
  final String? snackbarMessage;
}

class ForwardMessageIntent {
  const ForwardMessageIntent();

  ForwardMessageResult forward(
    NavivoxChannel channel, {
    required NavivoxChatMessage message,
    required NavivoxProfileContact target,
  }) {
    final text = forwardText(message);
    if (text.isEmpty) return ForwardMessageResult.notForwarded(text);

    channel.selectProfileContact(
      serverId: target.serverId,
      profileId: target.profileId,
    );
    channel.sendText(text);
    return ForwardMessageResult(
      forwarded: true,
      text: text,
      routeLocation: AppRoutes.chatLocation(
        serverId: target.serverId,
        profileId: target.profileId,
      ),
      snackbarMessage: 'Forwarded to ${target.displayName}',
    );
  }

  String forwardText(NavivoxChatMessage message) {
    return TranscriptMessagePlainTextPresentation.fromMessage(message).text;
  }
}
