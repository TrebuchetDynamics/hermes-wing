import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/core/protocol/navivox_event.dart';

import '../../../shared/profiles/profile_contact_chat_test_fixtures.dart';
import '../../../shared/protocol/chat_message_test_fixtures.dart';
import 'transcript_fixture_defaults.dart';

/// Shared Profile contact target used by transcript forwarding/action tests.
const transcriptSupportContact = chatSupportTriageContact;

/// Secondary Profile contact target used when tests need multiple destinations.
const transcriptOpsContact = NavivoxProfileContact(
  serverId: 'lab',
  profileId: 'ops',
  displayName: 'Ops Desk',
  serverLabel: 'lab',
  health: NavivoxProfileHealth.warning,
  latestPreview: 'Watching devices',
);

NavivoxChatMessage transcriptChatMessage({
  String id = 'message-1',
  required NavivoxMessageKind kind,
  NavivoxMessageAuthor author = NavivoxMessageAuthor.assistant,
  DateTime? createdAt,
  String? text,
  NavivoxToolCall? toolCall,
  NavivoxVoiceMessage? voice,
  NavivoxSafetyNotice? safetyNotice,
  String? runRecordReference,
  String? serverId,
  String? profileId,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: kind,
    createdAt: createdAt ?? transcriptDefaultCreatedAt,
    text: text,
    toolCall: toolCall,
    voice: voice,
    safetyNotice: safetyNotice,
    runRecordReference: runRecordReference,
    serverId: serverId,
    profileId: profileId,
  );
}

NavivoxChatMessage transcriptTextMessage({
  String id = 'text-1',
  String? text,
  NavivoxMessageAuthor author = NavivoxMessageAuthor.assistant,
  DateTime? createdAt,
  String? runRecordReference,
  String? serverId,
  String? profileId,
}) {
  return chatTextMessage(
    id: id,
    author: author,
    createdAt: createdAt ?? transcriptDefaultCreatedAt,
    text: text,
    runRecordReference: runRecordReference,
    serverId: serverId,
    profileId: profileId,
  );
}

NavivoxVoiceMessage transcriptVoice({
  String transcript = '',
  Duration duration = const Duration(seconds: 1),
  double confidence = 0.9,
}) {
  return NavivoxVoiceMessage(
    duration: duration,
    transcript: transcript,
    confidence: confidence,
  );
}

NavivoxChatMessage transcriptVoiceMessage({
  String id = 'voice-1',
  String transcript = '',
  NavivoxMessageAuthor author = NavivoxMessageAuthor.user,
  DateTime? createdAt,
  Duration duration = const Duration(seconds: 1),
  double confidence = 0.9,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: NavivoxMessageKind.voice,
    createdAt: createdAt ?? transcriptDefaultCreatedAt,
    voice: transcriptVoice(
      duration: duration,
      transcript: transcript,
      confidence: confidence,
    ),
  );
}

NavivoxToolApproval transcriptShellApproval({
  String id = 'approval-shell',
  String status = 'approval_required',
  String prompt = 'Approve shell.run?',
  String risk = 'Writes files',
}) {
  return NavivoxToolApproval(
    id: id,
    status: status,
    prompt: prompt,
    risk: risk,
  );
}

NavivoxToolArtifact transcriptDiffArtifact({
  String id = 'a-1',
  String kind = 'file',
  String title = 'diff.patch',
  String? summary = '14 lines changed',
  String? ref,
}) {
  return NavivoxToolArtifact(
    id: id,
    kind: kind,
    title: title,
    summary: summary,
    ref: ref,
  );
}

NavivoxToolArtifact transcriptScreenshotArtifact({
  String id = 'a-2',
  String kind = 'image',
  String title = 'screenshot.png',
  String? summary,
  String? ref,
}) {
  return NavivoxToolArtifact(
    id: id,
    kind: kind,
    title: title,
    summary: summary,
    ref: ref,
  );
}

NavivoxToolCall transcriptToolCall({
  String name = 'grep',
  String status = 'finished',
  String summary = 'Matched 2 files',
  NavivoxToolApproval? approval,
  List<NavivoxToolArtifact> artifacts = const [],
}) {
  return NavivoxToolCall(
    name: name,
    status: status,
    summary: summary,
    approval: approval,
    artifacts: artifacts,
  );
}

NavivoxChatMessage transcriptToolMessage({
  String id = 'tool-1',
  required NavivoxToolCall toolCall,
  NavivoxMessageAuthor author = NavivoxMessageAuthor.system,
  DateTime? createdAt,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: NavivoxMessageKind.toolCall,
    createdAt: createdAt ?? transcriptDefaultCreatedAt,
    toolCall: toolCall,
  );
}

NavivoxChatMessage transcriptNoticeMessage({
  String id = 'notice-1',
  required NavivoxMessageKind kind,
  required NavivoxSafetyNotice notice,
  NavivoxMessageAuthor author = NavivoxMessageAuthor.system,
  DateTime? createdAt,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: kind,
    createdAt: createdAt ?? transcriptDefaultCreatedAt,
    safetyNotice: notice,
  );
}

NavivoxRunRecordSnapshot transcriptRunRecordSnapshot({
  String runId = 'req-run-record',
  String sessionId = 's-run-record',
  String status = 'completed',
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? completedAt,
}) {
  return NavivoxRunRecordSnapshot(
    runId: runId,
    sessionId: sessionId,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    completedAt: completedAt,
    raw: const {
      'transcript': [
        {'role': 'user', 'text': 'transcribed voice command'},
        {'role': 'assistant', 'text': 'assistant final answer'},
      ],
      'voice': {
        'device_transcript': 'transcribed voice command',
        'audio': {
          'duration_ms': 1200,
          'codec': 'opus',
          'raw_audio_stored': false,
          'retention': 'not_stored',
        },
        'server_stt': {'provider': 'local', 'status': 'available'},
        'tts': {'provider': 'piper', 'voice_id': 'amy', 'status': 'ready'},
      },
      'provider_usage': {'status': 'unknown'},
      'provider_cost': {'status': 'unknown'},
      'tool_events': [
        {
          'tool_call_id': 'tool-1',
          'name': 'read_file',
          'status': 'finished',
          'metadata': {
            'artifact_ref': 'artifact://readme',
            'secret_token': 'must-not-render',
          },
        },
      ],
    },
  );
}

NavivoxSafetyNotice transcriptSafetyNotice({
  String id = 'safety-1',
  String? severity,
  required String message,
  String? risk,
}) {
  return NavivoxSafetyNotice(
    id: id,
    severity: severity,
    message: message,
    risk: risk,
  );
}

NavivoxSafetyNotice transcriptApprovalNotice({
  String id = 'approval-1',
  String? severity,
  String? approvalId,
  String? toolCallId,
  required String message,
  String? risk,
}) {
  return NavivoxSafetyNotice(
    id: id,
    severity: severity,
    approvalId: approvalId,
    toolCallId: toolCallId,
    message: message,
    risk: risk,
  );
}
