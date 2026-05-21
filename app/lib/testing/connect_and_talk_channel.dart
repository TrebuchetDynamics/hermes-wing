import '../core/channel/gateway_navivox_channel.dart';
import '../core/channel/navivox_channel.dart';
import '../core/protocol/navivox_event.dart';

class ConnectAndTalkChannel extends GatewayNavivoxChannel {
  NavivoxChannelState _state = const NavivoxChannelState();
  String? connectedBaseUrl;
  final List<String> sentTexts = [];

  @override
  NavivoxChannelState get state => _state;

  @override
  Future<void> connect({required String baseUrl, String? token}) async {
    connectedBaseUrl = baseUrl;
    const server = NavivoxServer(
      id: 'navivox-gateway',
      name: 'Gormes Gateway',
      status: 'Gateway online - 127.0.0.1:8765',
    );
    const profile = NavivoxProfileContact(
      serverId: 'navivox-gateway',
      profileId: 'default',
      displayName: 'Default profile',
      serverLabel: 'Gormes Gateway',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Gateway online',
      micAvailable: true,
    );
    _state = _state.copyWith(
      servers: [server],
      activeServerId: server.id,
      profileContacts: [profile],
    );
    notifyListeners();
  }

  @override
  void sendText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    sentTexts.add(trimmed);
    final now = DateTime(2026, 5, 16, 9, 41);
    final messages = Map<String, NavivoxChatMessage>.from(_state.messages);
    messages['user-${sentTexts.length}'] = NavivoxChatMessage(
      id: 'user-${sentTexts.length}',
      author: NavivoxMessageAuthor.user,
      kind: NavivoxMessageKind.text,
      createdAt: now,
      text: trimmed,
    );
    messages['assistant-${sentTexts.length}'] = NavivoxChatMessage(
      id: 'assistant-${sentTexts.length}',
      author: NavivoxMessageAuthor.assistant,
      kind: NavivoxMessageKind.text,
      createdAt: now,
      text: 'hello from gateway',
    );
    _state = _state.copyWith(messages: messages);
    notifyListeners();
  }

  @override
  void selectProfileContact({
    required String serverId,
    required String profileId,
  }) {
    _state = _state.copyWith(
      activeServerId: serverId,
      selectedProfileContactKey: '$serverId::$profileId',
    );
    notifyListeners();
  }

  @override
  void sendVoice({required String transcript}) {
    sendText(transcript);
  }

  @override
  void cancelActiveTurn() {}

  @override
  void stopActiveTurn() {}
}

class FailingConnectChannel extends GatewayNavivoxChannel {
  @override
  Future<void> connect({required String baseUrl, String? token}) async {
    throw StateError('connection failed for $token');
  }
}
