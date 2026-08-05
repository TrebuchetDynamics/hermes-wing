import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/protocol/voice/models/wing_voice_run.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';

VoiceCapture voiceSmokeCapture(String transcript) => VoiceCapture(
  audio: Uint8List.fromList(transcript.codeUnits),
  transcript: transcript,
  duration: const Duration(milliseconds: 500),
  confidence: 0.95,
);

class QueueVoiceCaptureService extends ChangeNotifier
    implements VoiceCaptureService {
  QueueVoiceCaptureService(
    List<VoiceCapture> captures, {
    this.waitWhenEmpty = false,
  }) : _captures = List.of(captures);

  final List<VoiceCapture> _captures;
  final bool waitWhenEmpty;
  int captureCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls += 1;
    notifyListeners();
    if (_captures.isNotEmpty) return Future.value(_captures.removeAt(0));
    if (waitWhenEmpty) return Completer<VoiceCapture>().future;
    throw StateError('No queued voice capture');
  }

  @override
  Future<void> cancel() async {}
}

class AndroidHermesVoiceSmokeChannel extends ChangeNotifier
    implements HermesChannel {
  AndroidHermesVoiceSmokeChannel()
    : _state = const HermesChannelState(
        status: HermesConnectionStatus.connected,
        sessions: [HermesSession(id: _sessionId, source: 'android-smoke')],
        activeSessionId: _sessionId,
        messages: {_sessionId: <HermesChatTurn>[]},
      );

  static const _sessionId = 'android-smoke-session';

  final sentVoiceTranscripts = <String>[];
  int _voiceRunCounter = 0;
  HermesChannelState _state;
  final _approvals = StreamController<HermesApprovalRequest>.broadcast();

  @override
  HermesChannelState get state => _state;

  @override
  Stream<HermesApprovalRequest> get approvalRequests => _approvals.stream;

  @override
  void dispose() {
    _approvals.close();
    super.dispose();
  }

  void _setState(HermesChannelState next) {
    _state = next;
    notifyListeners();
  }

  void _setMessages(List<HermesChatTurn> messages) {
    _setState(
      _state.copyWith(messages: {..._state.messages, _sessionId: messages}),
    );
  }

  @override
  Future<void> sendText(
    String text, {
    String? imageDataUrl,
    String? textAttachment,
    String? attachmentName,
  }) async {
    final now = DateTime.now();
    _setMessages([
      ..._state.activeMessages,
      HermesChatTurn(
        id: 'user-${_state.activeMessages.length}',
        sessionId: _sessionId,
        author: HermesTurnAuthor.user,
        text: text,
        createdAt: now,
      ),
      HermesChatTurn(
        id: 'assistant-${_state.activeMessages.length}',
        sessionId: _sessionId,
        author: HermesTurnAuthor.assistant,
        text: 'echo: $text',
        createdAt: now,
      ),
    ]);
  }

  @override
  String startVoiceRun() {
    final id = 'voice-${++_voiceRunCounter}';
    final now = DateTime.now();
    _setState(
      _state.copyWith(
        activeVoiceRunId: id,
        voiceRuns: {
          ..._state.voiceRuns,
          id: WingVoiceRun.recording(
            id: id,
            serverId: 'hermes',
            profileId: _sessionId,
            createdAt: now,
          ),
        },
      ),
    );
    return id;
  }

  @override
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
  }) {
    final run = _state.voiceRuns[voiceRunId]!;
    _setState(
      _state.copyWith(
        voiceRuns: {
          ..._state.voiceRuns,
          voiceRunId: run.withDeviceTranscript(
            transcript: transcript,
            duration: duration,
            confidence: confidence,
            updatedAt: DateTime.now(),
          ),
        },
      ),
    );
  }

  @override
  void submitVoiceRun(String voiceRunId) {
    final run = _state.voiceRuns[voiceRunId]!;
    final transcript = run.transcript!;
    sentVoiceTranscripts.add(transcript);
    _setState(
      _state.copyWith(
        voiceRuns: {
          ..._state.voiceRuns,
          voiceRunId: run
              .markSubmitted(
                requestId: 'request-$voiceRunId',
                sessionId: _sessionId,
              )
              .markCompleted(),
        },
        clearActiveVoiceRunId: true,
      ),
    );
    unawaited(sendText(transcript));
  }

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> selectSession(String sessionId) async {}

  @override
  Future<void> createSession({String? title}) async {}

  @override
  Future<void> renameSession({
    required String sessionId,
    required String title,
  }) async {}

  @override
  Future<void> deleteSession(String sessionId) async {}

  @override
  Future<void> forkSession(String sessionId, {String? title}) async {}

  @override
  Future<void> selectProfile(String profileId) async {}

  @override
  Future<void> createProfile({required String name, String? cloneFrom}) async {}

  @override
  Future<void> renameProfile({
    required String profileId,
    required String name,
    required String revision,
  }) async {}

  @override
  Future<void> deleteProfile({
    required String profileId,
    required String revision,
  }) async {}

  @override
  Future<HermesProfileSoul> readProfileSoul(String profileId) async =>
      const HermesProfileSoul(soul: '', revision: '');

  @override
  Future<void> writeProfileSoul({
    required String profileId,
    required String soul,
    required String revision,
  }) async {}

  @override
  Future<void> loadDetailedHealth() async {}

  @override
  Future<void> loadJobs() async {}

  @override
  Future<void> loadProviders() async {}

  @override
  Future<void> setProviderCredential({
    required String slug,
    required String envVar,
    required String value,
  }) async {}

  @override
  Future<void> removeProviderCredential({
    required String slug,
    required String envVar,
  }) async {}

  @override
  Future<HermesCredentialProbe> validateProviderCredential({
    required String slug,
  }) async => const HermesCredentialProbe(ok: true);

  @override
  Future<void> loadModels() async {}

  @override
  Future<void> refreshModels() async {}

  @override
  Future<void> assignModel({
    required String scope,
    String? task,
    required String provider,
    required String model,
    required String revision,
  }) async {}

  @override
  void cancelActiveTurn() {}

  @override
  void stopActiveTurn() {}

  @override
  Future<void> respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
  }) async {}

  @override
  void cancelVoiceRun(String voiceRunId, {String reason = 'cancelled'}) {}

  @override
  void failVoiceRun(String voiceRunId, {required String reason}) {}
}
