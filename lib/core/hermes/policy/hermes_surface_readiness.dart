import '../models/hermes_capabilities.dart';
import 'hermes_transport_policy.dart';

enum HermesSurfaceStatus { available, readOnly, deferred, blocked }

extension HermesSurfaceStatusLabel on HermesSurfaceStatus {
  String get label => switch (this) {
    HermesSurfaceStatus.available => 'Available',
    HermesSurfaceStatus.readOnly => 'Read-only',
    HermesSurfaceStatus.deferred => 'Deferred',
    HermesSurfaceStatus.blocked => 'Blocked',
  };
}

class HermesSurfaceReadiness {
  const HermesSurfaceReadiness({
    required this.title,
    required this.status,
    required this.detail,
  });

  final String title;
  final HermesSurfaceStatus status;
  final String detail;
}

List<HermesSurfaceReadiness> hermesSurfaceReadiness(
  HermesCapabilityDocument capabilities,
) {
  final policy = HermesTransportPolicy(capabilities);
  final supportsSessions = capabilities.advertisesEndpoint(
    'sessions',
    'GET',
    '/api/sessions',
  );
  final supportsSessionCreate = capabilities.advertisesEndpoint(
    'session_create',
    'POST',
    '/api/sessions',
  );
  final advertisesDetailedHealth =
      capabilities.supportsSchema &&
      capabilities.auth.allows('gateway:read') &&
      capabilities.advertisesScopedEndpoint(
        'health_detailed',
        'GET',
        '/health/detailed',
        'gateway:read',
      );
  final advertisesJobsList =
      capabilities.supportsSchema &&
      capabilities.auth.allows('tasks:read') &&
      capabilities.advertisesScopedEndpoint(
        'jobs',
        'GET',
        '/api/jobs',
        'tasks:read',
      );
  final supportsJobsAdmin =
      capabilities.supportsFeature('jobs_admin') && advertisesJobsList;
  final supportsAttachments =
      capabilities.supportsFeature('attachments_api') ||
      capabilities.supportsFeature('multimodal_chat');
  final supportsPersonaRead =
      capabilities.supportsSchema &&
      capabilities.auth.allows('profiles:read') &&
      capabilities.advertisesScopedEndpoint(
        'profile_soul',
        'GET',
        '/api/profiles/{name}/soul',
        'profiles:read',
      );
  final supportsPersonaWrite =
      capabilities.supportsSchema &&
      capabilities.auth.allows('profiles:write') &&
      capabilities.advertisesScopedEndpoint(
        'profile_soul_update',
        'PUT',
        '/api/profiles/{name}/soul',
        'profiles:write',
      );
  final advertisedServerAudio =
      policy.supportsRealtimeVoice || policy.supportsAudioApi;

  return [
    HermesSurfaceReadiness(
      title: 'Chat transport',
      status: policy.supportsAnyChatTransport
          ? HermesSurfaceStatus.available
          : HermesSurfaceStatus.blocked,
      detail: policy.supportsRunsTransport
          ? 'Runs SSE transport; approval, tool progress, and stop controls are capability-gated separately.'
          : policy.supportsSessionChatStream
          ? 'Session chat streaming fallback.'
          : 'No supported Hermes chat stream endpoint advertised.',
    ),
    HermesSurfaceReadiness(
      title: 'Sessions',
      status: supportsSessions && supportsSessionCreate
          ? HermesSurfaceStatus.available
          : HermesSurfaceStatus.blocked,
      detail: supportsSessions && supportsSessionCreate
          ? 'List, create, select, rename, delete, and fork when advertised.'
          : 'Required session list/create endpoints are missing.',
    ),
    const HermesSurfaceReadiness(
      title: 'Local voice-to-text',
      status: HermesSurfaceStatus.available,
      detail: 'Device speech capture submits transcripts as Hermes text turns.',
    ),
    HermesSurfaceReadiness(
      title: 'Server realtime voice/audio',
      status: advertisedServerAudio
          ? HermesSurfaceStatus.blocked
          : HermesSurfaceStatus.deferred,
      detail: advertisedServerAudio
          ? 'Hermes server audio/realtime voice is advertised, but Hermes Wing has not wired server audio; device STT -> Hermes text remains the voice path.'
          : 'Hermes realtime/server audio is not advertised; device STT -> Hermes text remains the voice path.',
    ),
    HermesSurfaceReadiness(
      title: 'Config editing/admin',
      status: HermesSurfaceStatus.deferred,
      detail: policy.supportsConfigWrite
          ? 'admin_config_rw is advertised, but Hermes config editing is not wired in Hermes Wing.'
          : 'admin_config_rw is not advertised; Hermes Wing keeps this hidden.',
    ),
    HermesSurfaceReadiness(
      title: 'Gateway health',
      status: advertisesDetailedHealth
          ? HermesSurfaceStatus.readOnly
          : HermesSurfaceStatus.deferred,
      detail: advertisesDetailedHealth
          ? 'The gateway advertises bounded detailed health; lifecycle, logs, and configuration remain unavailable.'
          : 'Detailed gateway health is not advertised for this connection.',
    ),
    HermesSurfaceReadiness(
      title: 'Memory UI',
      status: HermesSurfaceStatus.deferred,
      detail: policy.supportsMemoryWrite
          ? 'Hermes memory API is advertised, but Hermes Wing memory UI is not wired.'
          : 'memory_write_api is not advertised; Hermes memory stays hidden.',
    ),
    HermesSurfaceReadiness(
      title: 'Jobs/schedules inventory',
      status: advertisesJobsList
          ? HermesSurfaceStatus.readOnly
          : HermesSurfaceStatus.deferred,
      detail: advertisesJobsList
          ? 'Jobs list endpoint is advertised; Hermes Wing shows a read-only inventory.'
          : 'Jobs list endpoint is not advertised for mobile use.',
    ),
    HermesSurfaceReadiness(
      title: 'Jobs/schedules admin',
      status: HermesSurfaceStatus.deferred,
      detail: supportsJobsAdmin
          ? 'Jobs admin is advertised, but Hermes Wing has not wired create/pause/resume/trigger/delete scheduling; no mobile mutation controls are shown.'
          : 'Jobs create/pause/resume/trigger/delete scheduling remains unavailable; no mobile mutation controls are shown.',
    ),
    const HermesSurfaceReadiness(
      title: 'Messaging gateways',
      status: HermesSurfaceStatus.deferred,
      detail:
          'No safe mobile Hermes gateway admin contract is wired; no gateway mutation controls are shown.',
    ),
    HermesSurfaceReadiness(
      title: 'Persona/SOUL',
      status: supportsPersonaRead && supportsPersonaWrite
          ? HermesSurfaceStatus.available
          : supportsPersonaRead
          ? HermesSurfaceStatus.readOnly
          : HermesSurfaceStatus.deferred,
      detail: supportsPersonaRead && supportsPersonaWrite
          ? 'Persona/SOUL is available through the gateway-scoped profile editor.'
          : supportsPersonaRead
          ? 'Persona/SOUL is readable, but this device cannot write it.'
          : 'Persona/SOUL remains hidden until the gateway advertises the exact scoped profile soul contract.',
    ),
    HermesSurfaceReadiness(
      title: 'Attachments/media',
      status: supportsAttachments
          ? HermesSurfaceStatus.available
          : HermesSurfaceStatus.deferred,
      detail: supportsAttachments
          ? 'Inline supported images and bounded UTF-8 text attachments are available; arbitrary media still requires opaque server resource handles.'
          : 'Bounded UTF-8 text is available; images and arbitrary media remain unavailable without an advertised mobile-safe contract.',
    ),
    const HermesSurfaceReadiness(
      title: 'Files/context folders',
      status: HermesSurfaceStatus.deferred,
      detail:
          'Files/context folders are not wired; they need mobile-safe workspace and remote path semantics before controls appear.',
    ),
    const HermesSurfaceReadiness(
      title: 'Bounded diagnostics',
      status: HermesSurfaceStatus.readOnly,
      detail:
          'Safe copyable status is available; raw logs and payloads remain excluded.',
    ),
    const HermesSurfaceReadiness(
      title: 'Raw diagnostics/log export',
      status: HermesSurfaceStatus.deferred,
      detail:
          'Raw logs, transcripts, credentials, and tool payload export remain excluded until a safe redaction contract exists.',
    ),
    const HermesSurfaceReadiness(
      title: 'Multi-endpoint/profile management',
      status: HermesSurfaceStatus.available,
      detail:
          'Saved Hermes endpoint profiles can be labeled, selected, renamed, or removed without storing API keys outside secure storage.',
    ),
  ];
}
