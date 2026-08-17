import '../models/hermes_capabilities.dart';

class HermesTransportPolicy {
  const HermesTransportPolicy(this.capabilities);

  final HermesCapabilityDocument capabilities;

  bool get supportsSessionChatStream {
    return capabilities.supportsFeature('session_chat_streaming') &&
        _endpointReady(
          'session_chat_stream',
          'POST',
          '/api/sessions/{session_id}/chat/stream',
        );
  }

  bool get supportsAnyChatTransport =>
      supportsSessionChatStream || supportsRunsTransport;

  bool get supportsRunsTransport {
    return capabilities.supportsFeature('run_submission') &&
        capabilities.supportsFeature('run_events_sse') &&
        _endpointReady('runs', 'POST', '/v1/runs') &&
        _endpointReady('run_events', 'GET', '/v1/runs/{run_id}/events');
  }

  bool get supportsRunStatus =>
      capabilities.supportsFeature('run_status') &&
      _endpointReady('run_status', 'GET', '/v1/runs/{run_id}');

  bool get supportsRunStop =>
      capabilities.supportsFeature('run_stop') &&
      _endpointReady('run_stop', 'POST', '/v1/runs/{run_id}/stop');

  bool get supportsRunApprovalResponse =>
      capabilities.supportsFeature('run_approval_response') &&
      _endpointReady('run_approval', 'POST', '/v1/runs/{run_id}/approval');

  bool get supportsToolProgressEvents =>
      capabilities.supportsSchema &&
      capabilities.supportsFeature('tool_progress_events');

  bool get supportsConfigWrite =>
      capabilities.supportsSchema &&
      capabilities.supportsFeature('admin_config_rw');
  bool get supportsMemoryWrite =>
      capabilities.supportsSchema &&
      capabilities.supportsFeature('memory_write_api');
  bool get supportsAudioApi =>
      capabilities.supportsSchema && capabilities.supportsFeature('audio_api');
  bool get supportsSpeechSynthesis =>
      supportsAudioApi &&
      _endpointReady('audio_speak', 'POST', '/api/audio/speak');
  bool get supportsSpeechTranscription =>
      supportsAudioApi &&
      _endpointReady('audio_transcribe', 'POST', '/api/audio/transcribe');
  bool get supportsRealtimeVoice =>
      capabilities.supportsSchema &&
      capabilities.supportsFeature('realtime_voice');

  /// Gates a named endpoint on schema support, every declared caller scope,
  /// and, when the server marks it `profile_scoped`, on a declared and
  /// understood profile-context contract. This never mutates or
  /// erases [capabilities] itself — only the derived boolean operations are
  /// hidden when the client cannot safely use them.
  bool _endpointReady(String name, String method, String path) {
    if (!capabilities.supportsSchema) return false;
    if (!capabilities.advertisesEndpoint(name, method, path)) return false;
    final endpoint = capabilities.endpoints[name];
    if (endpoint == null) return false;
    if (endpoint.requiredScopes.any(
      (scope) => !capabilities.auth.allows(scope),
    )) {
      return false;
    }
    if (endpoint.profileScoped &&
        !capabilities.profileContext.isSupportedQueryContext) {
      return false;
    }
    return true;
  }
}
